local M = {}

function M:init()
    self.tbl = {}
end

function M:heartbeat(msg)
    self.tbl[msg.host] = os.time()
end

function M:update_list()
    local now = os.time()
    for k,v in pairs(self.tbl) do
        if v + 20 < now then
            self.tbl[k] = nil
        end
    end
end

function M:get()
    local t = {servers={}}

    for k,v in pairs(self.tbl) do 
        table.insert(t.servers, k)
    end

    return t
end

return M
