# pv_keybinder

Persistent, framework-agnostic custom key binding system for FiveM.

## Commands

The resource intentionally does **not** use FiveM's native `/bind` command because `bind` is a reserved FiveM console command and can be disabled in production. citeturn0search6

Use these custom commands instead:

    /bindear F9 e dance
    /bindear F9 /e dance
    /bindear X e sit

List your local binds:

    /binds

Remove a bind:

    /desbindear F9

### Why these names?

`/bindear` and `/desbindear` are normal resource commands registered with FiveM's `RegisterCommand`, so they are not dependent on the reserved native `bind` command. FiveM documents `RegisterCommand` as the standard way to create player commands. citeturn0search0

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

The supported names follow FiveM's keyboard input mapper list. citeturn0search14

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

    /bindear F9 e dance
    /bindear F9 e wave

The second command is rejected until:

    /desbindear F9

## Persistence

Binds are stored locally using FiveM resource KVP.

No SQL, license, identifier, character ID or framework callback is required.

On resource startup, pv_keybinder loads the local entries and recreates their `RegisterKeyMapping` registrations.

## Framework compatibility

No ESX, QBCore, Qbox, vRP or other framework dependency exists.

The target command is executed through FiveM's client command system, allowing binds such as:

    /bindear F9 e dance
    /bindear F10 emote wave
    /bindear X inventory
    /bindear F11 phone

## Performance

No per-frame keyboard polling is used.

The resource uses `RegisterCommand` and `RegisterKeyMapping`, plus one startup KVP load. FiveM's key mapping system is designed for user-editable bindings. citeturn0search3

## Configuration

    Config.Command = 'bindear'
    Config.UnbindCommand = 'desbindear'
    Config.ListCommand = 'binds'
    Config.MaxBinds = 50
    Config.Blacklist = { ... }

## Installation

Add the resource to your server and start it:

    ensure pv_keybinder

No chat patch is required.

## Exports

    exports.pv_keybinder:GetBinds()
    exports.pv_keybinder:GetBind(key)
    exports.pv_keybinder:AddBind(key, command)
    exports.pv_keybinder:RemoveBind(key)

## FiveM references

Keyboard mapper inputs:
https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/

RegisterCommand:
https://docs.fivem.net/docs/scripting-manual/migrating-from-deprecated/creating-commands/

RegisterKeyMapping:
https://docs.fivem.net/docs/cookbook/2020/01/06/using-the-new-console-key-bindings/

Console commands:
https://docs.fivem.net/docs/client-manual/console-commands/
