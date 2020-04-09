local logged = getElementData(localPlayer, "player:logged") or false
local spawned = getElementData(localPlayer, "character:spawned") or false

if logged and not spawned then return end
if logged and spawned then return end

local GUI = exports["mm_gui"]
local zoom = GUI:getInterfaceZoom() or 1

local screen = Vector2(guiGetScreenSize())

local music = {
    sound = nil,
    volume = 0
}

local authorization = {
    loaded = false,
    rememberFile = nil,
    remembered = false,
    load_time = nil,
    tabs = {},
    tab_active = 0,
    tab_max = 0,
    previous_tab = 0,
    textures = {},
    fonts = {},
    buttons = {},
    editboxes = {},
    animations = {},
    positions = {}
}
local childs = {}

local function isNotInvalidEmail(mail)
    assert(type(mail) == "string", "Bad argument @ isValidMail [string expected, got " .. tostring(mail) .. "]")
    return mail:match("[A-Za-z0-9%.%%%+%-]+@[A-Za-z0-9%.%%%+%-]+%.%w%w%w?%w?") ~= nil
end

authorization.onLoad = function()
    if not authorization.loaded then
        exports["bmta_loading"]:destroyLoading();
        authorization.load_time = getTickCount()
        switchLoginMusic(true)
        authorization.textures = { -- tekstury
            background = dxCreateTexture("assets/images/background.png"),
            logo = dxCreateTexture("assets/images/logo.png"),
            edit_line = dxCreateTexture("assets/images/gui/edit_line.png"),
            email = dxCreateTexture("assets/images/icons/email.png"),
            user = dxCreateTexture("assets/images/icons/user.png"),
            password = dxCreateTexture("assets/images/icons/password.png"),
            points = {
                default = dxCreateTexture("assets/images/gui/points/default.png"),
                active  = dxCreateTexture("assets/images/gui/points/active.png")
            },
            checkbox = {
                default = dxCreateTexture("assets/images/gui/checkbox/default.png"),
                active  = dxCreateTexture("assets/images/gui/checkbox/active.png")
            },
            buttons = {
                default = dxCreateTexture("assets/images/gui/buttons/default.png"),
                active  = dxCreateTexture("assets/images/gui/buttons/active.png")
            },
            arrows = {
                left = dxCreateTexture("assets/images/gui/arrows/left.png"),
                right = dxCreateTexture("assets/images/gui/arrows/right.png")
            }
        }
        authorization.fonts = {
            light_big = GUI:getGUIFont("light_big") or "default",
            normal_small = GUI:getGUIFont("normal_small") or "default-bold"
        }
        showChat(false)
        showCursor(true)
        setElementAlpha(localPlayer, 0)
        setPlayerHudComponentVisible("all", false);
        setElementData(localPlayer, "player:logged", false)
        setElementData(localPlayer, "player:login_loaded", true)
        addEventHandler("onClientRender", root, authorization.renderBackground)
        addEventHandler("onClientRender", root, authorization.renderTabs)
        addEventHandler("onClientRender", root, authorization.renderSelection)
        addEventHandler("onClientRender", root, cameraRender)
        cameraTimer = setTimer(nextCamera, 15 * 1000, 0)
        nextCamera()
        switchMusicLights(true);
        if not authorization.animations.loaded then
            authorization.animations.loaded = true

            authorization.animations.tab_a = 0
            authorization.animations.main_a = 0

            authorization.animations.background_a = 0

            authorization.animations.tab_a_anim = createAnimation(0, 255, "Linear", 300, function(v)
                authorization.animations.tab_a = v
            end)
            authorization.animations.main_a_anim = createAnimation(0, 255, "Linear", 500, function(v)
                authorization.animations.main_a = v
            end)

            authorization.animations.background_a_anim = createAnimation(0, 200, "Linear", 500, function(v)
                authorization.animations.background_a = v
            end)
        end
        if not authorization.positions.loaded then
            authorization.positions.loaded = true
            authorization.positions = {
                logo = { -- logo position
                    x = (screen.x - 301/zoom)/2,
                    y = (screen.y - 301/zoom)/2,
                    w = 301/zoom,
                    h = 301/zoom
                },
                points = {
                    x = (screen.x - 23/zoom)/2,
                    y = (screen.y - 23/zoom)/2,
                    w = 23/zoom,
                    h = 23/zoom
                },
                select_button = {
                    x = (screen.x - 76/zoom)/2,
                    y = (screen.y - 74/zoom)/2,
                    w = 76/zoom,
                    h = 74/zoom
                },
                checkboxes = {
                    w = 32/zoom,
                    h = 32/zoom
                },
                editboxes = {
                    w = 380/zoom,
                    h = 55/zoom
                },
                buttons = {
                    w = 150/zoom,
                    h = 50/zoom
                },
            }
            authorization.positions.logo.y = screen.y * .51 - authorization.positions.logo.y
        end
        if not authorization.tabs.loaded then
            authorization.tabs.loaded = true
            authorization.buttons = {
                next_selection = GUI:createButton(" ", 0, 0, authorization.positions.select_button.w, authorization.positions.select_button.h),
                previous_selection = GUI:createButton(" ", 0, 0, authorization.positions.select_button.w, authorization.positions.select_button.h),
                login = nil,
                remember = nil,
                register = nil
            }
            GUI:setButtonTextures(authorization.buttons.next_selection, {
                default = authorization.textures.arrows.right,
                hover = authorization.textures.arrows.right,
                press = authorization.textures.arrows.right
            })
            GUI:setButtonPosition(authorization.buttons.previous_selection, authorization.positions.select_button.x - 150/zoom, authorization.positions.select_button.y + 413/zoom)
            GUI:setButtonTextures(authorization.buttons.previous_selection, {
                default = authorization.textures.arrows.left,
                hover = authorization.textures.arrows.left,
                press = authorization.textures.arrows.left
            })
            GUI:setButtonPosition(authorization.buttons.next_selection, authorization.positions.select_button.x + 150/zoom, authorization.positions.select_button.y + 413/zoom)
            addEventHandler("onClientClickButton", authorization.buttons.previous_selection, function()
                if not authorization.loaded then return end
                if authorization.tab_active <= 1 then return end
    
                GUI:setButtonEnabled(authorization.buttons.previous_selection, false)
                authorization.previous_tab = authorization.tab_active
                authorization.animations.tab_a_anim = createAnimation(255, 0, "InOutQuad", 300,
                    function(v)
                        authorization.animations.tab_a = v
                    end,
                    function()
                        GUI:setButtonEnabled(authorization.buttons.previous_selection, true)
                        authorization.tab_active = authorization.tab_active - 1
    
                        authorization.tabs[authorization.previous_tab].active = false
                        authorization.tabs[authorization.tab_active].active = true
                        authorization.tabs[authorization.previous_tab].elements("unload")
                        authorization.tabs[authorization.tab_active].elements("load")
    
                        authorization.animations.tab_a_anim = createAnimation(0, 255, "InOutQuad", 300, function(v)
                            authorization.animations.tab_a = v
                        end)
                    end
                )
            end)
            addEventHandler("onClientClickButton", authorization.buttons.next_selection, function()
                if not authorization.loaded then return end
                if authorization.tab_active >= authorization.tab_max then return end
    
                GUI:setButtonEnabled(authorization.buttons.next_selection, false)
                authorization.previous_tab = authorization.tab_active
                authorization.animations.tab_a_anim = createAnimation(255, 0, "InOutQuad", 300,
                    function(v)
                        authorization.animations.tab_a = v
                    end,
                    function()
                        GUI:setButtonEnabled(authorization.buttons.next_selection, true)
                        authorization.tab_active = authorization.tab_active + 1
    
                        authorization.tabs[authorization.tab_active].active = true
                        authorization.tabs[authorization.previous_tab].active = false
                        authorization.tabs[authorization.tab_active].elements("load")
                        authorization.tabs[authorization.previous_tab].elements("unload")
    
                        authorization.animations.tab_a_anim = createAnimation(0, 255, "InOutQuad", 300, function(v)
                            authorization.animations.tab_a = v
                        end)
                    end
                )
            end)
            authorization.editboxes = {
                auth = {
                    login = nil,
                    password = nil
                },
                register = {
                    login = nil,
                    password = nil,
                    email = nil
                }
            }
            authorization.tabs = {
                [1] = { -- login tab
                    active = true,
                    elements = function(type)
                        if (type == "load") then
                            -- load remembered data
                            authorization.rememberFile = xmlLoadFile("data.xml")
                            authorization.loadRememberedData()
                            local user_login, user_pass, user_check = authorization.returnRememberedData()
                            -- creating editboxes and buttons
                            authorization.buttons.login = GUI:createButton("Zaloguj", 0, 0, authorization.positions.buttons.w, authorization.positions.buttons.h)
                            authorization.buttons.remember = GUI:createButton(" ", 0, 0, authorization.positions.checkboxes.w, authorization.positions.checkboxes.h)
                            if string.len(user_login) ~= 0 and string.len(user_pass) ~= 0 and user_check == "1" then
                                authorization.editboxes.auth.login = GUI:createEditbox(user_login, 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                                authorization.editboxes.auth.password = GUI:createEditbox(user_pass, 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                                authorization.remembered = true
                                GUI:setButtonTextures(authorization.buttons.remember, {
                                    default = authorization.textures.checkbox.active,
                                    hover = authorization.textures.checkbox.active,
                                    press = authorization.textures.checkbox.active
                                })
                            else
                                authorization.editboxes.auth.login = GUI:createEditbox("", 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                                authorization.editboxes.auth.password = GUI:createEditbox("", 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                                authorization.remembered = false
                                GUI:setButtonTextures(authorization.buttons.remember, {
                                    default = authorization.textures.checkbox.default,
                                    hover = authorization.textures.checkbox.default,
                                    press = authorization.textures.checkbox.default
                                })
                            end
                            -- login
                            GUI:setEditboxLine(authorization.editboxes.auth.login, authorization.textures.edit_line)
                            GUI:setEditboxHelperText(authorization.editboxes.auth.login, "Nazwa użytkownika")
                            GUI:setEditboxPosition(authorization.editboxes.auth.login, authorization.positions.logo.x - 24/zoom, authorization.positions.logo.y + 340/zoom)
                            GUI:setEditboxMaxLength(authorization.editboxes.auth.login, 22)
                            GUI:setEditboxAlpha(authorization.editboxes.auth.login, 0)
                            GUI:setEditboxImage(authorization.editboxes.auth.login, authorization.textures.user)
                            -- password
                            GUI:setEditboxLine(authorization.editboxes.auth.password, authorization.textures.edit_line)
                            GUI:setEditboxHelperText(authorization.editboxes.auth.password, "Hasło")
                            GUI:setEditboxPosition(authorization.editboxes.auth.password, authorization.positions.logo.x - 24/zoom, authorization.positions.logo.y + 410/zoom)
                            GUI:setEditboxMasked(authorization.editboxes.auth.password, true)
                            GUI:setEditboxMaxLength(authorization.editboxes.auth.password, 16)
                            GUI:setEditboxAlpha(authorization.editboxes.auth.password, 0)
                            GUI:setEditboxImage(authorization.editboxes.auth.password, authorization.textures.password)
                            -- remember checkbox
                            GUI:setButtonPosition(authorization.buttons.remember, authorization.positions.logo.x + 50/zoom, authorization.positions.logo.y + 492/zoom)
                            GUI:setButtonTexturesColor(authorization.buttons.remember, tocolor(255, 255, 255, 0))
                            addEventHandler("onClientClickButton", authorization.buttons.remember, function()
                                if not authorization.loaded then return end
                                if not authorization.remembered then
                                    authorization.remembered = true
                                    GUI:setButtonTextures(authorization.buttons.remember, {
                                        default = authorization.textures.checkbox.active,
                                        hover = authorization.textures.checkbox.active,
                                        press = authorization.textures.checkbox.active
                                    })
                                else
                                    authorization.remembered = false
                                    GUI:setButtonTextures(authorization.buttons.remember, {
                                        default = authorization.textures.checkbox.default,
                                        hover = authorization.textures.checkbox.default,
                                        press = authorization.textures.checkbox.default
                                    })
                                end
                            end)
                            -- login button
                            GUI:setButtonTextures(authorization.buttons.login, {
                                default = authorization.textures.buttons.default,
                                hover = authorization.textures.buttons.active,
                                press = authorization.textures.buttons.default
                            })
                            GUI:setButtonFont(authorization.buttons.login, authorization.fonts.normal_small, 1/zoom)
                            GUI:setButtonPosition(authorization.buttons.login, authorization.positions.logo.x + 72/zoom, authorization.positions.logo.y + 545/zoom)
                            GUI:setButtonTexturesColor(authorization.buttons.login, tocolor(255, 255, 255, 0))
                            addEventHandler("onClientClickButton", authorization.buttons.login, function()
                                if not authorization.loaded then return end
                                local data = {
                                    login = GUI:getEditboxText(authorization.editboxes.auth.login),
                                    password = GUI:getEditboxText(authorization.editboxes.auth.password)
                                }
                                if string.len(data.login) < 3 or string.len(data.password) > 22 then
                                    return exports.mm_hud:showNotification("Nazwa użytkownika musi mieć więcej niż 3 znaki i mniej niż 22 znaków.", "error")
                                elseif string.len(data.password) < 5 or string.len(data.password) > 16 then
                                    return exports.mm_hud:showNotification("Hasło musi mieć więcej niż 5 znaków i mniej niż 16 znaków.", "error")
                                else
                                    --GUI:setButtonEnabled(authorization.buttons.login, false)
                                    authorization.saveRememberedData(data.login, data.password)
                                    triggerServerEvent("onAuthorizationRequest", localPlayer, "login", {
                                        login = data.login,
                                        password = data.password
                                    })
                                end
                            end)
                            return true
                        elseif (type == "unload") then
                            GUI:destroyButton(authorization.buttons.login)
                            GUI:destroyButton(authorization.buttons.remember)
                            GUI:destroyEditbox(authorization.editboxes.auth.login)
                            GUI:destroyEditbox(authorization.editboxes.auth.password)
                            authorization.buttons.login = nil
                            authorization.buttons.remember = nil
                            authorization.editboxes.auth.login = nil
                            authorization.editboxes.auth.password = nil
                            return true
                        else
                            return false
                        end
                    end,
                    render = function()
                        local drawImage   = dxDrawImage
                        local drawText    = dxDrawText

                        drawText("AUTORYZACJA", 0, 418/zoom, screen.x, 418/zoom, tocolor(255, 255, 255, authorization.animations.tab_a), 1.23/zoom, authorization.fonts.light_big, "center", "top")
                        drawText("Zapamiętaj dane", authorization.positions.logo.x + 100/zoom, authorization.positions.logo.y + 507/zoom, authorization.positions.logo.x + authorization.positions.logo.w, authorization.positions.logo.y + 507/zoom, tocolor(255, 255, 255, authorization.animations.tab_a), 1/zoom, authorization.fonts.normal_small, "left", "center")

                        GUI:renderButton(authorization.buttons.login)
                        GUI:renderButton(authorization.buttons.remember)

                        GUI:renderEditbox(authorization.editboxes.auth.login)
                        GUI:renderEditbox(authorization.editboxes.auth.password)

                        GUI:setButtonTexturesColor(authorization.buttons.login, tocolor(255, 255, 255, authorization.animations.tab_a))
                        GUI:setButtonTexturesColor(authorization.buttons.remember, tocolor(255, 255, 255, authorization.animations.tab_a))

                        GUI:setEditboxAlpha(authorization.editboxes.auth.login, authorization.animations.tab_a)
                        GUI:setEditboxAlpha(authorization.editboxes.auth.password, authorization.animations.tab_a)
                    end
                },
                [2] = { -- register tab
                    active = false,
                    elements = function(type)
                        if (type == "load") then
                            authorization.editboxes.register.login = GUI:createEditbox("", 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                            authorization.editboxes.register.password = GUI:createEditbox("", 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                            authorization.editboxes.register.email = GUI:createEditbox("", 0, 0, authorization.positions.editboxes.w, authorization.positions.editboxes.h, authorization.fonts.normal_small, 1.15/zoom)
                            authorization.buttons.register = GUI:createButton("Zarejestruj", 0, 0, authorization.positions.buttons.w, authorization.positions.buttons.h)
                            -- login
                            GUI:setEditboxLine(authorization.editboxes.register.login, authorization.textures.edit_line)
                            GUI:setEditboxHelperText(authorization.editboxes.register.login, "Nazwa użytkownika")
                            GUI:setEditboxPosition(authorization.editboxes.register.login, authorization.positions.logo.x - 24/zoom, authorization.positions.logo.y + 340/zoom)
                            GUI:setEditboxMaxLength(authorization.editboxes.register.login, 22)
                            GUI:setEditboxAlpha(authorization.editboxes.register.login, 0)
                            GUI:setEditboxImage(authorization.editboxes.register.login, authorization.textures.user)
                            -- password
                            GUI:setEditboxLine(authorization.editboxes.register.password, authorization.textures.edit_line)
                            GUI:setEditboxHelperText(authorization.editboxes.register.password, "Hasło")
                            GUI:setEditboxPosition(authorization.editboxes.register.password, authorization.positions.logo.x - 24/zoom, authorization.positions.logo.y + 410/zoom)
                            GUI:setEditboxMasked(authorization.editboxes.register.password, true)
                            GUI:setEditboxMaxLength(authorization.editboxes.register.password, 22)
                            GUI:setEditboxAlpha(authorization.editboxes.register.password, 0)
                            GUI:setEditboxImage(authorization.editboxes.register.password, authorization.textures.password)
                            -- email
                            GUI:setEditboxLine(authorization.editboxes.register.email, authorization.textures.edit_line)
                            GUI:setEditboxHelperText(authorization.editboxes.register.email, "E-mail")
                            GUI:setEditboxPosition(authorization.editboxes.register.email, authorization.positions.logo.x - 24/zoom, authorization.positions.logo.y + 480/zoom)
                            GUI:setEditboxMaxLength(authorization.editboxes.register.email, 32)
                            GUI:setEditboxAlpha(authorization.editboxes.register.email, 0)
                            GUI:setEditboxImage(authorization.editboxes.register.email, authorization.textures.email)
                            -- register button
                            GUI:setButtonTextures(authorization.buttons.register, {
                                default = authorization.textures.buttons.default,
                                hover = authorization.textures.buttons.active,
                                press = authorization.textures.buttons.default
                            })
                            GUI:setButtonFont(authorization.buttons.register, authorization.fonts.normal_small, 1/zoom)
                            GUI:setButtonPosition(authorization.buttons.register, authorization.positions.logo.x + 72/zoom, authorization.positions.logo.y + 565/zoom)
                            GUI:setButtonTexturesColor(authorization.buttons.register, tocolor(255, 255, 255, 0))
                            addEventHandler("onClientClickButton", authorization.buttons.register, function()
                                if not authorization.loaded then return end
                                local data = {
                                    login = GUI:getEditboxText(authorization.editboxes.register.login),
                                    password = GUI:getEditboxText(authorization.editboxes.register.password),
                                    email = GUI:getEditboxText(authorization.editboxes.register.email)
                                }
                                if string.len(data.login) < 3 or string.len(data.password) > 22 then
                                    return exports.mm_hud:showNotification("Nazwa użytkownika musi mieć więcej niż 3 znaki i mniej niż 22 znaków.", "error")
                                elseif string.len(data.password) < 5 or string.len(data.password) > 16 then
                                    return exports.mm_hud:showNotification("Hasło musi mieć więcej niż 5 znaków i mniej niż 16 znaków.", "error")
                                elseif not isNotInvalidEmail(data.email) then
                                    return exports.mm_hud:showNotification("Podano nieprawidłowy adres e-mail.", "error")
                                else
                                    triggerServerEvent("onAuthorizationRequest", localPlayer, "register", {
                                        login = data.login,
                                        password = data.password,
                                        email = data.email
                                    })
                                end
                            end)
                            return true
                        elseif (type == "unload") then
                            GUI:destroyEditbox(authorization.editboxes.register.login)
                            GUI:destroyEditbox(authorization.editboxes.register.password)
                            GUI:destroyEditbox(authorization.editboxes.register.email)
                            GUI:destroyButton(authorization.buttons.register)
                            authorization.editboxes.register.login = nil
                            authorization.editboxes.register.password = nil
                            authorization.editboxes.register.email = nil
                            authorization.buttons.register = nil
                            return true
                        else
                            return false
                        end
                    end,
                    render = function()
                        local drawImage   = dxDrawImage
                        local drawText    = dxDrawText

                        drawText("REJESTRACJA", 0, 418/zoom, screen.x, 418/zoom, tocolor(255, 255, 255, authorization.animations.tab_a), 1.23/zoom, authorization.fonts.light_big, "center", "top")

                        GUI:renderEditbox(authorization.editboxes.register.login)
                        GUI:renderEditbox(authorization.editboxes.register.password)
                        GUI:renderEditbox(authorization.editboxes.register.email)

                        GUI:setEditboxAlpha(authorization.editboxes.register.login, authorization.animations.tab_a)
                        GUI:setEditboxAlpha(authorization.editboxes.register.password, authorization.animations.tab_a)
                        GUI:setEditboxAlpha(authorization.editboxes.register.email, authorization.animations.tab_a)

                        GUI:renderButton(authorization.buttons.register)

                        GUI:setButtonTexturesColor(authorization.buttons.register, tocolor(255, 255, 255, authorization.animations.tab_a))
                    end
                },
                [3] = { -- changes tab
                    active = false,
                    elements = function() end,
                    render = function()
                        local drawImage = dxDrawImage
                        local drawText  = dxDrawText

                        drawText("LISTA ZMIAN", 0, 418/zoom, screen.x, 418/zoom, tocolor(255, 255, 255, authorization.animations.tab_a), 1.23/zoom, authorization.fonts.light_big, "center", "top")
                    end
                }
            }
            authorization.tab_active = 1
            authorization.tabs[authorization.tab_active].elements("load")
            authorization.tab_max = #authorization.tabs
        end        
        authorization.loaded = true
    end
end
addEventHandler("onClientResourceStart", resourceRoot, authorization.onLoad)

authorization.onUnload = function()
    if authorization.loaded then
        for key, texture in ipairs(authorization.textures) do
            if isElement(texture) then
                destroyElement(texture)
            end
        end
        for key, button in ipairs(authorization.buttons) do
            if isElement(button) then
                GUI:destroyButton(button)
            end
        end
        GUI:destroyEditbox(authorization.editboxes.auth.login)
        GUI:destroyEditbox(authorization.editboxes.auth.password)
        GUI:destroyEditbox(authorization.editboxes.register.login)
        GUI:destroyEditbox(authorization.editboxes.register.password)
        GUI:destroyEditbox(authorization.editboxes.register.email)
    end
end
addEventHandler("onClientResourceStop", resourceRoot, authorization.onUnload)

authorization.response = function(data)
        if (data.type == "login" and data.success == true) then
            exports.mm_hud:showNotification("Autoryzacja..", "info", true, 5000);
            setTimer(function()
                exports.mm_core:switchScreen(true, 500);
                authorization.animations.main_a_anim = createAnimation(255, 0, "Linear", 500, function(v)
                    authorization.animations.main_a = v
                end)
                authorization.animations.background_a_anim = createAnimation(200, 0, "Linear", 500, function(v)
                    authorization.animations.background_a = v
                end)
                authorization.animations.tab_a_anim = createAnimation(255, 0, "InOutQuad", 500,
                    function(v)
                        authorization.animations.tab_a = v
                    end,
                    function()
                        removeEventHandler("onClientRender", root, authorization.renderBackground)
                        removeEventHandler("onClientRender", root, authorization.renderTabs)
                        removeEventHandler("onClientRender", root, authorization.renderSelection)
                        removeEventHandler("onClientRender", root, cameraRender)
                        killTimer(cameraTimer)
                        authorization.tabs[authorization.tab_active].elements("unload")
                        authorization.tab_active = 0
                        switchMusicLights(false);
                        
                        setTimer(function()
                            prelogin_spawns.switchRender(true);
                            switchMusicLights(true);
                            exports.mm_core:switchScreen(false, 500);
                        end, 2000, 1);
                    end
                )
            end, 2000, 1);
        end
        if (data.type == "register" and data.success == true) then
            exports.mm_hud:showNotification("Twoje konto zostało pomyślnie zarejestrowane! Życzymy miłej gry na serwerze!", "success");
            exports.mm_core:switchScreen(true, 1000);
            authorization.animations.main_a_anim = createAnimation(255, 0, "Linear", 500, function(v)
                authorization.animations.main_a = v
            end)
            authorization.animations.background_a_anim = createAnimation(200, 0, "Linear", 500, function(v)
                authorization.animations.background_a = v
            end)
            authorization.animations.tab_a_anim = createAnimation(255, 0, "InOutQuad", 500,
                function(v)
                    authorization.animations.tab_a = v
                end,
                function()
                    removeEventHandler("onClientRender", root, authorization.renderBackground)
                    removeEventHandler("onClientRender", root, authorization.renderTabs)
                    removeEventHandler("onClientRender", root, authorization.renderSelection)
                    removeEventHandler("onClientRender", root, cameraRender)
                    killTimer(cameraTimer)
                    authorization.tabs[authorization.tab_active].elements("unload")
                    authorization.tab_active = 0
                    switchMusicLights(false);
                    
                    setTimer(function()
                        switchMusicLights(true);
                        prelogin_spawns.switchRender(true);
                        exports.mm_core:switchScreen(false, 500);
                    end, 2000, 1);
                end
            )
        end
        if (data.type == "spawn" and data.success == true) then
            prelogin_spawns.switchRender(false);
            switchMusicLights(false);
            setTimer(function()
                switchLoginMusic(false);
            end, 500, 1);
        end
end
addEvent("auth_response", true)
addEventHandler("auth_response", root, authorization.response)

authorization.returnRememberedData = function()
    if not authorization.rememberFile then return end
    c_login = xmlFindChild(authorization.rememberFile, "login", 0)
    c_password = xmlFindChild(authorization.rememberFile, "password", 0)
    c_checkbox = xmlFindChild(authorization.rememberFile, "remembered", 0)
    return xmlNodeGetValue(c_login), xmlNodeGetValue(c_password), xmlNodeGetValue(c_checkbox)
end

authorization.loadRememberedData = function()
    if not authorization.rememberFile then
        authorization.rememberFile = xmlCreateFile("data.xml", "data")
        c_login = xmlCreateChild(authorization.rememberFile, "login")
        c_password = xmlCreateChild(authorization.rememberFile, "password")
        c_checkbox = xmlCreateChild(authorization.rememberFile, "remembered")
        xmlSaveFile(authorization.rememberFile)
    end
end

authorization.saveRememberedData = function(login, password)
    if not authorization.loaded then return end
    c_login = xmlFindChild(authorization.rememberFile, "login", 0)
    c_password = xmlFindChild(authorization.rememberFile, "password", 0)
    c_checkbox = xmlFindChild(authorization.rememberFile, "remembered", 0)
    if authorization.remembered then
        xmlNodeSetValue(c_login, login)
        xmlNodeSetValue(c_password, password)
        xmlNodeSetValue(c_checkbox, "1")
        xmlSaveFile(authorization.rememberFile)
    else
        xmlNodeSetValue(c_login, "")
        xmlNodeSetValue(c_password, "")
        xmlNodeSetValue(c_checkbox, "0")
        xmlSaveFile(authorization.rememberFile)
    end
end

authorization.renderLogo = function(alpha)
    if not authorization.loaded then return end
    if not alpha or not type(alpha) == "number" then return end
    dxDrawImage(authorization.positions.logo.x + 35/zoom, authorization.positions.logo.y - 25/zoom, authorization.positions.logo.w - 60/zoom, authorization.positions.logo.h - 60/zoom, authorization.textures.logo, 0, 0, 0, tocolor(255, 255, 255, alpha))
end

authorization.renderBackground = function()
    if not authorization.loaded then return end
    GUI:drawBWRectangle(0, 0, screen.x, screen.y, tocolor(255, 255, 255, authorization.animations.background_a))
end

authorization.renderTabs = function()
    if not authorization.loaded then return end
    authorization.renderLogo(authorization.animations.tab_a)
    if authorization.tab_active ~= 0 then
        for key, tab in ipairs(authorization.tabs) do
            if authorization.tabs[key].active then
                authorization.tabs[key].render()
            end
        end
    end
end

authorization.renderSelection = function()
    if not authorization.loaded then return end
    local offsetX = authorization.positions.points.x - 70/zoom
    for key, point in ipairs(authorization.tabs) do
        if authorization.tabs[key].active then
            dxDrawImage(offsetX, authorization.positions.points.y + 410/zoom, authorization.positions.points.w, authorization.positions.points.h, authorization.textures.points.active, 0, 0, 0, tocolor(255, 255, 255, authorization.animations.main_a))
        else
            dxDrawImage(offsetX, authorization.positions.points.y + 410/zoom, authorization.positions.points.w, authorization.positions.points.h, authorization.textures.points.default, 0, 0, 0, tocolor(255, 255, 255, authorization.animations.main_a))
        end
        offsetX = offsetX + 68/zoom
    end
    GUI:renderButton(authorization.buttons.previous_selection)
    GUI:setButtonTexturesColor(authorization.buttons.previous_selection, tocolor(255, 255, 255, authorization.animations.main_a))
    GUI:renderButton(authorization.buttons.next_selection)
    GUI:setButtonTexturesColor(authorization.buttons.next_selection, tocolor(255, 255, 255, authorization.animations.main_a))
end

-- exports
function isAuthorizationPanelLoaded()
    return authorization.loaded or false
end