--[[
    @author Arman Darmawan
    @description Grow a Garden stock bot script (UI/UX Enhanced)
    Repository: https://github.com/ArmanDarmawan/roblox-grow-bot
]]

type table = {
    [any]: any
}

_G.Configuration = {
    ["Enabled"] = true,
    ["Webhook"] = "https://discord.com/api/webhooks/1396316652211142760/IGAzWGQmc1wL-3o2W7gLyomP0ZIgA7aj_-7LJPFakFl9awSg9UAFvaX3YEWZcD-LDH1n",
    ["Weather Reporting"] = true,
    ["Anti-AFK"] = true,
    ["Auto-Reconnect"] = true,
    ["Rendering Enabled"] = false,

    ["AlertLayouts"] = {
        ["Weather"] = {
            EmbedColor = Color3.fromRGB(42, 109, 255),
        },
        ["SeedsAndGears"] = {
            EmbedColor = Color3.fromRGB(56, 238, 23),
            Layout = {
                ["ROOT/SeedStock/Stocks"] = "Seeds Stock",
                ["ROOT/GearStock/Stocks"] = "Gear Stock"
            }
        },
        ["EventShop"] = {
            EmbedColor = Color3.fromRGB(212, 42, 255),
            Layout = {
                ["ROOT/EventShopStock/Stocks"] = "Event Shop Stock"
            }
        },
        ["Eggs"] = {
            EmbedColor = Color3.fromRGB(251, 255, 14),
            Layout = {
                ["ROOT/PetEggStock/Stocks"] = "Egg Stock"
            }
        },
        ["CosmeticStock"] = {
            EmbedColor = Color3.fromRGB(255, 106, 42),
            Layout = {
                ["ROOT/CosmeticStock/ItemStocks"] = "Cosmetic Items Stock"
            }
        }
    }
}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local VirtualUser = cloneref(game:GetService("VirtualUser"))
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local TeleportService = game:GetService("TeleportService")

local DataStream = ReplicatedStorage.GameEvents.DataStream
local WeatherEventStarted = ReplicatedStorage.GameEvents.WeatherEventStarted

local LocalPlayer = Players.LocalPlayer

if _G.StockBot then return end
_G.StockBot = true

local function GetConfigValue(Key: string)
    return _G.Configuration[Key]
end

RunService:Set3dRenderingEnabled(GetConfigValue("Rendering Enabled"))

local function ConvertColor3(Color: Color3): number
    return tonumber(Color:ToHex(), 16)
end

local function GetDataPacket(Data, Target: string)
    for _, Packet in Data do
        if Packet[1] == Target then
            return Packet[2]
        end
    end
end

local function MakeStockString(Stock: table): string
    local String = ""
    for Name, Data in Stock do
        local Amount = Data.Stock
        local EggName = Data.EggName
        Name = EggName or Name
        String ..= string.format("• **%s** x%s\n", Name, Amount)
    end
    return String
end

local function WebhookSend(Type: string, Fields: table)
    if not GetConfigValue("Enabled") then return end
    local Layout = _G.Configuration.AlertLayouts[Type]
    local Color = ConvertColor3(Layout.EmbedColor)

    local emojis = {
        ["Weather"] = "⛅",
        ["SeedsAndGears"] = "🌱⚙️",
        ["EventShop"] = "🛍️",
        ["Eggs"] = "🥚",
        ["CosmeticStock"] = "💄"
    }

    local emoji = emojis[Type] or ""
    local embedTitle = string.format("%s %s Update", emoji, Type:gsub("([A-Z])", " %1"):upper())

    local Body = {
        username = "Grow Stock Bot 🌿",
        avatar_url = "https://i.imgur.com/GVEFhQf.png", -- kamu bisa ganti icon-nya
        embeds = {
            {
                title = embedTitle,
                color = Color,
                description = "📦 **Grow a Garden Stock Report**",
                fields = Fields,
                footer = {
                    text = "Made by Arman Darmawan | github.com/ArmanDarmawan"
                },
                timestamp = DateTime.now():ToIsoDate()
            }
        }
    }

    task.spawn(request, {
        Url = GetConfigValue("Webhook"),
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = HttpService:JSONEncode(Body)
    })
end

local function ProcessPacket(Data, Type: string, Layout)
    local Fields = {}
    if not Layout.Layout then return end

    for Packet, Title in Layout.Layout do
        local Stock = GetDataPacket(Data, Packet)
        if not Stock then continue end

        local StockString = MakeStockString(Stock)
        table.insert(Fields, {
            name = "📁 " .. Title,
            value = StockString,
            inline = false
        })
    end

    if #Fields > 0 then
        WebhookSend(Type, Fields)
    end
end

DataStream.OnClientEvent:Connect(function(Type: string, Profile: string, Data: table)
    if Type ~= "UpdateData" then return end
    if not Profile:find(LocalPlayer.Name) then return end

    for Name, Layout in pairs(GetConfigValue("AlertLayouts")) do
        ProcessPacket(Data, Name, Layout)
    end
end)

WeatherEventStarted.OnClientEvent:Connect(function(Event: string, Length: number)
    if not GetConfigValue("Weather Reporting") then return end
    local EndUnix = math.round(workspace:GetServerTimeNow()) + Length
    WebhookSend("Weather", {
        {
            name = "📡 Weather Event",
            value = string.format("**%s**\n🕒 Ends: <t:%s:R>", Event, EndUnix),
            inline = false
        }
    })
end)

LocalPlayer.Idled:Connect(function()
    if not GetConfigValue("Anti-AFK") then return end
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())
end)

GuiService.ErrorMessageChanged:Connect(function()
    if not GetConfigValue("Auto-Reconnect") then return end
    local PlaceId = game.PlaceId
    local JobId = game.JobId
    local IsSingle = #Players:GetPlayers() <= 1

    queue_on_teleport("loadstring(game:HttpGet('https://raw.githubusercontent.com/ArmanDarmawan/roblox-grow-bot/main/grow_bot.lua'))()")

    if IsSingle then
        TeleportService:Teleport(PlaceId, LocalPlayer)
    else
        TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
    end
end)
