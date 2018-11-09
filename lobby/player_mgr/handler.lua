local skynet = require "skynet"
local token = require "token"
local player_mgr = require "player_mgr"
local roomcard_mgr = require "roomcard_mgr"
local product = require "product"
local utils = require "utils"
local date = require "date"
local crypt = require "crypt"
local md5 = require "md5"
local crypt = require "crypt"
local crypt_host = require "crypt_host"

-- 每日抽奖次数
local LOTTERY_DRAW_COUNT = 2
local PROXY_SECRET = "guess"


local M = {}

-- 登录
function M.login_lobby(msg)
    if not token.verify_token(msg) then
        print("verify token failed")
        return {result = "token failed"}
    end

    local p = player_mgr:load(msg.userid)
    if p == nil then
        print("创建玩家")
        p = player_mgr:create(msg)
    end

    -- 加载玩家失败
    if next(p) == nil then
        print("玩家为空")
        return {result = "player not find"}
    end

    -- 向房间管理器申请房间信息
    local info = skynet.call("room_mgr", "lua",
        "get_player_info", p.userid)

    local ret = {
        result = "success",
        sign = p.sign,
        score = p.score,
        roomcard = p.roomcard,
        roomid = info.roomid,
        gameid = info.gameid,
        ticket = info.ticket,
    }

    if info.ip and info.port then
        ret.host = crypt_host.crypt(info.ip..":"..info.port)
    end

    if p.proxy_time then
        ret.proxy_token = crypt.hexencode(md5.sum(p.openid..PROXY_SECRET))
    end

    return ret
end

-- 创建房间
function M.create_room(msg)
    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "relogin"}
    end

    if p.sign ~= msg.sign then
        print(p.sign, msg.sign)
        return {result = "sign fail"}
    end

    local pinfo = {
        account = p.account,
        userid = p.userid,
        nickname = p.nickname,
        sex = p.sex,
        score = p.score,
        headimgurl = p.headimgurl
    }

    -- 取得消耗房卡数量
    local costcard = roomcard_mgr.getRoomCard(msg.nGameID, msg.options)
    if costcard == nil or costcard < 0 then
        return {result = "costcard fail"}
    end

    local roomcard = p.roomcard
    if roomcard < costcard then
        return {result = "roomcard fail"}
    end

    local ret = skynet.call("room_mgr", "lua", "create_room", msg, pinfo)
    if not ret then
        return {result = "createroom fail"}
    end

    -- 更新玩家房卡
    local endcard = roomcard - costcard
    player_mgr:update(msg.userid, "roomcard", endcard)
    -- 记录房卡消耗
    local roomcard_msg =
    {
        userid = msg.userid,
        add_type = msg.nGameID,
        roomid = ret.roomid,
        begin_roomcard = roomcard,
        end_roomcard = endcard,
        cost_roomcard = -costcard,
        date = os.time(),
    }
    skynet.send("mongo", "lua", "roomcard_log", roomcard_msg)

    return {
        result = "success",
        roomid = ret.roomid,
        host = ret.host,
        ticket = ret.ticket,
        nGameID = msg.nGameID,
    }
end

-- 加入房间
function M.join_room(msg)
    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "relogin"}
    end

    if p.sign ~= msg.sign then
        return {result = "sign fail"}
    end

    local pinfo = {
        account = p.account,
        userid = p.userid,
        nickname = p.nickname,
        sex = p.sex,
        score = p.score,
        headimgurl = p.headimgurl
    }

    local ret = skynet.call("room_mgr", "lua", "join_room", msg.roomid, pinfo)
    if not ret then
        return {result = "join fail"}
    end

    return {
        result = "success",
        roomid = msg.roomid,
        host = ret.host,
        ticket = ret.ticket,
        nGameID = ret.gameid,
    }
end

function M.create_ipay(msg)
    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "relogin"}
    end

    if p.sign ~= msg.sign then
        return {result = "sign fail"}
    end

    if msg.ptype ~= 401 and msg.ptype ~= 403 then
        return {result = "wrong ptype"}
    end

    local item = product[msg.product_id]
    if not item then
        return {result="wrong product_id"}
    end

   -- 抽奖的
    if item.random_tbl then
        if p.lottery_draw_waresid then
            return {result="have lottery draw", waresid=p.lottery_draw_waresid}
        end
        -- 判断次数
        local now = os.time()
        if p.lottery_draw_time and date.is_same_day(p.lottery_draw_time, now)  then
            if  p.lottery_draw_count >= LOTTERY_DRAW_COUNT then
                return {result="count limit 2"}
            end
        end
    end

    -- 如果是代理
    if item.proxy then
        if p.proxy_time then
            return {result="already proxy"}
        end
    end

    local ret = skynet.call("order", "lua", "create_ipay", msg.userid, msg.product_id, msg.ptype)
    return ret
end

function M.get_ipay_result(msg)
    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "relogin"}
    end

    if p.sign ~= msg.sign then
        return {result = "sign fail"}
    end

    local ret = skynet.call("order", "lua", "get_ipay_result", msg.transid, msg.userid)
    if not ret then
        return {result = "can't find order"}
    end

    -- 加房卡
    local item = product[ret.waresid]
    if not item then
        return
    end

    -- 通知订单已被领取
    --skynet.send("redis", "lua", "update_order", ret.transid)
    skynet.send("mongo", "lua", "update_order", ret.transid)
    -- 重值买房卡
    if item.card then
        p.roomcard = p.roomcard + item.card
        -- 房卡操作,更新玩家信息
        player_mgr:save(msg.userid)
        skynet.send("xlog", "lua", "log", 
            "玩家"..p.account.."充值成功, 得到房卡"..item.card)
        return {result="SUCCESS", waresid = ret.waresid, roomcard = p.roomcard, get_card = item.card}
    end

    -- 抽奖
    if item.random_tbl then
        p.lottery_draw_waresid = ret.waresid
        skynet.send("xlog", "lua", "log", "玩家"..p.account.."充值获取到抽奖机会waresid="..ret.waresid)
        return {result="SUCCESS", waresid = ret.waresid}
    end

    -- 加代理
    if item.proxy_card then
        p.roomcard = p.roomcard + item.proxy_card
        player_mgr:save(msg.userid)
        skynet.send("xlog", "lua", "log",
            "玩家"..p.account.."充值成功, 成为代理, 得到房卡"..item.proxy_card)
        return {
            result="SUCCESS",
            waresid = ret.waresid,
            roomcard = p.roomcard,
            get_card = item.proxy_card,
            proxy_token = crypt.hexencode(md5.sum(p.openid..PROXY_SECRET))
        }
    end
end

-- 房间结束
function M.finish_room(msg)
    if not msg or not msg.game then
        return
    end

    local p = player_mgr:get(msg.game.masterid)
    if not p then
        return
    end

    if not msg.game.costcard or msg.game.costcard <= 0 then
        return
    end
    local costcard = msg.game.costcard

    -- 更新玩家房卡
    local endcard = p.roomcard + costcard
    player_mgr:update(msg.game.masterid, "roomcard", endcard)
    -- 记录房卡消耗
    local roomcard_msg =
    {
        userid = msg.game.masterid,
        add_type = msg.game.gameid,
        roomid = msg.game.roomid,
        begin_roomcard = p.roomcard,
        end_roomcard = endcard,
        cost_roomcard = costcard,
        date = os.time(),
    }
    skynet.send("mongo", "lua", "roomcard_log", roomcard_msg)
end

-- 抽奖
function M.lottery_draw(msg)
    if not msg or not msg.userid or not msg.sign then
        return {result="FAILED"}
    end

    local p = player_mgr:get(msg.userid)
    if not p then
        return {result="relogin"}
    end

    if not p.lottery_draw_waresid then
        return {result="FAILED"}
    end

    local item = product[p.lottery_draw_waresid]
    if not item then
        return {result="FAILED"}
    end
    local total = 0
    for _,v in pairs(item.random_tbl) do
        total = total + v
    end

    local card = 0
    local random_v = math.random(1,total)
    for k,v in pairs(item.random_tbl) do
        if random_v <= v then
            card = k
            break
        else
            random_v =  random_v - v
        end
    end

    skynet.send("xlog", "lua", "log", string.format(
        "用户%s抽奖waresid=%d,得到房卡%d",
        p.account,
        p.lottery_draw_waresid,
        card))
    -- 记录次数
    p.lottery_draw_waresid = nil
    local now = os.time()
    if not p.lottery_draw_time or not date.is_same_day(p.lottery_draw_time, now)  then
        p.lottery_draw_time = now
        p.lottery_draw_count = 1
    else
        p.lottery_draw_time = now
        p.lottery_draw_count = p.lottery_draw_count + 1
    end

    p.roomcard = p.roomcard + card
    -- 房卡操作,更新玩家信息
    player_mgr:save(msg.userid)
    local show_tbl = utils.copy_table(item.show_tbl)
    table.insert(show_tbl, card)
    return {result="SUCCESS", total_roomcard=p.roomcard, card = card, show_tbl=show_tbl}
end

-- 赠卡
function M.send_card(msg)
    if not msg or not msg.userid or not msg.getid or not msg.sign then
        return {result = "fail"}
    end

    if msg.count <= 0 then
        return {result = "count fial"}
    end

    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "fail"}
    end

    if p.sign ~= msg.sign then
        return {result = "sign fail"}
    end

    if msg.count < 5 then
        return {result = "count less 5 fail"}
    end

    if p.roomcard < msg.count then
        return {result = "count less fail"}
    end

    -- 获取增加玩家
    local pGet = player_mgr:get(msg.getid)
    if not pGet then
        -- 数据库查询
        local _player = skynet.call("mongo", "lua", "load_player", msg.getid)
        if not _player then
            return {result = "getid fial"}
        end

        -- 赠卡玩家
        p.roomcard = p.roomcard - msg.count
        skynet.call("mongo", "lua", "save_player", p)
        -- 记录房卡消耗
        local roomcard_sendmsg =
        {
            userid = msg.userid,
            add_type = 0,
            roomid = 0,
            begin_roomcard = p.roomcard,
            end_roomcard = p.roomcard + msg.count,
            cost_roomcard = -msg.count,
            date = os.time(),
        }
        skynet.send("mongo", "lua", "roomcard_log", roomcard_sendmsg)

        -- 给赠送玩家增加
        _player.roomcard = _player.roomcard + msg.count
        skynet.call("mongo", "lua", "save_player", _player)
        -- 记录房卡消耗
        local roomcard_getmsg =
        {
            userid = msg.getid,
            add_type = 0,
            roomid = 0,
            begin_roomcard = _player.roomcard - msg.count,
            end_roomcard = _player.roomcard,
            cost_roomcard = msg.count,
            date = os.time(),
        }
        skynet.send("mongo", "lua", "roomcard_log", roomcard_getmsg)
    else
        -- 赠卡玩家
        p.roomcard = p.roomcard - msg.count
        skynet.call("mongo", "lua", "save_player", p)
         -- 记录房卡消耗
        local roomcard_sendmsg =
        {
            userid = msg.userid,
            add_type = 0,
            roomid = 0,
            begin_roomcard = p.roomcard,
            end_roomcard = p.roomcard + msg.count,
            cost_roomcard = -msg.count,
            date = os.time(),
        }
        skynet.send("mongo", "lua", "roomcard_log", roomcard_sendmsg)

        -- 给赠送玩家增加
        pGet.roomcard = pGet.roomcard + msg.count
        skynet.call("mongo", "lua", "save_player", pGet)
        -- 记录房卡消耗
        local roomcard_getmsg =
        {
            userid = msg.getid,
            add_type = 0,
            roomid = 0,
            begin_roomcard = pGet.roomcard - msg.count,
            end_roomcard = pGet.roomcard,
            cost_roomcard = msg.count,
            date = os.time(),
        }
        skynet.send("mongo", "lua", "roomcard_log", roomcard_getmsg)
    end
    
    return {result="success", count = msg.count}
end

-- 赠卡
function M.update_userinfo(msg)
    if not msg or not msg.userid or not msg.sign then
        return {result = "fail"}
    end

    local p = player_mgr:get(msg.userid)
    if not p then
        return {result = "fail"}
    end

    if p.sign ~= msg.sign then
        return {result = "sign fail"}
    end

    return {
        result = "success",
        score = p.score,
        roomcard = p.roomcard,
    }
end

return M
