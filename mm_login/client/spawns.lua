local spawns = {};

addEventHandler("onClientResourceStart", resourceRoot, function()
    spawns = {
        {
            name = "Los Santos",
            position = Vector3(1473.72, -1713.32, 14.04),
            disabled = false
        },
        {
            name = "Las Venturas",
            position = Vector3(2435.96, 2377.08, 10.82),
            disabled = true
        },
        {
            name = "San Fierro",
            position = Vector3(-2047.27, 463.24, 35.17),
            disabled = true
        },
        {
            name = "Fort Carson",
            position = Vector3(-203.13, 1126.05, 19.74),
            disabled = true
        }
    };
end);

function getSpawnsTable()
    return spawns;
end;