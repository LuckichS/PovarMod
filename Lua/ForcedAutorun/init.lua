HH = HH or {}

HH.HuntersHusks = {
    Name = "Hunter's Husks",
    Version = "1.0.0",
    Path = table.pack(...)[1]
}

dofile(HH.HuntersHusks.Path .. "/Lua/Scripts/shared.lua")

if SERVER or not Game.IsMultiplayer then
    dofile(HH.HuntersHusks.Path .. "/Lua/Scripts/init.lua")
end

if CLIENT then
    dofile(HH.HuntersHusks.Path .. "/Lua/Scripts/cl_init.lua")
end
