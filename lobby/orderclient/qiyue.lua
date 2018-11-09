local host = "pay.prstyy.cn"
local url = "/pay.jsp"
local backurl = "http://121.46.2.131:8080"
local notifyurl = "http://121.46.2.131:7702/order_notify"
-- 正式
local merch = "19873561091"
local mch_secret = "63631892653971e36c78c6fd44d89e59"

-- 测试
--local merch = "105358465"
--local mch_secret = "42426a61434759c467fe3d443c72c68b"

local function query(userid, amount, product)
    local str = "amount="..amount
    str = str .. "&backurl="..backurl
    str = str .. "&desc=desc"
    str = str .. "&extra="..userid
    str = str .. "&merch="..merch
    str = str .. "&notifyurl="..notifyurl
    str = str .. "&product="..product
    str = str .. "&type=12"
    local sign = crypt.hexencode(md5.sum(str.."&key="..mch_secret))
    local ret = str .. "&sign="..sign

    return ret
end

local M = {}

function M.request(msg)
    local header = {}
    local respheader = {}
    local query_str = query(msg.userid, msg.amount, msg.product)
    local status, body = httpc.request("GET", host, url.."?"..query_str, respheader, header)
    print("[body] =====>", status)
    print(body)
    return cjson.decode(body)
end

return M
