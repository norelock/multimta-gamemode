local SETTINGS = {
    GAMEMODE_INFO = {
        NAME = "MultiMTA 1.0",
        MAP = "San Andreas"
    },
    FPS_LIMIT = 61,
    BLUR_LEVEL = 0,

    DATABASE_PREFIX = "multimta_",
    ACCOUNTS_LIMIT = 1,
    PREMIUM_FOR_FREE = false,
    PREMIUM = {
        ANNOUNCEMENTS_ENABLED = false,
    }
};

getSettingValue = function(setting)
    if (type(setting) == "string" and setting and setting:len() > 0) then
        return SETTINGS[setting];
    end;

    return nil;
end;