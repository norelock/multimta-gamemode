local id = {};

id.players = {};

local findFreeID = function(id_table)
    if not id_table or type(id_table) ~= "table" then return end;

    local free_id = 1;

    for key, id in ipairs(id.players) do
        if id == free_id then
            free_id = free_id + 1;
        end;
        if id > free_id then
            return free_id;
        end
    end;
    
    return free_id;
end;

local findPlayerTarget = function(player, target)
    if not player or getElementType(player) ~= "player" then return end;

    local targetedPlayer = nil;
    
    if tonumber(target) ~= nil then
        targetedPlayer = getElementByID(string.format("player%d", target));
    else
        for key, player in ipairs(getElementsByType("player")) do
            if string.find(string.gsub(getPlayerName(player):lower(), "#%x%x%x%x%x%x", ""), target:lower(), 0, true) then
                if targetedPlayer then
                    outputChatBox("Znaleziono więcej niż jednego gracza o pasującym pseudonimie, podaj więcej liter.", player);
                    return nil;
                end;
                targetedPlayer = player;
            end;
        end;
    end;

    return targetedPlayer;
end;

local assignPlayerID = function(player)
    if not player or getElementType(player) ~= "player" then return end;

    id.players = {};
    
    for key, player in ipairs(getElementsByType("player")) do
        local player_id = getElementData(player, "player:id") or -1;
        if player_id then
            table.insert(id.players, tonumber(player_id));
        end;
    end;

    local free_id = findFreeID(id.players);

    if isElement(player) then
        setElementData(player, "player:id", free_id);
        setElementID(player, string.format("player%d", free_id));
    end;

    return free_id;
end;

function findPlayer(...) return findPlayerTarget(...) end;

addEventHandler("onResourceStart", resourceRoot, function()
    for key, player in ipairs(getElementsByType("player")) do
        assignPlayerID(player);
    end;

    addEventHandler("onPlayerJoin", root, function()
        assignPlayerID(source);
    end);
end);