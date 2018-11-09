local skynet = require "skynet"
require "skynet.manager"
local G = require "global"
local room_mgr = require "room_mgr"
local timer_mgr = require "timer_mgr"
local game_mgr = require "game_mgr"

local function init()
    G.timer_mgr = timer_mgr.new()
    G.room_mgr = room_mgr
    G.game_mgr = game_mgr
    G.game_mgr:init()
    room_mgr:init()
end

local CMD = {}

-- 获取玩家房间信息
function CMD.get_player_info(userid)
    return room_mgr:get_player_info(userid)
end

function CMD.create_room(msg, player_info)
    return room_mgr:create(msg, player_info)
end

function CMD.join_room(roomid, player_info)
    return room_mgr:join(roomid, player_info)
end

function CMD.server_heartbeat(info)
    local g = game_mgr:get(info.game_id)
    if not g then
        skynet.send("xlog", "lua", "log",
            "游戏服务器注册找不到游戏类型"..info.game)
        return
    end

    return g:heartbeat(info)
end

function CMD.server_room_list(info)
    local g = G.game_mgr:get(info.game_id)
    if not g then
        return
    end
    g:server_room_list(info)
end

function CMD.server_stop_newroom(info)
    local g = G.game_mgr:get(info.game_id)
    if not g then
        return
    end
    g:server_stop_newroom(info)
end

function CMD.server_close(info)
    local g = G.game_mgr:get(info.game_id)
    if not g then
        return
    end
    g:server_close(info)
end

-- 房间信息-加入房间成功
function CMD.join_room_result(info)
    room_mgr:join_room_result(info)
end

-- 房间消息-游戏结束
function CMD.game_finish(info)
    room_mgr:game_finish(info)
end

-- 房间信息-离开房间成功
function CMD.leave_room_result(info)
    room_mgr:leave_room_result(info)
end

local function dispatch(_, session, cmd, ...)
    local f = CMD[cmd]
    assert(f, "room_mgr接收到非法lua消息: "..cmd)

    if session == 0 then
        f(...)
    else
        skynet.ret(skynet.pack(f(...)))
    end
end

skynet.start(function ()
    skynet.dispatch("lua", dispatch)

    init()

    skynet.register("room_mgr")

    skynet.error("room_mgr booted...")
end)
