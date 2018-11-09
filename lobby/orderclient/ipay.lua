local skynet = require "skynet"
local crypt = require "crypt"
local utils = require "utils"
local openssll = require "openssll"
local httpc = require "http.httpc"
local urllib = require "http.url"
local dns = require "dns"
local cjson = require "cjson"

local APP_KEY = "MjNEQkUzMjEzNUVEQzFGRERCMThEM0Y4N0UwMUQwRUQ3QUE2REMwM01UUXhORE0zT0RrME1UWXlORFl5TmpBME56TXJNakEzT1RFek1EY3lOalV3TVRJeE5qWTBOek13TXpnNU9Ua3pOelUwTnpVMU5EZ3dOekUz"

local APPV_KEY = "MIICXAIBAAKBgQCPRY/41UUDGYI3oa7Onzzs6DUzs2ur7TuMPETl1AXZYr71qZUhqhm8z8AepRlXT5FOm86WZMfbsbyv6CvhCV7oqq6qW9ZGftZbUTfXGUkVcJ+Gtiv9NeIPiNVOl7MqA73FwAkoQWhtQBgl9QJL5VrlX/5v9SBiVlYz66Zhm762HQIDAQABAoGAXqH77sgvxVRcBpLs+92CSJk4SuYAAJe59W75szTQiD4JFArnTk0kouo2ZAd5LYqI1/tiAUSgHiTQFQCtuv6NiPOnD1VaJblCJ0qWgkYeztb0X1O9On/agKLk+y+MZf/76HEw3Udcug9XE+h6PEC2WhSUdtlP/QU/yXL34xuzZAECQQDJIJn9A0RIQRFWnzq66tYLKRG03ddF0j1K4oakVdzekdDFIgRCAGLK5G81kB5ElKWxvu0yWUZmC+Qt9FvkDGb9AkEAtlwiFgD6DjpCYY7WA24RSAQp6/0FKx+q5QSIt2BkHMlPmQ5SvVktQTNQ7+dK2UuyWGMdn32Y/3758yYijlsFoQJBAK001UguIwSyfHMDp3lHOdPcp3ICRhzMBJrT4C3v/8jw/EB4ngAVAv9FoHwZQ+e9t8AN84mTlmvVO8lTkjsfbyUCQF+ArNE9PbfJxw30khxFvoMquxG99sD42rUJxNfUgVmaDDeqCqbjVxH4YADj7o0SWZp0fgUS79eOljRC2oIXJUECQGKUmReOQjSnfQWgSWpAm+vVCTQu2rDsofAM0ja/j2En46jFQMJtufRBjvQnEDA0LJ3sbt6YEKxmRyWMuxNm324="

local host = "ipay.iapppay.com:9999"
local url = "/payapi/order"

local M = {}

function M.query(userid, product, price)
    local orderid = tostring(userid).."-"..os.time()
    skynet.send("xlog", "lua", "log", string.format("ipay下单 userid=%d product=%d orderid=%s", userid, product, orderid))
    local transdata = string.format("{\"appid\":\"3011078187\",\"waresid\":%d,\"cporderid\":\"%s\", \"price\":%f, \"currency\":\"RMB\",\"appuserid\":\"%d\"}", product, orderid, price, userid)
    local transdata_urlencode = utils.encodeurl(transdata)
    local sign = M.sign(transdata)
    local sign_urlencode = utils.encodeurl(sign)

    return "transdata="..transdata_urlencode.."&sign="..sign_urlencode.."&signtype=RSA"
end

function M.sign(str)
    local pri_key = crypt.base64decode(APPV_KEY)
    local sign = openssll.md5withrsa(pri_key, str)
    return sign
end

function M.request(msg)
    local header = {
        ["Content-Type"] = "application/x-www-form-urlencoded",
        ["charset"] = "UTF-8"
    }
    local respheader = {}
    local query_str = M.query(msg.userid, msg.product, msg.price)
    local status, body = httpc.request("POST", host, url, respheader, header, query_str)
    if status ~= 200 or not body or #body == 0 then
        --skynet.send("xlog", "lua")
        return {result="request ipay failed"}
    end
    local q = urllib.parse_query(body)
    if not q.transdata then
        return
    end
    local transdata = cjson.decode(q.transdata)
    if not transdata.transid then
        return {result = "failed to request ipay"}
    end
    return{
        result = "SUCCESS",
        transid = transdata.transid,
        url = M.get_pay_url(transdata.transid, msg.ptype),
    }
end

function M.get_pay_url(tid, ptype)
    local transdata = string.format("{\"tid\":\"%s\",\"app\":\"3011078187\",\"url_r\":\"http://www.sina.com\", \"url_h\":\"http://www.baidu.com\",\"ptype\":%d}", tid, ptype)
    local sign = M.sign(transdata)
    local query_str = "?data="..utils.encodeurl(transdata).."&sign="..utils.encodeurl(sign).."&sign_type=RSA"
    return "https://web.iapppay.com/h5/d/gateway"..query_str
end

return M
