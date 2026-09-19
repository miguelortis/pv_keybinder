CreateThread(function()
    exports.pv_keybinder:RegisterKey(
        'open_inventory',
        'Open inventory',
        'F2',
        function()
            TriggerEvent('my_inventory:open')
        end
    )

    exports.pv_keybinder:RegisterKey(
        'open_phone',
        'Open phone',
        'F1',
        function()
            TriggerEvent('my_phone:open')
        end
    )
end)