if not Config.ChatHook then
    return
end

local function splitCommand(text)
    local parts = {}

    for value in string.gmatch(text or '', '%S+') do
        parts[#parts + 1] = value
    end

    return parts
end

local function handleFallback(source, rawCommand)
    if type(rawCommand) ~= 'string' then
        return false
    end

    local command, remainder = rawCommand:match('^%s*([%w_]+)%s*(.*)$')

    if not command then
        return false
    end

    command = command:lower()

    if command ~= 'bind'
        and command ~= 'unbind'
        and command ~= 'binds' then
        return false
    end

    local args = splitCommand(remainder)

    TriggerClientEvent(
        'pv_keybinder:chatCommand',
        source,
        command,
        args
    )

    return true
end

-- This is the important path for production servers.
-- FiveM's native "bind" is reserved, so a normal RegisterCommand('bind')
-- never gets a chance to handle it. The command fallback event is emitted
-- by the chat/command fallback path for commands that are not handled by a
-- normal resource command.
AddEventHandler('__cfx_internal:commandFallback', function(command)
    if handleFallback(source, command) then
        CancelEvent()
    end
end)

-- Keep the chat hook as a compatibility path for custom/default chat
-- implementations that deliver the raw message to chat first.
CreateThread(function()
    while GetResourceState('chat') ~= 'started' do
        Wait(1000)

        if GetResourceState(GetCurrentResourceName()) ~= 'started' then
            return
        end
    end

    if GetResourceState('chat') == 'started' then
        exports.chat:registerMessageHook(function(source, outMessage, hookRef)
            local text = outMessage and outMessage.args and outMessage.args[2]

            if type(text) ~= 'string' then
                return
            end

            local command, remainder =
                text:match('^%s*/([%w_]+)%s*(.*)$')

            if not command then
                return
            end

            command = command:lower()

            if command ~= 'bind'
                and command ~= 'unbind'
                and command ~= 'binds' then
                return
            end

            hookRef.cancel()

            TriggerClientEvent(
                'pv_keybinder:chatCommand',
                source,
                command,
                splitCommand(remainder)
            )
        end)

        print('^2[pv_keybinder]^7 chat command interception enabled.')
    end
end)
