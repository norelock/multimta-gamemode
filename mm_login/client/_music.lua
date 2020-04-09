local screen = Vector2(guiGetScreenSize());
local sound = {
    playing = nil,
    info = nil,
    id = 0,
    volume = 0,
    path = nil
};
local soundId = 0;

local function onVolumeFadeIn()
    sound.volume = sound.volume + 0.100;
    setSoundVolume(sound.playing, sound.volume);
    if sound.volume >= 1 then
        removeEventHandler("onClientRender", root, onVolumeFadeIn);
    end
end

local function onVolumeFadeOut()
    sound.volume = sound.volume - 0.0050;
    setSoundVolume(sound.playing, sound.volume);
    if sound.volume <= 0 then
        removeEventHandler("onClientRender", root, onVolumeFadeOut);
        destroyElement(sound.playing);
        sound.playing = nil;
        sound.info = nil;
    end
end

local function showActiveMusicInfo()
    if sound.info == nil then return end;
    if not sound.playing then return end;
    local library = getMusicLibrary();
    dxDrawText(string.format("%s - %s", sound.info.author, sound.info.title), screen.x * 0.0522, 0, screen.x, screen.y - 24, tocolor(192, 192, 192, 200), 0.75/exports.mm_gui:getInterfaceZoom(), exports.mm_gui:getGUIFont("light"), "left", "bottom", false, false, false);
    local fft = getSoundFFTData(sound.playing, 4096, 4);
    if type(fft) == "boolean" then return end;
    if fft then
        for i = 1, 3 do
            if fft[i] == "NaN" then return end;
            dxDrawRectangle(screen.x * 0.0082 + i * 13, screen.y - 23.8, 10, -fft[i] * 80, tocolor(192, 192, 192, 200), false);
        end;
    end;
end;

function switchLoginMusic(bool)
    if bool then
        local library = getMusicLibrary();
        local library_number = math.random(1, #library);
        sound.path = library[library_number].url;
        if not sound.playing or sound.playing == nil then
            sound.playing = playSound(sound.path, true);
            sound.volume = getSoundVolume(sound.playing) or 1;
            sound.info = library[library_number];
            setSoundVolume(sound.playing, sound.volume);
            addEventHandler("onClientRender", root, showActiveMusicInfo);
        end;
        addEventHandler("onClientRender", root, onVolumeFadeIn);
        removeEventHandler("onClientRender", root, onVolumeFadeOut);
    else
        addEventHandler("onClientRender", root, onVolumeFadeOut);
        removeEventHandler("onClientRender", root, onVolumeFadeIn);
        removeEventHandler("onClientRender", root, showActiveMusicInfo);
    end
end

function getPlayingLoginMusic()
    return sound.playing;
end