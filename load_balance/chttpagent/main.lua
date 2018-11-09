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

local function web_proxy_heartbeat(id, body)
    local msg = cjson.decode(body)
    response(id, 200, "SUCCESS")
    if msg.host then
        skynet.send("server_list", "lua", "web_proxy_heartbeat", msg)
    end
end

local function tcp_proxy_heartbeat(id, body)
    local msg = cjson.decode(body)
    response(id, 200, "SUCCESS")
    skynet.send("server_list", "lua", "tcp_proxy_heartbeat", msg)
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
    if not body then
        skynet.error("body长度不够")
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
    if url == "/web_proxy_heartbeat" then
        web_proxy_heartbeat(id, body)
    elseif url == "/tcp_proxy_heartbeat" then
        tcp_proxy_heartbeat(id, body)
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
