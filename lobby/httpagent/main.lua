local skynet = require "skynet"
local socket = require "socket"
local crypt = require "crypt"
local httpd = require "http.httpd"
local sockethelper = require "http.sockethelper"
local urllib = require "http.url"
local string = string
local cjson = require "cjson"
local utils = require "utils"
local openssll = require "openssll"

local function response(id, code, msg, ...)
    utils.print(msg)
  local ok, err = httpd.write_response(sockethelper.writefunc(id), code, msg, ...)
  if not ok then
    -- if err == sockethelper.socket_error , that means socket closed.
    skynet.error(string.format("fd = %d, %s", id, err))
  end
end

local function server_heartbeat(id, body)
    skynet.send("xlog", "lua", "log", "游戏服务器心跳"..body)
    local msg = cjson.decode(body)
    local ret = skynet.call("room_mgr", "lua", "server_heartbeat", msg)
    response(id, 200, cjson.encode(ret))
end

local function server_room_list(id, body)
    skynet.send("xlog", "lua", "log", "游戏服务器上报房间列表房间"..body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "server_room_list", msg)

    local ret_msg = {
        err = "success"
    }
    response(id, 200, cjson.encode(ret_msg))
end

local function server_stop_newroom(id, body)
    skynet.send("xlog", "lua", "log", "游戏服务器停止创建房间"..body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "server_stop_newroom", msg)

    local ret_msg = {
        err = "success"
    }
    response(id, 200, cjson.encode(ret_msg))
end

local function server_close(id, body)
    skynet.send("xlog", "lua", "log", "游戏服务器停服"..body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "server_close", msg)

    local ret_msg = {
        err = "success"
    }
    response(id, 200, cjson.encode(ret_msg))
end

-- 玩家加入房间成功
local function join_room_result(id, body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "join_room_result", msg)
    response(id, 200, cjson.encode({err = "success"}))
end

local function game_finish(id, body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "game_finish", msg)
    skynet.send("player_mgr", "lua", "finish_room", msg)
    local ret_msg = {
        err = "success"
    }
    response(id, 200, cjson.encode(ret_msg))
end

local function leave_room_result(id, body)
    local msg = cjson.decode(body)
    skynet.send("room_mgr", "lua", "leave_room_result", msg)
    response(id, 200, cjson.encode({err = "success"}))
end

-- 定单支付成功消息
local function order_notify(id, body)
    print(body)
    response(id, 200, "SUCCESS")
end

local PLATP_KEY = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCorO8jND2oPrfuookjgngRi+OKcIJYn9Maf4sR8EvNjHvkFPQ8XJBBMeMt6bhGG7tAXkKEAGGHlyVtkWm55wL2yh81pM4VEpIbgJ8L0tOox3BdQXn/d3O46wCZLNm9adm86/yUhxiGMPhSidUEKVhcw5aldSTrNO1c2w3luMRXFQIDAQAB"
--local PLATP_KEY = "MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCfIa4GsZ9YZzk2HeW4Y/Rk4LsLRJUmwLmLtCcSZs8xP9HBV5OEsBLekcOO3c6Ryb12G7GMJDmunBb0sesz9V6FIuiySrj5rpL+v9BGYaTvgh+0wgLFUN8+9ZQ5VaOGy4878m5A+24A0/qQvHnMHu5emCjf4nw4s4NmfqHSHpochwIDAQAB"
local function ipay_notify(id, body, query)
    print("爱贝支付回调",body, query)
    local querys = urllib.parse_query(body)
    local t = {}
    for k,v in pairs(querys) do
        print(k,utils.decodeurl(v))
        t[k] = utils.decodeurl(v)
    end

    local pubkey = crypt.base64decode(PLATP_KEY)
    local sign = crypt.base64decode(t.sign)
    local valid = openssll.verifymd5withrsa(pubkey, t.transdata, sign)
    if not valid then
        print("支付通知验签失败")
        return
    end
    skynet.send("order", "lua", "ipay_notify", cjson.decode(t.transdata))
    response(id, 200, "SUCCESS")
end

local function virtual_ipay_notify(id, body, query)
    local msg = cjson.decode(body)
    skynet.send("order", "lua", "ipay_notify", msg)
    response(id, 200, "SUCCESS")
end

local function handle(id)
    socket.start(id)
    -- limit request body size to 8192 (you can pass nil to unlimit)
    local code, url, method, header, body = httpd.read_request(sockethelper.readfunc(id), 8192)
    if code ~= 200 then
        skynet.send("xlog", "lua", "log", "大厅服务器WEB端口状态异常url="..url)
        socket.close(id)
        return
    end

    local path, query = urllib.parse(url)
    if path ~= "/server_heartbeat" then
        print(path, query, body)
    end
    if path == "/server_heartbeat" then
        server_heartbeat(id, body)
    elseif path == "/server_stop_newroom" then
        server_stop_newroom(id, body)
    elseif path == "/server_close" then
        server_close(id, body)
    elseif path == "/join_room_result" then
        join_room_result(id, body)
    elseif path == "/game_finish" then
        game_finish(id, body)
    elseif path == "/order_notify" then
        order_notify(id, body)
    elseif path == "/ipay_notify" then
        ipay_notify(id, body, query)
    elseif path == "/leave_room_result" then
        leave_room_result(id, body)
    elseif path == "/virtual_ipay_notify" then
        virtual_ipay_notify(id, body)
    else
        skynet.send("xlog", "lua", "log", "大厅服务器WEB端口url异常"..url)
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
