local skynet = require "skynet"
require "skynet.manager"
local player_mgr = require "player_mgr"
local handler = require "handler"

local CMD = {}

-- 获取玩家房间信息
function CMD.login_lobby(msg)
    return handler.login_lobby(msg)
end

-- 房间信息-创建房间
function CMD.create_room(msg)
    return handler.create_room(msg)
end

-- 房间消息-游戏加入房间
function CMD.join_room(msg)
    return handler.join_room(msg)
end

function CMD.create_ipay(msg)
    return handler.create_ipay(msg)
end

-- 房间消息-结束房间
function CMD.finish_room(msg)
    return handler.finish_room(msg)
end

function CMD.get_ipay_result(msg)
    return handler.get_ipay_result(msg)
end

function CMD.add_card(transid, userid, card)
    print("订单消息", transid, userid, card)
    local p = player_mgr:get(userid)
    if next(p) == nil then
    end

    p.roomcard = p.roomcard + card
    -- 存库
    print("玩家"..p.account.."充值成功, 得到房卡"..card)
end

function CMD.lottery_draw(msg)
    print("红包")
    return handler.lottery_draw(msg)
end

function CMD.fill_proxy(msg)
    print("fill_proxy")
    return handler.fill_proxy(msg)
end

function CMD.send_card(msg)
    return handler.send_card(msg)
end

function CMD.update_userinfo(msg)
    return handler.update_userinfo(msg)
end

local function dispatch(_, session, cmd, ...)
    local f = CMD[cmd]
    assert(f, "room_mgr接收到非法lua消息: "..cmd)

    if session == 0 then
        f(...)
    else
        skynet.ret(skynet.pack(f(...)))
    end
end

skynet.start(function ()
    player_mgr:init()

    skynet.dispatch("lua", dispatch)

    skynet.register("player_mgr")

    skynet.error("player_mgr booted...")
end)
