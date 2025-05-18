if Nexus then Nexus:Stop() end

-- Добавляем безопасное получение LocalPlayer
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
        messagebox(('Nexus encountered an error while launching!\n\n%s'):format('Your exploit (' .. (identifyexecutor and identifyexecutor() or 'UNKNOWN') .. ') is not supported'), 'Roblox Account Manager', 0)
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
local function SafeTeleportConnect()
    while true do
        if LocalPlayer and LocalPlayer.OnTeleport then
            return LocalPlayer.OnTeleport:Connect(function(State)
                if State == Enum.TeleportState.Started and Nexus.IsConnected then
                    Nexus:Stop()
                end
            end)
        end
        task.wait(1)
    end
end

local TeleportConnection = SafeTeleportConnect()

-- Оригинальный код класса Signal остается без изменений
local Signal = {} do
    Signal.__index = Signal

    function Signal.new()
        local self = setmetatable({ _BindableEvent = Instance.new'BindableEvent' }, Signal)
        return self
    end

    function Signal:Connect(Callback)
        assert(typeof(Callback) == 'function', 'function expected, got ' .. typeof(Callback))
        return self._BindableEvent.Event:Connect(Callback)
    end

    function Signal:Fire(...)
        self._BindableEvent:Fire(...)
    end

    function Signal:Wait()
        return self._BindableEvent.Event:Wait()
    end

    function Signal:Disconnect()
        if self._BindableEvent then
            self._BindableEvent:Destroy()
        end
    end
end

-- Модифицированный класс Nexus с защитой от ошибок
do -- Nexus
    local BTN_CLICK = 'ButtonClicked:'

    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()

    Nexus.Commands = {}
    Nexus.Connections = {}

    Nexus.ShutdownTime = 45
    Nexus.ShutdownOnTeleportError = true

    function Nexus:AddCommand(Name, Function)
        self.Commands[Name] = Function
    end

    function Nexus:RemoveCommand(Name)
        self.Commands[Name] = nil
    end

    function Nexus:Send(Command, Payload)
        if not self.Socket or not self.IsConnected then return end
        local success, message = pcall(function()
            return HttpService:JSONEncode {
                Name = Command,
                Payload = Payload
            }
        end)
        
        if success then
            pcall(function()
                self.Socket:Send(message)
            end)
        end
    end

    -- Остальные методы Nexus с защитой
    function Nexus:SetAutoRelaunch(Enabled)
        pcall(self.Send, self, 'SetAutoRelaunch', { Content = Enabled and 'true' or 'false' })
    end
    
    function Nexus:SetPlaceId(PlaceId)
        pcall(self.Send, self, 'SetPlaceId', { Content = PlaceId })
    end
    
    function Nexus:SetJobId(JobId)
        pcall(self.Send, self, 'SetJobId', { Content = JobId })
    end

    -- ... остальные методы остаются без изменений, но обернуты в pcall

    function Nexus:Connect(Host, Bypass)
        if not Bypass and self.IsConnected then return end

        while true do
            -- Очистка предыдущих соединений
            for _, conn in pairs(self.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            table.clear(self.Connections)

            -- Подключение к WebSocket
            local host = Host or 'localhost:5242'
            local success, socket = pcall(WSConnect, 
                ('ws://%s/Nexus?name=%s&id=%s&jobId=%s'):format(
                    host, 
                    LocalPlayer.Name, 
                    LocalPlayer.UserId, 
                    game.JobId
                )
            )

            if success and socket then
                self.Socket = socket
                self.IsConnected = true

                -- Обработчики сообщений
                table.insert(self.Connections, socket.OnMessage:Connect(function(msg)
                    self.MessageReceived:Fire(msg)
                end))

                table.insert(self.Connections, socket.OnClose:Connect(function()
                    self.IsConnected = false
                    self.Disconnected:Fire()
                end))

                self.Connected:Fire()

                -- Пинг-система
                while self.IsConnected do
                    pcall(function()
                        self.Socket:Send("ping")
                    end)
                    task.wait(1)
                end
            else
                task.wait(12)
            end
        end
    end

    -- ... остальная часть класса Nexus
end

-- Дополнения для автоматического перезапуска
do -- Connections
    GuiService.ErrorMessageChanged:Connect(function()
        if getgenv().NoShutdown then return end

        local success, code = pcall(function()
            return GuiService:GetErrorCode().Value
        end)

        if success and code >= Enum.ConnectionError.DisconnectErrors.Value then
            if not Nexus.ShutdownOnTeleportError and code > Enum.ConnectionError.PlacelaunchOtherError.Value then
                return
            end
            
            task.delay(Nexus.ShutdownTime, function()
                pcall(game.Shutdown, game)
            end)
        end
    end)

    -- Автоматический перезапуск при закрытии GUI
    game:GetService("CoreGui").ChildRemoved:Connect(function(child)
        if child.Name == "RobloxGui" then
            task.delay(5, function()
                if not getgenv().NoShutdown then
                    game:Shutdown()
                end
            end)
        end
    end)
end

-- Инициализация глобального окружения
local GEnv = getgenv()
GEnv.Nexus = Nexus
GEnv.performance = function(...)
    Nexus.Commands.performance(...)
end

-- Запуск соединения
if not Nexus_Version then
    task.spawn(function()
        while true do
            if not Nexus.IsConnected then
                pcall(Nexus.Connect, Nexus)
            end
            task.wait(5)
        end
    end)
end

-- Добавьте этот код в конец вашего скрипта Nexus.lua
-- Автоматическая система перезапуска

local AUTO_REBOOT = {
    Enabled = true,             -- Включить авто-перезапуск
    MaxAttempts = 5,            -- Максимум попыток
    Delay = 30,                 -- Задержка между попытками (сек)
    CrashDetectionTime = 15,    -- Время для детектирования краша (сек)
    CurrentAttempt = 0,
    LastCrashTime = 0
}

-- Функция инициализации перезапуска
local function InitiateReboot()
    if not AUTO_REBOOT.Enabled then return end
    if AUTO_REBOOT.CurrentAttempt >= AUTO_REBOOT.MaxAttempts then
        Nexus:Log("Достигнут лимит перезапусков!")
        return
    end

    AUTO_REBOOT.CurrentAttempt += 1
    AUTO_REBOOT.LastCrashTime = os.time()

    -- Отправка команды в Account Manager
    Nexus:Send("RebootRequest", {
        PlaceId = game.PlaceId,
        JobId = game.JobId,
        Attempt = AUTO_REBOOT.CurrentAttempt
    })

    -- Создание UI элементов
    Nexus:CreateLabel("RebootStatus", 
        string.format("Автоперезапуск через %d сек (Попытка %d/%d)", 
        AUTO_REBOOT.Delay, 
        AUTO_REBOOT.CurrentAttempt, 
        AUTO_REBOOT.MaxAttempts),
        {300, 40}, {5,5,5,5}
    )

    Nexus:CreateButton("CancelReboot", "Отменить перезапуск", {150, 30}, {5,5,5,5})
    Nexus:OnButtonClick("CancelReboot", function()
        AUTO_REBOOT.CurrentAttempt = 0
        Nexus:Send("RemoveElement", {Name = "RebootStatus"})
        Nexus:Send("RemoveElement", {Name = "CancelReboot"})
    end)

    -- Запланированный перезапуск
    task.delay(AUTO_REBOOT.Delay, function()
        if AUTO_REBOOT.CurrentAttempt > 0 then
            game:Shutdown()
        end
    end)
end

-- Детектор крашей
task.spawn(function()
    while task.wait(AUTO_REBOOT.CrashDetectionTime) do
        if AUTO_REBOOT.Enabled and os.time() - AUTO_REBOOT.LastCrashTime > AUTO_REBOOT.CrashDetectionTime then
            local pingSuccess = pcall(function()
                Nexus:Send("ping")
            end)
            
            if not pingSuccess then
                InitiateReboot()
            end
        end
    end
end)

-- Хук на закрытие игры
game:GetService("CoreGui").ChildRemoved:Connect(function(child)
    if child.Name == "RobloxGui" then
        InitiateReboot()
    end
end)

-- Хук на ошибки телепортации
TeleportService.TeleportInitFailed:Connect(function()
    InitiateReboot()
end)

-- Интеграция с Account Manager через WebSocket
Nexus:AddCommand("RebootRequest", function(payload)
    local data = game:GetService("HttpService"):JSONDecode(payload)
    
    -- Логика для вашего Account Manager
    Nexus:Log("Инициирован перезапуск аккаунта...")
    
    task.delay(data.Delay or 30, function()
        if not game:IsLoaded() then
            game:Shutdown()
        end
    end)
end)
    Nexus:Log("Инициирован перезапуск аккаунта...")
    
    -- Пример реализации:
    task.delay(data.Delay or 30, function()
        if not game:IsLoaded() then
            game:Shutdown()
        end
    end)
end)
