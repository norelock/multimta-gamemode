--
-- c_radar3D.lua
--

------------------------------------------------------------------------------------------------------------------
-- settings
------------------------------------------------------------------------------------------------------------------
local gui = exports.mm_gui;
local zoom = 0;
local radarTab = {billboard = nil, quad = nil, renderTarget = nil, tiles = {}, blips = {}, custom = {tiles = {}, blips = {}, materials = {}}, enabled = false}
local scx, scy = guiGetScreenSize()

-- window settings
local windowSize = {200, 125}
local blipSize = 0.5

windowSize = {windowSize[1] * (scy / 600) , windowSize[2] * (scy / 600)}
local windowStart = {scx * 0.012, scy * 0.97 - windowSize[2]}
local addSize = 10 * (scy / 600)
local borderDist = 0.1
local cullDist = 1500

-- 3D map settings
local backgroundColor = tocolor(125, 168, 210, 255) -- map background
local renderTargetColor = tocolor(255, 255, 255, 190) -- map tiles, zones
local rectangleColor = tocolor(0, 0, 0, 175)
local camHeight = {255, 455} -- #1 for ped #2 for veh
local camAngle = {-90, -55} -- #1 for ped #2 for veh
local arrowSize = 35 -- player arrow

-- don't touch
local clipDistance = {0.3, 4500}
local fieldOfView = math.rad(80)


------------------------------------------------------------------------------------------------------------------
-- onClientResourceStart/Stop
------------------------------------------------------------------------------------------------------------------
addEventHandler("onClientResourceStart", resourceRoot, function()
	setPlayerHudComponentVisible("radar", false)
	zoom = gui:getInterfaceZoom();
	radarTab.blip = nil
	radarTab.quad = nil
	radarTab.renderTarget = nil
	radarTab.enabled = createTileTextures() and createBlipTextures()
	radarTab.renderTarget = dxCreateRenderTarget(windowSize[1] + 2 * addSize, windowSize[2] + 2 * addSize, true)
	if radarTab.enabled and radarTab.renderTarget then
		radarTab.blip = dxCreateShader("fx/image2D_manual_blip.fx")
		radarTab.quad = dxCreateShader("fx/image3D_manual.fx")
		if radarTab.quad and radarTab.blip then
			dxSetShaderValue( radarTab.quad, "sElementRotation", 0, 0, 0 )
			dxSetShaderValue( radarTab.quad, "sElementPosition", 0, 0, 0 )
			dxSetShaderValue( radarTab.quad, "sElementSize", 0, 0 )	
			dxSetShaderValue( radarTab.quad, "sIsBillboard", false )
			dxSetShaderValue( radarTab.quad, "fCullMode", 2 )
			dxSetShaderValue( radarTab.quad, "sFov", fieldOfView )
			dxSetShaderValue( radarTab.quad, "sClip", clipDistance[1], clipDistance[2] )
			dxSetShaderValue( radarTab.quad, "sAspect", windowSize[2] / windowSize[1] )
			dxSetShaderValue( radarTab.quad, "sScrRes", scx, scy )
			dxSetShaderValue( radarTab.quad, "bIsArrow", false )
			
			dxSetShaderValue( radarTab.blip, "sElementRotation", 0, 0, 0 )
			dxSetShaderValue( radarTab.blip, "sElementPosition", 0, 0, 0 )
			dxSetShaderValue( radarTab.blip, "sElementSize", 0, 0 )	
			dxSetShaderValue( radarTab.blip, "sFov", fieldOfView )
			dxSetShaderValue( radarTab.blip, "sClip", clipDistance[1], clipDistance[2] )
			dxSetShaderValue( radarTab.blip, "sAspect", windowSize[2] / windowSize[1] )
			dxSetShaderValue( radarTab.blip, "sScrRes", scx, scy )
			dxSetShaderValue( radarTab.blip, "bIsBorder", false )
			dxSetShaderValue( radarTab.blip, "fBorderDist", borderDist )
		end
	else
		destroyTileTextures()
	end
	collectgarbage("setpause", 100)

	if getElementData(localPlayer, "player:spawned") then
		if getElementData(localPlayer, "player:bw") == nil then
			setRadarState(true);
		else
			setRadarState(false);
		end;
	else
		setRadarState(false);
	end;
end
)

addEventHandler("onClientResourceStop", resourceRoot, function()
	destroyTileTextures()
	destroyBlipTextures()
	if radarTab.quad then
		destroyElement(radarTab.quad)
	end
	if radarTab.blip then
		destroyElement(radarTab.blip)
	end
	if isElement(radarTab.renderTarget) then
		destroyElement(radarTab.renderTarget)
	end
end
)

function getRadarState()
	return radarTab.enabled;
end;

function setRadarState(state)
	radarTab.enabled = state;
end;

function getRadarPosition()
	return windowStart[1], windowStart[2];
end; 

function getRadarSize()
	return windowSize[1], windowSize[2];
end;


------------------------------------------------------------------------------------------------------------------
-- render 3dRadar
------------------------------------------------------------------------------------------------------------------
local timeValue = 0
local tickCount = getTickCount()
addEventHandler("onClientPreRender", root, function()
	if tickCount + 25 > getTickCount() then return end
	tickCount = getTickCount()
	if isPedInVehicle ( localPlayer ) and timeValue < 1 then
		timeValue = timeValue + 0.025
	end
	if not isPedInVehicle ( localPlayer ) and timeValue > 0 then
		timeValue = timeValue - 0.025
	end
end
)

-- count those only once
-- hud
local hudPos = {windowStart[1] - math.floor(windowSize[1] / 100) * 2, windowStart[2] - math.floor(windowSize[2] / 75) * 2}
local hudSiz = {windowSize[1] + math.floor(windowSize[1] / 100) * 4, windowSize[2] + math.floor(windowSize[2] / 75) * (4 + 5)}
local rad1Pos = {windowStart[1], windowStart[2] + windowSize[2] + math.floor((windowSize[2] / 75) * 1.5)}
local rad2Pos = {windowStart[1] + math.floor(windowSize[1] / 2 + windowSize[1] / 200), windowStart[2] + windowSize[2] + math.floor((windowSize[2] / 75) * 1.5)}
local radSiz = {math.floor(windowSize[1] / 2 - windowSize[1] / 400), math.floor(windowSize[2] / 75) *  4}
	
addEventHandler("onClientRender", root, function()
	if not radarTab.enabled then return end
	
	local col = tocolor(r, g, b, 190)
	local bg = tocolor(r, g, b, 100)
	
	-- switch to 3d map render target
	dxSetRenderTarget(radarTab.renderTarget)
	dxDrawRectangle(0, 0, scx, scy, backgroundColor)
	
	-- get camera matrix
	local camMat = getElementMatrix(getCamera())

	-- calculate radar view
	local altPosZ = camHeight[1] + ((camHeight[2] - camHeight[1]) * (timeValue + 0.05))
	local altRotX = math.rad(camAngle[1] - ((camAngle[1] - camAngle[2]) * (timeValue + 0.05)))
	local altRotZ = vec2Angle(camMat[2][1], camMat[2][2])

	-- create a matrix based on above
	local thisPos = camMat[4]
	if isElement(localPlayer) then
		if isElementStreamedIn(localPlayer) then
			thisPos[1], thisPos[2] = getElementPosition(localPlayer)
		end
	end

	dxSetShaderValue( radarTab.quad, "bIsArrow", false )
	dxSetShaderValue( radarTab.quad, "sElementRotation", 0, 0, 0)
	dxSetShaderValue( radarTab.quad, "sIsBillboard", false )	

	dxSetShaderValue( radarTab.blip, "sElementRotation", 0, 0, 0)	
	
	dxSetShaderValue( radarTab.quad, "sCameraInputPosition", thisPos[1], thisPos[2], altPosZ )
	dxSetShaderValue( radarTab.quad, "sCameraInputRotation", altRotX, 0, altRotZ )
	
	dxSetShaderValue( radarTab.blip, "sCameraInputPosition", thisPos[1], thisPos[2], altPosZ )
	dxSetShaderValue( radarTab.blip, "sCameraInputRotation", altRotX, 0, altRotZ )
	
	local plDimension = getElementDimension(localPlayer)
	local plInterior = getElementInterior(localPlayer)
	
	-- draw map tiles	
	if plInterior == 0 then	
		for x=0, 5, 1 do
			for y=0, 5, 1 do
				if ( math.abs(radarTab.tiles[x][y].position[1] - thisPos[1]) < cullDist and  math.abs(radarTab.tiles[x][y].position[2] - thisPos[2]) < cullDist ) then		

					dxSetShaderValue( radarTab.tiles[x][y].shader, "sCameraInputPosition", thisPos[1], thisPos[2], altPosZ )
					dxSetShaderValue( radarTab.tiles[x][y].shader, "sCameraInputRotation", altRotX, 0, altRotZ )

					dxDrawImage( 0, 0, scx, scy, radarTab.tiles[x][y].shader, 0, 0, 0 )		
				end
			end
		end
	end

	for k, v in ipairs(radarTab.custom.tiles) do
		if v.enabled then
			if plInterior == v.interior then	
				if ( math.abs(v.position[1] - thisPos[1]) < cullDist and  math.abs(v.position[2] - thisPos[2]) < cullDist ) then
					if isElement(v.texture) then
					
						dxSetShaderValue( v.shader, "sCameraInputPosition", thisPos[1], thisPos[2], altPosZ )
						dxSetShaderValue( v.shader, "sCameraInputRotation", altRotX, 0, altRotZ )

						dxDrawImage( 0, 0, scx, scy, v.shader, 0, 0, 0, v.color )
					end
				end
			end
		end
	end
	
	dxSetShaderValue( radarTab.quad, "sIsBillboard", false )			
	dxSetShaderValue( radarTab.quad, "fCullMode", 2 )
	dxSetShaderValue( radarTab.quad, "sTexColor", radarTab.blips[64] )

	-- draw radar areas
	for k, v in ipairs(getElementsByType("radararea")) do
		local raPos = {getElementPosition(v)}
		local raSiz = {getRadarAreaSize(v)}

		if getElementDimension(v) == plDimension and getElementInterior(v) == plInterior then	
			local bcR, bcG, bcB, bcA = getRadarAreaColor(v)
			bcA = math.min(bcA, 200)
			
			dxSetShaderValue( radarTab.quad, "sElementPosition", raPos[1] + raSiz[1] / 2, raPos[2] + raSiz[2] / 2, 0 )
			dxSetShaderValue( radarTab.quad, "sElementSize", raSiz[1], raSiz[2] )
			dxDrawImage( 0, 0, scx, scy, radarTab.quad, 0, 0, 0, tocolor(bcR, bcG, bcB, bcA) )	
		end
	end
	
	for k, v in ipairs(radarTab.custom.materials) do
		if v.enabled then
			if plInterior == v.interior then	
				if ( math.abs(v.position[1] - thisPos[1]) < cullDist and  math.abs(v.position[2] - thisPos[2]) < cullDist ) then
					if isElement(v.texture) then
					
						dxSetShaderValue( v.shader, "sCameraInputPosition", thisPos[1], thisPos[2], altPosZ )
						dxSetShaderValue( v.shader, "sCameraInputRotation", altRotX, 0, altRotZ )

						dxDrawImage( 0, 0, scx, scy, v.shader, 0, 0, 0, v.color )
					end
				end
			end
		end
	end	

	-- skip to original RT
	dxSetRenderTarget()	
	
	dxDrawImageSection( windowStart[1], windowStart[2], windowSize[1], windowSize[2],
                          addSize, addSize, windowSize[1], windowSize[2], radarTab.renderTarget, 0, 0, 0, renderTargetColor )

	-- set and clear map RT
	dxSetRenderTarget( radarTab.renderTarget, true )

	dxSetShaderValue( radarTab.blip, "bIsBorder", false )
	local plaPos = {getElementPosition(localPlayer)}
	
	-- draw blips
	for k, v in ipairs(getElementsByType("blip")) do
		local bliPos = {getElementPosition(v)}
		if bliPos[1] and bliPos[2] then
			local actualDist = getDistanceBetweenPoints2D(plaPos[1], plaPos[2], bliPos[1], bliPos[2])
			if actualDist <= getBlipVisibleDistance(v) and getElementDimension(v) == plDimension and getElementInterior(v) == plInterior then
				local bid = getElementData(v, "customIcon") or getBlipIcon(v)		
				local _, _, _, bcA = getBlipColor(v)
				local bcR, bcG, bcB = 255, 255, 255
				if getBlipIcon(v) == 0 then
					bcR, bcG, bcB = getBlipColor(v)
				end
				local bS = getBlipSize(v) * 0.75

				dxSetShaderValue( radarTab.blip, "sTexColor", radarTab.blips[bid] )			
				dxSetShaderValue( radarTab.blip, "sElementPosition", bliPos[1], bliPos[2], 0 )
				dxSetShaderValue( radarTab.blip, "sElementSize", bS, bS )
				dxDrawImage( 0, 0, scx, scy, radarTab.blip, 0, 0, 0, tocolor(bcR, bcG, bcB, bcA) )	
			end
		end
	end

	-- draw custom blips
	for k, v in ipairs(radarTab.custom.blips) do
		if v.enabled then
			local bliPos = v.position
			if bliPos[1] and bliPos[2] then
				local actualDist = getDistanceBetweenPoints2D(plaPos[1], plaPos[2], bliPos[1], bliPos[2])
				local maxDist = v.distance
				if actualDist <= maxDist and v.dimension == plDimension and v.interior == plInterior then
					if isElement(v.texture) then
						local bS = v.size * 0.75

						dxSetShaderValue( radarTab.blip, "sTexColor", v.texture )			
						dxSetShaderValue( radarTab.blip, "sElementPosition", bliPos[1], bliPos[2], 0 )
						dxSetShaderValue( radarTab.blip, "sElementSize", bS, bS )
						dxDrawImage( 0, 0, scx, scy, radarTab.blip, 0, 0, 0, v.color )
					end
				end
			end
		end
	end

	-- get arrow texture
	dxSetShaderValue( radarTab.quad, "sTexColor", radarTab.blips[2] )
	
	-- get ped arrow yaw
	local plVec = getElementMatrix(localPlayer)[2]
	local plAngle = vec2Angle(plVec[1], plVec[2])
	dxSetShaderValue( radarTab.quad, "sElementRotation", 0, 0, plAngle )

	-- set the remaining renderer stuff for arrow
	dxSetShaderValue( radarTab.quad, "sElementPosition", plaPos[1], plaPos[2], 0 )
	dxSetShaderValue( radarTab.quad, "sElementSize", arrowSize + 5/zoom, arrowSize + 5/zoom)
	dxSetShaderValue( radarTab.quad, "sIsBillboard", false )
	dxSetShaderValue( radarTab.quad, "bIsArrow", true )
	dxDrawImage( 0, 0, scx, scy, radarTab.quad, 0, 0, 0 )
	
	dxSetShaderValue( radarTab.blip, "sTexColor", radarTab.blips[4] )			
	dxSetShaderValue( radarTab.blip, "sElementPosition", thisPos[1], thisPos[2] + 3000, 0 )
	dxSetShaderValue( radarTab.blip, "sElementSize", blipSize * 2.5, blipSize * 2.5 )
	dxSetShaderValue( radarTab.blip, "bIsBorder", true )
	dxDrawImage( 0, 0, scx, scy, radarTab.blip, 0, 0, 0 )	
	
	-- skip to original RT
	dxSetRenderTarget()	
	dxDrawImage(windowStart[1], windowStart[2], windowSize[1], windowSize[2], "tex/radar_frame.png")
	-- draw the player arrow
	dxDrawImage(windowStart[1] - addSize, windowStart[2] - addSize, windowSize[1] + 2 * addSize, windowSize[2] + 2 * addSize, radarTab.renderTarget, 0, 0, 0)
end
)

------------------------------------------------------------------------------------------------------------------
-- tile textures
------------------------------------------------------------------------------------------------------------------
function setTileShaderValues(this)
	dxSetShaderValue( this.shader, "sTexColor", this.texture )
	dxSetShaderValue( this.shader, "sElementRotation", this.rotation )
	dxSetShaderValue( this.shader, "sElementPosition", this.position )
	dxSetShaderValue( this.shader, "sElementSize", this.size )	
	dxSetShaderValue( this.shader, "sFov", fieldOfView )
	dxSetShaderValue( this.shader, "sClip", clipDistance[1], clipDistance[2] )
	dxSetShaderValue( this.shader, "sAspect", windowSize[2] / windowSize[1] )
	dxSetShaderValue( this.shader, "sScrRes", scx, scy )

end

function createTileTextures()
	local isTexValid = true
	radarTab.tiles = {}
	for x=0, 5, 1 do
		radarTab.tiles[x] = {}
		for y=0, 5, 1 do
			radarTab.tiles[x][y] = {}
			radarTab.tiles[x][y].position = {-3000 + 1000 * x + 500, 3000 - 1000 * y - 500, 0}
			radarTab.tiles[x][y].size = {1000, 1000}
			radarTab.tiles[x][y].rotation = {0, 0, 0}
 			radarTab.tiles[x][y].texture = dxCreateTexture("tex/radar/tile_"..y.."_"..x..".dds")
			radarTab.tiles[x][y].shader = dxCreateShader("fx/image3D_manual_quad.fx")
			isTexValid = isElement(radarTab.tiles[x][y].texture) and isElement(radarTab.tiles[x][y].shader) and isTexValid
			if isTexValid then 	
				setTileShaderValues(radarTab.tiles[x][y])
			end
		end	
	end
	return isTexValid
end

function destroyTileTextures()
	local isTexValid = true
	for x=0, 5, 1 do
		for y=0, 5, 1 do
			if isElement(radarTab.tiles[x][y].texture) then
				isTexValid = destroyElement(radarTab.tiles[x][y].texture) and destroyElement(radarTab.tiles[x][y].shader) and isTexValid
			end
		end	
	end
	return isTexValid
end

function createBlipTextures()
	local isTexValid = true
	for x=0, 65, 1 do
		radarTab.blips[x] = dxCreateTexture("tex/blip/"..x..".png", "dxt5", false, "clamp")
		isTexValid = isElement(radarTab.blips[x]) and isTexValid
	end
	return isTexValid
end

function destroyBlipTextures()
	local isTexValid = true
	for x=0, 65, 1 do
		if isElement(radarTab.blips[x]) then
			isTexValid = destroyElement(radarTab.blips[x]) and isTexValid
		end
	end
	return isTexValid
end

------------------------------------------------------------------------------------------------------------------
-- exports handling
------------------------------------------------------------------------------------------------------------------
customBlip = {}
function customBlip.create(posX, posY, posZ, tTexture, size, colR, colG, colB, colA, visibleDistance)
	local w = findEmptyEntry(radarTab.custom.blips)
	radarTab.custom.blips[w] = {}
	radarTab.custom.blips[w].texture = tTexture
	radarTab.custom.blips[w].position = {posX, posY, posZ}
	radarTab.custom.blips[w].rotation = {0, 0, 0}
	radarTab.custom.blips[w].size = size
	radarTab.custom.blips[w].color = tocolor(colR, colG, colB, colA)
	radarTab.custom.blips[w].distance = visibleDistance
	radarTab.custom.blips[w].interior = 0
	radarTab.custom.blips[w].dimension = 0
	
	if isElement(radarTab.custom.blips[w].texture) then
		radarTab.custom.blips[w].shader = dxCreateShader("fx/image2D_manual_blip.fx.fx")
		if isElement(radarTab.custom.blips[w].shader) then
			setTileShaderValues(radarTab.custom.blips[w])
			radarTab.custom.blips[w].enabled = true	
			return w
		end
	end
	radarTab.custom.blips[w].enabled = false
	return false
end

function customBlip.destroy(w)
	radarTab.custom.blips[w].enabled = false
	if isElement(radarTab.custom.blips[w].shader) then
		destroyElement(radarTab.custom.blips[w].shader)
	end
	radarTab.custom.blips[w].tTexture = nil	
end

function customBlip.setTexture(w, tTexture)
	radarTab.custom.blips[w].tTexture = tTexture	
end

function customBlip.setPosition(w, posX, posY, posZ)
	radarTab.custom.blips[w].position = {posX, posY, posZ}
end

function customBlip.setColor(w, colR, colG, colB, colA)
	radarTab.custom.blips[w].color = tocolor(colR, colG, colB, colA)
end

function customBlip.setSize(w, size)
	radarTab.custom.blips[w].size = size
end

function customBlip.setDistance(w, dist)
	radarTab.custom.blips[w].distance = dist
end

function customBlip.setInterior(w, interior)
	radarTab.custom.blips[w].interior = interior
end

function customBlip.setDimension(w, dimension)
	radarTab.custom.blips[w].dimension = dimension
end

customTile = {}
function customTile.create(tTexture, posX, posY, posZ, rotX, rotY, rotZ, sizX, sizY, colR, colG, colB, colA , isBill)
	local w = findEmptyEntry(radarTab.custom.tiles)
	radarTab.custom.tiles[w] = {}
	radarTab.custom.tiles[w].texture = tTexture
	radarTab.custom.tiles[w].position = {posX, posY, posZ}
	radarTab.custom.tiles[w].rotation = {rotX, rotY, rotZ}
	radarTab.custom.tiles[w].size = {sizX, sizY}
	radarTab.custom.tiles[w].color = tocolor(colR, colG, colB, colA)
	radarTab.custom.tiles[w].isBillboard = isBill
	radarTab.custom.tiles[w].cull = 2
	radarTab.custom.tiles[w].interior = 0
	
	if isElement(radarTab.custom.tiles[w].texture) then
		radarTab.custom.tiles[w].shader = dxCreateShader("fx/image3D_manual.fx")
		if isElement(radarTab.custom.tiles[w].shader) then
			setTileShaderValues(radarTab.custom.tiles[w])
			dxSetShaderValue(radarTab.custom.tiles[w].shader, "fCullMode", 2)
			dxSetShaderValue(radarTab.custom.tiles[w].shader, "sIsBillboard", isBill)
			dxSetShaderValue(radarTab.custom.tiles[w].shader, "bIsArrow", false)
			radarTab.custom.tiles[w].enabled = true	
			return w
		end
	end
	radarTab.custom.tiles[w].enabled = false
	return false
end

function customTile.destroy(w)
	radarTab.custom.tiles[w].enabled = false
	if isElement(radarTab.custom.tiles[w].shader) then
		destroyElement(radarTab.custom.tiles[w].shader)
	end
	radarTab.custom.tiles[w].tTexture = nil
end

function customTile.setTexture(w, tTexture)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].tTexture = tTexture
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "sTexColor", tTexture)
	end
end

function customTile.setPosition(w, posX, posY, posZ)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].position = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "sElementPosition", posX, posY, posZ)
	end
end

function customTile.setRotation(w, rotX, rotY, rotZ)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].rotation = {rotX, rotY, rotZ}
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "sElementRotation", rotX, rotY, rotZ)
	end
end

function customTile.setColor(w, colR, colG, colB, colA)
	radarTab.custom.tiles[w].color = tocolor(colR, colG, colB, colA)
end

function customTile.setSize(w, sizeX, sizeY)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].size = {sizeX, sizeY}
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "sElementSize", sizeX, sizeY)
	end
end

function customTile.setInterior(w, interior)
	radarTab.custom.tiles[w].interior = interior
end

function customTile.setBillboard(w, isBill)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].isBillboard = isBill
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "sIsBillboard", isBill)	
	end
end

function customTile.setCullMode(w, cull)
	if radarTab.custom.tiles[w].enabled then
		radarTab.custom.tiles[w].cull = cull
		dxSetShaderValue(radarTab.custom.tiles[w].shader, "fCullMode", cull)	
	end
end

customMaterial = {}
function customMaterial.createLine3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, width, colR, colG, colB, colA, isBill, isSoft)
	local w = findEmptyEntry(radarTab.custom.materials)
	radarTab.custom.materials[w] = {}
	if isSoft then radarTab.custom.materials[w].texture = radarTab.blips[65]
		else radarTab.custom.materials[w].texture = radarTab.blips[64]
	end
	radarTab.custom.materials[w].position = {pos1X + ((pos2X - pos1X) / 2), pos1Y + ((pos2Y - pos1Y) / 2), pos1Z + ((pos2Z - pos1Z) / 2)}
	radarTab.custom.materials[w].position1 = {pos1X, pos1Y, pos1Z}
	radarTab.custom.materials[w].position2 = {pos2X, pos2Y, pos2Z}
	radarTab.custom.materials[w].position3 = {0, 0, 0}
	radarTab.custom.materials[w].position4 = {0, 0, 0}
	radarTab.custom.materials[w].rotation = {rotX, rotY, rotZ}
	radarTab.custom.materials[w].size = {width, 0}
	radarTab.custom.materials[w].color = tocolor(colR, colG, colB, colA)
	radarTab.custom.materials[w].isBillboard = isBill
	radarTab.custom.materials[w].cull = 1
	radarTab.custom.materials[w].interior = 0
	
	if isElement(radarTab.custom.materials[w].texture) then
		radarTab.custom.materials[w].shader = dxCreateShader("fx/image3D_manual_line.fx")
		if isElement(radarTab.custom.materials[w].shader) then
			setTileShaderValues(radarTab.custom.materials[w])
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition1", pos1X, pos1Y, pos1Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition2", pos2X, pos2Y, pos2Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "fCullMode", 1)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sIsBillboard", isBill)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sWidth", width)			
			radarTab.custom.materials[w].enabled = true	
			return w
		end
	end
	radarTab.custom.materials[w].enabled = false
	return false
end

function customMaterial.createBezier3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, pos3X, pos3Y, pos3Z, pos4X, pos4Y, pos4Z, width, colR, colG, colB, colA, isBill, isSoft)
	local w = findEmptyEntry(radarTab.custom.materials)
	radarTab.custom.materials[w] = {}
	if isSoft then radarTab.custom.materials[w].texture = radarTab.blips[65]
		else radarTab.custom.materials[w].texture = radarTab.blips[64]
	end
	radarTab.custom.materials[w].position = {pos1X + ((pos2X - pos1X) / 2), pos1Y + ((pos2Y - pos1Y) / 2), pos1Z + ((pos2Z - pos1Z) / 2)}
	radarTab.custom.materials[w].position1 = {pos1X, pos1Y, pos1Z}
	radarTab.custom.materials[w].position2 = {pos2X, pos2Y, pos2Z}
	radarTab.custom.materials[w].position3 = {pos3X, pos3Y, pos3Z}
	radarTab.custom.materials[w].position4 = {pos4X, pos4Y, pos4Z}
	radarTab.custom.materials[w].rotation = {rotX, rotY, rotZ}
	radarTab.custom.materials[w].size = {width, 0}
	radarTab.custom.materials[w].color = tocolor(colR, colG, colB, colA)
	radarTab.custom.materials[w].isBillboard = isBill
	radarTab.custom.materials[w].cull = 1
	radarTab.custom.materials[w].interior = 0
	
	if isElement(radarTab.custom.materials[w].texture) then
		radarTab.custom.materials[w].shader = dxCreateShader("fx/image3D_manual_bezier.fx")
		if isElement(radarTab.custom.materials[w].shader) then
			setTileShaderValues(radarTab.custom.materials[w])	
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition1", pos1X, pos1Y, pos1Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition2", pos2X, pos2Y, pos2Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition3", pos3X, pos3Y, pos3Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition4", pos4X, pos4Y, pos4Z)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sWidth", width)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "fCullMode", 1)
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sIsBillboard", isBill)			
			local pointDist = getDistanceBetweenPoints3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z) + 
				getDistanceBetweenPoints3D(pos2X, pos2Y, pos2Z, pos3X, pos3Y, pos3Z) +
				getDistanceBetweenPoints3D(pos3X, pos3Y, pos3Z, pos4X, pos4Y, pos4Z)
			dxSetShaderTessellation(radarTab.custom.materials[w].shader, 1, math.ceil(pointDist))
			dxSetShaderValue(radarTab.custom.materials[w].shader, "sTesselation", math.ceil(pointDist))		
			radarTab.custom.materials[w].enabled = true	
			return w
		end
	end
	radarTab.custom.materials[w].enabled = false
	return false
end

function customMaterial.destroy(w)
	radarTab.custom.materials[w].enabled = false
	if isElement(radarTab.custom.materials[w].shader) then
		destroyElement(radarTab.custom.materials[w].shader)
	end
	radarTab.custom.materials[w].tTexture = nil
end

function customMaterial.setTexture(w, tTexture)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].tTexture = tTexture
		dxSetShaderValue( radarTab.custom.materials[w].shader, "sTexColor", tTexture)
	end
end

function customMaterial.setPosition(w, posX, posY, posZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].position = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sElementPosition", posX, posY, posZ)
	end
end

function customMaterial.setPosition1(w, posX, posY, posZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].position1 = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition1", posX, posY, posZ)
	end
end

function customMaterial.setPosition2(w, posX, posY, posZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].position2 = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition2", posX, posY, posZ)
	end
end

function customMaterial.setPosition3(w, posX, posY, posZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].position3 = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition3", posX, posY, posZ)
	end
end

function customMaterial.setPosition4(w, posX, posY, posZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].position4 = {posX, posY, posZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sPointPosition4", posX, posY, posZ)
	end
end

function customMaterial.setRotation(w, rotX, rotY, rotZ)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].rotation = {rotX, rotY, rotZ}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sElementRotation", rotX, rotY, rotZ)
	end
end

function customMaterial.setColor(w, colR, colG, colB, colA)
	radarTab.custom.materials[w].color = tocolor(colR, colG, colB, colA)
end

function customMaterial.setSize(w, sizeX, sizeY)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].size = {sizeX, sizeY}
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sElementSize", sizeX, sizeY)
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sWidth", sizeX)
	end
end

function customMaterial.setInterior(w, interior)
	radarTab.custom.materials[w].interior = interior
end

function customMaterial.setBillboard(w, isBill)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].isBillboard = isBill
		dxSetShaderValue(radarTab.custom.materials[w].shader, "sIsBillboard", isBill)	
	end
end

function customMaterial.setCullMode(w, cull)
	if radarTab.custom.materials[w].enabled then
		radarTab.custom.materials[w].cull = cull
		dxSetShaderValue(radarTab.custom.materials[w].shader, "fCullMode", cull)	
	end
end

------------------------------------------------------------------------------------------------------------------
-- helper functions
------------------------------------------------------------------------------------------------------------------
function findEmptyEntry(inTable)
	for index,value in ipairs(inTable) do
		if not value.enabled then
			return index
		end
	end
	return #inTable + 1
end

function vec2Angle(x, y) 
	local t = -(math.atan2(x, y))
	if t < 0 then t = t + (2 * math.pi) end
	return t
end
