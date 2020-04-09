NOTIFICATION_TIME = 8000 -- domyślny czas notyfikacji
NOTIFICATION_LIMIT = 6
NOTIFICATION_CATEGORIES = {
	["info"] = {66, 134, 244},
	["error"] = {255, 61, 61},
	["success"] = {3, 216, 0},
	["heart"] = {0, 0, 0},
	["custom"] = {0, 0, 0}
}

local screenW, screenH = guiGetScreenSize()
-- pozycje
local radarPos = nil;
local radarSize = nil;
local radarState = false;

-- utilsy
local loadCustomFunction = function(func, ...)
	local f = loadstring(func)();
	return f(...);
end;

secondsToTime = function(seconds)
    if type(seconds) ~= "number" then return end;

    local minutes = string.format("%02.f", math.floor(seconds/60));
    local seconds = string.format("%02.f", seconds - (minutes * 60));

    return minutes .. ":" .. seconds;
end;

radarPos    = Vector2(exports.mm_radar:getRadarPosition());
radarSize	= Vector2(exports.mm_radar:getRadarSize());
radarState  = exports.mm_radar:getRadarState();

local zoom = exports.mm_gui:getInterfaceZoom()
local font = exports.mm_gui:getGUIFont("normal_small")
local notificationPos = {x = math.floor(552/zoom), y = screenH/1.2, w=math.floor(376/zoom), h=math.floor(81/zoom)}

notificationPos.x = notificationPos.x - notificationPos.w - math.floor(160/zoom);

if radarState then
	notificationPos.x = radarPos.x;
	notificationPos.y = radarPos.y - 90/zoom;

	notificationPos.w = radarSize.x;
	notificationPos.h = radarSize.y * 0.357;
else
	notificationPos.x = radarPos.x;
	notificationPos.y = radarPos.y + 160/zoom;

	notificationPos.w = radarSize.x;
	notificationPos.h = radarSize.y * 0.357;
end;

-- zmienne
local textures = {}
local notifications = {}
local visibleNotifications = 0

textures.background = dxCreateTexture("assets/images/notifications/background.png")
textures.info = dxCreateTexture("assets/images/notifications/info.png")
textures.error = dxCreateTexture("assets/images/notifications/error.png")
textures.success = dxCreateTexture("assets/images/notifications/success.png")

function addNotification(text, category, sound, time, icon, customN)
	if type(text) == "string" and NOTIFICATION_CATEGORIES[category] then
		if visibleNotifications + 1 > NOTIFICATION_LIMIT then
			for k, v in ipairs(notifications) do
				if not v.hidden and not v.custom then
					v.offsetY = 0;
					v.offsetX = 0;
					v.hidden = true;
					break;
				end;
			end;
		end;

		if icon then
			icon = dxCreateTexture(icon);
		else
			icon = textures[category];
		end;

		local allowSound = true;
		if type(sound) == "boolean" then
			allowSound = sound;
		end;

		if allowSound then
			local snd = playSound("assets/sounds/"..tostring(category)..".mp3", false);
			setSoundVolume(snd, 0.7);
		end;

		table.insert(notifications, {
			text = text,
			category = category,
			offsetX = notificationPos.w * 2,
			takeW = 0,
			offsetY = 0,
			icon = icon,
			alpha = 0,
			custom = type(customN) == "string" and true or false,
			customRender = customN
		});

		if #notifications > 1 then
			for k, v in ipairs(notifications) do
				if v.offsetY_anim then
					if k ~= #notifications then
						finishAnimation(v.offsetY_anim);
					end;
				end;
			end;

			for k, v in ipairs(notifications) do
				if k < #notifications then
					local offsetY = v.offsetY;
					local notification = k;
					v.offsetY_anim = createAnimation(0, notificationPos.h*1.06, "InOutQuad", 200, function(progress)
						if notifications[notification] then
							notifications[notification].offsetY = offsetY + progress;
						end;
					end);
				end;
			end;
		end;

		local notification = #notifications;

		createAnimation(notificationPos.w * 2, 0, "InOutQuad", 400, function(progress)
			if notifications[notification] then
				notifications[notification].offsetX = progress;
			end;
		end);

		createAnimation(0, 255, "InOutQuad", 400, function(progress)
			if notifications[notification] then
				notifications[notification].alpha = progress;
			end;
		end);

		createAnimation(0, notificationPos.w, "Linear", time or NOTIFICATION_TIME, function(progress)
			if notifications[notification] then
				notifications[notification].takeW = progress;
			end;
		end);

		outputConsole(string.format("[%s] %s", category, text));

		if not notifications[notification].custom then
			setTimer(deleteNotification, time or NOTIFICATION_TIME, 1, notification);
		end;

		return notification;
	end;
end;
addEvent("onClientAddNotification", true);
addEventHandler("onClientAddNotification", resourceRoot, addNotification);

function deleteNotification(id)
	if notifications[id] and not notifications[id].hiding and not notifications[id].hidden then
		local id = id

		notifications[id].hiding = true

		createAnimation(0, notificationPos.w*2, "InOutQuad", 700,
			function(progress)
				if notifications[id] then
					notifications[id].offsetX = progress
				end
			end,
			
			function()
				if #notifications > 1 then
					for k, v in ipairs(notifications) do
						if v.offsetY_anim then
							if k ~= #notifications then
								finishAnimation(v.offsetY_anim);
							end;

							if notifications[k].hidden then
								notifications[k].offsetY = 0;
							end;

							if notifications[k].custom and not notifications[k].hidden then
								if notifications[k - 1] then
									notifications[k - 1].offsetY = notifications[k].offsetY;
								end
							end;
						end;
					end;

					for k, v in ipairs(notifications) do
						if k < #notifications then
							local offsetY = v.offsetY;
							local notification = k;

							if not notifications[notification].offsetY == offsetY then return end;
							if notifications[notification].offsetY == 0 then return end;

							v.offsetY_anim = createAnimation(0, notificationPos.h * 1.06, "InOutQuad", 300, function(progress)
								if notifications[notification] then
									notifications[notification].offsetY = offsetY - progress;
								end
							end);
						end;
					end;
				end;
			end
		);

		createAnimation(255, 0, "InOutQuad", 600,
			function(progress)
				if notifications[id] then
					notifications[id].alpha = progress;
				end;
			end,

			function()
				if notifications[id] then
					notifications[id].hidden = true;
					if notifications[id].icon and notifications[id].icon ~= textures.info and notifications[id].icon ~= textures.error and notifications[id].icon ~= textures.success then
						destroyElement(notifications[id].icon);
					end;
				end;
			end
		)
	end;
end;

function getCustomNotificationId(text)
	if text and type(text) == "string" then
		for k, notification in ipairs(notifications) do
			if notification.custom then
				if text == notification.text then
					return k;
				end;
			end;
		end;
	end;

	return nil;
end;

function showNotification(...)
	return addNotification(...)
end;

addEventHandler("onClientRender", root, function()
	local hidden = 0
	visibleNotifications = 0

	radarPos    = Vector2(exports.mm_radar:getRadarPosition());
	radarSize	= Vector2(exports.mm_radar:getRadarSize());
	radarState  = exports.mm_radar:getRadarState();

	if radarState then
		notificationPos.x = radarPos.x;
		notificationPos.y = radarPos.y - 90/zoom;
	
		notificationPos.w = radarSize.x;
		notificationPos.h = radarSize.y * 0.357;
	else
		notificationPos.x = radarPos.x;
		notificationPos.y = radarPos.y + 160/zoom;
	
		notificationPos.w = radarSize.x;
		notificationPos.h = radarSize.y * 0.357;
	end;

	for k, notification in ipairs(notifications) do
		if notification.hidden then
			hidden = hidden + 1
		else
			visibleNotifications = visibleNotifications + 1;

			local offsetX, offsetY = notification.offsetX, notification.offsetY;
			local color = NOTIFICATION_CATEGORIES[notification.category];
			dxDrawImage(notificationPos.x-offsetX, notificationPos.y-offsetY, notificationPos.w, notificationPos.h, textures.background, 0, 0, 0, tocolor(255, 255, 255, notification.alpha), true);

			if not notification.custom then
				local x, y, w, h = notificationPos.x + (67/zoom) - offsetX, notificationPos.y - offsetY, notificationPos.w-10, notificationPos.h;

				dxDrawText(notification.text, x, y, x+w-(60/zoom), y+h, tocolor(255, 255, 255, notification.alpha), 0.76/zoom, font, "left", "center", false, true, true);
				dxDrawRectangle(notificationPos.x-offsetX, (notificationPos.y-2+notificationPos.h) - offsetY, notificationPos.w-notification.takeW, 2, tocolor(color[1], color[2], color[3], notification.alpha), true);
			else
				local x, y, w, h = notificationPos.x - offsetX, notificationPos.y - offsetY, notificationPos.w, notificationPos.h;
				local alpha = notification.alpha;

				loadCustomFunction(notification.customRender, zoom, x, y, w, h, alpha);
			end;

			if notification.icon then
				dxDrawImage(notificationPos.x-offsetX+math.floor(13.5/zoom), notificationPos.y-offsetY+math.floor((notificationPos.h*0.484)/2), math.floor(notificationPos.h)*0.52, math.floor(notificationPos.h)*0.52, notification.icon, 0, 0, 0, tocolor(255, 255, 255, notification.alpha), true);
			end;
		end
	end

	if hidden == #notifications then
		notifications = {}
	end
end);