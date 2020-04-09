--
-- c_exported_functions.lua
--

function createCustomBlip(posX, posY, posZ, tTexture, ...)
	if tTexture then
		if isElement(tTexture) then
			if getElementType(tTexture)=="texture" then
				local reqParam = {posX, posY, posZ}
				local isThisValid = true
				local countParam = 0
				for m, param in ipairs(reqParam) do
					countParam = countParam + 1
					isThisValid = isThisValid and param and (type(param) == "number")
				end
				if isThisValid  and (countParam == 3) then
					local opTable = {...}
					local size, colR, colG, colB, colA, visibleDistance = opTable[1] or 2, opTable[2] or 255, opTable[3] or 255, 
						opTable[4] or 255, opTable[5] or 255, opTable[6] or 9999
					if visibleDistance == 0 then visibleDistance = 9999 end
					local blipElementID = customBlip.create(posX, posY, posZ, tTexture, size, colR, colG, colB, colA, visibleDistance)
					return createElement("CustomBlip3D", tostring(blipElementID))
				else
					return false
				end	
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function destroyCustomBlip(w)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	if type(blipElementID) == "number" then
		return destroyElement(w) and customBlip.destroy(blipElementID)
	else
		return false
	end
end

function setCustomBlipTexture(w, tTexture)
	if not isElement(w) or not not tTexture then 
		return false
	end
	if not isElement(tTexture) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	if getElementType(tTexture)== "texture" and type(blipElementID) == "number" then
		return customBlip.setTexture(blipElementID, tTexture)
	else
		return false
	end
end

function setCustomBlipPosition(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customBlip.setPosition(blipElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomBlipColor(w, colR, colG, colB, colA)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, colR, colG, colB, colA}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 5) then
		return customBlip.setColor(blipElementID, colR, colG, colB, colA)
	else
		return false
	end
end

function setCustomBlipVisibleDistance(w, dist)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, dist}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customBlip.setDistance(blipElementID, dist)
	else
		return false
	end
end

function setCustomBlipSize(w, size)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, size}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customBlip.setSize(blipElementID, size)
	else
		return false
	end
end

function setCustomBlipInterior(w, interior)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, interior}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customBlip.setInterior(blipElementID, interior)
	else
		return false
	end
end

function createCustomTile(tTexture, posX, posY, posZ, ...)
	if tTexture then
		if isElement(tTexture) then
			if getElementType(tTexture)=="texture" then
				local reqParam = {posX, posY, posZ}
				local isThisValid = true
				local countParam = 0
				for m, param in ipairs(reqParam) do
					countParam = countParam + 1
					isThisValid = isThisValid and param and (type(param) == "number")
				end
				if isThisValid  and (countParam == 3) then
					local opTable = {...}
					local rotX, rotY, rotZ, sizX, sizY, colR, colG, colB, colA , isBill = opTable[1] or 0, opTable[2] or 0, opTable[3] or 0
						, opTable[4] or 250, opTable[5] or 250, opTable[6] or 255, opTable[7] or 255, opTable[8] or 255, opTable[9] or 255, opTable[10] or false	
					local tileElementID = customTile.create(tTexture, posX, posY, posZ, rotX, rotY, rotZ, sizX, sizY, colR, colG, colB, colA , isBill)
					return createElement("CustomTile3D", tostring(tileElementID))
				else
					return false
				end	
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function destroyCustomTile(w)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) == "number" then
		return destroyElement(w) and customTile.destroy(tileElementID)
	else
		return false
	end
end

function setCustomTileTexture(w, tTexture)
	if not isElement(w) or not not tTexture then 
		return false
	end
	if not isElement(tTexture) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if getElementType(tTexture)== "texture" and type(tileElementID) == "number" then
		return customTile.setTexture(tileElementID, tTexture)
	else
		return false
	end
end

function setCustomTilePosition(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customTile.setPosition(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomTileRotation(w, rotX, rotY, rotZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, rotX, rotY, rotZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customTile.setRotation(tileElementID, rotX, rotY, rotZ)
	else
		return false
	end
end

function setCustomTileColor(w, colR, colG, colB, colA)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, colR, colG, colB, colA}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 5) then
		return customTile.setColor(tileElementID, colR, colG, colB, colA)
	else
		return false
	end
end

function setCustomTileSize(w, sizeX, ...)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, sizeX}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		local inTable = {}
		local sizeY = inTable[1] or sizeX
		return customTile.setSize(blipElementID, sizeX, sizeY)
	else
		return false
	end
end

function setCustomTileBillboard(w, isBillboard)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) =="number"  and (type(isBillboard) =="boolean") then
		return customTile.setBillboard(tileElementID, isBillboard)
	else
		return false
	end
end

function setCustomTileCullMode(w, cull)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) =="number"  and (type(cull) =="number") then
		return customTile.setCullMode(tileElementID, cull)
	else
		return false
	end
end

function setCustomTileInterior(w, interior)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, interior}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customTile.setInterior(blipElementID, interior)
	else
		return false
	end
end

function createCustomMaterialLine2D(pos1X, pos1Y, pos2X, pos2Y, ...)
	local reqParam = {pos1X, pos1Y, pos2X, pos2Y}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		local opTable = {...}
		local width, colR, colG, colB, colA, isBill, isSoft = opTable[1] or 1, opTable[2] or 255, opTable[3] or 255
			, opTable[4] or 255, opTable[5] or 255, opTable[6] or false, opTable[7] or false
		local tileElementID = customMaterial.createLine3D(pos1X, pos1Y, 0, pos2X, pos2Y, 0, width, colR, colG, colB, colA, isBill, isSoft)
		return createElement("CustomMaterial3D", tostring(tileElementID))
	else
		return false
	end	
end

function createCustomMaterialBezierLine3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, pos3X, pos3Y, pos3Z, pos4X, pos4Y, pos4Z, ...)
	local reqParam = {pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, pos3X, pos3Y, pos3Z, pos4X, pos4Y, pos4Z}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 12) then
		local opTable = {...}
		local width, colR, colG, colB, colA, isBill, isSoft = opTable[1] or 1, opTable[2] or 255, opTable[3] or 255
			, opTable[4] or 255, opTable[5] or 255, opTable[6] or false, opTable[7] or false	
		local tileElementID = customMaterial.createBezier3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, pos3X, pos3Y, pos3Z, pos4X, pos4Y, pos4Z, width, colR, colG, colB, colA, isBill, isSoft)
		return createElement("CustomMaterial3D", tostring(tileElementID))
	else
		return false
	end	
end

function createCustomMaterialBezierLine2D(pos1X, pos1Y, pos2X, pos2Y, pos3X, pos3Y, pos4X, pos4Y, ...)
	local reqParam = {pos1X, pos1Y, pos2X, pos2Y, pos3X, pos3Y, pos4X, pos4Y}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 8) then
		local opTable = {...}
		local width, colR, colG, colB, colA, isBill, isSoft = opTable[1] or 1, opTable[2] or 255, opTable[3] or 255
			, opTable[4] or 255, opTable[5] or 255, opTable[6] or false, opTable[7] or false
		local tileElementID = customMaterial.createBezier3D(pos1X, pos1Y, 0, pos2X, pos2Y, 0, pos3X, pos3Y, 0, pos4X, pos4Y, 0, width, colR, colG, colB, colA, isBill, isSoft)
		return createElement("CustomMaterial3D", tostring(tileElementID))
	else
		return false
	end	
end

function createCustomMaterialLine3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, ...)
	local reqParam = {pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 6) then
		local opTable = {...}
		local width, colR, colG, colB, colA, isBill, isSoft = opTable[1] or 1, opTable[2] or 255, opTable[3] or 255
			, opTable[4] or 255, opTable[5] or 255, opTable[6] or false, opTable[7] or false	
		local tileElementID = customMaterial.createLine3D(pos1X, pos1Y, pos1Z, pos2X, pos2Y, pos2Z, width, colR, colG, colB, colA, isBill, isSoft)
		return createElement("CustomMaterial3D", tostring(tileElementID))
	else
		return false
	end	
end

function destroyCustomMaterial(w)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) == "number" then
		return destroyElement(w) and customMaterial.destroy(tileElementID)
	else
		return false
	end
end

function setCustomMaterialPosition(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setPosition(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomMaterialPosition1(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setPosition1(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomMaterialPosition2(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setPosition2(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomMaterialPosition3(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setPosition3(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomMaterialPosition4(w, posX, posY, posZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, posX, posY, posZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setPosition4(tileElementID, posX, posY, posZ)
	else
		return false
	end
end

function setCustomMaterialRotation(w, rotX, rotY, rotZ)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, rotX, rotY, rotZ}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 4) then
		return customMaterial.setRotation(tileElementID, rotX, rotY, rotZ)
	else
		return false
	end
end

function setCustomMaterialColor(w, colR, colG, colB, colA)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	local reqParam = {tileElementID, colR, colG, colB, colA}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 5) then
		return customMaterial.setColor(tileElementID, colR, colG, colB, colA)
	else
		return false
	end
end

function setCustomMaterialSize(w, sizeX, ...)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, sizeX}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		local inTable = {}
		local sizeY = inTable[1] or sizeX
		return customMaterial.setSize(blipElementID, sizeX, sizeY)
	else
		return false
	end
end

function setCustomMaterialWidth(w, sizeX)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, sizeX}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customMaterial.setSize(blipElementID, sizeX, sizeX)
	else
		return false
	end
end

function setCustomMaterialBillboard(w, isBillboard)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) =="number"  and (type(isBillboard) =="boolean") then
		return customMaterial.setBillboard(tileElementID, isBillboard)
	else
		return false
	end
end

function setCustomMaterialCullMode(w, cull)
	if not isElement(w) then 
		return false
	end
	local tileElementID = tonumber(getElementID(w))
	if type(tileElementID) =="number"  and (type(cull) =="number") then
		return customMaterial.setCullMode(tileElementID, cull)
	else
		return false
	end
end

function setCustomMaterialInterior(w, interior)
	if not isElement(w) then 
		return false
	end
	local blipElementID = tonumber(getElementID(w))
	local reqParam = {blipElementID, interior}
	local isThisValid = true
	local countParam = 0
	for m, param in ipairs(reqParam) do
		countParam = countParam + 1
		isThisValid = isThisValid and param and (type(param) == "number")
	end
	if isThisValid  and (countParam == 2) then
		return customMaterial.setInterior(blipElementID, interior)
	else
		return false
	end
end
