if not Config.ChatHook then
    return
end

local function splitCommand(text)
    local parts = {}

    for value in string.gmatch(text, '%S+') do
        parts[#parts + 1] = value
    end

    return parts
end

CreateThread(function()
    while GetResourceState('chat') ~= 'started' do
        Wait(1000)

        if GetResourceState(GetCurrentResourceName()) ~= 'started' then
            return
        end
    end

    exports.chat:registerMessageHook(function(source, outMessage, hookRef)
        local text = outMessage and outMessage.args and outMessage.args[2]

        if type(text) ~= 'string' then
            return
        end

        local command, remainder = text:match('^%s*/([%w_]+)%s*(.*)$')

        if not command then
            return
        end

        command = command:lower()

        if command ~= 'bind'
            and command ~= 'unbind'
            and command ~= 'binds' then
            return
        end

        -- Stop the normal chat message before the reserved FiveM command
        -- handler can reject /bind in production mode.
        hookRef.cancel()

        local args = splitCommand(remainder or '')

        TriggerClientEvent(
            'pv_keybinder:chatCommand',
            source,
            command,
            args
        )
    end)

    print('^2[pv_keybinder]^7 /bind chat hook enabled.')
end)
