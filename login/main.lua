local crypt_host = require "crypt_host"
local skynet = require "skynet"


local function test_log()
    print("time=",os.time())
    local message = "test log message"
    for i=1,100000 do
        skynet.call("xlog", "lua", "log", message..i)
    end
    print("time=",os.time())
end

local function mysql_test()
    skynet.call("mysql", "lua", "new_account",
    {
        account="test",
        openid = "openid",
        userid = 33
    })

    local acc = {
        account = "guest",
        password = "a",
        sex = 2,
        headimgurl = "h",
        nickname = "yu",
        userid = 2,
        openid = "0"
    }

    skynet.call("mysql", "lua", "new_account", acc)

    skynet.call("mysql", "lua", "load_all_account")
end

local function main()
    -- skynet.newservice("debug_console", 1800)
    local r = skynet.newservice("xlog")
    skynet.call("xlog", "lua", "start")

    --test_log()

    -- mysql
--    skynet.newservice("mysql")
--    skynet.call("mysql", "lua", "start",
--       {
--            host = "127.0.0.1",
--            port = 3306,
--            database = "gmop37",
--            user = "gmop",
--            password = "a123456"
--       })

    -- mysql_test()

    -- mongo
    local dbconf = {
        host="127.0.0.1",
        port=27017,
        db="xserver",
        --username="yun",
        --password="yun",
        --authmod="mongodb_cr"
    }
    skynet.newservice("mongo")
    skynet.call("mongo", "lua", "start", dbconf)

    -- 登陆http服务
    skynet.newservice("httplogin")

    skynet.newservice("wxlogin")

    -- 登陆服务
    local login = skynet.newservice("login")
    skynet.call(login, "lua", "start")

    print(crypt_host.crypt("121.46.18.121:8080"))
    print(crypt_host.crypt("121.46.18.121:7701"))
    skynet.exit()
end

skynet.start(main)
