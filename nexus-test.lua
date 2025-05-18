-- Добавляем проверку на существование Nexus и его метода Stop
if Nexus and type(Nexus.Stop) == "function" then
    Nexus:Stop()
end

-- Безопасное получение LocalPlayer
local Players = game:GetService("Players")
local LocalPlayer

repeat
    LocalPlayer = Players.LocalPlayer
    task.wait(1)
until LocalPlayer

-- Модифицированная проверка загрузки игры
local function SafeLoadCheck()
    if not game:IsLoaded() then
        local loaded = false
        
        task.delay(60, function()
            if getgenv().NoShutdown or loaded then return end

            if not game:IsLoaded() then
                return game:Shutdown()
            end

            local success, code = pcall(function()
                return game:GetService("GuiService"):GetErrorCode().Value
            end)
            
            if success and code >= Enum.ConnectionError.DisconnectErrors.Value then
                return game:Shutdown()
            end
        end)
        
        repeat task.wait() until game:IsLoaded()
        loaded = true
    end
end

SafeLoadCheck()

local Nexus = {}
local WSConnect

-- Безопасная инициализация WebSocket
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
        messagebox(('Nexus encountered an error!\n\n%s'):format(
            'WebSocket не поддерживается вашим эксплойтом (' .. 
            (identifyexecutor and identifyexecutor() or 'UNKNOWN') .. ')'
        ), 'Ошибка', 0)
    end
    return
end

-- Безопасное получение сервисов
local function GetService(name)
    local service
    while true do
        service = game:GetService(name)
        if service then break end
        task.wait(1)
    end
    return service
end

local TeleportService = GetService("TeleportService")
local InputService = GetService("UserInputService")
local HttpService = GetService("HttpService")
local RunService = GetService("RunService")
local GuiService = GetService("GuiService")

local UGS = UserSettings():GetService("UserGameSettings")
local OldVolume = UGS.MasterVolume

-- Безопасное подключение к OnTeleport
local TeleportConnection
local function SafeTeleportConnect()
    while true do
        if LocalPlayer and LocalPlayer.OnTeleport then
            TeleportConnection = LocalPlayer.OnTeleport:Connect(function(State)
                if State == Enum.TeleportState.Started and Nexus.IsConnected then
                    pcall(Nexus.Stop, Nexus)
                end
            end)
            break
        end
        task.wait(1)
    end
end
SafeTeleportConnect()

-- Класс Signal остается без изменений
local Signal = {} do
    Signal.__index = Signal

    function Signal.new()
        return setmetatable({_BindableEvent = Instance.new("BindableEvent")}, Signal)
    end

    function Signal:Connect(callback)
        assert(type(callback) == "function", "Функция ожидается")
        return self._BindableEvent.Event:Connect(callback)
    end

    function Signal:Fire(...)
        self._BindableEvent:Fire(...)
    end

    function Signal:Wait()
        return self._BindableEvent.Event:Wait()
    end

    function Signal:Destroy()
        self._BindableEvent:Destroy()
    end
end

-- Модифицированный класс Nexus
do
    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()
    Nexus.Commands = {}
    Nexus.Connections = {}
    Nexus.ShutdownTime = 45
    Nexus.ShutdownOnTeleportError = true

    -- Добавляем обязательные методы
    function Nexus:AddCommand(name, func)
        self.Commands[name:lower()] = func
    end

    function Nexus:RemoveCommand(name)
        self.Commands[name:lower()] = nil
    end

    function Nexus:Send(command, payload)
        if not self.Socket or not self.IsConnected then return end
        local success, json = pcall(HttpService.JSONEncode, HttpService, {
            Name = command,
            Payload = payload
        })
        if success then
            pcall(function() self.Socket:Send(json) end)
        end
    end

    -- Остальные методы Nexus
    function Nexus:Connect(host, bypass)
        if not bypass and self.IsConnected then return end

        host = host or "localhost:5242"
        while true do
            -- Очистка старых соединений
            for _, conn in pairs(self.Connections) do
                pcall(conn.Disconnect, conn)
            end
            table.clear(self.Connections)

            -- Подключение WebSocket
            local success, socket = pcall(WSConnect, 
                ("ws://%s/Nexus?name=%s&id=%s&jobId=%s"):format(
                    host,
                    LocalPlayer.Name,
                    LocalPlayer.UserId,
                    game.JobId
                )
            )

            if success and socket then
                self.Socket = socket
                self.IsConnected = true

                -- Обработчики событий
                table.insert(self.Connections, socket.OnMessage:Connect(function(msg)
                    self.MessageReceived:Fire(msg)
                end))

                table.insert(self.Connections, socket.OnClose:Connect(function()
                    self.IsConnected = false
                    self.Disconnected:Fire()
                end))

                self.Connected:Fire()

                -- Пинг-луп
                while self.IsConnected do
                    pcall(function() socket:Send("ping") end)
                    task.wait(1)
                end
            else
                task.wait(12)
            end
        end
    end

    function Nexus:Stop()
        self.IsConnected = false
        if self.Socket then
            pcall(function() self.Socket:Close() end)
        end
    end
end

-- Инициализация автоперезапуска
local function InitializeAutoReboot()
    Nexus:AddCommand("RebootRequest", function(payload)
        local data = game:GetService("HttpService"):JSONDecode(payload)
        Nexus:Log("Перезапуск аккаунта...")
        task.delay(data.Delay or 30, function()
            if not game:IsLoaded() then
                game:Shutdown()
            end
        end)
    end)
end

-- Инициализация глобальных переменных
getgenv().Nexus = Nexus
getgenv().performance = function(...)
    if Nexus.Commands.performance then
        Nexus.Commands.performance(...)
    end
end

-- Запуск системы
if not Nexus_Version then
    InitializeAutoReboot()
    pcall(Nexus.Connect, Nexus)
end
