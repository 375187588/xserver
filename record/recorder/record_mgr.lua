local MongoLib = require "mongolib"
local skynet = require "skynet"
local utils = require "utils"

local mongo_db = "xserver"

local dbconf = {
    host="127.0.0.1",
    port=27017,
    db="game",
--    username="yun",
--    password="yun",
--    authmod="mongodb_cr"
}

local M = {}

function M:init()
    self.mongo = MongoLib.new()
    self.mongo:connect(dbconf)
    self.mongo:use(mongo_db)

    self.tbl = {}
    self.id = 0

    self.tbl_user = {}
    self.tbl_room = {}

    -- 当前清理回放记录
    self.clear_id = 1
    -- 1个小时清理一次过期回放记录
    skynet.timeout(3600*100, function() self:clear_record() end)
end

function M:clear_record()
    -- 1个小时清理一次过期回放记录
    skynet.timeout(3600*100, function() self:clear_record() end)

    -- 一天时间
    local day_time = 86400
    local cur_time = os.time()
    while true do
        if not self.tbl[self.clear_id] then
            break
        end

        local msg = self.tbl[self.clear_id]
        -- 超过时间
        if msg.head.start_time + day_time <= cur_time then
            local room_id = msg.head.room_id
            if room_id ~= nil then
                for _, players in ipairs(msg.players) do
                    local userid = players.userid
                    if userid ~= nil then
                        if self.tbl_user[userid] ~= nil then
                            -- 清除玩家信息
                            self.tbl_user[userid][room_id] = nil
                            if next(self.tbl_user[userid]) == nil then
                                self.tbl_user[userid] = nil
                            end
                        end

                        if self.tbl_room[userid] ~= nil then
                            -- 清除玩家房间信息
                            self.tbl_room[userid][room_id] = nil
                            if next(self.tbl_room[userid]) == nil then
                                self.tbl_room[userid] = nil
                            end
                        end
                    end
                end
            end

            self.tbl[self.clear_id] = nil
            self.clear_id = self.clear_id + 1
        else
            break
        end
    end
end

function M:get_record(id)
    return self.tbl[id]
end

function M:get_id()
    self.id = self.id + 1
    return self.id
end

--[[
    msg = 
    {
        head =
        {
            room_id,            房间ID
            game_id,            游戏ID
            count,              房间第几局
            start_time,         房间开始时间
            end_time,           房间结束时间
        },
        players = 
        {
            {
                userid,         玩家ID
                nickname,       玩家名字
                score,          本局输赢分
                total_score,    本局结束总分
            },
        },
        game = 
        {
            room = {},
            players = {},
            prepare_data = {},
            data = 
            {
                {
                    time,
                    name,
                    msg,
                }
            },
        },
    }
--]]
function M:add_record_list(msg)
    if not msg.players then
        return
    end

    self.mongo:insert("record", msg)

    local id = self:get_id()
    self.tbl[id] = msg

    local room_id = msg.head.room_id
    local room_info = {id = id, head = msg.head, players = msg.players}
    for _, players in ipairs(msg.players) do
        local userid = players.userid
        if self.tbl_room[userid] == nil then
            self.tbl_room[userid] = {}
        end

        if self.tbl_room[userid][room_id] == nil then
            self.tbl_room[userid][room_id] = {}
        end

        table.insert(self.tbl_room[userid][room_id], room_info)
    end

    for _, p in ipairs(msg.players) do
        local userid = p.userid
        if self.tbl_user[userid] == nil then
            self.tbl_user[userid] = {}
        end

        self.tbl_user[userid][room_id] = {head = msg.head, players = msg.players}
    end
end

function M:get_record_room_list(msg)
    local ack = {}
    local gameid = msg.gameid
    if not gameid or gameid <= 0 then
        return ack
    end

    local userid = msg.userid
    if not userid or userid <= 0 then
        return ack
    end

    utils.print(self.tbl_user)
    if not self.tbl_user[userid] then
        return ack
    end

    for _, data in pairs(self.tbl_user[userid]) do
        if data.head.game_id == gameid then
            table.insert(ack, data)
        end
    end
    return ack
end

function M:get_record_list(msg)
    local ack = {}
    local userid = msg.userid
    if not userid or userid <= 0 then
        return ack
    end

    local roomid = msg.roomid
    if not roomid or roomid <= 0 then
        return ack
    end

    if not self.tbl_room[userid] or not self.tbl_room[userid][roomid] then
        return ack
    end

    for _, data in ipairs(self.tbl_room[userid][roomid]) do
        table.insert(ack, data)
    end
    return ack
end

function M:get_record_game(msg)
    if not msg.id or msg.id <= 0 then
        return nil
    end

    if not self.tbl[msg.id] then
        return nil
    end

    local r = utils.copy_table(self.tbl[msg.id])
    -- 置空mongo生成ID
    r._id = nil

    return r
end

return M
