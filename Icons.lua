-- RocketUI Icons.lua
-- Unificador dos ícones do Footagesus/Icons.
-- Fontes: Lucide, Solar, Geist, Craft, Gravity e SF Symbols.

local Sources = {
    "https://raw.githubusercontent.com/Footagesus/Icons/main/lucide/dist/Icons.lua",
    "https://raw.githubusercontent.com/Footagesus/Icons/main/solar/dist/Icons.lua",
    "https://raw.githubusercontent.com/Footagesus/Icons/main/geist/dist/Icons.lua",
    "https://raw.githubusercontent.com/Footagesus/Icons/main/craft/dist/Icons.lua",
    "https://raw.githubusercontent.com/Footagesus/Icons/main/gravity/dist/Icons.lua",
    "https://raw.githubusercontent.com/Footagesus/Icons/main/sfsymbols/dist/Icons.lua",
}

local Icons = {}
local LIMIT = 2000
local Count = 0

local function loadPack(url)
    if Count >= LIMIT then
        return true
    end

    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)

    if not ok or type(source) ~= "string" then
        return false
    end

    for name, id in source:gmatch(
        '%[%s*["\']([^"\']+)["\']%s*%]%s*=%s*["\'](rbxassetid://%d+)["\']'
    ) do
        if not Icons[name] then
            Icons[name] = id
            Count += 1

            if Count >= LIMIT then
                return true
            end
        end
    end

    return false
end

for _, url in ipairs(Sources) do
    if loadPack(url) then
        break
    end
end

return Icons
