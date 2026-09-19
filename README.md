# pv_keybinder

Persistent, framework-agnostic custom /bind system for FiveM.

## Commands

Players can create local key binds:

    /bind F9 e dance
    /bind X /e dance
    /bind F10 me hello

The leading slash is optional.

List current binds:

    /binds

Remove a bind:

    /unbind F9

## Blacklist

Edit `config.lua`:

    Config.Blacklist = {
        W = true,
        A = true,
        S = true,
        D = true,
        SPACE = true,
        LSHIFT = true
    }

Keys are normalized to uppercase, so `x`, `X` and `x ` are treated consistently.

The resource rejects blacklisted keys before creating the mapping.

## Persistence

Each bind is stored locally using FiveM resource KVP.

The stored data contains only:

    key
    command
    local bind id

No license, identifier, character ID or database is required.

When the player reconnects, pv_keybinder reads the local KVP data and recreates the mappings.

## Framework compatibility

There is no ESX, QBCore, Qbox, vRP or framework dependency.

The command executed by a bind is simply passed to FiveM's client command system. This makes it possible to bind framework-specific commands without pv_keybinder knowing which framework is installed.

Examples:

    /bind F9 e dance
    /bind F10 emote wave
    /bind X inventory
    /bind F11 phone

## Performance

There is no permanent input polling loop and no `Wait(0)` key scanner.

Bindings use FiveM's native RegisterCommand + RegisterKeyMapping system.

The only startup work is loading the small local KVP index and recreating the player's saved mappings.

## Limits

`Config.MaxBinds` limits the number of custom binds stored by the resource.

The default is 50.

## Installation

Add:

    ensure pv_keybinder

Start it before any resource that needs its exports.

## Exports

    exports.pv_keybinder:GetBinds()
    exports.pv_keybinder:GetBind(key)
    exports.pv_keybinder:AddBind(key, command)
    exports.pv_keybinder:RemoveBind(key)

Example:

    local ok = exports.pv_keybinder:AddBind('F9', 'e dance')

## Important FiveM behavior

FiveM owns the actual input mapping through RegisterKeyMapping. pv_keybinder uses client KVP as its own persistence/index layer and recreates the mappings when it starts.

This avoids the blocked /bind workflow while still giving players a simple /bind command controlled by the resource.
