Config = {
    -- Custom command names are used so pv_keybinder never depends on
    -- FiveM's reserved native "bind" command.
    Command = 'bindear',
    UnbindCommand = 'desbindear',
    ListCommand = 'binds',
    MenuCommand = 'bindmenu',

    -- Empty by default: the player can assign this action in
    -- FiveM Settings > Key Bindings > FiveM.
    MenuKey = '',

    StoragePrefix = 'pv_keybinder:bind:',
    Debug = false,

    MaxBinds = 50,

    Blacklist = {
        W = true,
        A = true,
        S = true,
        D = true,

        UP = true,
        DOWN = true,
        LEFT = true,
        RIGHT = true,

        SPACE = true,

        LSHIFT = true,
        RSHIFT = true,
        LCONTROL = true,
        RCONTROL = true,
        LMENU = true,
        RMENU = true,

        TAB = true,
        ESCAPE = true,
        CAPITAL = true,

        F1 = true,
        F2 = true,
        F3 = true,
        F4 = true,
        F5 = true,
        F6 = true,
        F7 = true,
        F8 = true,

        LWIN = true,
        RWIN = true,
        APPS = true
    }
}
