-- Author: Zbigniewqq
-- Rewritten by: ansceniczny
-- Graphic: ansceniczny

local screen = Vector2(guiGetScreenSize());
local zoom = 1920/screen.x;

local function comma_value(n)
	local left,num,right = string.match(n,'^([^%d]*%d)(%d*)(.-)$')
	return left..(num:reverse():gsub('(%d%d%d)','%1,'):reverse())..right
end

HUD = {};

HUD.switch = function(state)
    if type(state) == "boolean" then
        if state then
            HUD.enabled = state;

            HUD.main_alpha_anim = createAnimation(0, 255, "Linear", 500, function(x)
                HUD.main_alpha = x;
            end);
        else
            HUD.main_alpha_anim = createAnimation(255, 0, "Linear", 500,
                function(x)
                    HUD.main_alpha = x;
                end,
                function()
                    HUD.enabled = false;
                end
            );
        end;
    end;
end;

HUD.init = function()
    local isPlayerLogged;
    local isPlayerSpawned;
    local playerLevel;

    isPlayerLogged = getElementData(localPlayer, "player:logged") or false;
    isPlayerSpawned = getElementData(localPlayer, "player:spawned") or false;
    playerLevel = getElementData(localPlayer, "player:level") or 0;

    HUD.enabled = false;
    HUD.size = {
        background = {
            w = 150/zoom,
            h = 150/zoom
        },
        icons = {
            w = 70/zoom,
            h = 70/zoom
        }
    };
    HUD.textures = {
        background = dxCreateTexture("assets/images/background_circle.png"),
        heart_icon = dxCreateTexture("assets/images/heart.png"),
        progress = {
            mask_default = dxCreateTexture("assets/images/progressbar_mask.png"),
            mask_active = dxCreateTexture("assets/images/progressbar_active_mask.png"),
            default = dxCreateTexture("assets/images/progressbar.png"),
            active = dxCreateTexture("assets/images/progressbar_active.png")
        }
    };
    HUD.masks = {
        progress_default_mask = dxCreateShader("assets/fx/mask.fx"),
        progress_active_mask = dxCreateShader("assets/fx/mask.fx")
    };

    dxSetShaderValue(HUD.masks.progress_default_mask, "sPicTexture", HUD.textures.progress.default);
    dxSetShaderValue(HUD.masks.progress_active_mask, "sPicTexture", HUD.textures.progress.active);

    dxSetShaderValue(HUD.masks.progress_default_mask, "sMaskTexture", HUD.textures.progress.mask_default);
    dxSetShaderValue(HUD.masks.progress_active_mask, "sMaskTexture", HUD.textures.progress.mask_active);

    HUD.main_alpha_anim = nil;
    HUD.main_alpha = 0;

    if isPlayerLogged or isPlayerSpawned then
        HUD.switch(true);
    end;

    local render;

    render = function()
        if not HUD.enabled then return end;

        local money = comma_value(getPlayerMoney(localPlayer));
        local health = tonumber(math.ceil(getElementHealth(localPlayer)));

        playerLevel = getElementData(localPlayer, "player:level") or 0;

        dxDrawText('$'..money, 0, 75/zoom + 1, screen.x - 170/zoom + 1, 0, tocolor(0, 0, 0, HUD.main_alpha * .6), 0.8/zoom, exports.mm_gui:getGUIFont("bold_big"), "right")
        dxDrawText('$'..money, 0, 75/zoom, screen.x - 170/zoom, 0, tocolor(210, 210, 210, HUD.main_alpha), 0.8/zoom, exports.mm_gui:getGUIFont("bold_big"), "right")

        -- poziom
        dxDrawImage(screen.x - 175/zoom, 25/zoom, 150/zoom, 150/zoom, HUD.textures.background, 0, 0, 0, tocolor(255, 255, 255, HUD.main_alpha * .92));
        dxDrawText(string.upper("Poziom"), screen.x - 130/zoom, 69/zoom, 70/zoom + screen.x - 130/zoom, 69/zoom, tocolor(210, 210, 210, HUD.main_alpha), 0.80/zoom, exports.mm_gui:getGUIFont("normal"), "center");
        dxDrawText(playerLevel, screen.x - 130/zoom, 89/zoom, 70/zoom + screen.x - 130/zoom, 89/zoom, tocolor(210, 210, 210, HUD.main_alpha), 1/zoom, exports.mm_gui:getGUIFont("bold_big"), "center")

        -- życko

        --[[for i = 0, health + 5 do
            dxDrawCircle(screen.x - 175/zoom, 172/zoom, 75/zoom, -30 + i - 1, -30 + i, tocolor(255, i/2, 75), tocolor(0, 0, 0, 0), 332, 1)
        end]]
        --dxDrawImage(screen.x - 175/zoom, 172/zoom, 150/zoom, 150/zoom, HUD.masks.progress_default_mask, 0, 0, 0, tocolor(255, 255, 255, HUD.main_alpha * .92))
        dxDrawImageSection(screen.x - 175/zoom, 172/zoom, 150/zoom, 150/zoom, 0, 0, 273, 262, HUD.masks.progress_default_mask)
        --dxDrawImage(screen.x - 175/zoom, 172/zoom, 150/zoom, 150/zoom, HUD.textures.background, 0, 0, 0, tocolor(255, 255, 255, HUD.main_alpha * .92));
        dxDrawImage(screen.x - 130/zoom, 205/zoom, 70/zoom, 70/zoom, HUD.textures.heart_icon, 0, 0, 0, tocolor(255, 255, 255, HUD.main_alpha));
        dxDrawText(string.format("%d", health) .. "%", screen.x - 130/zoom, 269/zoom, 70/zoom + screen.x - 130/zoom, 269/zoom, tocolor(210, 210, 210, HUD.main_alpha), 1/zoom, exports.mm_gui:getGUIFont("light_small"), "center");
    end;

    addEventHandler("onClientRender", root, render);
end;

addEventHandler("onClientResourceStart", resourceRoot, HUD.init);

function showHud(...) return HUD.switch(...); end;