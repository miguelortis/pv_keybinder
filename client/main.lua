local RESOURCE = GetCurrentResourceName()
local PREFIX = Config.StoragePrefix or 'pv_keybinder:'

local binds = {}
local usedKeys = {}
local nextId = 1

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

local function normalizeCommand(command)
    if type(command) ~= 'string' then return nil end

    command = command:gsub('^%s+', ''):gsub('%s+$', '')
    command = command:gsub('^/', '')

    if command == '' then return nil end

    return command
end

local function isBlacklisted(key)
    key = normalizeKey(key)
    return key and Config.Blacklist and Config.Blacklist[key] == true
end

local function storageKey(id)
    return PREFIX .. tostring(id)
end

local function indexKey()
    return PREFIX .. 'index'
end

local function saveIndex()
    SetResourceKvp(indexKey(), json.encode({
        nextId = nextId
    }))
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
    if not command then return end

    ExecuteCommand(command)
end

local function registerBind(bind)
    local commandName = createCommandName(bind.id)

    RegisterCommand(commandName, function()
        executeBoundCommand(bind)
    end, false)

    RegisterKeyMapping(
        commandName,
        ('PV Bind: %s'):format(bind.command),
        'keyboard',
        bind.key
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

    -- Reconstruct bindings from the local KVP store.
    -- IDs are bounded by MaxBinds, so this is tiny and only runs once.
    for id = 1, (Config.MaxBinds or 50) * 2 do
        local raw = GetResourceKvpString(storageKey(id))

        if raw then
            local ok, bind = pcall(json.decode, raw)

            if ok and type(bind) == 'table'
                and bind.id
                and bind.key
                and bind.command then

                bind.id = tonumber(bind.id)
                bind.key = normalizeKey(bind.key)
                bind.command = normalizeCommand(bind.command)

                if bind.id and bind.key and bind.command then
                    binds[bind.id] = bind
                    usedKeys[bind.key] = bind.id

                    registerBind(bind)

                    if bind.id >= nextId then
                        nextId = bind.id + 1
                    end
                end
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

local function createBind(key, command)
    key = normalizeKey(key)
    command = normalizeCommand(command)

    if not key then
        printError('Invalid key.')
        return false
    end

    if not command then
        printError('Invalid command.')
        return false
    end

    if isBlacklisted(key) then
        printError(('The key ^3%s^7 is blacklisted.'):format(key))
        return false
    end

    local existing = findBindByKey(key)

    if existing then
        printError(('The key ^3%s^7 is already bound to ^3/%s^7.'):format(
            key,
            existing.command
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

RegisterCommand(Config.Command or 'bind', function(_, args)
    if not args[1] then
        print('^3Usage:^7 /bind [key] [command]')
        print('^3Example:^7 /bind F9 e dance')
        print('^3Example:^7 /bind X /e dance')
        return
    end

    local key = args[1]

    if not args[2] then
        printError('You must specify a command.')
        return
    end

    local commandParts = {}

    for i = 2, #args do
        commandParts[#commandParts + 1] = args[i]
    end

    createBind(key, table.concat(commandParts, ' '))
end, false)

RegisterCommand('unbind', function(_, args)
    if not args[1] then
        print('^3Usage:^7 /unbind [key]')
        return
    end

    removeBind(args[1])
end, false)

RegisterCommand('binds', function()
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
