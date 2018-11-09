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
    msg = utils.base64encode(msg)
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

--　获取房间列表
local function get_record_room_list(id, body)
    local msg = cjson.decode(body)
    local info = skynet.call("recorder", "lua", "get_record_room_list", msg)
    response(id, 200, cjson.encode(info))
end

--　获取回放列表
local function get_record_list(id, body)
    local msg = cjson.decode(body)
    local info = skynet.call("recorder", "lua", "get_record_list", msg)
    response(id, 200, cjson.encode(info))
end

--　获取回放游戏数据
local function get_record_game(id, body)
    local msg = cjson.decode(body)
    local info = skynet.call("recorder", "lua", "get_record_game", msg)
    if info then
        response(id, 200, cjson.encode(info))
    else
        response(id, 1, "")
    end
end

local function handle(id)
    socket.start(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if not code or code ~= 200 then
        socket.close(id)
        return
    end

    if code ~= 200 then
        socket.close(id)
        return
    end

    if body then
        body = utils.base64decode(body)
    end

    local path, query = urllib.parse(url)
    print(path, query, body)

    if path == "/get_record_room_list" then
        get_record_room_list(id, body)
    elseif path == "/get_record_list" then
        get_record_list(id, body)
    elseif path == "/get_record_game" then
        get_record_game(id, body)
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
