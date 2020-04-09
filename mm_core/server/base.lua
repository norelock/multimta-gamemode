local settings = exports["mm_settings"];

addEventHandler("onResourceStart", resourceRoot, function()
    setGameType(string.format("%s%s", settings:getSettingValue("GAMEMODE_INFO").NAME, (settings:getSettingValue("PREMIUM_FOR_FREE") and " (Premium za darmo)" or "")));
    setMapName(settings:getSettingValue("GAMEMODE_INFO").MAP);

    setFPSLimit(settings:getSettingValue("FPS_LIMIT"));

    addEventHandler("onVehicleDamage", root, function()
        if getElementHealth(source) <= 320 then
            setElementHealth(source, 320);
        end;
    end);
    
    addEventHandler("onPlayerJoin", root, function()
        setPlayerBlurLevel(source, settings:getSettingValue("BLUR_LEVEL") or 0);
    end);
end);