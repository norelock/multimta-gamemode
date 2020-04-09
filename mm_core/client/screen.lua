local screen = Vector2(guiGetScreenSize());

local bScreen = {};

bScreen.render = function()
    if not bScreen.state then return end;

    dxDrawRectangle(0, 0, screen.x, screen.y, tocolor(0, 0, 0, bScreen.alpha), true);
end;
addEventHandler("onClientRender", root, bScreen.render);

bScreen.switch = function(state, time)
    if type(state) == "boolean" then
        if type(time) == "number" then
            if state then
                bScreen.state = state;
                bScreen.alpha_anim = createAnimation(0, 255, "Linear", time,
                    function(x)
                        bScreen.alpha = x;
                    end,
                    function()
                        bScreen.alpha_anim = nil;
                    end
                );
            else
                bScreen.alpha_anim = createAnimation(255, 0, "Linear", time,
                    function(x)
                        bScreen.alpha = x;
                    end,
                    function()
                        bScreen.state = false;
                        bScreen.alpha_anim = nil;
                    end
                );
            end;
        end;
    end;
end;
addEvent("switchScreen", true);
addEventHandler("switchScreen", root, bScreen.switch);

function switchScreen(...) return bScreen.switch(...) end;