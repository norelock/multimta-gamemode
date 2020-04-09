local zoom = exports["mm_gui"]:getInterfaceZoom() or 1;
local screen = Vector2(guiGetScreenSize());

local speedo = {};

local POSITION = {
    x = screen.x - 384/zoom,
    y = 0,
    w = 384/zoom,
    h = 390/zoom
};
POSITION.y = screen.y - POSITION.h - 10/zoom;
POSITION.x = POSITION.x - 70/zoom;

local ICONS = {
    {name = "engine"},
    {name = "brake"},
    {name = "lights"}
};

speedo.onLoad = function()
    speedo.showing = false;

    speedo.textures = {
        bars = dxCreateTexture("assets/images/speedo/bars.png"),
        numbers = dxCreateTexture("assets/images/speedo/numbers.png"),
        pointer = dxCreateTexture("assets/images/speedo/pointer.png"),
        icons = {
            brake = dxCreateTexture("assets/images/speedo/icons/brake_icon.png"),
            brake_active = dxCreateTexture("assets/images/speedo/icons/brake_icon_active.png"),
            engine = dxCreateTexture("assets/images/speedo/icons/engine_icon.png"),
            engine_active = dxCreateTexture("assets/images/speedo/icons/engine_icon_active.png"),
            lights = dxCreateTexture("assets/images/speedo/icons/lights_icon.png"),
            lights_active = dxCreateTexture("assets/images/speedo/icons/lights_icon_active.png")
        }
    };

    speedo.animations = {
        alpha_anim = nil,
        alpha = 0
    };

    speedo.fonts = {
        gears = exports["mm_gui"]:getGUIFont("normal"),
        speed = exports["mm_gui"]:getGUIFont("bold_big"),
        unit = exports["mm_gui"]:getGUIFont("light")
    };

    if getPedOccupiedVehicle(localPlayer) then
        speedo.showing = true;
        speedo.animations.alpha_anim = createAnimation(0, 255, "Linear", 400, function(x)
            speedo.animations.alpha = x;
        end);
        
        addEventHandler("onClientRender", root, speedo.onRender);
    end;

    addEventHandler("onClientVehicleEnter", root, function(player)
        if player ~= localPlayer then return end;

        speedo.showing = true;
        speedo.animations.alpha_anim = createAnimation(0, 255, "Linear", 400, function(x)
            speedo.animations.alpha = x;
        end);
        addEventHandler("onClientRender", root, speedo.onRender);
    end);

    addEventHandler("onClientVehicleStartExit", root, function(player)
        if player ~= localPlayer then return end;

        speedo.animations.alpha_anim = createAnimation(255, 0, "Linear", 400,
            function(x)
                speedo.animations.alpha = x;
            end,
            function()
                speedo.showing = false;
                removeEventHandler("onClientRender", root, speedo.onRender);
            end
        );
    end);
end;
addEventHandler("onClientResourceStart", resourceRoot, speedo.onLoad);

speedo.onUnload = function()
    if speedo.showing then
        removeEventHandler("onClientRender", root, speedo.onRender);
    end;

    for key, texture in ipairs(speedo.textures) do
        if isElement(texture) then
            destroyElement(texture);
        end;
    end;
    speedo.textures = {};
end;
addEventHandler("onClientResourceStop", resourceRoot, speedo.onUnload);

speedo.onRender = function()
    if not speedo.showing then return end;
    
    local vehicle = getPedOccupiedVehicle(localPlayer);
    if not vehicle then return end;

    local rpm = ((exports["bengines"]:getVehicleRPM(vehicle))/9000) * 220;
    local gear = exports["bengines"]:getVehicleGear(vehicle);
    local speed = math.floor((Vector3(getElementVelocity(vehicle)) * 170).length);

    dxDrawImage(POSITION.x, POSITION.y, POSITION.w, POSITION.h, speedo.textures.bars, 0, 0, 0, tocolor(255, 255, 255, speedo.animations.alpha));
    dxDrawImage(POSITION.x, POSITION.y, POSITION.w, POSITION.h, speedo.textures.numbers, 0, 0, 0, tocolor(255, 255, 255, speedo.animations.alpha));
    dxDrawImage(POSITION.x, POSITION.y - 10/zoom, POSITION.w, POSITION.h, speedo.textures.pointer, rpm, 0, 0, tocolor(255, 255, 255, speedo.animations.alpha));

    dxDrawText(gear, POSITION.x + 185.7/zoom, POSITION.y - 19.5/zoom, POSITION.w + POSITION.x, POSITION.h + POSITION.y, tocolor(255, 100, 100, speedo.animations.alpha), 1/zoom, speedo.fonts.gears, "left", "center");
    dxDrawText(string.format("%03.f", speed), POSITION.x + 245/zoom, POSITION.y + 180/zoom, POSITION.w + POSITION.x, POSITION.h + POSITION.y, tocolor(255, 255, 255, speedo.animations.alpha), 1.2/zoom, speedo.fonts.speed, "left", "center");
    dxDrawText("km/h", POSITION.x + 246/zoom, POSITION.y + 240/zoom, POSITION.w + POSITION.x, POSITION.h + POSITION.y, tocolor(255, 255, 255, speedo.animations.alpha), 0.75/zoom, speedo.fonts.unit, "left", "center");

    for key, icon in ipairs(ICONS) do
        offset = ((key - 1)) * (35/zoom);

        local active = nil;

        if icon.name == "engine" then
            active = getVehicleEngineState(vehicle) and "_active" or "";
        elseif icon.name == "brake" then
            active = isElementFrozen(vehicle) and "_active" or "";
        elseif icon.name == "lights" then
            active = getVehicleOverrideLights(vehicle) == 2 and "_active" or "";
        end;

        dxDrawImage(POSITION.x + 242/zoom + offset, POSITION.y + 330/zoom, 38/zoom, 28/zoom, speedo.textures.icons[icon.name .. active], 0, 0, 0, tocolor(255, 255, 255, speedo.animations.alpha));
    end;
end;