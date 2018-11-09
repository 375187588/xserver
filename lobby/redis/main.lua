local skynet = require "skynet"
require "skynet.manager"
local db = require "db"
local utils = require "utils"

local CMD = {}

function CMD.start(cfg)
    db:init(cfg)
    db:connect()
end

function CMD.load_player(userid)
    local p = db:get_obj("player:"..userid)
    if next(p) == nil then
        return {}
    end
    local obj = utils.copy_table(p)
    obj.userid = tonumber(obj.userid)
    obj.score = tonumber(obj.score)
    obj.roomcard = tonumber(obj.roomcard)
    obj.roomid = tonumber(obj.roomid)
    obj.lottery_draw_waresid = tonumber(obj.lottery_draw_time)
    obj.lottery_draw_time = tonumber(obj.lottery_draw_time)
    obj.lottery_draw_count = tonumber(obj.lottery_draw_count)
    return obj
end

function CMD.save_player(obj)
    db:save_obj("player:"..obj.userid, obj)
end

function CMD.load_rooms()

end

function CMD.save_order(order)
    db:save_obj("order:"..order.transid, order)
end

function CMD.update_order(transid)
    db:hset("order:"..transid, "get_card_time", os.time())
end

skynet.start(function()
    skynet.dispatch("lua", function(_,session,cmd,...)
        local f = CMD[cmd]
        if not f then
            return
        end

        if session > 0 then
            skynet.ret(skynet.pack(f(...)))
        else
            f(...)
        end
    end)

    skynet.register("redis")
end)
