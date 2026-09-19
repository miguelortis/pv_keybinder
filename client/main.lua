local RESOURCE = GetCurrentResourceName()
local PREFIX = Config.StoragePrefix or 'pv_keybinder:'

local binds = {}
local usedKeys = {}
local nextId = 1

local VALID_KEYS = {
    BACK = true, TAB = true, RETURN = true, PAUSE = true, CAPITAL = true,
    ESCAPE = true, SPACE = true, PAGEUP = true, PRIOR = true,
    PAGEDOWN = true, NEXT = true, END = true, HOME = true,
    LEFT = true, UP = true, RIGHT = true, DOWN = true,
    SYSRQ = true, SNAPSHOT = true, INSERT = true, DELETE = true,
    LWIN = true, RWIN = true, APPS = true,
    NUMPAD0 = true, NUMPAD1 = true, NUMPAD2 = true, NUMPAD3 = true,
    NUMPAD4 = true, NUMPAD5 = true, NUMPAD6 = true, NUMPAD7 = true,
    NUMPAD8 = true, NUMPAD9 = true,
    MULTIPLY = true, ADD = true, SUBTRACT = true, DECIMAL = true,
    DIVIDE = true, NUMPADEQUALS = true, NUMPADENTER = true,
    NUMLOCK = true, SCROLL = true,
    LSHIFT = true, RSHIFT = true,
    LCONTROL = true, RCONTROL = true,
    LMENU = true, RMENU = true,
    OEM_1 = true, SEMICOLON = true, EQUALS = true, PLUS = true,
    COMMA = true, MINUS = true, PERIOD = true, SLASH = true,
    OEM_2 = true, OEM_3 = true, GRAVE = true,
    LBRACKET = true, OEM_4 = true, OEM_5 = true,
    BACKSLASH = true, OEM_6 = true, RBRACKET = true,
    APOSTROPHE = true, OEM_7 = true, OEM_102 = true
}

for i = 0, 9 do VALID_KEYS[tostring(i)] = true end
for i = string.byte('A'), string.byte('Z') do VALID_KEYS[string.char(i)] = true end
for i = 1, 24 do VALID_KEYS['F' .. i] = true end

local KEY_ALIASES = {
    ESC = 'ESCAPE',
    ENTER = 'RETURN',
    CTRL = 'LCONTROL',
    LCTRL = 'LCONTROL',
    RCTRL = 'RCONTROL',
    ALT = 'LMENU',
    LALT = 'LMENU',
    RALT = 'RMENU',
    CAPSLOCK = 'CAPITAL',
    BACKSPACE = 'BACK',
    TILDE = 'GRAVE'
}

local function debugPrint(message)
    if Config.Debug then
        print(('[%s] %s'):format(RESOURCE, message))
    end
end

local function normalizeKey(key)
    if type(key) ~= 'string' then return nil end

    key = key:upper():gsub('^%s+', ''):gsub('%s+$', '')

    if key == '' then return nil end

    return KEY_ALIASES[key] or key
end

local function isValidKey(key)
    key = normalizeKey(key)

    if not key then
        return false, 'Invalid key.'
    end

    if not VALID_KEYS[key] then
        return false, ('^3%s^7 is not a supported keyboard input.'):format(key)
    end

    if Config.Blacklist and Config.Blacklist[key] then
        return false, ('^3%s^7 is blacklisted.'):format(key)
    end

    return true
end

local function normalizeCommand(command)
    if type(command) ~= 'string' then return nil end

    command = command:gsub('^%s+', ''):gsub('%s+$', '')
    command = command:gsub('^/', '')

    if command == '' then return nil end

    return command
end

local function storageKey(id)
    return PREFIX .. tostring(id)
end

local function indexKey()
    return PREFIX .. 'index'
end

local function saveIndex()
    SetResourceKvp(indexKey(), json.encode({ nextId = nextId }))
end

local function saveBind(bind)
    SetResourceKvp(storageKey(bind.id), json.encode({
        id = bind.id,
        key = bind.key,
        command = bind.command
    }))
end

local function deleteBindStorage(id)
    DeleteResourceKvp(storageKey(id))
end


local function createCommandName(id)
    return ('pvkb_%s'):format(id)
end

local function executeBoundCommand(bind)
    if not bind or not bind.command then return end

    local command = normalizeCommand(bind.command)

    if command then
        ExecuteCommand(command)
    end
end

local function registerBind(bind)
    local commandName = createCommandName(bind.id)

    RegisterCommand(commandName, function()
        -- RegisterKeyMapping has no resource-side unregister API.
        -- The mapping can remain registered, but it must become inert
        -- immediately after /desbindear removes the bind from memory.
        if binds[bind.id] ~= bind then
            return
        end

        executeBoundCommand(bind)
    end, false)

    RegisterKeyMapping(
        commandName,
        ('PV Bind: %s'):format(bind.command),
        'keyboard',
        bind.key:lower()
    )

    debugPrint(('registered #%s [%s] -> /%s'):format(
        bind.id,
        bind.key,
        bind.command
    ))
end

local function loadBinds()
    local indexData = GetResourceKvpString(indexKey())

    if indexData then
        local ok, data = pcall(json.decode, indexData)

        if ok and type(data) == 'table' then
            nextId = tonumber(data.nextId) or 1
        end
    end

    local maxScan = math.max((Config.MaxBinds or 50) * 2, nextId)

    for id = 1, maxScan do
        local raw = GetResourceKvpString(storageKey(id))

        if raw then
            local ok, bind = pcall(json.decode, raw)

            if ok and type(bind) == 'table' then
                bind.id = tonumber(bind.id)
                bind.key = normalizeKey(bind.key)
                bind.command = normalizeCommand(bind.command)

                local valid = bind.id and bind.key and bind.command
                local keyOk = valid and isValidKey(bind.key)

                if valid and keyOk and not usedKeys[bind.key] then
                    binds[bind.id] = bind
                    usedKeys[bind.key] = bind.id

                    registerBind(bind)

                    if bind.id >= nextId then
                        nextId = bind.id + 1
                    end
                elseif not valid or not keyOk then
                    deleteBindStorage(id)
                end
            else
                deleteBindStorage(id)
            end
        end
    end

    saveIndex()
end

local function getBindCount()
    local count = 0

    for _ in pairs(binds) do
        count = count + 1
    end

    return count
end

local function findBindByKey(key)
    key = normalizeKey(key)

    if not key then return nil end

    local id = usedKeys[key]

    return id and binds[id] or nil
end

local function printError(message)
    print(('^1[pv_keybinder]^7 %s'):format(message))
end

local function printSuccess(message)
    print(('^2[pv_keybinder]^7 %s'):format(message))
end

local function printInfo(message)
    print(('^3[pv_keybinder]^7 %s'):format(message))
end

local function createBind(key, command)
    key = normalizeKey(key)
    command = normalizeCommand(command)

    local keyOk, keyError = isValidKey(key)

    if not keyOk then
        printError(keyError)
        return false
    end

    if not command then
        printError('Invalid command.')
        return false
    end

    local existing = findBindByKey(key)

    if existing then
        printError(('The key ^3%s^7 is already bound to ^3/%s^7.'):format(
            key,
            existing.command
        ))

        printInfo(('Use /%s %s first.'):format(
            Config.UnbindCommand or 'desbindear',
            key
        ))

        return false
    end

    if getBindCount() >= (Config.MaxBinds or 50) then
        printError(('Maximum of %s binds reached.'):format(Config.MaxBinds or 50))
        return false
    end

    local id = nextId
    nextId = nextId + 1

    local bind = {
        id = id,
        key = key,
        command = command
    }

    binds[id] = bind
    usedKeys[key] = id

    saveBind(bind)
    saveIndex()
    registerBind(bind)

    printSuccess(('Bound ^3%s^7 -> ^3/%s^7'):format(key, command))

    return true
end

local function removeBind(key)
    key = normalizeKey(key)
    local bind = findBindByKey(key)

    if not bind then
        printError(('No bind exists for ^3%s^7.'):format(key or '?'))
        return false
    end

    -- FiveM does not expose an unregister API for RegisterKeyMapping.
    -- Removing the bind from the active table makes its existing mapping
    -- a harmless no-op, so the key stops executing the old command.
    binds[bind.id] = nil
    usedKeys[key] = nil

    deleteBindStorage(bind.id)
    saveIndex()

    printSuccess(('Removed bind ^3%s^7 -> ^3/%s^7'):format(
        bind.key,
        bind.command
    ))

    return true
end

local function listBinds()
    local rows = {}

    for _, bind in pairs(binds) do
        rows[#rows + 1] = bind
    end

    table.sort(rows, function(a, b)
        return a.key < b.key
    end)

    print('^3[pv_keybinder]^7 Your local binds:')

    if #rows == 0 then
        print('  ^8No binds configured.^7')
        return
    end

    for i = 1, #rows do
        local bind = rows[i]

        print(('  ^5%s^7 -> ^2/%s^7'):format(
            bind.key,
            bind.command
        ))
    end
end

local function handleBindCommand(args)
    if not args[1] then
        print(('^3Usage:^7 /%s [key] [command]'):format(
            Config.Command or 'bindear'
        ))

        print(('^3Example:^7 /%s F9 e dance'):format(
            Config.Command or 'bindear'
        ))

        print(('^3Example:^7 /%s X /e dance'):format(
            Config.Command or 'bindear'
        ))

        return
    end

    if not args[2] then
        printError('You must specify a command.')
        return
    end

    local commandParts = {}

    for i = 2, #args do
        commandParts[#commandParts + 1] = args[i]
    end

    createBind(args[1], table.concat(commandParts, ' '))
end

RegisterCommand(Config.Command or 'bindear', function(_, args)
    handleBindCommand(args)
end, false)

RegisterCommand(Config.UnbindCommand or 'desbindear', function(_, args)
    if not args[1] then
        print(('^3Usage:^7 /%s [key]'):format(
            Config.UnbindCommand or 'desbindear'
        ))

        return
    end

    removeBind(args[1])
end, false)

RegisterCommand(Config.ListCommand or 'binds', function()
    listBinds()
end, false)

exports('GetBinds', function()
    local result = {}

    for id, bind in pairs(binds) do
        result[id] = {
            key = bind.key,
            command = bind.command
        }
    end

    return result
end)

exports('GetBind', function(key)
    local bind = findBindByKey(key)

    if not bind then return nil end

    return {
        id = bind.id,
        key = bind.key,
        command = bind.command
    }
end)

exports('AddBind', function(key, command)
    return createBind(key, command)
end)

exports('RemoveBind', function(key)
    return removeBind(key)
end)

CreateThread(function()
    Wait(0)
    loadBinds()
end)
