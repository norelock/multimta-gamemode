local duty_system = {};

local database = exports["mm_db"];
local settings = exports["mm_settings"];

local DB_PREFIX = settings:getSettingValue("DATABASE_PREFIX") or "multimta_";

local secondsToTime = function(seconds)
    if type(seconds) ~= "number" then return end;

    --[[local minutes = string.format("%02.f", math.floor(seconds/60));
    local seconds = string.format("%02.f", seconds - (minutes * 60));]]--
    local minutes = string.format("%d", math.floor(seconds/60));
    local seconds = string.format("%d", seconds - (minutes * 60));

    return minutes .. " minut " .. seconds .. " sekund";
end;

duty_system.login = function(player, command)
    if not player or getElementType(player) ~= "player" then return end;

    if tonumber(getElementData(player, "player:admin")) < 1 then
        exports.mm_hud:showNotification(player, "Nie posiadasz uprawnień, aby używać tej komendy.", "error");
        return;
    end;

    local isOnDuty = getElementData(player, "player:admin_duty") or false;

    if isOnDuty then
        exports.mm_hud:showNotification(player, "Wylogowano ze służby administracyjnej pomyślnie!", "success");
        
        removeElementData(player, "player:admin_level");
        removeElementData(player, "player:admin_duty");

        toggleControl(player, "fire", false);
        toggleControl(player, "aim_weapon", false);
    else
        exports.mm_hud:showNotification(player, "Zalogowano pomyślnie na służbę administracyjną!", "success");

        setElementData(player, "player:admin_level", tonumber(getElementData(player, "player:admin") or 0));
        setElementData(player, "player:admin_duty", true);

        toggleControl(player, "fire", true);
        toggleControl(player, "aim_weapon", true);
    end;
end;

duty_system.aj = function(player, command, target, time, ...)
    if not player or getElementType(player) ~= "player" then return end;

    if tonumber(getElementData(player, "player:admin")) < 2 then
        exports.mm_hud:showNotification(player, "Nie posiadasz uprawnień, aby używać tej komendy.", "error");
        return;
    end;

    local isOnDuty = getElementData(player, "player:admin_duty") or false;

    if not isOnDuty then
        exports.mm_hud:showNotification(player, "Nie jesteś zalogowany na służbie administracyjnej!", "error");
        return;
    else
        local time = tonumber(time);
        local reason = table.concat({...}, " ");

        if not target or time == 0 or #reason == 0 then
            exports.mm_hud:showNotification(player, "Poprawne użycie: /aj <id gracza/nick gracza> <czas (w sekundach)> <powód>", "error");
            return;
        end;

        local playerTarget = exports.mm_core:findPlayer(player, target);
        if not playerTarget then
            exports.mm_hud:showNotification(player, "Nie znaleziono podanego gracza!", "error");
            return;
        end;

        if not getElementData(playerTarget, "player:logged") then
            exports.mm_hud:showNotification(player, "Gracz nie jest zalogowany na serwerze!", "error");
            return;
        end;

        if not getElementData(playerTarget, "player:spawned") then
            exports.mm_hud:showNotification(player, "Gracz nie jest zespawnowany!", "error");
            return;
        end;

        local adminJail = getElementData(playerTarget, "player:aj") or nil;
        if adminJail == nil or adminJail == 0 then
            exports.mm_hud:showNotification(player, string.format("Nadano pomyślnie graczowi %s AJ (AdminJail)!", getPlayerName(playerTarget) or "nr. " .. getElementData(player, "player:id") or 0), "success");
            exports.mm_hud:showNotification(playerTarget, string.format("Zostałeś uwięziony w AdminJail przez %s z powodu %s na okres %s", getPlayerName(player), reason, secondsToTime(time)), "error", true, 15000);

            if isPedInVehicle(playerTarget) then
                removePedFromVehicle(playerTarget);
            end;

            local playerPos = Vector3(getElementPosition(playerTarget));
            local lastSpawn = {x = playerPos.x, y = playerPos.y, z =playerPos.z};

            setElementData(playerTarget, "player:last_spawn_pos", lastSpawn);
            setElementData(playerTarget, "player:aj", time or 120);

            local randomDim = math.random(1, 99);
            setElementPosition(playerTarget, 154.23313903809, -1951.8502197266, 47.875);
            setElementDimension(playerTarget, randomDim);

            triggerClientEvent(playerTarget, "onClientPlayerAJ", playerTarget, playerTarget, tonumber(getElementData(player, "player:aj") or 0));
        else
            if (type(adminJail) == "number" and adminJail ~= 0) then
                exports.mm_hud:showNotification(player, "Ten gracz jest już w AdminJail!", "error");
                return;
            end;
        end;
    end;
end;

duty_system.warn = function(player, command, target, ...)
    if not player or getElementType(player) ~= "player" then return end;

    if tonumber(getElementData(player, "player:admin")) < 1 then
        exports.mm_hud:showNotification(player, "Nie posiadasz uprawnień, aby używać tej komendy.", "error");
        return;
    end;

    local isOnDuty = getElementData(player, "player:admin_duty") or false;

    if not isOnDuty then
        exports.mm_hud:showNotification(player, "Nie jesteś zalogowany na służbie administracyjnej!", "error");
        return;
    else
        local reason = table.concat({...}, " ");

        if not target or #reason == 0 then
            exports.mm_hud:showNotification(player, "Poprawne użycie: /warn <id gracza/nick gracza> <powód>", "error");
            return;
        end;

        local playerTarget = exports.mm_core:findPlayer(player, target);
        if not playerTarget then
            exports.mm_hud:showNotification(player, "Nie znaleziono podanego gracza!", "error");
            return;
        end;

        if not getElementData(playerTarget, "player:logged") then
            exports.mm_hud:showNotification(player, "Gracz nie jest zalogowany na serwerze!", "error");
            return;
        end;

        if not getElementData(playerTarget, "player:spawned") then
            exports.mm_hud:showNotification(player, "Gracz nie jest zespawnowany!", "error");
            return;
        end;

        local targetUID = getElementData(playerTarget, "player:uid") or -1;
        local warns = database:single(string.format("SELECT warns FROM %saccounts WHERE id=? LIMIT 1;", DB_PREFIX), targetUID);
        warns = warns.warns;

        warns = warns + 1;

        exports.mm_hud:showNotification(playerTarget, string.format("Otrzymałeś %d ostrzeżenie od %s z powodu %s", warns, getPlayerName(player), reason), "error", true, 10000);
        
        if warns == 3 or warns > 3 then
            for key, players in ipairs(getElementsByType("player")) do
                exports.mm_hud:showNotification(players, string.format("[Ostrzeżenie 3/3] %s otrzymał ostrzeżenie od %s z powodu %s", getPlayerName(playerTarget), getPlayerName(player) or "System", reason), "error", false);
            end;
            warns = 0;
        else
            for key, players in ipairs(getElementsByType("player")) do
                exports.mm_hud:showNotification(players, string.format("[Ostrzeżenie %d/3] %s otrzymał ostrzeżenie od %s z powodu %s", warns, getPlayerName(playerTarget), getPlayerName(player) or "System", reason), "error", false);
            end;
        end;

        if database:query(string.format("UPDATE %saccounts SET warns=? WHERE id=?", DB_PREFIX), warns, targetUID) then
            exports.mm_hud:showNotification(player, string.format("Pomyślnie nadano ostrzeżenie graczowi %s.", getPlayerName(playerTarget)), "success");
        else
            exports.mm_hud:showNotification(player, "Wystąpił błąd podczas wykonywania komendy, spróbuj ponownie później.", "error"); 
            return;
        end;
    end;
end;

duty_system.commands = {
    {
        com = "duty",
        funct = duty_system.login
    },
    {
        com = "aj",
        funct = duty_system.aj
    },
    {
        com = "warn",
        funct = duty_system.warn
    }
};

addEventHandler("onResourceStart", resourceRoot, function()
    for key, command in ipairs(duty_system.commands) do
        addCommandHandler(command.com, command.funct);
    end;
end);