local skynet = require "skynet"
require "skynet.manager"
local order_mgr = require "order_mgr"

local CMD = {}

function CMD.create_ipay(userid, product_id, ptype)
    return order_mgr:create_ipay(userid, product_id, ptype)
end

function CMD.ipay_notify(info)
    return order_mgr:ipay_notify(info)
end

function CMD.get_ipay_result(transid, userid)
    return order_mgr:get_ipay_result(transid, userid)
end

local function lua_dispatch(_, session, cmd, ...)
    local f = CMD[cmd]
    assert(f, "order can't dispatch cmd ".. (cmd or nil))

    if session > 0 then
        skynet.ret(skynet.pack(f(...)))
    else
        f(...)
    end
end

local function init()
    order_mgr:init()

    skynet.dispatch("lua", lua_dispatch)

    skynet.register("order")

    skynet.error("order booted...")
end

skynet.start(init)
