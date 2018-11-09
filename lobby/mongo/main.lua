local skynet = require "skynet"
require "skynet.manager"
local mongolib = require "mongolib"
local utils = require "utils"

local db

local CMD = {}

function CMD.start(conf)
    db = mongolib.new()
    db:connect(conf)
    db:use(conf.db)
end

function CMD.close()
    db:disconnect()
    db = nil
end

function CMD.load_player(userid)
    local p = db:find_one("player",{_id=userid},{_id=false})
    return p
end

function CMD.new_player(obj)
    obj._id = obj.userid
    db:insert("player", obj)
end

function CMD.save_player(obj)
    db:update("player", {_id=obj.userid}, obj)
end

function CMD.update_player(obj)
    db:update("player", {_id=obj.userid}, obj)
end

function CMD.get_unfinished_order()
    print("加载没有兑现的订单")
    local it = db:find("account",{get_card_time={['in']="null"}},{_id=false})
    if not it then
        return
    end
    local t = {}
    while it:hasNext() do
        local obj = it:next()
        table.insert(t, obj)
    end
    utils.print(t)
    return t
end

function CMD.new_order(obj)
    obj._id = obj.transid
    db:insert("order", obj)
end

function CMD.update_order(transid)
    db:update("order", {_id=transid}, {["$set"]={get_card_time=os.time()}})
end

function CMD.roomcard_log(msg)
    db:insert("roomcard_log", msg)
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

    skynet.register("mongo")
end)
