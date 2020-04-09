local core = exports["mm_core"];
local database = exports["mm_db"];
local settings = exports["mm_settings"];

local gWeekDays = { "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday" }

local function switch(n, ...)
    for _, v in ipairs {...} do
        if v[1] == n or v[1] == nil then
            return v[2]()
        end
    end
end
  
local function case(n,f)
    return {n, f}
end
  
local function default(f)
    return {nil, f}
end

local function formatDate(format, escaper, timestamp)
	Check("FormatDate", "string", format, "format", {"nil","string"}, escaper, "escaper", {"nil","string"}, timestamp, "timestamp")
	
	escaper = (escaper or "'"):sub(1, 1)
	local time = getRealTime(timestamp)
	local formattedDate = ""
	local escaped = false

	time.year = time.year + 1900
	time.month = time.month + 1
	
	local datetime = { d = ("%02d"):format(time.monthday), h = ("%02d"):format(time.hour), i = ("%02d"):format(time.minute), m = ("%02d"):format(time.month), s = ("%02d"):format(time.second), w = gWeekDays[time.weekday+1]:sub(1, 2), W = gWeekDays[time.weekday+1], y = tostring(time.year):sub(-2), Y = time.year }
	
	for char in format:gmatch(".") do
		if (char == escaper) then escaped = not escaped
		else formattedDate = formattedDate..(not escaped and datetime[char] or char) end
	end
	
	return formattedDate
end

local onAuthorizationRequest = function(auth_type, request_data)
    local DB_PREFIX = settings:getSettingValue("DATABASE_PREFIX") or "multimta_";

    if request_data then
        if (type(auth_type) == "string" and auth_type) then
            if auth_type == "login" then
                local account = core:logIntoAccount(client, request_data.login, request_data.password);

                switch(account,
                    case("ACCOUNT_NO_EXISTS", function()
                        exports["mm_hud"]:showNotification(client, "Konto do którego próbujesz się zalogować, nie istnieje.", "error");
                        return;
                    end),
                    case("ACCOUNT_INVALID_OWNER", function()
                        exports["mm_hud"]:showNotification(client, "Konto do którego próbujesz się zalogować, nie należy do ciebie.", "error");
                        return;
                    end),
                    case("INVALID_PASSWORD", function()
                        exports["mm_hud"]:showNotification(client, "Podane hasło jest nieprawidłowe.", "error");
                        return;
                    end),
                    default(function()
                        local acc_data = database:rows(string.format("SELECT * FROM %saccounts WHERE login=?", DB_PREFIX), request_data.login);

                        if acc_data and #acc_data > 0 then
                            local data = acc_data[1];

                            setElementData(client, "player:uid", data.id);
                            setElementData(client, "player:admin", data.admin);
                            setElementData(client, "player:reputation", data.reputation);
                            setElementData(client, "player:skin", data.skin);
                            setElementData(client, "player:premium", data.premium);
                            setElementData(client, "player:driving", {
                                a = data.drivingA == "1" and true or false,
                                b = data.drivingB == "1" and true or false,
                                c = data.drivingC == "1" and true or false,
                                d = data.drivingD == "1" and true or false
                            });
                            setElementData(client, "player:old_health", data.health);

                            setElementData(client, "player:time_played", data.time_played);
                            setElementData(client, "player:session_time", 0);

                            if data.bw ~= 0 then setElementData(client, "player:bw", data.bw); else setElementData(client, "player:bw", nil); end;
                            if data.aj ~= 0 then setElementData(client, "player:aj", data.aj); else setElementData(client, "player:aj", nil); end;
    
                            setElementData(client, "player:logged", true);
                            setElementData(client, "player:spawned", false);
                            setElementData(client, "player:away", false);
                            setElementData(client, "player:typing", false);
                            setElementData(client, "player:job", false);
    
                            setPlayerName(client, data.login);
                            setPlayerMoney(client, data.money);
                        end;
    
                        triggerClientEvent(client, "auth_response", client, {
                            success = true,
                            type = "login"
                        });
                    end)
                );
            elseif auth_type == "register" then
                local account = core:registerAccount(client, request_data.login, request_data.password, request_data.email);

                switch(account,
                    case("ACCOUNTS_LIMIT", function()
                        exports["mm_hud"]:showNotification(client, "Przekroczono limit zarejestrowanych kont.", "error");
                        return;
                    end),
                    case("ACCOUNT_ALREADY_EXISTS", function()
                        exports["mm_hud"]:showNotification(client, "Konto o takim loginie już istnieje!", "error");
                        return;
                    end),
                    case("REGISTER_ERROR", function()
                        exports["mm_hud"]:showNotification(client, "Wystąpił błąd podczas rejestracji, spróbuj ponownie później.", "error");
                        return;
                    end),
                    default(function()
                        local acc_data = database:rows(string.format("SELECT * FROM %saccounts WHERE login=?", DB_PREFIX), request_data.login);

                        if acc_data and #acc_data > 0 then
                            local data = acc_data[1];

                            setElementData(client, "player:uid", data.id);
                            setElementData(client, "player:admin", data.admin);
                            setElementData(client, "player:reputation", data.reputation);
                            setElementData(client, "player:skin", data.skin);
                            setElementData(client, "player:premium", data.premium);
                            setElementData(client, "player:driving", {
                                a = data.drivingA == "1" and true or false,
                                b = data.drivingB == "1" and true or false,
                                c = data.drivingC == "1" and true or false,
                                d = data.drivingD == "1" and true or false
                            });

                            setElementData(client, "player:time_played", data.time_played);
                            setElementData(client, "player:session_time", 0);

                            if data.bw ~= 0 then setElementData(client, "player:bw", data.bw); else setElementData(client, "player:bw", nil); end;
                            if data.aj ~= 0 then setElementData(client, "player:aj", data.aj); else setElementData(client, "player:aj", nil); end;

                            setElementData(client, "player:logged", true);
                            setElementData(client, "player:spawned", false);
                            setElementData(client, "player:away", false);
                            setElementData(client, "player:typing", false);
                            setElementData(client, "player:job", false);

                            setPlayerName(client, data.login);
                        end;

                        triggerClientEvent(client, "auth_response", client, {
                            success = true,
                            type = "register"
                        });
                    end)
                );
            elseif auth_type == "spawn" then
                local isPlayerLogged = getElementData(client, "player:logged") or false;
                local isPlayerSpawned = getElementData(client, "player:spawned") or false;
               
                if isPlayerLogged and not isPlayerSpawned then
                    local premiumDate = getElementData(client, "player:premium") or 0;
                    local timestamp = getRealTime().timestamp;

                    if premiumDate > timestamp then
                        outputChatBox(string.format("Posiadasz konto premium ważne do %s.", formatDate("y/m/d h:i:s", "'", premiumDate)));
                        setElementData(client, "player:premium", premiumDate);
                    else
                        setElementData(client, "player:premium", false);        
                    end;

                    setElementAlpha(client, 255);
                    setCameraTarget(client, client);

                    spawnPlayer(client, request_data.position.x, request_data.position.y, request_data.position.z, 0, getElementData(client, "player:skin") or 0, 0, 0);
                    setElementData(client, "player:spawned", true);
                    setElementHealth(client, tonumber(getElementData(client, "player:old_health") or 0));
                    removeElementData(client, "player:old_health");

                    setTimer(function(player)
                        if type(getElementData(player, "player:bw")) ~= nil then
                            if getElementData(player, "player:bw") ~= 0 then
                                exports.mm_bw:setPlayerBW(player, tonumber(getElementData(player, "player:bw") or 0));
                            end;
                        end;

                        if type(getElementData(player, "player:aj")) ~= nil then
                            if getElementData(player, "player:aj") ~= 0 then
                                local lastSpawn = {x = request_data.position.x, y = request_data.position.y, z = request_data.position.z};
                                setElementData(player, "player:last_spawn_pos", lastSpawn);

                                local randomDim = math.random(1, 99);
                                setElementPosition(player, 154.23313903809, -1951.8502197266, 47.875);
                                setElementDimension(player, randomDim);

                                triggerClientEvent(player, "onClientPlayerAJ", player, player, tonumber(getElementData(player, "player:aj") or 0));
                            end;
                        end;
                    end, 500, 1, client);
                    setPlayerHudComponentVisible(client, "crosshair", true);

                    toggleControl(client, "fire", false);
                    toggleControl(client, "aim_weapon", false);
                    
                    triggerClientEvent(client, "auth_response", client, {
                        success = true,
                        type = "spawn"
                    });
                end;
            end;
        end;
    end;
end;

local saveAccount = function(player)
    local DB_PREFIX = settings:getSettingValue("DATABASE_PREFIX") or "multimta_";

    if not player or getElementType(player) ~= "player" then
        return;
    end;

    local uid = getElementData(player, "player:uid") or -1;
    local spawned = getElementData(player, "player:spawned") or false;

    if not uid or uid == -1 then return end;
    if not spawned then return end;

    local money = getPlayerMoney(player);
    local skin = getElementModel(player);
    local health = getElementHealth(player);
    
    local bw = getElementData(player, "player:bw") or 0;
    local aj = getElementData(player, "player:aj") or 0;

    local reputation = getElementData(player, "player:reputation") or 0;
    local time_played = getElementData(player, "player:time_played") or 0;

    local driving = {
        a = getElementData(player, "player:driving").a or false,
        b = getElementData(player, "player:driving").b or false,
        c = getElementData(player, "player:driving").c or false,
        d = getElementData(player, "player:driving").d or false
    };

    local premium = getElementData(player, "player:premium") or false;

    if premium then
        local now = getRealTime().timestamp;
        if now > premium then
            if getPlayerFromName(getPlayerName(player)) then
                triggerClientEvent(player, "onClientAddNotification", player, "Stan konta premium wygasł.", "error");
                setElementData(player, "player:premium", false);
            end;
        end;
    end;

    database:query(string.format("UPDATE %saccounts SET aj=?, bw=?, health=?, skin=?, money=?, reputation=?, time_played=?, drivingA=?, drivingB=?, drivingC=?, drivingD=? WHERE id=?", DB_PREFIX), aj, bw, health, skin, money, reputation, time_played, driving.a, driving.b, driving.c, driving.d, uid);
end;
addEvent("onAuthorizationRequest", true);
addEventHandler("onAuthorizationRequest", root, onAuthorizationRequest);

addEventHandler("onResourceStart", resourceRoot, function()
    setTimer(function()
        for _, player in ipairs(getElementsByType("player")) do
            saveAccount(player);
        end;
    end, (120 * 1000), 0);

    addEventHandler("onPlayerQuit", root, function()
        saveAccount(source);
    end);

    addEvent("onPlayerSpawnLoginPos", true);
    addEventHandler("onPlayerSpawnLoginPos", root, function(position)
        if position then
            setElementPosition(source, position.x, position.y, position.z);
            setElementDimension(source, 0);
            setElementInterior(source, 0);

            removeElementData(source, "player:last_spawn_pos");
        end;
    end);
end);