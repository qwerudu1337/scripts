if Nexus then Nexus:Stop() end

-- Добавляем второй порт для текстовой информации
local SECONDARY_PORT = 5243

if not game:IsLoaded() then
    task.delay(60, function()
        if NoShutdown then return end

        if not game:IsLoaded() then
            return game:Shutdown()
        end

        local Code = game:GetService'GuiService':GetErrorCode().Value

        if Code >= Enum.ConnectionError.DisconnectErrors.Value then
            return game:Shutdown()
        end
    end)
    
    game.Loaded:Wait()
end

local Nexus = {}
local WSConnect = syn and syn.websocket.connect or
    (Krnl and (function() repeat task.wait() until Krnl.WebSocket and Krnl.WebSocket.connect return Krnl.WebSocket.connect end)()) or
    WebSocket and WebSocket.connect

if not WSConnect then
    if messagebox then
        messagebox(('Nexus encountered an error while launching!\n\n%s'):format('Your exploit (' .. (identifyexecutor and identifyexecutor() or 'UNKNOWN') .. ') is not supported'), 'Roblox Account Manager', 0)
    end
    
    return
end

local TeleportService = game:GetService'TeleportService'
local InputService = game:GetService'UserInputService'
local HttpService = game:GetService'HttpService'
local RunService = game:GetService'RunService'
local GuiService = game:GetService'GuiService'
local Players = game:GetService'Players'
local LocalPlayer = Players.LocalPlayer if not LocalPlayer then repeat LocalPlayer = Players.LocalPlayer task.wait() until LocalPlayer end task.wait(0.5)

local UGS = UserSettings():GetService'UserGameSettings'
local OldVolume = UGS.MasterVolume

LocalPlayer.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started and Nexus.IsConnected then
        Nexus:Stop()
    end
end)

local Signal = {} do
    Signal.__index = Signal

    function Signal.new()
        return setmetatable({ _BindableEvent = Instance.new'BindableEvent' }, Signal)
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

do -- Nexus
    local TEXT_CHANNEL = 'TextChannel:'
    
    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()
    Nexus.TextReceived = Signal.new()

    Nexus.Commands = {}
    Nexus.Connections = {}
    Nexus.TextConnections = {}

    Nexus.ShutdownTime = 45
    Nexus.ShutdownOnTeleportError = true

    function Nexus:Send(Command, Payload)
        assert(self.Socket ~= nil, 'websocket is nil')
        assert(self.IsConnected, 'websocket not connected')
        assert(typeof(Command) == 'string', 'Command must be a string, got ' .. typeof(Command))

        local Message = HttpService:JSONEncode {
            Name = Command,
            Payload = Payload or {}
        }

        self.Socket:Send(Message)
    end

    -- Новая функция для работы с текстовым каналом
    function Nexus:SendText(text)
        if self.TextSocket then
            self.TextSocket:Send(HttpService:JSONEncode{
                Type = TEXT_CHANNEL,
                Content = text
            })
        end
    end

    function Nexus:CreateElement(ElementType, Name, Content, Size, Margins, Table)
        assert(typeof(Name) == 'string', 'string expected on argument #1, got ' .. typeof(Name))
        assert(typeof(Content) == 'string', 'string expected on argument #2, got ' .. typeof(Content))

        local Payload = {
            Name = Name,
            Content = Content,
            Size = Size and table.concat(Size, ','),
            Margin = Margins and table.concat(Margins, ',')
        }

        if Table then
            for Index, Value in pairs(Table) do
                Payload[Index] = Value
            end
        end

        self:Send(ElementType, Payload)
    end

    function Nexus:CreateLabel(...)
        return self:CreateElement('CreateLabel', ...)
    end

    function Nexus:Connect(Host, Bypass)
        if not Bypass and self.IsConnected then return end

        while true do
            -- Основное соединение
            local mainHost = Host or ('localhost:%d'):format(5242)
            local mainSuccess, mainSocket = pcall(WSConnect, ('ws://%s/Nexus?name=%s&id=%s&jobId=%s'):format(
                mainHost, 
                LocalPlayer.Name, 
                LocalPlayer.UserId, 
                game.JobId
            ))

            -- Текстовый канал
            local textHost = Host or ('localhost:%d'):format(SECONDARY_PORT)
            local textSuccess, textSocket = pcall(WSConnect, ('ws://%s/TextChannel'):format(textHost))

            if not mainSuccess or not textSuccess then 
                task.wait(12) 
                continue 
            end

            self.Socket = mainSocket
            self.TextSocket = textSocket
            self.IsConnected = true

            -- Обработчики сообщений
            table.insert(self.Connections, mainSocket.OnMessage:Connect(function(msg)
                self.MessageReceived:Fire(msg)
            end))

            table.insert(self.TextConnections, textSocket.OnMessage:Connect(function(msg)
                local data = HttpService:JSONDecode(msg)
                if data.Type == TEXT_CHANNEL then
                    self:CreateLabel("TextDisplay", data.Content, {300, 100}, {10,10,10,10})
                    self.TextReceived:Fire(data.Content)
                end
            end))

            table.insert(self.Connections, mainSocket.OnClose:Connect(function()
                self.IsConnected = false
                self.Disconnected:Fire()
            end))

            self.Connected:Fire()
            break
        end
    end

    function Nexus:Stop()
        self.IsConnected = false
        if self.Socket then pcall(function() self.Socket:Close() end) end
        if self.TextSocket then pcall(function() self.TextSocket:Close() end) end
        self.Disconnected:Fire()
    end

    Nexus.MessageReceived:Connect(function(Message)
        local command, args = Message:match("([^:]+):?(.*)")
        if Nexus.Commands[command] then
            pcall(Nexus.Commands[command], args)
        end
    end)
end

do -- Default Commands
    Nexus:AddCommand('display', function(text)
        Nexus:CreateLabel("DisplayText", text, {400, 50}, {20,20,20,20})
    end)

    Nexus:AddCommand('execute', function(code)
        local func, err = loadstring(code)
        if func then 
            pcall(func) 
            Nexus:SendText("Execution successful!")
        else
            Nexus:SendText("Execution error: "..err)
        end
    end)
end

local GEnv = getgenv()
GEnv.Nexus = Nexus

if not Nexus_Version then
    Nexus:Connect()
    Nexus:CreateLabel("Status", "Connected to Nexus!", {200, 30}, {5,5,5,5})
    Nexus:SendText("Session started at "..os.date("%X"))
end
