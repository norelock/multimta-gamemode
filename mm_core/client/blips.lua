addEventHandler("onClientResourceStart", resourceRoot, function()
    local blipRoot = createElement("pbroot", "pbroot");
    
    for k, player in ipairs(getElementsByType("player")) do
        if player ~= localPlayer then
            local blip = createBlipAttachedTo(player, 0, 2, 255, 255, 255, 255);
            setBlipVisibleDistance(blip, 200);
            setElementParent(blip, blipRoot);
        end;
    end;

    addEventHandler("onClientPlayerSpawn", root, function()
        local blip = createBlipAttachedTo(source, 0, 2, 255, 255, 255, 255);
        setBlipVisibleDistance(blip, 200);
        setElementParent(blip, blipRoot);
    end);

    addEventHandler("onClientPlayerQuit", root, function()
        for k, blip in ipairs(getElementChildren(blipRoot)) do
            if getElementAttachedTo(blip) == source then
                destroyElement(blip);
            end;
        end;
    end);
end);