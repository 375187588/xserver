local redis = require "redis"

local M = {}

function M:init(conf)
    self.conf = conf
    self.db = nil
end

function M:connect()
    print("conn",self.db)
    self.db = redis.connect(self.conf)
    print("conn",self.db)
end

function M:disconnect()
    self.db:disconnect()
end

function M:check_conn()
    return self.db:ping() == "pong"
end

function M:get(key)
    return self.db:get()
end

function M:set(key, value)
    return self.db:set(key, value)
end

function M:hgetall(key)
    return self.db:hgetall(key)
end

function M:hget(key, field)
    return self.db:hget(key, field)
end

function M:hset(key, field, value)
    return self.db:hset(key, field, value)
end

function M:hmget(key, field, ...)
    return self.db:hmget(key, field)
end

function M:hmset(key, field, value, ...)
    return self.db:hmset(key, field, value, ...)
end

function M:get_obj(key)
    local t = M:hgetall(key)
    local obj = {}
    local key
    for i,v in ipairs(t) do
        if i % 2 == 0 then
            obj[key] = v
        else
            key = v
        end
    end
    return obj
end

function M:save_obj(key, obj)
    print(self.db,key,obj)
    local t = {}
    for k,v in pairs(obj) do
        table.insert(t, k)
        table.insert(t, v)
    end
    self.db:hmset(key, table.unpack(t))
end

return M
