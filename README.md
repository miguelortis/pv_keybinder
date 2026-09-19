# pv_keybinder

Persistent, framework-agnostic custom /bind system for FiveM.

## Commands

Create a bind:

    /bind F9 e dance
    /bind F9 /e dance
    /bind X e sit
    /bind F10 me Hello everyone

List binds:

    /binds

Remove a bind:

    /unbind F9

The slash before the target command is optional.

## Key validation

The resource validates the requested key against FiveM's documented KEYBOARD input names before creating the mapping.

Supported families include:

- A-Z
- 0-9
- F1-F24
- arrows
- navigation keys
- numpad keys
- modifiers
- punctuation/OEM keys

Examples:

    /bind F9 e dance
    /bind X e sit
    /bind NUMPAD1 e wave
    /bind F24 e salute

Invalid input names are rejected instead of creating a mapping that FiveM may not recognize.

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

The default configuration blocks movement keys and several core/system keys.

Aliases are accepted for convenience:

    ESC      -> ESCAPE
    ENTER    -> RETURN
    CTRL     -> LCONTROL
    LCTRL    -> LCONTROL
    RCTRL    -> RCONTROL
    ALT      -> LMENU
    LALT     -> LMENU
    RALT     -> RMENU
    CAPSLOCK -> CAPITAL
    BACKSPACE -> BACK
    TILDE    -> GRAVE

Keys are normalized to uppercase.

## Conflicts

A key can only have one pv_keybinder bind.

For example:

    /bind F9 e dance

followed by:

    /bind F9 e wave

will be rejected. The player must first use:

    /unbind F9

This prevents the resource from creating duplicate local definitions for the same key.

## Persistence

Each bind is stored locally using FiveM resource KVP.

Stored data contains:

    key
    command
    local bind id

No SQL, identifier, license or framework callback is required.

On resource startup, pv_keybinder loads the local data and recreates the registered mappings.

FiveM also maintains its own user-editable key mapping configuration for RegisterKeyMapping.

## Framework compatibility

There is no ESX, QBCore, Qbox, vRP or framework dependency.

The command attached to a bind is executed through the client's command system, so the target command can belong to any framework/resource that registers a client command.

Examples:

    /bind F9 e dance
    /bind F10 emote wave
    /bind X inventory
    /bind F11 phone

## Performance

There is no permanent input polling loop and no per-frame key scanner.

The resource uses:

    RegisterCommand
    RegisterKeyMapping

The only startup work is loading the small local KVP data and registering the saved mappings.

## Limits

`Config.MaxBinds` controls the maximum number of pv_keybinder entries.

Default:

    50

## Installation

Add:

    ensure pv_keybinder

Start it before resources that depend on it.

## Exports

    exports.pv_keybinder:GetBinds()
    exports.pv_keybinder:GetBind(key)
    exports.pv_keybinder:AddBind(key, command)
    exports.pv_keybinder:RemoveBind(key)

Example:

    local ok = exports.pv_keybinder:AddBind('F9', 'e dance')

## FiveM references

FiveM documents the KEYBOARD mapper inputs here:

https://docs.fivem.net/docs/game-references/input-mapper-parameter-ids/keyboard/

FiveM documents RegisterKeyMapping and user-editable bindings here:

https://docs.fivem.net/docs/cookbook/2020/01/06/using-the-new-console-key-bindings/

FiveM also documents its native console bind/unbind commands. pv_keybinder intentionally provides its own player-facing /bind layer instead of relying on the console workflow.

## Important behavior

FiveM owns the actual input mapping through RegisterKeyMapping. pv_keybinder maintains the player's local bind definitions and recreates them when the resource starts.

The server never needs to poll, store or synchronize key presses.
