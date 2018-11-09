local M = {}

function M:init()
    self.tbl = {}
end

function M:get_random_token(userid)
    local token = math.random(1,999999)
    self.tbl[userid] = token
    return token
end

return M
