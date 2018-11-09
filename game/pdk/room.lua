local skynet = require "skynet"
local define = require "define"

local RECORD_HOST = skynet.getenv("RECORD_HOST")

local M = {}

-- 代理可以直接创建房间,其他玩家不可以解散代理开的房,这里记录房主ID

function M.init(info)
    local tOptions = {}
    -- 房主ID
    tOptions["master_id"] = info.player.userid
    -- 设置房间信息
    for _, tData in pairs(info.room.options) do
        if tData.key == "first_out" or tData.key == "code_card" then
            local nNum = 0
            for _, value in ipairs(tData.mvalue or {}) do
                nNum = nNum + value
            end
            tOptions[tData.key] = nNum
        else
            tOptions[tData.key] = tData.snvalue ~= nil and tData.snvalue or 0
        end
    end
    tOptions["room_id"] = info.room.roomid
    tOptions["game_id"] = info.room.gameid

    -- 人数
    if tOptions.player_count <= 0 or tOptions.player_count > define.game_player then
        tOptions.player_count = define.game_player
    end

    -- 局数
    if tOptions.room_card == 0 then
        tOptions.room_card = 10
    else
        tOptions.room_card = tOptions.room_card * 10
    end

    M.tOptions = tOptions
end

-- cost_card    消耗房卡数量,游戏未开始,解散房间,返还此消耗
-- room_id      房间ID
-- master_id    房主ID
-- game_id      游戏ID
-- room_card    房卡->游戏局数
-- player_count
-- show_card
-- first_out
-- press_card
-- code_card
function M.get(key)
    return M.tOptions[key]
end

function M.dump()
    local ret = {}
    for key, nValue in pairs(M.tOptions) do
        table.insert(ret, {key=key, nValue=nValue})
    end
    return ret
end

function M.finish(msg)
    skynet.send("roommgr", "lua", "game_finish", msg)
end

function M.leave(msg)
    skynet.send("roommgr", "lua", "leave_room_result", msg)
end

function M.add_record_list(msg)
    skynet.send("httpclient", "lua", "post", RECORD_HOST, "/add_record_list", msg)
end

return M
