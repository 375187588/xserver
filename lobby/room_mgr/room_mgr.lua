local skynet = require "skynet"
local utils = require "utils"
local crypt_host = require "crypt_host"
local id_mgr = require "id_mgr"
local room = require "room"
local G = require "global"

local M = {}

function M:init()
    id_mgr:init()
    self.room_tbl = {}
    self.player_2_room = {}
end

function M:get_player_info(userid)
    local info = {}
    local roomid = self.player_2_room[userid]
    if not roomid then
        return info
    end

    local r = self.room_tbl[roomid]
    if not r then
        return info
    end

    info.roomid = roomid
    info.gameid = r.game_id
    info.ip = r.ip
    info.port = r.port
    info.ticket = r.ticket

    return info
end

function M:create(msg, player_info)
    local id = id_mgr:gen_id()
    local gameid = msg.nGameID
    local req_msg = {
        room = {
            roomid = id,
            gameid = gameid,
            costcard = msg.costcard,
            options = msg.options,
        },
        player = player_info,
    }

    local g = G.game_mgr:get(gameid)
    if not g then
        return
    end
    local server = g:get_random_server()
    if not server then
       return
    end
    local ret = skynet.call("httpclient", "lua",
        "post", server.host,"/create_room", req_msg)
    local r = room.new(id, gameid, player_info, server, ret.ticket)
    self.room_tbl[id] = r
    self.player_2_room[player_info.userid] = id
    g:add_room(r)
    return {
        roomid = id,
        host = crypt_host.crypt(server.ip..":"..server.port),
        ticket = ret.ticket,
    }
end

function M:join(roomid, player_info)
    local r = self.room_tbl[roomid]
    if not r then
        return false
    end
    local msg = {roomid = roomid, player = player_info}

    local ret = skynet.call("httpclient", "lua",
        "post", r.host, "/join_room", msg)
    if not ret then
        return false
    end
    return {
        gameid = r.game_id,
        host = crypt_host.crypt(r.ip..":"..r.port),
    }
end

-- 来自游戏服的消息-玩家加入房间成功
function M:join_room_result(info)
    local r = self.room_tbl[info.roomid]
    if not r then
        return
    end

    r:join(info.userid)
    self.player_2_room[info.userid] = info.roomid
end

-- 来自游戏服的消息，游戏结束
function M:game_finish(info)
    local r = self.room_tbl[info.roomid]
    if not r then
        return
    end
    for _,userid in pairs(r.players) do
        self.player_2_room[userid] = nil
    end
    self.room_tbl[info.roomid] = nil
    local g = G.game_mgr:get(r.game_id)
    if g then
        g:del_room(r)
    end
end

-- 来自游戏服的消息，玩家离开房间
function M:leave_room_result(info)
    local r = self.room_tbl[info.roomid]
    if not r then
        return
    end

    for _, userid in ipairs(info.players) do
        r:leave(userid)
        self.player_2_room[userid] = nil
    end
end

function M:get_room(room_id)
    return self.room_tbl[room_id]
end

return M
