local _writeScript = function ( responseData, errno, filepath )
	if errno > 0 then
		return
	end
	
	local file = fileCreate ( filepath )
	if file then
		fileWrite ( file, responseData )
		fileClose ( file )
	end
end

function compileScript ( filepath , compiled)
	local filename = gettok ( filepath, 1, 46 )
	if compiled then 
		filepath = string.sub(filepath, 0, #filepath-1)
	end
	
	local file = fileOpen ( filepath, true )
	if file then
		local content = fileRead ( file, fileGetSize ( file ) )
		fileClose ( file )	
		fetchRemote ( "http://luac.mtasa.com/?compile=1&debug=0&obfuscate=3", _writeScript, content, true, filename .. ".luac" )
	end
end

function compileAllScriptsInResource(resource)
	outputChatBox("Kompilacja zasobu " .. resource, root)
	local xml = xmlLoadFile ( ":"..resource.."/meta.xml"  )
	if xml == false then
		return
	end
	
	local node
	local index = 0
	local _next = function ( )
		node = xmlFindChild ( xml, "script", index )
		index = index + 1
		return node
	end
	
	local num = 0
	while _next ( ) do
		if xmlNodeGetAttribute ( node, "special" ) == false then
			local filepath = xmlNodeGetAttribute ( node, "src" )
			local isClient = xmlNodeGetAttribute ( node, "type" ) == "client"
			local isNoCached = xmlNodeGetAttribute ( node, "cache" ) == "false"
			if isClient then 
				local compiled = false 
				if string.find(filepath, "luac") then 
					compiled = true 
				end
				
				if not isNoCached then
					compileScript ( ":"..resource.."/"..filepath, compiled)
				end
				num = num + 1
			end
		end
	end
end

function compileAllScripts()
	for k,v in ipairs(getResources()) do 
		local name = getResourceName(v)
		if string.find(name, "mm_") then 
			compileAllScriptsInResource(name)
		end
	end
end
addCommandHandler("coall", compileAllScripts)

function compileMSScript(resourceName)
	local res = getResourceFromName(resourceName)
	if res then 
		compileAllScriptsInResource(resourceName)
		return true 
	end
	
	return false 
end 

function compileCMD(player, cmd, arg1)
	if compileMSScript(arg1 or "") then 
		triggerClientEvent(player, "onClientAddNotification", player, "Kompilowanie zasobu "..arg1..".", "info")
	else 
		triggerClientEvent(player, "onClientAddNotification", player, "Nie znaleziono takiego zasobu.", "error")
	end
end 
addCommandHandler("compile", compileCMD)