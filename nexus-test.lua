if Nexus then Nexus:Stop() end

-- Добавляем второй порт для информационного канала
local INFO_PORT = 5252
local infoSocket = nil
local infoConnected = false

if not game:IsLoaded() then
    task.delay(60, function()
        if NoShutdown then return end
        if not game:IsLoaded() then return game:Shutdown() end
        
        local Code = game:GetService'GuiService':GetErrorCode().Value
        if Code >= Enum.ConnectionError.DisconnectErrors.Value then
            return game:Shutdown()
        end
    end)
    game.Loaded:Wait()
end

local Nexus = {}
local WSConnect = syn and syn.websocket.connect or
    (Krnl and (function() repeat until Krnl.WebSocket and Krnl.WebSocket.connect return Krnl.WebSocket.connect end)()) or
    WebSocket.connect

if not WSConnect then
    if messagebox then
        messagebox(('Nexus Error!\n%s'):format('Unsupported exploit: '..(identifyexecutor() or 'UNKNOWN')), 'RAM', 0)
    end
    return
end

-- Сервисы
local HttpService = game:GetService'HttpService'
local Players = game:GetService'Players'
local LocalPlayer = Players.LocalPlayer
repeat task.wait() until LocalPlayer

-- Инициализация информационного канала
local function InitInfoChannel()
    local success, socket = pcall(WSConnect, 'ws://localhost:'..tostring(INFO_PORT))
    if success then
        infoSocket = socket
        infoConnected = true
        infoSocket.OnMessage:Connect(function(msg)
            -- Обработка сообщений для веб-интерфейса
            print('[INFO CHANNEL]', msg)
        end)
        infoSocket.OnClose:Wait()
        infoConnected = false
    end
end

task.spawn(InitInfoChannel)

-- Модифицированные функции Nexus
function Nexus:SendInfo(...)
    if not infoConnected then return end
    local args = {...}
    local message = HttpService:JSONEncode({
        Type = 'InfoUpdate',
        Data = table.concat(args, ' ')
    })
    infoSocket:Send(message)
end

function Nexus:UpdateWebUI(message)
    self:SendInfo('WEB_UI_UPDATE', message)
end

-- Оригинальные функции Nexus с интеграцией информационного канала
do
    local BTN_CLICK = 'ButtonClicked:'
    Nexus.Connected = Signal.new()
    Nexus.Disconnected = Signal.new()
    Nexus.MessageReceived = Signal.new()
    
    Nexus.Commands = {}
    Nexus.Connections = {}

    function Nexus:Log(...)
        local T = {}
        for _,v in ipairs{...} do table.insert(T, tostring(v)) end
        self:Send('Log', {Content = table.concat(T, ' ')})
        self:SendInfo('LOG', table.concat(T, ' ')) -- Отправка в веб-интерфейс
    end

    function Nexus:Connect(Host)
        task.spawn(function()
            while true do
                if self.IsConnected then
                    for _,c in pairs(self.Connections) do c:Disconnect() end
                    self.IsConnected = false
                    self.Socket = nil
                end

                Host = Host or 'localhost:5242'
                local success, sock = pcall(WSConnect, ('ws://%s/Nexus?user=%s&id=%s'):format(
                    Host, LocalPlayer.Name, LocalPlayer.UserId))

                if success then
                    self.Socket = sock
                    self.IsConnected = true
                    
                    self.Connections = {
                        sock.OnMessage:Connect(function(msg)
                            self.MessageReceived:Fire(msg)
                            self:SendInfo('WS_MSG', msg) -- Пересылка сообщений
                        end),
                        sock.OnClose:Connect(function()
                            self.IsConnected = false
                            self.Disconnected:Fire()
                        end)
                    }
                    
                    self.Connected:Fire()
                    while self.IsConnected do
                        pcall(self.Send, self, 'ping')
                        task.wait(1)
                    end
                else
                    task.wait(12)
                end
            end
        end)
    end
end

-- Интеграция с веб-интерфейсом
Nexus:AddCommand('webui', function(msg)
    Nexus:UpdateWebUI(msg)
    print('[WEB UI]', msg)
end)

-- Пример использования
Nexus:Connect()
Nexus:CreateLabel('Status', 'Connected to Nexus', {200, 20}, {5,5,5,5})
Nexus:SendInfo('SYSTEM', 'Initialization complete')

getgenv().Nexus = Nexus
