local skynet = require "skynet"
local socket = require "socket"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local string = string
local cjson = require "cjson"
local utils = require "utils"
local crc32 = require "crc32"

local function response(id, code, msg, ...)
    utils.print(msg)
    local ok, err = httpd.write_response(sockethelper.writefunc(id), code, msg, ...)
    if not ok then
        -- if err == sockethelper.socket_error , that means socket closed.
        skynet.error(string.format("fd = %d, %s", id, err))
    end
end

local function get_web_proxy(id, body)
    local ret = skynet.call("server_list", "lua", "get_web_proxy", msg)
    response(id, 200, cjson.encode(ret))
end

local function get_tcp_proxy(id, body)
    local ret = skynet.call("server_list", "lua", "get_tcp_proxy", msg)
    response(id, 200, cjson.encode(ret))
end

local function handle(id)
    socket.start(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, _, _, body = httpd.read_request(sockethelper.readfunc(id), 128)
    if not code or code ~= 200 then
        skynet.error("状态码不对")
        print(code)
        socket.close(id)
        return
    end
    print(url, body)
    --local sign = string.sub(body,2,9)
    --local content = string.sub(body,11)
    --if sign ~= crc32.hash(content) then
        --skynet.error("body签名不对")
        --socket.close(id)
        --return
    --end
    if url == "/get_web_proxy" then
        get_web_proxy(id, body)
    elseif url == "/get_tcp_proxy" then
        get_tcp_proxy(id, body)
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
