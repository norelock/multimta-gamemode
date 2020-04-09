local resources = {
    -- uzywane (ale rzadko)
    "runcode",
    "ipb",
    -- community
    "bengines",
    -- mysql, ustawienia i baza (core)
    "mm_compiler",
    "mm_db",
    "mm_settings",
    "mm_core",
    -- shadery
    "mm_2dfog",
    -- markery (tylko ten zasób)
    "mm_markers",
    -- coś z gui
    "mm_gui",
    "mm_radar",
    "mm_hud",
    "mm_admin",
    "mm_bw",
    "mm_nametags",
    "mm_login",
    -- frakcje (grupy)
    "mm_groups_sapd",
    -- mapy
    "mm_map_ls_spawn",
};

addEventHandler("onResourceStart", resourceRoot, function()
    for key, r in ipairs(resources) do
        local resource = getResourceFromName(r);
        if resource then
            if getResourceState(resource) == "running" then
                restartResource(resource);
            elseif getResourceState(resource) == "loaded" then
                startResource(resource);
            end;
        end;
    end;
end);