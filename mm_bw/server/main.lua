addEventHandler("onResourceStart", resourceRoot, function()
    addEventHandler("onPlayerDamage", root, function()
        if getElementData(source, "player:bw") then
            cancelEvent();
            return;
        end;
    end);

    addEvent("onPlayerBW", true);
    addEventHandler("onPlayerBW", root, function(toggle)
        if toggle then
            if not getElementData(source, "player:logged") or not getElementData(source, "player:spawned") then return end;

            local position = Vector3(getElementPosition(source));

            spawnPlayer(source, position.x, position.y, position.z, 0, getElementModel(source), getElementInterior(source), getElementDimension(source));

            if isPedInVehicle(source) then
                removePedFromVehicle(source);
            end;

            setElementHealth(source, 1);
            setElementFrozen(source, true);

            setPedAnimation(source, "PED", "KO_shot_front", -1, false, true, false, true);

            toggleAllControls(source, false);
            showChat(source, false);
        else
            local position = Vector3(getElementPosition(source));

            if isPedDead(source) then
                spawnPlayer(source, position.x, position.y, position.z, 0, getElementModel(source), getElementInterior(source), getElementDimension(source));
                
                if not getElementData(source, "player:admin_duty") then
                    toggleControl(source, "fire", false);
                    toggleControl(source, "aim_weapon", false);
                end;

                setElementHealth(source, 10);
                setElementFrozen(source, false);
                setPedAnimation(source, false);
                toggleAllControls(source, true);
                showChat(source, true);
            else
                setElementHealth(source, 10);
                setElementFrozen(source, false);
                setPedAnimation(source, false);
                toggleAllControls(source, true);
                showChat(source, true);

                if not getElementData(source, "player:admin_duty") then
                    toggleControl(source, "fire", false);
                    toggleControl(source, "aim_weapon", false);
                end;
            end;
        end;
    end);
end);

function setPlayerBW(player, seconds)
    if not player or getElementType(player) ~= "player" then
        return;
    end;
    if (seconds) then
        triggerClientEvent(player, "onClientPlayerBW", player, tonumber(getElementData(player, "player:bw") or 0));
    end;
end;