local skynet = require "skynet"
local G = require "global"

local M = {}

M.__index = M

function M.new(...)
    local o = {}
    setmetatable(o, M)
    M.init(o, ...)
    return o
end

function M:init(id, game_id, owner, server, ticket)
    self.id = id
    self.game_id = game_id
    self.owner = owner
    self.server_id = server.id
    self.host = server.host
    self.ip = server.ip
    self.port = server.port
    self.ticket = ticket
    self.players = {owner}
end

function M:join(userid)
    for _,v in ipairs(self.players) do
        if v == userid then
            return
        end
    end

    table.insert(self.players, userid)
end

function M:leave(userid)
    for i,v in ipairs(self.players) do
        if v == userid then
            table.remove(self.players, i)
            break
        end
    end
end

return M
