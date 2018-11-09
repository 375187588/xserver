-- 游戏管理器(包含若干游戏)

local game = require "game"

local M = {}

function M:init()
    self.tbl = {}

    -- 跑得快
    self.tbl[1] = game.new()

    -- 地锅牛牛
    self.tbl[3] = game.new()

    -- 宁乡跑胡子
    self.tbl[4] = game.new()

    -- 长沙麻将
    self.tbl[5] = game.new()
end

function M:get(id)
    return self.tbl[id]
end

return M
