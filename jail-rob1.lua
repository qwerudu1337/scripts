local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local player = Players.LocalPlayer

-- НАСТРОЙКИ
local TARGET_ADD = 1000000  -- Сколько нужно нафармить дополнительно
local CONFIG_FILE = "money_farm_config_jail.json"

-- Ожидаем загрузки данных игрока
repeat wait(1) until player:FindFirstChild("leaderstats")
local money = player.leaderstats:WaitForChild("Money")

-- Функции для работы с конфигом
local function loadConfig()
    if not isfile or not isfile(CONFIG_FILE) then 
        return {} 
    end
    
    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    
    return success and data or {}
end

local function saveConfig(config)
    if not writefile then return end
    
    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

-- Основная логика
local playerName = player.Name 
local config = loadConfig()
local currentMoney = money.Value

-- Если аккаунт новый - сохраняем начальный баланс
if not config[playerName] then
    config[playerName] = {
        initial = currentMoney,
        target = currentMoney + TARGET_ADD
    }
    saveConfig(config)
end

-- Получаем целевое значение для этого аккаунта
local accountConfig = config[playerName]
local targetMoney = accountConfig.target

if currentMoney >= targetMoney then
    return
end

-- Запускаем основной скрипт
loadstring(game:HttpGet("https://raw.githubusercontent.com/BlitzIsKing/UniversalFarm/refs/heads/main/Jailbreak/autoRob"))()
