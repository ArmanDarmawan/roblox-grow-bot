--[[
    @author Arman Darmawan
    @description Grow a Garden stock bot script (UX-Imut Version)
    Repository: https://github.com/ArmanDarmawan/roblox-grow-bot
]]

type table = { [any]: any }

_G.Configuration = {
    Enabled = true,
    Webhook = "https://discord.com/api/webhooks/1396316652211142760/IGAzWGQmc1wL-3o2W7gLyomP0ZIgA7aj_-7LJPFakFl9awSg9UAFvaX3YEWZcD-LDH1n", -- ganti webhook kamu
    WeatherReporting = true,
    AntiAFK = true,
    AutoReconnect = true,
    Rendering = false,
    
    AlertLayouts = {
        Weather = { EmbedColor = Color3.fromRGB(173, 216, 230) },         -- pastel biru
        SeedsAndGears = { EmbedColor = Color3.fromRGB(152, 251, 152), Layout = {
            ["ROOT/SeedStock/Stocks"] = "Seeds 🌱",
            ["ROOT/GearStock/Stocks"] = "Gears ⚙️"
        }},
        EventShop = { EmbedColor = Color3.fromRGB(221, 160, 221), Layout = {
            ["ROOT/EventShopStock/Stocks"] = "Events 🛍️"
        }},
        Eggs = { EmbedColor = Color3.fromRGB(255, 182, 193), Layout = {
            ["ROOT/PetEggStock/Stocks"] = "Eggs 🥚"
        }},
        CosmeticStock = { EmbedColor = Color3.fromRGB(255, 228, 181), Layout = {
            ["ROOT/CosmeticStock/ItemStocks"] = "Cosmetics 💄"
        }}
    }
}

local RS = game:GetService("ReplicatedStorage")
local P = game:GetService("Players")
local HS = game:GetService("HttpService")
local VU = cloneref(game:GetService("VirtualUser"))
local RSvc = game:GetService("RunService")
local GS = game:GetService("GuiService")
local TS = game:GetService("TeleportService")

local DataStream = RS.GameEvents.DataStream
local WeatherEvent = RS.GameEvents.WeatherEventStarted
local Local = P.LocalPlayer

if _G.StockBot then return end
_G.StockBot = true

local function getCfg(k) return _G.Configuration[k] end
RSvc:Set3dRenderingEnabled(getCfg("Rendering"))

local function colorDec(c) return tonumber(c:ToHex(), 16) end
local function findPacket(data, key)
    for _, p in data do if p[1] == key then return p[2] end end
end

local function makeStockStr(stock)
    local s = ""
    for n, d in stock do
        local name = d.EggName or n
        s ..= string.format("• **%s** x%s\n", name, d.Stock)
    end
    return s
end

local emojis = {
    Weather = "⛅", SeedsAndGears = "🌱⚙️", EventShop = "🛍️",
    Eggs = "🥚", CosmeticStock = "💄"
}

local function webhookSend(type, fields)
    if not getCfg("Enabled") then return end
    local L = _G.Configuration.AlertLayouts[type]
    local color = colorDec(L.EmbedColor)
    local title = string.format("%s %s Update!",
        emojis[type] or "📬",
        type:gsub("(%u)", " %1"):upper()
    )
    local body = {
        username = "🌿 GardenBot",
        avatar_url = "https://i.imgur.com/GVEFhQf.png",
        embeds = {{
            title = title,
            description = "📦 Grow a Garden Stock Report",
            color = color,
            fields = fields,
            footer = { text = "Made by Arman Darmawan" },
            timestamp = DateTime.now():ToIsoDate()
        }}
    }
    task.spawn(request, {
        Url = getCfg("Webhook"), Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HS:JSONEncode(body)
    })
end

local function process(type, layout, data)
    local fields = {}
    if not layout.Layout then return end
    for p, name in layout.Layout do
        local stock = findPacket(data, p)
        if stock then
            table.insert(fields, {
                name = "📁 " .. name,
                value = makeStockStr(stock),
                inline = false
            })
        end
    end
    if #fields > 0 then webhookSend(type, fields) end
end

DataStream.OnClientEvent:Connect(function(t, prof, data)
    if t ~= "UpdateData" or not prof:find(Local.Name) then return end
    for type, layout in pairs(getCfg("AlertLayouts")) do
        process(type, layout, data)
    end
end)

WeatherEvent.OnClientEvent:Connect(function(ev, len)
    if not getCfg("WeatherReporting") then return end
    local endTs = math.round(workspace:GetServerTimeNow() + len)
    webhookSend("Weather", {{
        name = "📡 Weather Event",
        value = string.format("**%s**\n🕒 Ends: <t:%d:R>", ev, endTs),
        inline = false
    }})
end)

Local.Idled:Connect(function()
    if getCfg("Anti-AFK") then
        VU:CaptureController()
        VU:ClickButton2(Vector2.new())
    end
end)

GS.ErrorMessageChanged:Connect(function()
    if not getCfg("Auto-Reconnect") then return end
    local isSolo = #P:GetPlayers() <= 1
    queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/ArmanDarmawan/roblox-grow-bot/main/grow_bot.lua'))()")
    if isSolo then TS:Teleport(game.PlaceId, Local)
    else TS:TeleportToPlaceInstance(game.PlaceId, game.JobId, Local) end
end)
