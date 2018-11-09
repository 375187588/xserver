local mysql = require "mysql"

local M = {}

M.__index = M

function M.new(...)
    local o = {}
    setmetatable(o, M)
    M.init(o, ...)
    return o
end

function M:init(host, port, database, user, password)
    self.conf = {
        host = host,
        port = port,
        database = database,
        user = user,
        password = password,
        on_connect = on_connect
    }
end

function M:connect()
    local db = mysql.connect(self.conf)
    self.db = db
    return db ~= nil
end

-- 执行sql语句
function M:query(sql)
    return self.db:query(sql)
end

function M:heartbeat()
    self.db:query("select now()")
end

function M:disconnect()
    self.db:disconnect()
end

return M
