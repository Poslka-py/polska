-- polska loader (version github) : verifie la key dans keys.txt, recupere le kaitun, le lance
-- remplace TONPSEUDO par ton pseudo github (et polska par le nom du depot si different)
local REPO = "https://raw.githubusercontent.com/Poslka-py/polska/main"
local KEY_FILE = "polska_key.txt"

local Players = game:GetService("Players")
local player = Players.LocalPlayer
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)

local function getHwid()
    local ok, id = pcall(function() return gethwid and gethwid() end)
    if ok and type(id) == "string" and #id >= 6 then return id end
    local ok2, cid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok2 and type(cid) == "string" and #cid >= 6 then return cid end
    return "uid-" .. tostring(player.UserId)
end

local function httpGet(url)
    local ok, body = pcall(function()
        if httpRequest then return httpRequest({ Url = url, Method = "GET" }).Body end
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and not body:find("^404") then return body end
    return nil
end

-- keys.txt : une key par ligne -> KEY  EXPIRATION(AAAA-MM-JJ ou 0)  HWID(ou -)  note
local function findKey(list, key)
    for line in (list .. "\n"):gmatch("(.-)\r?\n") do
        local k, exp, hwid = line:match("^%s*(%S+)%s+(%S+)%s+(%S+)")
        if k and k:upper() == key then return exp, hwid end
    end
    return nil
end

local function expired(exp)
    if exp == "0" then return false end
    local y, m, d = exp:match("^(%d+)%-(%d+)%-(%d+)$")
    if not y then return true end
    return os.time() > os.time({ year = tonumber(y), month = tonumber(m), day = tonumber(d), hour = 23, min = 59, sec = 59 })
end

local function fetchScript(key)
    local stamp = "?t=" .. tostring(os.time())
    local list = httpGet(REPO .. "/keys.txt" .. stamp)
    if not list then return nil, "github injoignable" end
    local exp, hwid = findKey(list, key)
    if not exp then return nil, "key inconnue" end
    if hwid == "BAN" then return nil, "key bannie" end
    if expired(exp) then return nil, "key expiree" end
    if hwid ~= "-" and hwid ~= getHwid() then
        if setclipboard then pcall(setclipboard, getHwid()) end
        return nil, "autre pc (ton hwid est copie)"
    end
    local code = httpGet(REPO .. "/polska_kaitun.lua" .. stamp)
    if not code then return nil, "kaitun introuvable sur github" end
    return code
end

local function prompt(message)
    local done = Instance.new("BindableEvent")
    local code, key
    local screen = Instance.new("ScreenGui")
    screen.Name = "PolskaLoader"; screen.IgnoreGuiInset = true; screen.DisplayOrder = 1000000; screen.ResetOnSpawn = false
    pcall(function() screen.Parent = (gethui and gethui()) or game:GetService("CoreGui") end)
    if not screen.Parent then screen.Parent = player:WaitForChild("PlayerGui") end
    local bg = Instance.new("Frame", screen); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = Color3.fromRGB(9, 7, 15); bg.BorderSizePixel = 0
    local card = Instance.new("Frame", bg); card.Size = UDim2.fromOffset(420, 210); card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(19, 15, 30); card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    Instance.new("UIStroke", card).Color = Color3.fromRGB(46, 36, 74)
    local title = Instance.new("TextLabel", card); title.BackgroundTransparency = 1; title.Position = UDim2.fromOffset(20, 16); title.Size = UDim2.fromOffset(380, 30)
    title.Text = "Polska Kaitun"; title.Font = Enum.Font.GothamBlack; title.TextSize = 24; title.TextColor3 = Color3.fromRGB(240, 236, 250); title.TextXAlignment = Enum.TextXAlignment.Left
    local info = Instance.new("TextLabel", card); info.BackgroundTransparency = 1; info.Position = UDim2.fromOffset(20, 50); info.Size = UDim2.fromOffset(380, 20)
    info.Text = message or "entre ta key"; info.Font = Enum.Font.Gotham; info.TextSize = 13; info.TextColor3 = Color3.fromRGB(255, 176, 96); info.TextXAlignment = Enum.TextXAlignment.Left
    local box = Instance.new("TextBox", card); box.Position = UDim2.fromOffset(20, 84); box.Size = UDim2.fromOffset(380, 40)
    box.BackgroundColor3 = Color3.fromRGB(13, 10, 22); box.TextColor3 = Color3.fromRGB(240, 236, 250); box.PlaceholderText = "POLSKA-XXXX-XXXX-XXXX"
    box.Font = Enum.Font.GothamBold; box.TextSize = 16; box.ClearTextOnFocus = false; box.Text = ""
    Instance.new("UICorner", box).CornerRadius = UDim.new(0, 8)
    local button = Instance.new("TextButton", card); button.Position = UDim2.fromOffset(20, 142); button.Size = UDim2.fromOffset(380, 44)
    button.BackgroundColor3 = Color3.fromRGB(168, 112, 255); button.Text = "Valider"; button.Font = Enum.Font.GothamBold; button.TextSize = 16; button.TextColor3 = Color3.fromRGB(20, 9, 42)
    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 10)
    button.MouseButton1Click:Connect(function()
        local typed = box.Text:gsub("%s", ""):upper()
        info.Text = "verification..."
        local body, why = fetchScript(typed)
        if body then code, key = body, typed; done:Fire() else info.Text = "refusee : " .. tostring(why) end
    end)
    done.Event:Wait()
    screen:Destroy()
    return code, key
end

local key = getgenv().PolskaKey
if (not key or key == "") and readfile and isfile then
    pcall(function() if isfile(KEY_FILE) then key = readfile(KEY_FILE) end end)
end
local code, message
if key and key ~= "" then
    key = key:gsub("%s", ""):upper()
    code, message = fetchScript(key)
    if message then message = "key refusee : " .. message end
end
if not code then code, key = prompt(message) end
if writefile and key then pcall(writefile, KEY_FILE, key) end

getgenv().PolskaKeyOk = true
local fn, err = loadstring(code)
if not fn then error("[polska] script illisible : " .. tostring(err)) end
fn()
