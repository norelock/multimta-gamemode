adminjail = {};

adminjail.init = function(player, time)
    if not player or getElementType(player) ~= "player" then
        return;
    end;

    if not getElementData(player, "player:spawned") then return end;

    if time == nil or time == 0 then
        local lastSpawnPos = getElementData(localPlayer, "player:last_spawn_pos") or {};

        triggerServerEvent("onPlayerSpawnLoginPos", localPlayer, lastSpawnPos);
        return;
    end;

    exports.mm_hud:showNotification("aj", "custom", false, 0, ":mm_admin/assets/images/icons/jail_icon.png", [[
        return function(zoom, x, y, w, h, alpha)
            local barFlash = interpolateBetween (255, 0, 0, 100, 0, 0, (getTickCount()/600), "CosineCurve");
            local color = tocolor(255, 20, 0, barFlash);
        
            dxDrawText("Uwięziony(a) przez administrację", x + 75/zoom, y - 35/zoom, x + w, y + h, tocolor(255, 255, 255, alpha), 0.80/zoom, exports.mm_gui:getGUIFont("bold_small"), "left", "center", false, true, true);
            dxDrawText(string.format("%s", secondsToTime(tonumber(getElementData(localPlayer, "player:aj")) or 0)), x + 74.2/zoom, y + 22/zoom, x + w, y + h, tocolor(255, 255, 255, alpha), 1/zoom, exports.mm_gui:getGUIFont("light"), "left", "center", false, true, true);
            dxDrawRectangle(x, (y - 2 + h), w, 2, color, true);
        end;
    ]]);

    local tick = getTickCount();
    local render;
    render = function()
        if getElementData(localPlayer, "player:aj") <= 0 then
            exports.mm_hud:deleteNotification(exports.mm_hud:getCustomNotificationId("aj"));

            local lastSpawnPos = getElementData(localPlayer, "player:last_spawn_pos") or {};
            removeEventHandler("onClientRender", root, render);
            exports.mm_core:switchScreen(true, 500);

            setTimer(function()
                exports.mm_core:switchScreen(false, 1500);
                exports.mm_hud:showNotification("Gratulacje, udało ci się przeżyć w więzieniu administracyjnym!", "success");
                triggerServerEvent("onPlayerSpawnLoginPos", localPlayer, {
                    x = lastSpawnPos.x,
                    y = lastSpawnPos.y,
                    z = lastSpawnPos.z
                });
            end, 1500, 1);
        end;

        if getTickCount() - tick > 1000 then
            tick = getTickCount();
            setElementData(localPlayer, "player:aj", tonumber(getElementData(localPlayer, "player:aj")) - 1);
        end;
    end;

    addEventHandler("onClientRender", root, render);
end;

addEvent("onClientPlayerAJ", true);
addEventHandler("onClientPlayerAJ", root, adminjail.init);