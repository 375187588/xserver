local skynet = require "skynet"
require "skynet.manager"
local utils = require "utils"
local record_mgr = require "record_mgr"

local CMD = {}

function CMD.start(_)
    record_mgr:init()
end

function CMD.add_record_list(msg)
    record_mgr:add_record_list(msg)
end

function CMD.get_record_room_list(msg)
    return record_mgr:get_record_room_list(msg)
end

function CMD.get_record_list(msg)
    return record_mgr:get_record_list(msg)
end

function CMD.get_record_game(msg)
    return record_mgr:get_record_game(msg)
end

skynet.start(function()
    skynet.dispatch("lua", function(_, session, cmd, subcmd, ...)
        local f = CMD[cmd]
        assert(f, cmd)
        if session == 0 then
            f(subcmd, ...)
        else
            skynet.ret(skynet.pack(f(subcmd, ...)))
        end
    end)

    skynet.register("recorder")

    skynet.error("recorder booted...")
end)
