local zoom = exports["mm_gui"]:getInterfaceZoom();
local screen = Vector2(guiGetScreenSize());
local map = {
    size = 3072,
    zoom = {
        actual = 1.2,
        limit = {1.2, 3.4},
        plus = 0,
    },
    moving = false,
    unit = 3072/6000
};

local worldW, worldH = 0, 0;
local mapOffsetX, mapOffsetY = 0, 0;
local playerMapOffsetX, playerMapOffsetY = 1476.83, -1693;

local function getPositionFromElementOffset(element, offX, offY, offZ)
	local m = getElementMatrix(element);
    local x = offX * m[1][1] + offY * m[2][1] + offZ * m[3][1] + m[4][1];
    local y = offX * m[1][2] + offY * m[2][2] + offZ * m[3][2] + m[4][2];
    local z = offX * m[1][3] + offY * m[2][3] + offZ * m[3][3] + m[4][3];
    return x, y, z;
end;

local function getPosInMap( mapX, mapY )
	local x, y, w, h = map.positions.x, map.positions.y, map.positions.w, map.positions.h;
	local worldX = playerMapOffsetX+( ( mapX-( x+w/2) ) / map.zoom.actual ) / map.unit;
	local worldY = playerMapOffsetY-( ( mapY-( y+h/2 ) ) / map.zoom.actual ) / map.unit;
	
	return worldX, worldY;
end;

local function getMapFromPos( wx, wy )
	local x, y, w, h = map.positions.x, map.positions.y, map.positions.w, map.positions.h;

	local cx, cy = ( x + ( w/2 ) ), ( y+( h/2 ) );
	local left = cx - ( ( playerMapOffsetX-wx ) / map.zoom.actual*map.unit );
	local right = cx + ( ( wx-playerMapOffsetX ) / map.zoom.actual*map.unit );
	local top = cy - ( ( wy-playerMapOffsetY ) / map.zoom.actual*map.unit );
	local bottom = cy+ ( ( playerMapOffsetY-wy ) / map.zoom.actual*map.unit );
	
	cx=math.max( left, math.min( right, cx ) );
	cy=math.max( top, math.min( bottom, cy ) );
	
	return cx, cy;
end;

local function isMouseInPosition ( x, y, width, height )
	if not isCursorShowing( ) then return false end;
    local sx, sy = guiGetScreenSize ( );
    local cx, cy = getCursorPosition ( );
    local cx, cy = ( cx*sx ), ( cy*sy );
    if ( cx >= x and cx <= x + width ) and ( cy >= y and cy <= y + height ) then
        return true;
    else
        return false;
    end;
end;

map.positions = {};
map.positions.w, map.positions.h = screen.x, screen.y;
map.positions.x, map.positions.y = screen.x/2 - map.positions.w/2, screen.y/2 - map.positions.h/2;

prelogin_spawns = {};

prelogin_spawns.start = function()
    prelogin_spawns.showing = false;
    prelogin_spawns.selected = 0;
    prelogin_spawns.buttons = {};
    prelogin_spawns.waybuttons = {};
    prelogin_spawns.shader = {};
    prelogin_spawns.camera = {};
    prelogin_spawns.camera_object = {};
    prelogin_spawns.rotation = {};
    prelogin_spawns.waysize = Vector2(24/zoom, 38/zoom);
    prelogin_spawns.textures = {
        map = dxCreateTexture("assets/images/spawn/map.png"),
        waypoint = dxCreateTexture("assets/images/spawn/waypoint.png"),
        window = dxCreateTexture("assets/images/spawn/spawn_background.png"),
        mask = dxCreateTexture("assets/images/spawn/spawn_window_mask.png")
    };
    prelogin_spawns.fonts = {
        bold = exports["mm_gui"]:getGUIFont("bold"),
        light_small = exports["mm_gui"]:getGUIFont("light_small"),
        normal = exports["mm_gui"]:getGUIFont("light"),
        normal_hover = exports["mm_gui"]:getGUIFont("normal")
    };
    prelogin_spawns.animations = {
        main_anim = nil,
        main = 0
    };
    dxSetTextureEdge(prelogin_spawns.textures.map, "border", tocolor(0, 0, 0, 0));

    for key, spawn in ipairs(getSpawnsTable()) do
        if spawn.disabled then return end;
        -- waypointy
        prelogin_spawns.waybuttons[key] = exports["mm_gui"]:createButton("", 0, 0, prelogin_spawns.waysize.x, prelogin_spawns.waysize.y);
        exports["mm_gui"]:setButtonTextures(prelogin_spawns.waybuttons[key], {
            default = prelogin_spawns.textures.waypoint,
            hover = prelogin_spawns.textures.waypoint,
            press = prelogin_spawns.textures.waypoint
        });

        addEventHandler("onClientClickButton", prelogin_spawns.waybuttons[key], function()
            prelogin_spawns.selected = key;
            playerMapOffsetX, playerMapOffsetY = spawn.position.x, spawn.position.y           
        end);

        -- spawnowanie
        local renderData = {
            x = 380/zoom,
            y = 255/zoom
        };

        prelogin_spawns.buttons[key] = exports["mm_gui"]:createButton("Zespawnuj", 0, 0, 190/zoom, 32/zoom);
        exports["mm_gui"]:setButtonTextures(prelogin_spawns.buttons[key], {default = ":mm_login/assets/images/gui/buttons/default.png", hover = ":mm_login/assets/images/gui/buttons/active.png", press = ":mm_login/assets/images/gui/buttons/default.png"});
        exports["mm_gui"]:setButtonFont(prelogin_spawns.buttons[key], prelogin_spawns.fonts.normal, 0.75/zoom);

        prelogin_spawns.shader[key] = dxCreateShader("assets/fx/mask.fx");
        prelogin_spawns.camera[key] = dxCreateScreenSource(renderData.x, renderData.y);

        prelogin_spawns.camera_object[key] = createObject(2000, spawn.position.x, spawn.position.y, spawn.position.z + 12);
        setElementAlpha(prelogin_spawns.camera_object[key], 0);

        prelogin_spawns.rotation[key] = 0;
        dxSetShaderValue(prelogin_spawns.shader[key], "sPicTexture", prelogin_spawns.camera[key]);
        dxSetShaderValue(prelogin_spawns.shader[key], "sMaskTexture", prelogin_spawns.textures.mask);

        addEventHandler("onClientClickButton", prelogin_spawns.buttons[key], function()
            local logged = getElementData(localPlayer, "player:logged") or false;
            local spawn_position = spawn.position;

            if not logged then
                exports["mm_hud"]:showNotification("Nie jesteś zalogowany!", "error");
                return;
            end;

            triggerServerEvent("onAuthorizationRequest", localPlayer, "spawn", {
                position = {
                    x = spawn_position.x,
                    y = spawn_position.y,
                    z = spawn_position.z
                }
            });
        end);
    end;
end;
addEventHandler("onClientResourceStart", resourceRoot, prelogin_spawns.start);

prelogin_spawns.stop = function()
    for k, v in ipairs(prelogin_spawns.textures) do
        if isElement(v) then
            destroyElement(v);
        end;
    end;
end;
addEventHandler("onClientResourceStop", resourceRoot, prelogin_spawns.stop);

prelogin_spawns.onClick = function(button, state, cx, cy)
    if prelogin_spawns.showing then
        fadeCamera(false);
        if (button == "left") then 
            if (state == "down") then
                local x, y, w, h = map.positions.x, map.positions.y, map.positions.w, map.positions.h;
                if cx >= x and cx <= x + w and cy >= y and cy <= y + h then
                    mapOffsetX = cx * map.zoom.actual + playerMapOffsetX;
                    mapOffsetY = cy * map.zoom.actual - playerMapOffsetY;
                    mouseCurrentPositionX, mouseCurrentPositionY = getCursorPosition( );
                end;
            elseif (state == "up") then
                map.moving = false;
            end;
        end;
    end;
end;

prelogin_spawns.onKey = function(key)
    if prelogin_spawns.showing then
        if (key == "mouse_wheel_down") then
            map.zoom.actual = map.zoom.actual + 0.1;
            if (map.zoom.actual > map.zoom.limit[2]) then
                map.zoom.actual = map.zoom.limit[2];
            end;
        elseif (key == "mouse_wheel_up") then
            map.zoom.actual = map.zoom.actual - 0.1;
            if (map.zoom.actual < map.zoom.limit[1]) then
                map.zoom.actual = map.zoom.limit[1];
            end;
        end;
    end;
end;

prelogin_spawns.switchRender = function(bool)
    if type(bool) ~= "boolean" then return end;
    if bool then
        addEventHandler("onClientRender", root, prelogin_spawns.render);
        addEventHandler("onClientClick", root, prelogin_spawns.onClick);
        addEventHandler("onClientKey", root, prelogin_spawns.onKey);
        showCursor(true);
        exports["mm_2dfog"]:reload();

        prelogin_spawns.showing = true;
        prelogin_spawns.animations.main_anim = createAnimation(0, 255, "Linear", 400,
            function(x)
                prelogin_spawns.animations.main = x;
            end,
            function()
                prelogin_spawns.animations.main_anim = nil;
            end
        );
    else
        exports.mm_core:switchScreen(true, 400);
        prelogin_spawns.animations.main_anim = createAnimation(255, 0, "Linear", 400,
            function(x)
                prelogin_spawns.animations.main = x;
            end,
            function()
                fadeCamera(true, 3.0);
                removeEventHandler("onClientRender", root, prelogin_spawns.render);
                removeEventHandler("onClientClick", root, prelogin_spawns.onClick);
                removeEventHandler("onClientKey", root, prelogin_spawns.onKey);
            
                showCursor(false);
                setCameraTarget(localPlayer, localPlayer);
                toggleAllControls(true);
                showChat(true);
                exports.mm_core:switchScreen(false, 3000);
                exports.mm_radar:setRadarState(true);
                exports.mm_nametags:setNametagsEnabled(true);
                exports.mm_hud:showHud(true);
                
                prelogin_spawns.animations.main_anim = nil;
                prelogin_spawns.showing = false;
            end
        );
    end;
end;

prelogin_spawns.render = function()
    if not prelogin_spawns.showing then return end;
    local x, y, w, h = map.positions.x, map.positions.y, map.positions.w, map.positions.h;
    local absx, absy = 0, 0

    if isCursorShowing( ) then
        local cursorX, cursorY = getCursorPosition()
        absx = cursorX * screen.x
        absy = cursorY * screen.y
    end

    worldW, worldH=map.size*map.zoom.actual, map.size*map.zoom.actual
    local mapX, mapY, mapPX, mapPY= 0, 0, 0, 0
    mapPX, mapPY = getPosInMap(absx, absy)
    mapX, mapY = map.positions.w/2 - mapPX, map.positions.h/2 + mapPY

    if getKeyState("mouse1") then
        if( mouseCurrentPositionX ~= absx and mouseCurrentPositionX ~= absy )then
            map.moving = true;
        end;
    
        if( map.moving )then
            playerMapOffsetX = -( absx * map.zoom.actual - mapOffsetX );
            playerMapOffsetY = (absy * map.zoom.actual - mapOffsetY);
            playerMapOffsetX = math.max( -3000, math.min( 3000, playerMapOffsetX ) );
            playerMapOffsetY = math.max( -3000, math.min( 3000, playerMapOffsetY ) );
        end;
    else
        map.moving = false
    end;

    local mapX = ( ( ( 3000 + playerMapOffsetX ) * map.unit ) - ( w/2 ) * map.zoom.actual )
    local mapY = ( ( ( 3000 - playerMapOffsetY ) * map.unit ) - ( h/2 ) * map.zoom.actual )
    local mapWidth, mapHeight = w*map.zoom.actual, h*map.zoom.actual

    dxDrawRectangle(0, 0, screen.x, screen.y, tocolor(0, 0, 0, prelogin_spawns.animations.main));

    exports["mm_2dfog"]:color(75, 75, 75, prelogin_spawns.animations.main/3.4);
    exports["mm_2dfog"]:render();

    dxDrawImageSection(x, y, w, h, mapX, mapY, mapWidth, mapHeight, prelogin_spawns.textures.map, 0, 0, 0, tocolor(255, 255, 255, prelogin_spawns.animations.main));
    dxDrawText("Lista spawnów", 0, 0, screen.x - 60/zoom, 120/zoom, tocolor(255, 255, 255, prelogin_spawns.animations.main), 1/zoom, prelogin_spawns.fonts.bold, "right", "center");
    
    local offsetY = 121/zoom;

    for key, spawn in ipairs(getSpawnsTable()) do
        local data = {
            isDisabled = spawn.disabled,
            name = spawn.name
        };

        if data.isDisabled then
            dxDrawText(string.format("%s (wyłączony)", data.name), 0, offsetY + 99/zoom - 125/zoom, screen.x - 67/zoom, offsetY + 99/zoom - 125/zoom, tocolor(255, 255, 255, prelogin_spawns.animations.main - 110), 0.92/zoom, prelogin_spawns.fonts.normal, "right", "center");
        else
            if key == prelogin_spawns.selected then
                dxDrawText(data.name, 0, offsetY + 102/zoom - 125/zoom, screen.x - 60/zoom, offsetY + 99/zoom - 125/zoom, tocolor(255, 255, 255, prelogin_spawns.animations.main), 0.86/zoom, prelogin_spawns.fonts.normal_hover, "right", "center")
            else
                dxDrawText(data.name, 0, offsetY + 102/zoom - 125/zoom, screen.x - 60/zoom, offsetY + 99/zoom - 125/zoom, tocolor(255, 255, 255, prelogin_spawns.animations.main), 0.86/zoom, prelogin_spawns.fonts.normal, "right", "center")
            end
        end;

        offsetY = offsetY + 38.2/zoom;

        local spawnX, spawnY = spawn.position.x, spawn.position.y;

        local cx, cy = (x + (w/2)), (y + (h/2));
        local left = cx - w/2 + prelogin_spawns.waysize.x/2;
        local right = cx + w/2 - prelogin_spawns.waysize.x/2;
        local top = cy - h/2 + prelogin_spawns.waysize.y/2;
        local bottom = cy + h/2 -prelogin_spawns.waysize.y/2;

        spawnX, spawnY = getMapFromPos(spawnX, spawnY);
        spawnX = math.max(left, math.min(right, spawnX));
        spawnY = math.max(top, math.min(bottom, spawnY));

        if not data.isDisabled then
            if key == prelogin_spawns.selected then
                local rotation = 0;
                local renderData = {
                    x = 380/zoom,
                    y = 255/zoom
                };

                local _, _, rz = getElementRotation(prelogin_spawns.camera_object[key]);
                local x, y, z = getElementPosition(prelogin_spawns.camera_object[key]);
                rz = rz + 0.4;
                setElementRotation(prelogin_spawns.camera_object[key], 0, 0, rz);
                local lx, ly, lz = getPositionFromElementOffset(prelogin_spawns.camera_object[key], 0, 1, 0);
                setCameraMatrix(x, y, z, lx, ly, lz);
                
                dxUpdateScreenSource(prelogin_spawns.camera[key]);
                dxDrawImage((spawnX - prelogin_spawns.waysize.x/2) + renderData.x - 556.3/zoom, (spawnY - prelogin_spawns.waysize.y/2) - renderData.y - 1.5/zoom, renderData.x, renderData.y, prelogin_spawns.textures.window, 0, 0, 0, tocolor(255, 255, 255, prelogin_spawns.animations.main));
                dxDrawImage((spawnX - prelogin_spawns.waysize.x/2) + renderData.x - 556.3/zoom, (spawnY - prelogin_spawns.waysize.y/2) - renderData.y - 1.5/zoom, renderData.x, renderData.y, prelogin_spawns.shader[key], 0, 0, 0, tocolor(255, 255, 255, prelogin_spawns.animations.main));
                dxSetRenderTarget();

                exports["mm_gui"]:setButtonPosition(prelogin_spawns.buttons[key], (spawnX - prelogin_spawns.waysize.x/2) + renderData.x - 461/zoom, (spawnY - prelogin_spawns.waysize.y/2) - renderData.y + 202.5/zoom);
                exports["mm_gui"]:setButtonTexturesColor(prelogin_spawns.buttons[key], tocolor(255, 255, 255, prelogin_spawns.animations.main));
                exports["mm_gui"]:renderButton(prelogin_spawns.buttons[key]);
            end;
            
            exports["mm_gui"]:renderButton(prelogin_spawns.waybuttons[key]);
            exports["mm_gui"]:setButtonPosition(prelogin_spawns.waybuttons[key], spawnX - prelogin_spawns.waysize.x/2, spawnY - prelogin_spawns.waysize.y/2);
            exports["mm_gui"]:setButtonTexturesColor(prelogin_spawns.waybuttons[key], tocolor(255, 255, 255, prelogin_spawns.animations.main));
        end;
    end;
end;