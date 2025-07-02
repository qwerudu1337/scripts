local Players = game:GetService('Players')
local HttpService = game:GetService('HttpService')
local player = Players.LocalPlayer

-- НАСТРОЙКИ
local TARGET_ADD = 1000000 -- Сколько нужно нафармить дополнительно
local CONFIG_FILE = 'money_farm_config.json'

-- Ожидаем загрузки данных игрока
repeat
    wait(1)
until player:FindFirstChild('leaderstats')
local money = player.leaderstats:WaitForChild('Money')

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
    if not writefile then
        return
    end

    pcall(function()
        writefile(CONFIG_FILE, HttpService:JSONEncode(config))
    end)
end

-- Основная логика
local userId = tostring(player.UserId)
local config = loadConfig()
local currentMoney = money.Value

-- Если аккаунт новый - сохраняем начальный баланс
if not config[userId] then
    config[userId] = {
        initial = currentMoney,
        target = currentMoney + TARGET_ADD,
    }
    saveConfig(config)
    print(
        ' Новый аккаунт сохранён | Начальные: '
            .. currentMoney
    )
end

-- Получаем целевое значение для этого аккаунта
local targetMoney = config[userId].target

-- Проверяем текущий баланс
print(
    '\n👤 Аккаунт: '
        .. player.Name
        .. '\n Текущий баланс: '
        .. currentMoney
        .. '\n Целевой баланс: '
        .. targetMoney
        .. '\n Осталось нафармить: '
        .. (targetMoney - currentMoney)
)

if currentMoney >= targetMoney then
    print('⛔ Цель достигнута! Скрипт не запущен')
    return
end

-- Запускаем основной скрипт
print('\n Запускаю фарминг-скрипт...')
loadstring(
    game:HttpGet(
        'https://api.luarmor.net/files/v3/loaders/ef2b75a1c0445997d44b7371f11ee88a.lua'
    )
)()
