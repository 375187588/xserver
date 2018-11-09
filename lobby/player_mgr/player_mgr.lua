local skynet = require "skynet"
local crypt = require "crypt"
local md5 = require "md5"
local utils = require "utils"

local sign_key = "do you know"

local M = {}

function M:init()
    self.tbl = {}
end

function M:get(userid)
    return self.tbl[userid]
end

function M:load(userid)
    local obj = self.tbl[userid]
    if obj then
        return obj
    end

    --obj = skynet.call("redis", "lua", "load_player", userid)
    obj = skynet.call("mongo", "lua", "load_player", userid)
    if not obj then
        return
    end

    self.tbl[userid] = obj
    return obj
end

function M:save(userid)
    local obj = self:get(userid)
    if not obj then
        return
    end
    --skynet.call("redis", "lua", "save_player", obj)
    skynet.call("mongo", "lua", "save_player", obj)
end

function M:create(info)
    local obj = utils.copy_table(info)
    obj.score = 0
    obj.roomcard = 5
    obj.roomid = 0
    obj.sign = crypt.hexencode(md5.sum(sign_key..obj.userid))
    obj.lottery_draw_waresid = nil
    obj.lottery_draw_time = nil
    obj.lottery_draw_count = nil

    self.tbl[info.userid] = obj

    -- 保存玩家信息
    skynet.send("mongo", "lua", "new_player", obj)
    return obj
end

function M:update(userid, key, data)
    local obj = self:get(userid)
    if not obj then
        return
    end

    if not obj[key] then
        return
    end

    obj[key] = data

    --skynet.call("redis", "lua", "save_player", obj)
    skynet.call("mongo", "lua", "update_player", obj)
end

return M
