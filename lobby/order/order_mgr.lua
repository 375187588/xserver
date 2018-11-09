local skynet = require "skynet"
local product = require "product"
local utils = require "utils"

local M = {}

function M:init()
    -- 未兑现的订单
    self.not_get_card_orders = skynet.call("mongo", "lua", "get_unfinished_order")
    skynet.send("xlog", "lua", "log", "加载未兑付的订单，数量"..#self.not_get_card_orders)
end

function M:create_ipay(userid, product_id, ptype)
    skynet.send("xlog", "lua", "log", string.format("order_mgr create_ipay userid=%d product_id=%d ptype=%d", userid, product_id, ptype))
    local item = product[product_id]
    if not item then
        return {result="product_id is wrong"}
    end
    local msg = {
        userid = userid,
        product = item.product,
        price = item.price,
        ptype = ptype
    }
    local ret = skynet.call("orderclient", "lua", "create_ipay", msg)
    return ret
end

function M:ipay_notify(info)
    skynet.send("xlog", "lua", "log", string.format("order_mgr ipay_notify info=%s", utils.table_2_str(info)))
    -- 检查是否已经处理过的订单
    if self.not_get_card_orders[info.transid] then
        return
    end
    self.not_get_card_orders[info.transid] = info

    -- 存库
    --skynet.send("redis", "lua", "save_order", info)
    skynet.send("mongo", "lua", "new_order", info)
    skynet.send("mysql", "lua", "save_order", info)
end

function M:get_ipay_result(transid, userid)
    local order = self.not_get_card_orders[transid]
    if not order then
        return
    end

    if order.appuserid ~= tostring(userid) then
        return
    end

    self.not_get_card_orders[transid] = nil
    return order
end

return M
