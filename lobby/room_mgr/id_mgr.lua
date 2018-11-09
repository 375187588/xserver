local game_list = require "game_list"

local M = {}

function M:init()
    math.randomseed(os.time())
    self.tbl =  {}
    self.used = {}
end

function M:gen_id()
    local id = nil
    while true do
        id =  math.random(100000,999999)
        if not self.used[id] then
            self.used[id] = os.time()
            break
        end
    end

    return id
end

return M
