local skynet = require "skynet"
local room = require "room"

-- 房间管理器
local M = {}

function M:init()
    self.tbl = {}
    self.tbl_game = {
        [1] = "pdk",
        [2] = "nn",
        [3] = "dgnn",
        [4] = "nxphz",
        [5] = "csmj",
    }
end

function M:get(id)
    return self.tbl[id]
end

function M:remove(obj)
    self.tbl[obj.id] = nil
end

function M:create_room(info)
    local game = self.tbl_game[info.room.gameid]
    local addr = skynet.newservice(game)
    local r = room.new(info.room, addr)
    self.tbl[r.roomid] = r
    skynet.call(addr, "lua", "create", info)
    return r
end

function M:join_room(info)
    local r = self.tbl[info.roomid]
    skynet.call(r.addr, "lua", "join", info)
    return r
end

function M:get_room_addr(room_id)
    local r = self.tbl[room_id]
    return r.addr
end

return M
