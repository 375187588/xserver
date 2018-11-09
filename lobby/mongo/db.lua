local MongoLib = require "mongolib"
local utils = require "utils"

local dbconf = {
    host="127.0.0.1",
    port=27017,
    db="xserver",
--    username="yun",
--    password="yun",
--    authmod="mongodb_cr"
}

local M = {}

function M:init()
    self.mongo = MongoLib.new()
    self.mongo:connect(dbconf)
    self.mongo:use(dbconf.db)
end

function M:add_roomcardLog(obj)
    self.mongo:insert("roomcard", obj)
end

return M
