Config = {
    -- FiveM reserves the native "bind" command in production.
    -- The chat hook lets pv_keybinder still accept /bind from chat.
    Command = 'pvbind',

    ChatHook = true,

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
