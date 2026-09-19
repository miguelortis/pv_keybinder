local RESOURCE = GetCurrentResourceName()
local PREFIX = Config.StoragePrefix or 'pv_keybinder:'

local actions = {}
local bindings = {}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s] %s'):format(RESOURCE, message))
    end
end

local function normalizeKey(key)
    if type(key) ~= 'string' then return nil end
    key = key:upper():gsub('^%s+', ''):gsub('%s+$', '')
    if key == '' then return nil end
    return key
end

local function storageKey(action)
    return PREFIX .. tostring(action)
end

local function loadKey(action)
    return normalizeKey(GetResourceKvpString(storageKey(action)))
end

local function saveKey(action, key)
    key = normalizeKey(key)
    if not key then return false end
    SetResourceKvp(storageKey(action), key)
    bindings[action] = key
    debugPrint(('saved %s = %s'):format(action, key))
    return true
end

local function commandName(action)
    return ('pvkb_%s'):format(action:gsub('[^%w_]', '_'))
end

local function registerAction(action, description, defaultKey, callback)
    assert(type(action) == 'string' and action ~= '', 'pv_keybinder: invalid action')
    assert(type(callback) == 'function', ('pv_keybinder: callback missing for %s'):format(action))

    local command = commandName(action)
    local savedKey = loadKey(action)
    local key = savedKey or normalizeKey(defaultKey) or 'F6'

    actions[action] = {
        action = action,
        description = description or action,
        defaultKey = key,
        command = command,
        callback = callback
    }

    bindings[action] = key

    RegisterCommand(command, function()
        local entry = actions[action]
        if entry and entry.callback then
            entry.callback()
        end
    end, false)

    RegisterKeyMapping(command, description or action, 'keyboard', key)

    debugPrint(('registered %s [%s]'):format(action, key))
end

local function unregisterAction(action)
    actions[action] = nil
    bindings[action] = nil
end

exports('RegisterKey', function(action, description, defaultKey, callback)
    registerAction(action, description, defaultKey, callback)
end)

exports('UnregisterKey', function(action)
    unregisterAction(action)
end)

exports('GetKey', function(action)
    return bindings[action]
end)

exports('GetBindings', function()
    local result = {}
    for action, key in pairs(bindings) do
        result[action] = key
    end
    return result
end)

exports('ResetKey', function(action)
    local entry = actions[action]
    if not entry then return false end

    DeleteResourceKvp(storageKey(action))
    bindings[action] = normalizeKey(entry.defaultKey)
    return true
end)

RegisterCommand(Config.Command or 'keybinds', function()
    local rows = {}

    for action, entry in pairs(actions) do
        rows[#rows + 1] = {
            action = action,
            key = bindings[action] or '?',
            description = entry.description
        }
    end

    table.sort(rows, function(a, b)
        return a.action < b.action
    end)

    print(('^3[%s]^7 key bindings:'):format(RESOURCE))

    if #rows == 0 then
        print('  ^8No registered bindings.^7')
        return
    end

    for i = 1, #rows do
        local row = rows[i]
        print(('  ^5%s^7 = ^2%s^7 (%s)'):format(
            row.action,
            row.key,
            row.description
        ))
    end
end, false)

RegisterNetEvent('pv_keybinder:client:saveKey', function(action, key)
    if type(action) ~= 'string' then return end
    if not actions[action] then return end
    saveKey(action, key)
end)

AddEventHandler('onClientResourceStop', function(resourceName)
    if resourceName ~= RESOURCE then return end

    for action, key in pairs(bindings) do
        if key then
            SetResourceKvp(storageKey(action), key)
        end
    end
end)

RegisterNetEvent('pv_keybinder:register', function(action, description, defaultKey, eventName)
    if type(eventName) ~= 'string' then return end

    registerAction(action, description, defaultKey, function()
        TriggerEvent(eventName)
    end)
end)
