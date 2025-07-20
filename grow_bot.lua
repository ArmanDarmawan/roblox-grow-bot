--[[
    @author Arman Darmawan
    @description Grow a Garden stock bot (Full Version)
    Game: https://www.roblox.com/games/126884695634066
]]

-- Konfigurasi
_G.Configuration = {
    Enabled = true,
    Webhook = "https://discord.com/api/webhooks/1396305601054642298/8h_T7xbfHemULMhKR7lTfurD4RpuCJt6WWmfZ4yvQAJTvUFbfpKLFWqRf9COmxD9avFY", -- Ganti dengan webhook kamu
    WeatherReporting = true,
    AntiAFK = true,
    AutoReconnect = true,
    Rendering = false,

    Alerts = {
        Weather = {
            Color = Color3.fromRGB(30, 144, 255),
        },
        Stocks = {
            Color = Color3.fromRGB(50, 205, 50),
            Paths = {
                ["ROOT/SeedStock/Stocks"] = "Seeds",
                ["ROOT/GearStock/Stocks"] = "Gears",
                ["ROOT/EventShopStock/Stocks"] = "Events",
                ["ROOT/PetEggStock/Stocks"] = "Eggs",
                ["ROOT/CosmeticStock/ItemStocks"] = "Cosmetics",
            }
        }
    }
}

-- Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))

local Player = Players.LocalPlayer
RunService:Set3dRenderingEnabled(_G.Configuration.Rendering)

if _G.BotActive then return end
_G.BotActive = true

-- Convert Color3 to Decimal
local function ColorToDecimal(color)
    return tonumber(color:ToHex(), 16)
end

-- Kirim Webhook
local function SendWebhook(alertType, fields)
    if not _G.Configuration.Enabled then return end
    local alert = _G.Configuration.Alerts[alertType]
    if not alert then return end

    local body = {
        embeds = { {
            color = ColorToDecimal(alert.Color),
            fields = fields,
            footer = { text = "Made by Arman Darmawan" },
            timestamp = DateTime.now():ToIsoDate()
        } }
    }

    local data = {
        Url = _G.Configuration.Webhook,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(body)
    }

    task.spawn(request, data)
end

-- Ambil data dari stream
local function FindDataPacket(data, key)
    for _, item in data do
        if item[1] == key then return item[2] end
    end
end

-- Format hasil stock
local function FormatStock(stock)
    local result = ""
    for name, item in stock do
        local display = item.EggName or name
        result ..= string.format("**%s** x%s\n", display, item.Stock)
    end
    return result
end

-- Proses semua data stock
local function HandleStockUpdate(data)
    local fields = {}
    local paths = _G.Configuration.Alerts.Stocks.Paths

    for path, title in paths do
        local stock = FindDataPacket(data, path)
        if stock then
            table.insert(fields, {
                name = title,
                value = FormatStock(stock),
                inline = true
            })
        end
    end

    SendWebhook("Stocks", fields)
end

-- Deteksi cuaca dimulai
ReplicatedStorage.GameEvents.WeatherEventStarted.OnClientEvent:Connect(function(eventName, duration)
    if not _G.Configuration.WeatherReporting then return end
    local endsAt = math.round(workspace:GetServerTimeNow() + duration)
    SendWebhook("Weather", { {
        name = "Weather Alert",
        value = string.format("**%s** ends <t:%d:R>", eventName, endsAt),
        inline = true
    } })
end)

-- Ketika data user diperbarui
ReplicatedStorage.GameEvents.DataStream.OnClientEvent:Connect(function(eventType, profileName, data)
    if eventType == "UpdateData" and profileName:find(Player.Name) then
        HandleStockUpdate(data)
    end
end)

-- Anti-AFK
Player.Idled:Connect(function()
    if not _G.Configuration.AntiAFK then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.zero)
end)

-- Auto Reconnect
GuiService.ErrorMessageChanged:Connect(function()
    if not _G.Configuration.AutoReconnect then return end

    queue_on_teleport("https://raw.githubusercontent.com/ArmanDarmawan/roblox-grow-bot/main/grow_bot.lua")

    local placeId, jobId = game.PlaceId, game.JobId
    if #Players:GetPlayers() <= 1 then
        TeleportService:Teleport(placeId, Player)
    else
        TeleportService:TeleportToPlaceInstance(placeId, jobId, Player)
    end
end)
