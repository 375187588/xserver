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

function CMD.new_account(acc)
    -- 账号用户
    if acc.openid == "0" then
        local sql = string.format(
            "insert into account(account,password,sex,headimgurl,nickname,userid,openid) values(%s, %s, %d, %s, %s,%d,%s);",
            mysql.quote_sql_str(acc.account),
            mysql.quote_sql_str(acc.password),
            acc.sex,
            mysql.quote_sql_str(acc.headimgurl),
            mysql.quote_sql_str(acc.nickname),
            acc.userid,
            mysql.quote_sql_str(acc.openid))
        print(sql)
        utils.print(db:query(sql))
    else
        local sql = string.format(
            "insert into account(account,userid,openid) values(%s,%s,%s);",
            mysql.quote_sql_str(acc.account),
            acc.userid,
            mysql.quote_sql_str(acc.openid))
        quote_sql =  mysql.quote_sql_str(sql)
        print(quote_sql)
        print(db:query(quote_sql))
    end
end

function CMD.save_account(acc)

end

function CMD.load_all_account()
    skynet.send("xlog", "lua", "log", "load all account")
    local accounts = db:query("select * from account;")
    utils.print(accounts)
end

function CMD.bind(openid, userid, nickname)
    local sql = string.format("call pro_save_game_gameuserid('%s','%s','%s');",openid,tostring(userid),nickname)
    db:query(sql)
    print(sql)
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
