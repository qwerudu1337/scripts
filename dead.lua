local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local player = Players.LocalPlayer

-- Основная функция перезахода
local function reconnectToMain()
    local success, err = pcall(function()
        TeleportService:Teleport(116495829188952)
    end)
    if not success then
        warn("Ошибка перезахода: " .. err)
    end
end

-- Функция проверки экрана загрузки
local function isLoadingScreenVisible()
    if not player:FindFirstChild("PlayerGui") then 
        return false 
    end
    
    local loadingScreen = player.PlayerGui:FindFirstChild("LoadingScreenPrefab")
    return loadingScreen and loadingScreen:IsA("ScreenGui") and loadingScreen.Enabled
end

-- Главный обработчик
local function mainHandler()
    if game.PlaceId == 116495829188952 then -- Главное меню
        task.wait(1) -- Ждем 1 минуту
        reconnectToMain()
        
    elseif game.PlaceId == 70876832253163 then -- Игровой режим
        if isLoadingScreenVisible() then
            task.wait(40) -- Ждем 40 секунд
        else
            task.wait(1) -- Ждем 5 минут
        end
        reconnectToMain()
    end
end

-- Ожидаем полной загрузки игры
repeat task.wait() until game:IsLoaded() and player.Character

-- Запускаем основной цикл
while true do
    local success, err = pcall(mainHandler)
    if not success then
        warn("Ошибка в основном цикле: " .. err)
        task.wait(10) -- Защита от бесконечного цикла ошибок
    end
end

-- Основной скрипт Rift
repeat
    task.wait()
until game:IsLoaded() and game.Players.LocalPlayer
local a = game.Players.LocalPlayer
if
    not a.Character
    or not a:HasAppearanceLoaded()
    or not a.Character:FindFirstChildOfClass('Humanoid')
then
    a.CharacterAdded:Wait()
    repeat
        task.wait()
    until a:HasAppearanceLoaded()
        and a.Character:FindFirstChildOfClass('Humanoid')
end

if isfile('RiftAssets/donotqueue.txt') then
    delfile('RiftAssets/donotqueue.txt')
    return
end

local a = 'https://raw.githubusercontent.com/synnyyy/Obsidian/refs/heads/main'
local b = {
    Library = a .. '/Library.lua',
    ThemeManager = a .. '/addons/ThemeManager.lua',
    Information = 'https://raw.githubusercontent.com/Synergy-Networks/products/refs/heads/main/Rift/Assets/Information.lua',
    API = 'https://sdkapi-public.luarmor.net/library.lua',
}

local c, d = false, nil
local e = 4
local f = 0
local g = ''

for a, c in next, b do
    task.spawn(function()
        local c = game:HttpGet(c)
        b[a] = loadstring(c)()
        f = f + 1
    end)
end

repeat
    task.wait()
until f == e

local e = {
    ['KEY_EXPIRED'] = 'This key has expired. Please generate a new one.',
    ['KEY_BANNED'] = 'This key has been banned and cannot be used.',
    ['KEY_HWID_LOCKED'] = 'Your key is HWID-locked. Reset your HWID in our server to proceed.',
    ['KEY_INCORRECT'] = 'The key entered is incorrect or has been deleted.',
    ['KEY_INVALID'] = 'The key format is invalid. Make sure you pasted it correctly.',
    ['SCRIPT_ID_INCORRECT'] = 'The script ID you are using is incorrect for this key.',
    ['SCRIPT_ID_INVALID'] = 'The script ID is invalid. Please contact support.',
    ['INVALID_EXECUTOR'] = 'Your executor is not supported by this script.',
    ['SECURITY_ERROR'] = 'A Cloudflare security issue occurred. Please try again later.',
    ['TIME_ERROR'] = 'The request took too long to respond. Check your internet connection.',
    ['UNKNOWN_ERROR'] = 'An unknown server error occurred. Please try again or report this.',
}

b.Library:SetAssetsFolder('RiftAssets')
b.Library:SetAssetsUrl(
    'https://raw.githubusercontent.com/Synergy-Networks/products/refs/heads/main/Rift/Assets'
)
b.Library:SetModulesUrl(
    'https://raw.githubusercontent.com/synnyyy/Obsidian/refs/heads/main/addons'
)
b.Library:CheckAssetsFolder()
b.Library:LoadModules()
b.ThemeManager:SetLibrary(b.Library)
b.ThemeManager:SetFolder('Rift')
b.ThemeManager:LoadDefault()
b.Library:SetNotifySide('left')

local f = b.Library.Options

if game.PlaceId == 16732694052 or game.PlaceId == 131716211654599 then
    b.Library:Notify({
        Title = 'Unsupported Game',
        Description = 'Rift does not support this game because support for the game discontinued..',
        Time = 5,
    })
elseif game.PlaceId == 72907489978215 then
    g = '1c57708a6733fcdac89be981d028aebc'
elseif game.PlaceId == 18687417158 then
    g = '296d23036fbb1af463d3ad03f08a67a4'
elseif game.PlaceId == 70876832253163 then
    g = '373f5d42922fa6b5ac57adbb41b8015f'
elseif game.PlaceId == 116495829188952 then
    g = 'bd4df7f8b3bab2997c8557bd36685984'
elseif game.PlaceId == 126884695634066 then
    g = '271e9f42ea856423a03c9d04f3ac93ff'
else
    b.Library:Notify({
        Title = 'Unsupported Game',
        Description = 'Rift does not support this game.\n\nIf you feel that this is a mistake, please contact us on vaultcord.win/synergy.',
        Time = 5,
    })
    task.wait(5)
    b.Library:Unload()
    getgenv().Library = nil
end

b.API.script_id = g

if getfenv().script_key then
    local a = isfile('RiftAssets/SavedKey.txt')
        and readfile('RiftAssets/SavedKey.txt')
    if not a or a ~= getfenv().script_key then
        writefile('RiftAssets/SavedKey.txt', getfenv().script_key)
    end
    c = true
elseif isfile('RiftAssets/SavedKey.txt') then
    local a = b.API.check_key(readfile('RiftAssets/SavedKey.txt'))
    if a.code == 'KEY_VALID' then
        c = true
        getfenv().script_key = readfile('RiftAssets/SavedKey.txt')
    else
        delfile('RiftAssets/SavedKey.txt')
    end
end

local a = function(c)
    b.Library = loadstring(game:HttpGet(a .. '/Library.lua'))()
    b.ThemeManager = loadstring(game:HttpGet(a .. '/addons/ThemeManager.lua'))()
    b.Library:SetAssetsFolder('RiftAssets')
    b.Library:SetAssetsUrl(
        'https://raw.githubusercontent.com/Synergy-Networks/products/refs/heads/main/Rift/Assets'
    )
    b.Library:SetModulesUrl(
        'https://raw.githubusercontent.com/synnyyy/Obsidian/refs/heads/main/addons'
    )
    b.Library:CheckAssetsFolder()
    b.Library:LoadModules()
    b.ThemeManager:SetLibrary(b.Library)
    b.ThemeManager:SetFolder('Rift')
    b.ThemeManager:LoadDefault()
    b.Library:SetNotifySide('left')

    local a = b.Library:CreateChangableWindow({
        Title = 'Rift',
        Footer = 'Case: ' .. g .. ' • Executor: ' .. identifyexecutor(),
        Icon = b.Library:GetAsset('Logo.png'),
        Modal = true,
    })

    local a = a:CreateCanvas()
    a:AddLabel(
        'Rift encountered an unexpected error. Please report this to the developers if it continues.\n\n<font color="rgb(255, 0, 0)"><b>Error:\n</b></font>'
            .. c
            .. '\n',
        true
    )
    a
        :AddButton('Report Issue', function()
            setclipboard('https://vaultcord.win/synergy')
            b.Library:Notify({
                Title = 'Report Issue',
                Description = 'We have copied our Discord Server to your clipboard.\n\nAfter you have verified, please post a ticket and send the screenshot from the error.\n\nFrom there, we will assist you in your issue.',
                Time = 15,
            })
        end)
        :AddButton('Exit', function()
            getgenv().Library:Unload()
            getgenv().Library = nil
        end)
end

if not c then
    b.Library:Notify({
        Title = 'New Game',
        Description = 'Rift now supports <b>Grow a Garden</b> and is the BEST script with TONS of useful features.\n\nMake sure to check it out!',
        Time = 5,
    })

    local a = b.Library:CreateChangableWindow({
        Title = 'Rift',
        Icon = b.Library:GetAsset('Logo.png'),
        Footer = 'Loader · '
            .. b.Information.VERSION
            .. ' · vaultcord.win/synergy',
        NotifySide = 'Left',
        Size = UDim2.fromOffset(450, 240),
    })

    local a = a:CreateCanvas({
        FillDirection = Enum.FillDirection.Horizontal,
        Padding = UDim.new(0, 20),
        Lines = {
            {
                AnchorPoint = Vector2.new(0, 0),
                Position = UDim2.new(0.4, 3),
                Size = UDim2.new(0, 1, 1, 0),
            },
        },
    })

    a:SetVisible()
    local f = a:AddSplit({ Size = UDim2.fromScale(0.4, 1) })
    f:AddInput('', {
        Numeric = false,
        Finished = false,
        ClearTextOnFocus = true,
        Text = 'Key:',
        Placeholder = 'Enter your key here..',
        Callback = function(a)
            d = a
        end,
    })

    f:AddButton({
        Text = 'Enter',
        Func = function()
            local a = b.API.check_key(d)
            local e = e[a.code] or 'Unknown response.'
            if a.code == 'KEY_VALID' then
                getfenv().script_key = d
                writefile('RiftAssets/SavedKey.txt', d)
                c = true
            else
                b.Library:Notify({
                    Title = 'Invalid Key',
                    Description = e,
                    Time = 5,
                })
            end
        end,
    })

    f:AddButton({
        Text = 'Copy Key Link',
        Func = function()
            setclipboard('https://rifton.top/getkey')
            b.Library:Notify({
                Title = 'Copied to Clipboard',
                Description = 'Paste the key link into your browser of choice.',
                Time = 5,
            })
        end,
    })

    local a = a:AddSplit({ Size = UDim2.fromScale(0.6, 1) })
    local a = a:AddScrollingFrame()
    local b = b.Library.Scheme.AccentColor
    local b = string.format('rgb(%d, %d, %d)', b.R * 255, b.G * 255, b.B * 255)

    a:AddLabel('', {
        DoesWrap = true,
        RichText = true,
        Text = '<font color="'
            .. b
            .. '">❖ How do I buy a lifetime key?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> You can buy a lifetime key by visiting https://rifton.top and purchasing it for $3.99 via '
            .. 'Bitcoin, Ethereum, and Litecoin.\n\n'
            .. '<font color="'
            .. b
            .. '">❖ How many checkpoints are there?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> There is only one checkpoint which gives you 24-hour access to Rift under a key.\n\n'
            .. '<font color="'
            .. b
            .. '">❖ What is a provider?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> A provider is the advertisement service used to get you a key. You\'ll need to pick one to continue.\n\n'
            .. '<font color="'
            .. b
            .. '">❖ Why won\'t the page load?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Try using a browser like Google Chrome.\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Disable any firewalls, VPNs/proxies, or antivirus software that might block the page.\n\n'
            .. '<font color="'
            .. b
            .. '">❖ Why aren\'t the tasks completing?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Disable ad blockers like UBlock Origin.\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Refresh the page and try again.\n\n'
            .. '<font color="'
            .. b
            .. '">❖ Why is my key invalid?</font>\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Make sure there are no extra spaces in the key.\n'
            .. '<b><font color="'
            .. b
            .. '">·</font></b> Keys generated by others are not usable by you.',
    })
end

repeat
    task.wait()
until c

if getgenv().Library then
    getgenv().Library:Unload()
    getgenv().Library = nil
end

getgenv().script_key = getfenv().script_key
local b, c = pcall(function()
    b.API.load_script()
end)

if not b then
    a(c)
end
