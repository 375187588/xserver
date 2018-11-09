local utils = require "utils"

-- 房间类，每个房间为一场比赛
local M = {}

M.__index = M

function M.new(...)
    local o = {}
    setmetatable(o, M)

    M.init(o, ...)

    return o
end

function M:init(info, addr)
    utils.print(info)
    self.roomid = info.roomid
    self.addr = addr
    self.ticket = tostring(math.random(os.time()))
end

function M:get_addr()
    return self.addr
end

return M
