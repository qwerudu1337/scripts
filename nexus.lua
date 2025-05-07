if Nexus then Nexus:Stop() end

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
    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()

    Nexus.Commands = {}
    Nexus.Connections = {}
    Nexus.InfoConnections = {}

    Nexus.ShutdownTime = 45
    Nexus.ShutdownOnTeleportError = true

    function Nexus:Send(Command, Payload)
        assert(self.Socket ~= nil, 'websocket is nil')
        assert(self.IsConnected, 'websocket not connected')
        local Message = HttpService:JSONEncode { Name = Command, Payload = Payload }
        self.Socket:Send(Message)
        if self.InfoSocket then -- Отправка копии на инфо порт
            self.InfoSocket:Send(Message)
        end
    end

    -- Добавлена функция для инфо порта
    function Nexus:SetupInfoSocket()
        local Success, Socket = pcall(WSConnect, 'ws://localhost:5243/NexusInfo')
        if Success then
            self.InfoSocket = Socket
            table.insert(self.InfoConnections, Socket.OnMessage:Connect(function(Message)
                print("[INFO PORT] Received:", Message)
            end))
            table.insert(self.InfoConnections, Socket.OnClose:Connect(function()
                self.InfoSocket = nil
            end))
        end
    end

    function Nexus:Log(...)
        local T = {}
        for Index, Value in pairs{ ... } do table.insert(T, tostring(Value)) end
        local msg = table.concat(T, ' ')
        self:Send('Log', { Content = msg })
        
        -- Дополнительный вывод через инфо порт
        if self.InfoSocket then
            self.InfoSocket:Send(HttpService:JSONEncode{
                Name = 'InfoLog',
                Payload = { Content = msg, Type = 'SYSTEM_LOG' }
            })
        end
    end

    function Nexus:Connect(Host, Bypass)
        if not Bypass and self.IsConnected then return end

        while true do
            for Index, Connection in pairs(self.Connections) do
                Connection:Disconnect()
            end
            table.clear(self.Connections)

            if self.IsConnected then
                self.IsConnected = false
                self.Socket = nil
                self.Disconnected:Fire()
            end

            if self.Terminated then break end

            Host = Host or 'localhost:5242'
            local Success, Socket = pcall(WSConnect, ('ws://%s/Nexus?name=%s&id=%s&jobId=%s'):format(
                Host, LocalPlayer.Name, LocalPlayer.UserId, game.JobId))

            if Success then
                self.Socket = Socket
                self.IsConnected = true
                self:SetupInfoSocket() -- Инициализация инфо порта

                table.insert(self.Connections, Socket.OnMessage:Connect(function(Message)
                    self.MessageReceived:Fire(Message)
                end))

                table.insert(self.Connections, Socket.OnClose:Connect(function()
                    self.IsConnected = false
                    self.Disconnected:Fire()
                end))

                self.Connected:Fire()

                while self.IsConnected do
                    local Success = pcall(self.Send, self, 'ping')
                    if not Success or self.Terminated then break end
                    task.wait(1)
                end
            else
                task.wait(12)
            end
        end
    end

    function Nexus:Stop()
        self.IsConnected = false
        self.Terminated = true
        if self.Socket then pcall(function() self.Socket:Close() end) end
        if self.InfoSocket then pcall(function() self.InfoSocket:Close() end) end
        self.Disconnected:Fire()
    end

    function Nexus:AddCommand(Name, Function)
        self.Commands[Name] = Function
    end

    function Nexus:RemoveCommand(Name)
        self.Commands[Name] = nil
    end

    function Nexus:OnButtonClick(Name, Function)
        self:AddCommand('ButtonClicked:' .. Name, Function)
    end

    Nexus.MessageReceived:Connect(function(Message)
        local S = Message:find(' ')

        if S then
            local Command, Message = Message:sub(1, S - 1):lower(), Message:sub(S + 1)

            if Nexus.Commands[Command] then
                local Success, Error = pcall(Nexus.Commands[Command], Message)

                if not Success and Error then
                    Nexus:Log(('Error with command `%s`: %s'):format(Command, Error))
                end
            end
        elseif Nexus.Commands[Message] then
            local Success, Error = pcall(Nexus.Commands[Message], Message)

            if not Success and Error then
                Nexus:Log(('Error with command `%s`: %s'):format(Message, Error))
            end
        end
    end)
end

do -- Default Commands
    Nexus:AddCommand('execute', function(Message)
        local Function, Error = loadstring(Message)
        
        if Function then
            local Env = getfenv(Function)
            
            Env.Player = LocalPlayer
            Env.print = function(...)
                local T = {}

                for Index, Value in pairs{ ... } do
                    table.insert(T, tostring(Value))
                end

                Nexus:Log(table.concat(T, ' '))
            end

            if newcclosure then Env.print = newcclosure(Env.print) end

            local S, E = pcall(Function)

            if not S then
                Nexus:Log(E)
            end
        else
            Nexus:Log(Error)
        end
    end)

    Nexus:AddCommand('teleport', function(Message)
        local S = Message:find(' ')
        local PlaceId, JobId = S and Message:sub(1, S - 1) or Message, S and Message:sub(S + 1)
        
        if JobId then
            TeleportService:TeleportToPlaceInstance(tonumber(PlaceId), JobId)
        else
            TeleportService:Teleport(tonumber(PlaceId))
        end
    end)

    Nexus:AddCommand('rejoin', function(Message)
        TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId)
    end)

    Nexus:AddCommand('mute', function()
        if (UGS.MasterVolume - OldVolume) > 0.01 then
            OldVolume = UGS.MasterVolume
        end

        UGS.MasterVolume = 0
    end)

    Nexus:AddCommand('unmute', function()
        UGS.MasterVolume = OldVolume
    end)

    Nexus:AddCommand('performance', function(Message)
        if _PERF then return end
        
        _PERF = true
        _TARGETFPS = 8

        if Message and tonumber(Message) then
            _TARGETFPS = tonumber(Message)
        end

        local OldLevel = settings().Rendering.QualityLevel

        RunService:Set3dRenderingEnabled(false)
        settings().Rendering.QualityLevel = 1

        InputService.WindowFocused:Connect(function()
            RunService:Set3dRenderingEnabled(true)
            settings().Rendering.QualityLevel = OldLevel
            setfpscap(60)
        end)

        InputService.WindowFocusReleased:Connect(function()
            OldLevel = settings().Rendering.QualityLevel

            RunService:Set3dRenderingEnabled(false)
            settings().Rendering.QualityLevel = 1
            setfpscap(_TARGETFPS)
        end)

        setfpscap(_TARGETFPS)
    end)
end

do -- Connections
    GuiService.ErrorMessageChanged:Connect(function()
        if NoShutdown then return end

        local Code = GuiService:GetErrorCode().Value

        if Code >= Enum.ConnectionError.DisconnectErrors.Value then
            if not Nexus.ShutdownOnTeleportError and Code > Enum.ConnectionError.PlacelaunchOtherError.Value then
                return
            end
            
            task.delay(Nexus.ShutdownTime, game.Shutdown, game)
        end
    end)
end

local GEnv = getgenv()
GEnv.Nexus = Nexus
GEnv.performance = Nexus.Commands.performance

if not Nexus_Version then
    Nexus:Connect()
    Nexus:Connect("localhost:5243") -- Дополнительное подключение к инфо порту
end
