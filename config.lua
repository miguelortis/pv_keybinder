Config = {
    Command = 'bind',
    StoragePrefix = 'pv_keybinder:bind:',
    Debug = false,

    MaxBinds = 50,

    -- FiveM keyboard inputs that players are not allowed to use.
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
        CAPSLOCK = true,

        -- Reserve common FiveM / server keys.
        F1 = true,
        F2 = true,
        F3 = true,
        F4 = true,
        F5 = true,
        F6 = true,
        F7 = true,
        F8 = true,
        F10 = true,
        F11 = true,
        F12 = true,

        LWIN = true,
        RWIN = true,
        APPS = true
    }
}
