local M =
{
    game_card =
    {
        -- 跑得快
        [1] = {2, 4},
        -- 普通牛牛
        [2] = {1, 2},
        -- 地锅牛牛
        [3] = {4},
        -- 宁乡跑胡子
        [4] = {2, 4},
        -- 长沙麻将
        [5] = {2, 4},
    },
}

function M.getRoomCard(gameid, options)
    if not M.game_card[gameid] then
        print("getRoomCard error gameid=", gameid)
        return nil
    end
    local tbl_card = M.game_card[gameid]

    local index = nil
    for _, tData in pairs(options) do
        if tData.key == "room_card" then
            index = tData.snvalue
        end
    end
    if index == nil then
        print("getRoomCard error index==nil")
        return nil
    end

    if index <= 0 or index > #tbl_card then
        print("getRoomCard error index="..index..",nLen="..#tbl_card)
        return nil
    end
    local cost_card = tbl_card[index]
    local t =
    {
        ["key"] = "cost_card",
        ["snvalue"] = cost_card,
    }
    table.insert(options, t)

    return cost_card
end

return M
