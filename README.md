# pv_keybinder

Persistent, framework-agnostic custom key binding system for FiveM.

## Exact /bind support

FiveM reserves the native `bind` command. In production, the native console command is restricted, so registering a resource command with the same name does not give the resource ownership of `/bind`.

pv_keybinder therefore uses the standard FiveM `chat` resource message hook to intercept:

    /bind F9 e dance
    /bind X /e dance
    /unbind F9
    /binds

The hook cancels the original chat message and sends the command to pv_keybinder.

If a server uses a custom chat implementation instead of the standard `chat` resource, the fallback command is:

    /pvbind F9 e dance

Set `Config.ChatHook = false` if the server does not use the standard chat resource.

## Commands

    /bind F9 e dance
    /bind F9 /e dance
    /bind X e sit
    /bind F10 me Hello everyone

List:

    /binds

Remove:

    /unbind F9

Fallback when the standard chat resource is unavailable:

    /pvbind F9 e dance

## Key validation

The resource validates keyboard inputs before creating a mapping.

Supported families include:

- A-Z
- 0-9
- F1-F24
- arrows
- navigation
- numpad
- modifiers
- punctuation/OEM keys

## Blacklist

Edit `config.lua`:

    Config.Blacklist = {
        W = true,
        A = true,
        S = true,
        D = true,
        SPACE = true,
        LSHIFT = true,
        LCONTROL = true
    }

The default configuration blocks movement and several core/system keys.

## Conflicts

A key can only have one pv_keybinder entry.

    /bind F9 e dance
    /bind F9 e wave

The second command is rejected until:

    /unbind F9

## Persistence

Binds are stored locally using FiveM resource KVP.

No SQL, license, identifier, character ID or framework callback is required.

On resource startup, pv_keybinder loads the local entries and recreates their RegisterKeyMapping registrations.

## Framework compatibility

No ESX, QBCore, Qbox, vRP or other framework dependency exists.

The target command is executed through FiveM's client command system, allowing binds such as:

    /bind F9 e dance
    /bind F10 emote wave
    /bind X inventory
    /bind F11 phone

## Performance

No per-frame keyboard polling is used.

The resource uses RegisterCommand and RegisterKeyMapping, plus one startup KVP load.

## Configuration

    Config.ChatHook = true
    Config.MaxBinds = 50
    Config.Blacklist = { ... }

## Installation

    ensure chat
    ensure pv_keybinder

The resource waits for `chat` before installing the message hook, so startup order is not critical as long as the standard chat resource eventually starts.

## Exports

    exports.pv_keybinder:GetBinds()
    exports.pv_keybinder:GetBind(key)
    exports.pv_keybinder:AddBind(key, command)
    exports.pv_keybinder:RemoveBind(key)

## FiveM references

Keyboard mapper inputs:
https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/

RegisterKeyMapping:
https://docs.fivem.net/docs/cookbook/2020/01/06/using-the-new-console-key-bindings/

Chat message hooks:
https://docs.fivem.net/docs/resources/chat/exports/registerMessageHook/

Console commands:
https://docs.fivem.net/docs/client-manual/console-commands/
