local skynet = require "skynet"
require "skynet.manager"
local mongolib = require "mongolib"

local db
local CMD = {}

function CMD.start(conf)
    db = mongolib.new()
    db:connect(conf)
    db:use(conf.db)
end

function CMD.close()
    db:disconnect()
end

function CMD.load_all_account(obj)
    local it = db:find("account",{},{})
    if not it then
        return
    end
    local t = {}
    while it:hasNext() do
        local obj = it:next()
        table.insert(t, obj)
    end
    return t
end

function CMD.new_account(acc)
    db:insert("account", acc)
end

function CMD.update_account(acc)
    db:update("account", {account = acc.account} , acc)
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
