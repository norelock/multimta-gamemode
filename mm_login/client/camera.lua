local sx, sy = guiGetScreenSize()
cameraTimer = nil
local camerasData = {
	["actual"] = 1,
	{1531, -1766, 84.5, 1475, -1710, 70},
	{2477.2, 1665.3, 42, 2436.5, 1652.9, 29.4},
	{2477.2, -1665.3, 42, 2436.5, -1652.9, 29.4},
	{2110.5, 1256.6, 50.8, 2062.3, 1400.8, 37.8},
}

cameraRender = function()
	x, y, z, lx, ly, lz = getCameraMatrix()
	setCameraMatrix(x, y + 0.1, z, lx + 0.1, ly + 0.1, lz)
end

function nextCamera()
	fadeCamera(false)
	setTimer(function()
		camerasData["actual"] = camerasData["actual"] + 1
		if camerasData["actual"] > #camerasData then
			camerasData["actual"] = 1
		end
		setCameraMatrix(unpack(camerasData[camerasData["actual"]]))
		fadeCamera(true)
	end, 1000, 1)
end