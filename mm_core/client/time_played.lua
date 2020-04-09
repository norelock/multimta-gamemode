local tick = nil;
local debug_enabled = false;

local function convertSecondS(seconds)
    local minutes = string.format("%02.f", math.floor(seconds/60));
    local seconds = string.format("%02.f", seconds - (minutes * 60));
    return {minutes, seconds};
end

local update_time = function()
    local isPlayerLogged = getElementData(localPlayer, "player:logged") or false;
    local isPlayerSpawned = getElementData(localPlayer, "player:spawned") or false;
    local isPlayerAway = getElementData(localPlayer, "player:away") or false;

    if not isPlayerLogged or not isPlayerSpawned then
        return;
    end;

    if isPlayerAway then
        return;
    end;
    
    local remain = getTickCount() - tick;

    local time_played = getElementData(localPlayer, "player:time_played") or 0;
    local session_time = getElementData(localPlayer, "player:session_time") or 0;

    if remain > 1000 then
        tick = getTickCount();

        time_played = time_played + 1;
        session_time = session_time + 1;

        setElementData(localPlayer, "player:time_played", time_played, true);
        setElementData(localPlayer, "player:session_time", session_time, true);
    end;
end;

local debug = function()
    if not debug_enabled then return end;

    local screen = Vector2(guiGetScreenSize());

    local time_played = getElementData(localPlayer, "player:time_played") or 0;
    local session_time = getElementData(localPlayer, "player:session_time") or 0;

    dxDrawText("[DEBUG]\nCzas sesji "..convertSecondS(tonumber(session_time))[1]..":"..convertSecondS(tonumber(session_time))[2].." (" .. tonumber(session_time) .. ")\nCzas ogólny "..convertSecondS(tonumber(time_played))[1]..":"..convertSecondS(tonumber(time_played))[2].." (" .. tonumber(time_played) .. ")", 0, 0, screen.x - 4, screen.y - 14, tocolor(255, 255, 255, 120), 1, "default-bold", "right", "bottom", false, false, false);
end;

addEventHandler("onClientResourceStart", resourceRoot, function()
    tick = getTickCount();

    addEventHandler("onClientRender", root, update_time);

    if debug_enabled then
        addEventHandler("onClientRender", root, debug);
    end;
end);