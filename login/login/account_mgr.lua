local skynet = require "skynet"
local utils = require "utils"

local M = {}

function M:init()
    self.id_tbl = {}
    self.account_tbl = {}
    self:load_all()
end

function M:load_all()
    local num = 0
    local accounts = skynet.call("mongo", "lua", "load_all_account")
    for _,obj in ipairs(accounts) do
        self.account_tbl[obj.account] = obj
        self.id_tbl[obj.userid] = obj.account
        num = num + 1
    end

    skynet.send("xlog", "lua", "log", "加载所有用户成功，num="..num)
end

function M:gen_id()
    local id
    while true do
        id = math.random(100000,999999)
        if not self.id_tbl[id] then
            return id
        end
    end
end

function M:get_by_account(account)
    return self.account_tbl[account]
end

-- 验证账号密码
function M:verify(account, password)
    local info = self.account_tbl[account]
    if not info then
        return "account not exist"
    end
    if info.password ~= password then
        return "wrong password"
    end

    return "success", info
end

-- 注册账号
function M:register(info)
    if self.account_tbl[info.account] then
        return "account exists"
    end

    local userid = self:gen_id()
    local acc = {
        userid = userid,
        account = info.account,
        password = info.password,
        sex = info.sex,
        openid = "0",
        headimgurl = info.headimgurl,
        nickname = info.nickname,
    }
    self.account_tbl[info.account] = acc
    skynet.send("mongo", "lua", "new_account", acc)
    skynet.send("mysql", "lua", "bind", acc.openid, acc.userid, acc.nickname)

    return "success", acc
end

-- 注册微信账号
function M:wx_login(info)
    skynet.send("xlog", "lua", "log", "微信账号登录"..utils.table_2_str(info))
    local acc = self.account_tbl[info.account]
    if not acc then
        acc = utils.copy_table(info)
        acc.userid = self:gen_id()
        self.account_tbl[info.account] = acc
        skynet.send("mongo", "lua", "new_account", acc)
        skynet.send("mysql", "lua", "bind", acc.openid, acc.userid, acc.nickname)
    end

    return acc
end

function M:guest()
    local account
    local code
    local time = os.time()
    while true do
        code = time .. math.random(1,100)
        account = "guest" .. code
        if not self.account_tbl[account] then
            break
        end
    end

    local userid = self:gen_id()
    local acc = {
        userid = userid,
        account = account,
        password = tostring(time),
        sex = math.random(1,2),
        openid = "1",
        headimgurl = "",
        nickname = "游客"..math.random(100,999)
    }
    self.account_tbl[account] = acc
    skynet.send("mongo", "lua", "new_account", acc)
    skynet.send("mysql", "lua", "bind", acc.openid, acc.userid, acc.nickname)
    return acc
end

function M:save(info)
    local acc = self:get_by_account(info.account)
    if not acc then
        return
    end

    skynet.send("mongo", "lua", "update_account", acc)
end

return M
