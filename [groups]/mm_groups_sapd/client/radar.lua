local GUI = exports["mm_gui"]
local zoom = GUI:getInterfaceZoom()
local screen = Vector2(guiGetScreenSize())
local radar = {
    vehicleSpheres = {},
    vehiclesWithRadar = {},
    showing = false,
    textures = {},
    fonts = {}
}

radar.onLoad = function()
    radar.vehiclesWithRadar = {
        [596] = true,
        [599] = true,
    }
    radar.textures = {
        background = dxCreateTexture("assets/images/radar.png", "argb", true, "clamp")
    }
    radar.fonts = {
        normal = GUI:getGUIFont("light_small")
    }
end
addEventHandler("onClientResourceStart", resourceRoot, radar.onLoad)

radar.onVehicleEnter = function(player, seat)
    if seat ~= 0 and seat ~= 1 or player ~= localPlayer then return end
    if not radar.showing then
        radar.showing = true
        radar.vehicleSpheres[source] = createColSphere(0, 0, 0, 10)
        attachElements(radar.vehicleSpheres[source], source, 0, 10, 0)
        addEventHandler("onClientRender", root, radar.render)
    end
end
addEventHandler("onClientVehicleEnter", root, radar.onVehicleEnter)

radar.onVehicleExit = function(player, seat)
    if seat ~= 0 and seat ~= 1 or player ~= localPlayer then return end
    if radar.showing then
        radar.showing = false
        if radar.vehicleSpheres[source] then
            destroyElement(radar.vehicleSpheres[source])
            radar.vehicleSpheres[source] = nil
        end
        removeEventHandler("onClientRender", root, radar.render)
    end
end
addEventHandler("onClientVehicleExit", root, radar.onVehicleExit)

radar.replace = function(selected)
    if type(selected) ~= "string" then return end
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle then return end
    local last = {
        speed = getElementData(vehicle, "radar:lastSpeed") or 0,
        plate = getElementData(vehicle, "radar:lastPlate") or nil,
        driver = getElementData(vehicle, "radar:lastDriver") or nil,
        isOld = getElementData(vehicle, "radar:isTrafficOld") or false,
        name = getElementData(vehicle, "radar:lastName") or nil
    }
    if selected == "speed" then
        return last.speed
    elseif selected == "driver" then
        if last.driver == nil then
            return "Brak kierowcy"
        else
            return last.driver
        end
    elseif selected == "plate" then
        if last.plate == nil then
            return "Brak"
        else
            return last.plate
        end
    elseif selected == "name" then
        if last.name == nil then
            return "Brak"
        else
            return last.name
        end
    else
        return nil
    end
end

radar.render = function()
    if not radar.showing then return end
    local vehicle = getPedOccupiedVehicle(localPlayer)
    if not vehicle or not radar.vehiclesWithRadar[getElementModel(vehicle)] or not radar.vehicleSpheres[vehicle] then return end
    dxDrawImage(screen.x/2 - 550/zoom/2, screen.y - 610/zoom/2, 550/zoom, 187/zoom, radar.textures.background)
    dxDrawText(radar.replace("name"), screen.x/2 - 398/zoom/2, screen.y - 1110/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "left", "center")
    dxDrawText(radar.replace("plate"), screen.x/2 - 398/zoom/2, screen.y - 946/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "left", "center")
    dxDrawText(radar.replace("driver"), screen.x/2 - 398/zoom/2, screen.y - 780/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "left", "center")
    if getElementData(vehicle, "radar:isTrafficOld") then
        dxDrawText("Ostatni pomiar", screen.x/2 - 398/zoom/2, screen.y - 610/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "left", "center")
        dxDrawText(radar.replace("speed") .. " km/h", screen.x/2 - 1280/zoom/2, screen.y - 680/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "center", "center")
    else
        dxDrawText("Aktualny pomiar", screen.x/2 - 398/zoom/2, screen.y - 610/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "left", "center") 
    end
    for _, vehicles in pairs(getElementsWithinColShape(radar.vehicleSpheres[vehicle], "vehicle")) do
        if vehicles ~= vehicle then
            local vx, vy, vz = getElementVelocity(vehicles)
            local speed = math.ceil((vx^2 + vy^2 + vz^2) ^ (0.5) * 161)
            dxDrawText(speed .. " km/h\n(" .. radar.replace("speed") .. ")", screen.x/2 - 1280/zoom/2, screen.y - 680/zoom/2, screen.x, screen.y, tocolor(255, 255, 255, 255), 1/zoom, radar.fonts.normal, "center", "center")
            local occupant = getVehicleOccupant(vehicles, 0)
            if occupant then
                setElementData(vehicle, "radar:lastDriver", getPlayerName(occupant), true)
            end
            setElementData(vehicle, "radar:lastSpeed", speed, true)
            setElementData(vehicle, "radar:isTrafficOld", false)
            setElementData(vehicle, "radar:lastPlate", getVehiclePlateText(vehicles), true)
            setElementData(vehicle, "radar:lastName", getVehicleName(vehicles), true)
            break
        else
            setElementData(vehicle, "radar:isTrafficOld", true)
            break
        end
	end
end