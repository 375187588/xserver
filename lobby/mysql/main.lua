local skynet = require "skynet"
require "skynet.manager"
local mysql = require "mysql"
local utils = require "utils"
local db

local CMD = {}

function CMD.start(conf)
    db = require("db").new(
        conf.host,
        conf.port,
        conf.database,
        conf.user,
        conf.password)
    skynet.send("xlog", "lua", "log", 
        string.format(
            "连接mysql,host=%s,port=%d,database=%s",
            conf.host,
            conf.port,
            conf.database))

    if not db:connect() then
        skynet.send("xlog", "lua", "log", string.format(
            conf.host,
            conf.port,
            conf.database))
    end
end

function CMD.save_order(order)
    local sql = string.format(
        "call pro_save_game_pay_info('%s','%s','%s','%s',%d,%d,%d);",
        order.appuserid,
        order.transtime,
        order.cporderid,
        order.transid,
        order.paytype,
        math.floor(order.money),
        order.waresid)
    db:query(sql)
end

local function main()
    skynet.dispatch("lua", function(_, session, cmd, ...)
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
    skynet.register("mysql")
end

skynet.start(main)
