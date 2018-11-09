local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local urllib = require "http.url"
local sockethelper = require "http.sockethelper"
local string = string
local cjson = require "cjson"
local utils = require "utils"

local function response(id, code, msg, ...)
    utils.print(msg)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), code, msg, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

-- 增加回放
local function add_record_list(id, body)
    local msg = cjson.decode(body)
    skynet.send("recorder", "lua", "add_record_list", msg)
    response(id, 200, cjson.encode({}))
end

local function handle(id)
    socket.start(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 16384)
    if not code or code ~= 200 then
        socket.close(id)
        return
    end

    if code ~= 200 then
        socket.close(id)
        return
    end

    local path, query = urllib.parse(url)
    print(path, query)

    if path == "/add_record_list" then
        add_record_list(id, body)
    else
        print(path)
    end
    socket.close(id)
end

skynet.start(function()
    skynet.dispatch("lua", function (_,_,id)
      handle(id)
     -- if not pcall(handle, id) then
      --    response(id, 200, "{\"msg\"=\"exception\"}")
     -- end
    end)
end)
