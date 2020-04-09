Nametags = {
    MAX_DISTANCE = 30;
    NAMETAGS_ENABLED = false;

    iconTextures = {};
    iconSize = 47;
    iconMargin = 2;

    init = function()
        local isLogged = getElementData(localPlayer, "player:logged") or false;
        local isSpawned = getElementData(localPlayer, "player:spawned") or false;

        Nametags.iconTextures = {
            away = dxCreateTexture("assets/icons/afk.png"),
            low_health = dxCreateTexture("assets/icons/blood_icon.png"),
            typing = dxCreateTexture("assets/icons/chat.png"),
            premium = dxCreateTexture("assets/icons/premium.png")
        };

        if isLogged then
            if isSpawned then
                Nametags.NAMETAGS_ENABLED = true;
            end;
        end;

        addEventHandler("onClientHUDRender", root, Nametags.onClientHUDRender);
    end;

    stop = function()
        for key, iconTexture in ipairs(Nametags.iconTextures) do
            if isElement(iconTexture) then
                destroyElement(iconTexture);
            end;
        end;

        local isLogged = getElementData(localPlayer, "player:logged") or false;
        local isSpawned = getElementData(localPlayer, "player:spawned") or false;

        if isLogged then
            if isSpawned then
                Nametags.NAMETAGS_ENABLED = false;
            end;
        end;

        Nametags.iconTextures = {};
    end;

    switch = function(state)
        if type(state) == "boolean" then
            Nametags.NAMETAGS_ENABLED = state;
        end;
    end;

    draw = function(player)
        if not Nametags.NAMETAGS_ENABLED then return end;

        if player == localPlayer then
            return;
        end;

        local position = getCameraTarget() and Vector3(getElementPosition(getCameraTarget())) or Vector3(getCameraMatrix());
        if getElementDimension(player) ~= getElementDimension(localPlayer) or getElementInterior(player) ~= getElementInterior(localPlayer) then
            return;
        end;

        local vecBonePosition = Vector3(getPedBonePosition(player, 4));
        vecBonePosition.z = vecBonePosition.z + 0.56;

        local fDistance = Vector3(position - vecBonePosition).length;
        if fDistance > Nametags.MAX_DISTANCE or not isLineOfSightClear(position.x, position.y, position.z, vecBonePosition.x, vecBonePosition.y, vecBonePosition.z, true, false, false, true, false, false, true) then
            return; 
        end;
        
        local fScreen = Vector2(getScreenFromWorldPosition(vecBonePosition.x, vecBonePosition.y, vecBonePosition.z));
        if not fScreen.x or not fScreen.y then return end;

        local dis = getEasingValue(1 - fDistance/Nametags.MAX_DISTANCE, "Linear");
        local fScale = dis * 0.5;
        local fAlpha = dis * 255;

        local isPlayerInvisible = getElementAlpha(player) == 0;
        
        if isPlayerInvisible then
            return;
        else
            local name = getPlayerName(player) or string.format("Gracz %d", tonumber(getElementData(player, "player:id")) or 0);
            local icons = {};
            
            if name then
                if not isPlayerInvisible then
                    local adminLevel = getElementData(player, "player:admin_level") or 0;
                    local adminColor = {
                        [0] = "#ffffff",
                        [1] = "#009ac9",
                        [2] = "#4be802",
                        [3] = "#f26d6d",
                        [4] = "#c90808"
                    };
                    local adminRanks = {
                        [1] = "Support",
                        [2] = "Moderator",
                        [3] = "Administrator",
                        [4] = "Zarząd"
                    };
    
                    local premium = getElementData(player, "player:premium") or false;
                    local typing = getElementData(player, "player:typing") or false;
                    local away = getElementData(player, "player:away") or false;

                    local health = getElementHealth(player);

                    if premium then
                        table.insert(icons, "premium");
                    end;

                    if health < 11 then
                        table.insert(icons, "low_health");
                    end;

                    if typing then
                        table.insert(icons, "typing");
                    end;

                    if away then
                        table.insert(icons, "away");
                    end;

                    -- nick gracza
                    dxDrawText(string.format("[%d] %s", tonumber(getElementData(player, "player:id")) or 0, string.gsub(name, "#%x%x%x%x%x%x", "")), fScreen.x + 1, fScreen.y + 1, fScreen.x + 1, fScreen.y + 1, tocolor(0, 0, 0, fAlpha * .6), fScale, exports.mm_gui:getGUIFont("bold") or "default-bold", "center", "center", false, false, false, true);
                    dxDrawText(string.format("#949494[%d] %s%s", tonumber(getElementData(player, "player:id")) or 0, (adminLevel ~= 0 and adminColor[adminLevel] or (premium ~= false and "#f5c320" or "#ffffff")), name), fScreen.x, fScreen.y, fScreen.x, fScreen.y, tocolor(230, 230, 230, fAlpha), fScale, exports.mm_gui:getGUIFont("bold") or "default-bold", "center", "center", false, false, false, true);

                    -- ranga
                    if adminLevel > 1 then
                        dxDrawText(string.format("(%s)", (adminLevel ~= 0 and adminRanks[adminLevel] or "")), fScreen.x + 1, fScreen.y + 30 + 1, fScreen.x + 1, fScreen.y + 1, tocolor(0, 0, 0, fAlpha * .6), dis * 0.41, exports.mm_gui:getGUIFont("normal") or "default", "center", "center", false, false, false, true);
                        dxDrawText(string.format("%s(%s)", (adminLevel ~= 0 and adminColor[adminLevel] or ""), (adminLevel ~= 0 and adminRanks[adminLevel] or "")), fScreen.x, fScreen.y + 30, fScreen.x, fScreen.y, tocolor(230, 230, 230, fAlpha), dis * 0.41, exports.mm_gui:getGUIFont("normal") or "default", "center", "center", false, false, false, true);
                    end;

                    local icSize = Nametags.iconSize * fScale;
                    local iconsWidth = #icons * icSize + (#icons - 1) * Nametags.iconMargin;

                    for i, v in pairs(icons) do
                        dxDrawImage(fScreen.x - iconsWidth/2 + icSize * (i - 1) + (#icons > 1 and Nametags.iconMargin or 0), fScreen.y - 25 * fScale - icSize, icSize, icSize, Nametags.iconTextures[v], 0,0,0, tocolor( 255,255,255,fAlpha ))
                    end
                end;
            end;
        end;
    end;

    onClientHUDRender = function()
        if Nametags.NAMETAGS_ENABLED then
            for key, player in ipairs(getElementsByType("player", root, true)) do
                setPlayerNametagShowing(player, false);
                Nametags.draw(player);
            end;
        end;
    end;
};

addEventHandler("onClientResourceStart", resourceRoot, Nametags.init);
addEventHandler("onClientResourceStop", resourceRoot, Nametags.stop);

function setNametagsEnabled(...) return Nametags.switch(...) end;