local MAX_RESTARTS = 3 -- Максимальное количество перезапусков
local RESTART_DELAY = 20 -- Задержка между перезапусками в секундах

-- Глобальные переменные состояния
getgenv().RestartData = {
    Attempts = 0,
    LastRestart = 0,
    IsRestarting = false
}

-- Основная функция перезапуска
local function ScheduleRestart()
    if getgenv().RestartData.IsRestarting then return end
    getgenv().RestartData.IsRestarting = true
    
    -- Проверка максимального количества попыток
    if getgenv().RestartData.Attempts >= MAX_RESTARTS then
        Nexus:Log("Достигнут лимит перезапусков!")
        return
    end

    -- Увеличиваем счетчик и обновляем время
    getgenv().RestartData.Attempts += 1
    getgenv().RestartData.LastRestart = os.time()
    
    -- Отправка команды в Account Manager
    Nexus:Send("RestartRequest", {
        PlaceId = game.PlaceId,
        JobId = game.JobId,
        Attempt = getgenv().RestartData.Attempts
    })

    -- Создание UI элементов
    Nexus:CreateLabel("RestartInfo", 
        string.format("Перезапуск через %d сек...", RESTART_DELAY), 
        {200, 40}, {5,5,5,5}
    )
    
    Nexus:CreateButton("ForceRestart", "Перезапустить сейчас", {150, 30}, {5,5,5,5})
    
    -- Обработчик кнопки
    Nexus:OnButtonClick("ForceRestart", function()
        game:Shutdown()
    end)

    -- Автоматический перезапуск
    task.delay(RESTART_DELAY, function()
        if getgenv().RestartData.IsRestarting then
            game:Shutdown()
        end
    end)
end

-- Хук на закрытие интерфейса
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "RobloxGui" and not getgenv().RestartData.IsRestarting then
        ScheduleRestart()
    end
end)

-- Модифицированная проверка загрузки
if not game:IsLoaded() then
    local loaded = false
    
    task.delay(60, function()
        if loaded or getgenv().NoShutdown then return end
        
        if not game:IsLoaded() then
            ScheduleRestart()
        end
        
        local errorCode = game:GetService("GuiService"):GetErrorCode().Value
        if errorCode >= Enum.ConnectionError.DisconnectErrors.Value then
            ScheduleRestart()
        end
    end)
    
    game.Loaded:Wait()
    loaded = true
end

-- Интеграция с Nexus WebSocket
do
    local function HandleRestartCommand(payload)
        local data = HttpService:JSONDecode(payload)
        
        if data.Command == "ForceRestart" then
            game:Shutdown()
        elseif data.Command == "ScheduleRestart" then
            ScheduleRestart()
        end
    end

    Nexus:AddCommand("restart", HandleRestartCommand)
    Nexus:AddCommand("force_restart", HandleRestartCommand)
end

-- Дополнительные хуки
game:GetService("Players").PlayerRemoving:Connect(function(player)
    if player == LocalPlayer then
        ScheduleRestart()
    end
end)

LocalPlayer.OnTeleport:Connect(function(state)
    if state == Enum.TeleportState.Failed then
        ScheduleRestart()
    end
end)

-- Инициализация Nexus
if not Nexus_Version then
    Nexus:Connect("localhost:5242", true)
    
    Nexus:SetAutoRelaunch(true)
    Nexus:SetPlaceId(game.PlaceId)
    Nexus:SetJobId(game.JobId)
    
    Nexus:Log("Система автоперезапуска активирована!")
end
