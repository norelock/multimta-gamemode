function showNotification(player, text, category, sound, time, icon)
	if isElement(player) then 
		triggerClientEvent(player, "onClientAddNotification", resourceRoot, text, category, sound, time, icon)
	end
end 