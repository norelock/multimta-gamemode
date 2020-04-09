local screen = Vector2(guiGetScreenSize());
local lights_texture = dxCreateTexture("assets/images/lights.png");
local _animations = {
    pulse_alpha = 0,
    pulse_anim = nil
};
local fft = nil;

local function isEventHandlerAdded(eventName, attachedTo, funct)
    if (type(eventName) == "string" and isElement(attachedTo) and type(funct) == "function") then
        local attachedFunctions = getEventHandlers(eventName, attachedTo);
        if type(attachedFunctions) == "table" and #attachedFunctions > 0 then
            for index, value in ipairs(attachedFunctions) do
                if value == funct then
                    return true;
                end;
            end;
        end;
    end;
    return false;
end;

local renderMusicLights = function()
    if isEventHandlerAdded("onClientRender", root, renderMusicLights) then return end;
    
    local alpha_lights = 0;
    if getPlayingLoginMusic() then
        fft = getSoundFFTData(getPlayingLoginMusic(), 4096, 256);
        if type(fft) == "boolean" then return end;
        
        local fft_tick = fft[4];

        alpha_lights = fft_tick * 250;

        if _animations.pulse_anim == nil then
            _animations.pulse_alpha = interpolateBetween(0, 255, 0, 255, 0, 255, (getTickCount())/2800, "CosineCurve");
        end;

        if alpha_lights >= 57 then
            _animations.pulse_anim = createAnimation(255, 0, "Linear", 700,
                function(x)
                    _animations.pulse_alpha = x;
                end,
                function()
                    --_animations.pulse_anim = nil;
                    -- animacja sie buguje xD
                end
            );
        end;
    end;

    dxDrawImage(0, 0, screen.x, screen.y, lights_texture, 0, 0, 0, tocolor(255, 255, 255, _animations.pulse_alpha));
end;

function switchMusicLights(bool)
    if type(bool) ~= "boolean" then return end;
    if bool then
        addEventHandler("onClientRender", root, renderMusicLights);
    else
        removeEventHandler("onClientRender", root, renderMusicLights);
    end;
end;