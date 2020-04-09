MARKER_DRAW_DISTANCE = 75
MARKER_FADE_DISTANCE = MARKER_DRAW_DISTANCE-10
MARKER_REFRESH_TIMEOUT = 500 -- czas w ms co ile wyszukuje markery w poblizu 

local markers = {}
local textures = {}
local iconSize = Vector2(1, 1)
local rotation = 0;

function renderCustomMarkers()
	local cx, cy, cz = getCameraMatrix()
	local rx, ry, rz = getElementRotation(getCamera())
	rz = rz;

	local tick = math.abs(getTickCount() % 2000 - 1000) / 1000
	
	for i, marker in ipairs(markers) do 
		if isElement(marker) then
			local x, y, z = getElementPosition(marker)
			local radius = getElementData(marker, "radius") or 3 
			local color = getElementData(marker, "color") or {255, 255, 255, 255}
			local icon = getElementData(marker, "icon") or "marker"
			
			local dist = getDistanceBetweenPoints3D(cx, cy, cz, x, y, z)
			local progress = (dist-MARKER_FADE_DISTANCE)/(MARKER_DRAW_DISTANCE-MARKER_FADE_DISTANCE)
			color[4] = math.max(0, math.min(255 - (255*progress), 255))
			
			if isOnScreen(x, y, z, radius*0.25) and color[4] > 0 then
				rotation = rotation + 0.007;
				drawTransformedMaterial(textures[icon.."_icon"], x, y, z+iconSize.y*1.5+0.15*tick, -90+rx, ry, rz, iconSize.x, iconSize.y, color, 0, 0, 0)
				
				local lightColor = color 
				lightColor[4] = (lightColor[4]*0.8) - ((lightColor[4]*0.3)*tick)
				drawTransformedMaterial(textures.light, x, y, z, 0, 0, 0, radius, radius, lightColor, 0, 0, 0)
			end
		end
	end
end 

function getNearbyMarkers()
	local cx, cy, cz = getCameraMatrix()
	
	markers = {}
	for k, v in ipairs(getElementsByType("mm_marker")) do 
		local x, y, z = getElementPosition(v)
		if getDistanceBetweenPoints3D(x, y, z, cx, cy, cz) < MARKER_DRAW_DISTANCE*2 then 
			table.insert(markers, v)
		end
	end
end 

addEventHandler("onClientResourceStart", resourceRoot, function()
	textures.marker_icon = dxCreateTexture("assets/images/marker.png", "dxt5")
	textures.get_car_icon = dxCreateTexture("assets/images/icons/get_car.png", "dxt5")
	textures.store_car_icon = dxCreateTexture("assets/images/icons/store_car.png", "dxt5")
	textures.station_lpg_icon = dxCreateTexture("assets/images/icons/station_lpg.png", "dxt5")
	
	textures.light = dxCreateTexture("assets/images/light.png")

	setTimer(getNearbyMarkers, MARKER_REFRESH_TIMEOUT, 0)
	addEventHandler("onClientPreRender", root, renderCustomMarkers)
end)
