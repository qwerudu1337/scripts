local MAX_RESTARTS = 3
local RESTART_DELAY = 20

-- Безопасная инициализация сервисов
local function GetService(serviceName)
    local service
    while true do
        service = game:GetService(serviceName)
        if service then break end
        task.wait(1)
    end
    return service
end

local Players = GetService("Players")
local TeleportService = GetService("TeleportService")
local InputService = GetService("UserInputService")
local HttpService = GetService("HttpService")
local RunService = GetService("RunService")
local GuiService = GetService("GuiService")

-- Инициализация LocalPlayer с защитой
local LocalPlayer
while true do
    LocalPlayer = Players.LocalPlayer
    if LocalPlayer then break end
    task.wait(1)
end

-- Ожидание полной инициализации
while not LocalPlayer:IsDescendantOf(game) do
    task.wait(1)
end

if Nexus then Nexus:Stop() end

-- Модифицированный блок проверки загрузки
local function SafeLoadCheck()
    if not game:IsLoaded() then
        local loaded = false
        
        task.delay(60, function()
            if loaded or getgenv().NoShutdown then return end
            
            if not game:IsLoaded() then
                game:Shutdown()
            end
            
            local success, errorCode = pcall(function()
                return GuiService:GetErrorCode().Value
            end)
            
            if success and errorCode >= Enum.ConnectionError.DisconnectErrors.Value then
                game:Shutdown()
            end
        end)
        
        repeat task.wait() until game:IsLoaded()
        loaded = true
    end
end

SafeLoadCheck()

-- Безопасное подключение Nexus
local Nexus = {}
local WSConnect

local function InitializeWebSocket()
    local attempts = 0
    while attempts < 5 do
        WSConnect = syn and syn.websocket.connect or
            (Krnl and Krnl.WebSocket and Krnl.WebSocket.connect) or
            WebSocket and WebSocket.connect
        
        if WSConnect then break end
        attempts += 1
        task.wait(2)
    end
end

InitializeWebSocket()

if not WSConnect then
    if messagebox then
        messagebox("WebSocket не инициализирован", "Ошибка Nexus", 0)
    end
    return
end

-- Безопасное подключение к телепорту
local TeleportConnection
local function SafeTeleportConnect()
    while true do
        if LocalPlayer and LocalPlayer.OnTeleport then
            TeleportConnection = LocalPlayer.OnTeleport:Connect(function(State)
                if State == Enum.TeleportState.Started and Nexus.IsConnected then
                    Nexus:Stop()
                end
            end)
            break
        end
        task.wait(1)
    end
end

SafeTeleportConnect()

-- Модифицированный класс Signal с защитой
local Signal = {}
Signal.__index = Signal

function Signal.new()
    local self = setmetatable({
        _BindableEvent = Instance.new("BindableEvent"),
        _connections = {}
    }, Signal)
    return self
end

function Signal:Connect(callback)
    if not typeof(callback) == "function" then return end
    local connection = self._BindableEvent.Event:Connect(callback)
    table.insert(self._connections, connection)
    return connection
end

function Signal:Fire(...)
    self._BindableEvent:Fire(...)
end

function Signal:Destroy()
    for _, conn in pairs(self._connections) do
        conn:Disconnect()
    end
    self._BindableEvent:Destroy()
end

-- Инициализация Nexus с защищенными методами
do
    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()
    Nexus.Commands = {}
    Nexus.Connections = {}
    Nexus.ShutdownTime = 45
    Nexus.ShutdownOnTeleportError = true

    function Nexus:Send(command, payload)
        if not self.Socket or not self.IsConnected then return end
        local success, message = pcall(function()
            return HttpService:JSONEncode({
                Name = command,
                Payload = payload
            })
        end)
        
        if success then
            pcall(function()
                self.Socket:Send(message)
            end)
        end
    end

    -- Остальные методы Nexus с добавлением pcall...
    -- [Вставить остальные функции Nexus из оригинального кода, обернув опасные операции в pcall]
end

-- Безопасная инициализация перезапуска
local function InitializeRestartSystem()
    local RestartData = {
        Attempts = 0,
        LastRestart = 0,
        IsRestarting = false
    }

    local function ScheduleRestart()
        if RestartData.IsRestarting or RestartData.Attempts >= MAX_RESTARTS then return end
        
        RestartData.IsRestarting = true
        RestartData.Attempts += 1
        RestartData.LastRestart = os.time()

        Nexus:Send("RestartRequest", {
            PlaceId = game.PlaceId,
            JobId = game.JobId,
            Attempt = RestartData.Attempts
        })

        Nexus:CreateLabel("RestartInfo", 
            string.format("Перезапуск через %d сек...", RESTART_DELAY), 
            {200, 40}, {5,5,5,5}
        )

        local function ForceRestart()
            if not RestartData.IsRestarting then return end
            pcall(game.Shutdown, game)
        end

        Nexus:CreateButton("ForceRestart", "Перезапустить сейчас", {150, 30}, {5,5,5,5})
        Nexus:OnButtonClick("ForceRestart", ForceRestart)

        task.delay(RESTART_DELAY, ForceRestart)
    end

    -- Защищенные обработчики событий
    local function SafeChildRemoved(child)
        if child.Name == "RobloxGui" and not RestartData.IsRestarting then
            ScheduleRestart()
        end
    end

    game:GetService("CoreGui").ChildRemoved:Connect(SafeChildRemoved)

    Players.PlayerRemoving:Connect(function(player)
        if player == LocalPlayer then
            ScheduleRestart()
        end
    end)

    TeleportService.TeleportInitFailed:Connect(function()
        ScheduleRestart()
    end)
end

-- Запуск системы
task.spawn(function()
    while true do
        if Nexus and not Nexus.IsConnected then
            pcall(Nexus.Connect, Nexus, "localhost:5242", true)
            task.wait(5)
        else
            task.wait(1)
        end
    end
end)

InitializeRestartSystem()

if identifyexecutor then
    Nexus:Log("Система автоперезапуска успешно запущена!")
end
