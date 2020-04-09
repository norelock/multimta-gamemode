function isOnScreen(x, y, z, s)
	if not x or not y or not z then return end 
	
	local sx, sy = getScreenFromWorldPosition(x, y, z, s or 0.2) 
	
	return type(sx) == "number" and type(sy) == "number"
end 

local mathRad = math.rad 
local mathCos = math.cos 
local mathSin = math.sin 
local function createElementMatrix(pos, rot)
	local rx, ry, rz = mathRad(rot[1]), mathRad(rot[2]), mathRad(rot[3])
	return {{ mathCos(rz) * mathCos(ry) - mathSin(rz) * mathSin(rx) * mathSin(ry), 
			mathCos(ry) * mathSin(rz) + mathCos(rz) * mathSin(rx) * mathSin(ry), -mathCos(rx) * mathSin(ry), 0},
			{ -mathCos(rx) * mathSin(rz), mathCos(rz) * mathCos(rx), mathSin(rx), 0},
			{mathCos(rz) * mathSin(ry) + mathCos(ry) * mathSin(rz) * mathSin(rx), mathSin(rz) * mathSin(ry) - 
				mathCos(rz) * mathCos(ry) * mathSin(rx), mathCos(rx) * mathCos(ry), 0},
			{pos[1], pos[2], pos[3], 1 }}
end

local function getPositionFromMatrixOffset(mat, pos)
	return (pos[1] * mat[1][1] + pos[2] * mat[2][1] + pos[3] * mat[3][1] + mat[4][1]), 
		(pos[1] * mat[1][2] + pos[2] * mat[2][2] + pos[3] * mat[3][2] + mat[4][2]),
		(pos[1] * mat[1][3] + pos[2] * mat[2][3] + pos[3] * mat[3][3] + mat[4][3])
end

function drawTransformedMaterial( texture, posX, posY, posZ, dirX, dirY, dirZ, sizeX, sizeY, color, offsetX, offsetY, offsetZ)
	local mat = createElementMatrix({posX, posY, posZ}, {dirX, dirY, dirZ})
	posX, posY, posZ = getPositionFromMatrixOffset(mat, {offsetX, offsetY, offsetZ})
	
	local elMat =  createElementMatrix({posX, posY, posZ}, {dirX, dirY, dirZ})
		
	local v1x,v1y,v1z = getPositionFromMatrixOffset(elMat, {0,-sizeY/2,0})
	local v2x,v2y,v2z = getPositionFromMatrixOffset(elMat, {0,sizeY/2,0})
	local vUx,vUy,vUz = getPositionFromMatrixOffset(elMat, {0,0,1})		
	dxDrawMaterialLine3D ( v1x,v1y,v1z,v2x,v2y,v2z, texture, sizeX, tocolor(color[1], color[2], color[3], color[4]), vUx,vUy,vUz)
end
