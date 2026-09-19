# pv_keybinder

Persistent, framework-agnostic key binding resource for FiveM.

## Installation

Add:

    ensure pv_keybinder

Start it before resources that use its exports.

## API

    exports.pv_keybinder:RegisterKey(action, description, defaultKey, callback)
    exports.pv_keybinder:UnregisterKey(action)
    exports.pv_keybinder:GetKey(action)
    exports.pv_keybinder:GetBindings()
    exports.pv_keybinder:ResetKey(action)

## Example

    exports.pv_keybinder:RegisterKey(
        'open_inventory',
        'Open inventory',
        'F2',
        function()
            TriggerEvent('my_inventory:open')
        end
    )

## Persistence

The selected key is also stored locally as:

    pv_keybinder:<action> = <key>

using FiveM resource KVP.

## Framework compatibility

No ESX/QBCore/Qbox/vRP dependency exists. It is standalone and can be consumed by any client resource that can call exports.

## Performance

There is no permanent per-frame polling loop. The resource is event/command driven.

## FiveM input model

The actual editable user binding is created with RegisterKeyMapping. KVP is the persistence layer, while FiveM remains the authoritative input system.