local GUI = exports.mm_gui;
local zoom = GUI:getInterfaceZoom() or 1;

local screen = Vector2(guiGetScreenSize());

-- events
addEvent("onClientPlayerBW", true);

-- bw
BW = {};

BW.start = function()
    BW.showing = false;
    BW.fonts = {
        title = GUI:getGUIFont("normal_big"),
        time = GUI:getGUIFont("light_big")
    };

    if getElementData(localPlayer, "player:spawned") then
        if getElementData(localPlayer, "player:bw") ~= 0 then
            triggerEvent("onClientPlayerBW", localPlayer, tonumber(getElementData(localPlayer, "player:bw") or 0));

            if not exports.mm_radar:getRadarState() then
                exports.mm_radar:setRadarState(true);
            end;
        end;
    end;

    addEventHandler("onClientPlayerDamage", localPlayer, function()
        if not getElementData(localPlayer, "player:logged") or not getElementData(localPlayer, "player:spawned") then return end;
        if getElementData(localPlayer, "player:bw") then
            cancelEvent();
            return;
        end;
    end);

    addEventHandler("onClientPlayerWasted", localPlayer, function()
        if not getElementData(localPlayer, "player:logged") or not getElementData(localPlayer, "player:spawned") then return end;
        setElementData(localPlayer, "player:bw", 90);
        triggerEvent("onClientPlayerBW", localPlayer, tonumber(getElementData(localPlayer, "player:bw") or 0));
    end);
end;
addEventHandler("onClientResourceStart", resourceRoot, BW.start);

BW.onClientEvent = function(seconds)
    if source == localPlayer then
        if (seconds ~= nil) then
            if not getElementData(localPlayer, "player:logged") or not getElementData(localPlayer, "player:spawned") then return end;
            if seconds > 0 then
                if not BW.showing then
                    BW.tick = getTickCount();
                    BW.showing = true;

                    if exports.mm_radar:getRadarState() then
                        exports.mm_radar:setRadarState(false);
                    end;

                    exports.mm_hud:showNotification("bw", "custom", false, 0, ":mm_bw/assets/images/icon.png", [[
                        return function(zoom, x, y, w, h, alpha)
                            local barFlash = interpolateBetween (255, 0, 0, 100, 0, 0, (getTickCount()/600), "CosineCurve");
                            local color = tocolor(255, 20, 0, barFlash);
                        
                            dxDrawText("Straciłeś(aś) przytomność", x + 75/zoom, y - 35/zoom, x + w, y + h, tocolor(255, 255, 255, alpha), 0.80/zoom, exports.mm_gui:getGUIFont("bold_small"), "left", "center", false, true, true);
                            dxDrawText(string.format("%s", secondsToTime(tonumber(getElementData(localPlayer, "player:bw")) or 0)), x + 74.2/zoom, y + 22/zoom, x + w, y + h, tocolor(255, 255, 255, alpha), 1/zoom, exports.mm_gui:getGUIFont("light"), "left", "center", false, true, true);
                            dxDrawRectangle(x, (y - 2 + h), w, 2, color, true);
                        end;
                    ]]);

                    addEventHandler("onClientRender", root, BW.onRender);
                    triggerServerEvent("onPlayerBW", localPlayer, true);
                end;
            elseif seconds <= 0 then
                if not exports.mm_radar:getRadarState() then
                    exports.mm_radar:setRadarState(true);
                end;

                BW.showing = false;

                setElementData(source, "player:bw", nil);
                removeEventHandler("onClientRender", root, BW.onRender);
                triggerServerEvent("onPlayerBW", localPlayer, false);
            end;
        end;
    end;
end;
addEventHandler("onClientPlayerBW", root, BW.onClientEvent);

BW.onRender = function()
    if not BW.showing then return end;

    GUI:drawBWRectangle(0, 0, screen.x, screen.y);

    if getElementData(localPlayer, "player:bw") <= 0 then
        exports.mm_hud:deleteNotification(exports.mm_hud:getCustomNotificationId("bw"));
        triggerEvent("onClientPlayerBW", localPlayer, tonumber(getElementData(localPlayer, "player:bw") or 0));
    end;

    if getTickCount() - BW.tick > 1000 then
        BW.tick = getTickCount();
        setElementData(localPlayer, "player:bw", tonumber(getElementData(localPlayer, "player:bw")) - 1);
    end;
end;