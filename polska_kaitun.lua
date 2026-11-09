--[[
  polska kaitun v2 | tap simulator reborn  (full AFK, config-based)
  edit the Config table, save as polska_kaitun.lua in your executor workspace, run it.
  getgenv().KaitunConfig = { ... } set before running overrides any value here.

  craft / delete : en attente d'une capture (craft d'un pet commun en golden + remote AutoDeleteRequested).
]]

local Config = {
    -- keys : serveur Cloudflare (dossier keys/). laisse vide tant que le serveur n'est pas en ligne
    keyServer   = "",     -- ex "https://polska-keys.tonpseudo.workers.dev"
    keyRequired = false,  -- true = le kaitun refuse de demarrer sans key valide

    -- ecran / perf
    ui          = true,
    hudVisible  = true,
    maxOpti     = true,
    cpuSaver    = true,
    saverFps    = 5,      -- fps en cpu saver (moins = moins de cpu ; les clics/s ne depassent pas ce nombre)
    freezeGameLoops = true, -- cpu saver : coupe les boucles d'affichage du jeu (RenderStepped/Heartbeat) apres la preparation
    freezeGameEvents = true, -- cpu saver : le jeu ne traite plus les resultats de clic / hatch / rebirth (animations, popups)
    hideOthers  = true,   -- cpu saver : retire les autres joueurs de ton ecran (plus d'animations a calculer)   -- 3D et interface du jeu coupees en permanence ; RightShift = dashboard ou ecran noir ; aucun bouton   -- dashboard visible = 3D coupee + interface du jeu cachee + graphismes au minimum   -- dashboard plein ecran au lancement (RightShift ou le bouton rond pour voir le jeu)
    disable3D   = false,  -- true = coupe la 3D (gain max mais ecran noir)
    fpsCap      = 8,
    mute        = true,
    lowGfx      = true,   -- graphismes au minimum (force par maxOpti)
    antiAfk     = true,
    autoRejoin  = true,
    selfFile    = "polska_kaitun.lua",
    saveFile    = "polska_kaitun.json",

    -- hatch
    autoHatch   = true,
    egg         = "30M Visits",   -- nom exact de l'oeuf, ou "last" = le plus cher debloque et payable
    eggSkip     = {},             -- oeufs a ne jamais choisir en mode "last", ex { "30M Visits" }
    hatchCount  = 3,              -- oeufs par hatch
    hatchDelay  = 0.3,
    teleportToEgg = true,         -- tp sur l'oeuf avant chaque hatch, meme depuis une autre zone
    -- positions connues : servent quand l'oeuf n'est pas encore charge (tu es loin)
    eggPositions = {
        ["30M Visits"] = Vector3.new(-48, -510, -1952),
        Basic = Vector3.new(0, -509, -1841),
        Spotted = Vector3.new(-14, -509, -1829),
        Spiked = Vector3.new(-23, -510, -1725),
        Nimbus = Vector3.new(-96, -47, -1891),
        Sky = Vector3.new(-89, -47, -1904),
        -- monde 2 (Time Rift)
        Grove = Vector3.new(195, 507, 6987),
        Rift = Vector3.new(218, 507, 6987),
        Jurassic = Vector3.new(926, 900, 6986),
        Glacier = Vector3.new(1610, 1372, 6772),
        Permafrost = Vector3.new(1629, 1372, 6775),
    },
    -- zone a posseder pour chaque oeuf du monde 2 (Grove et Rift sont au spawn)
    riftEggZones = { Jurassic = "Prehistoric Island", Glacier = "Ice Age", Permafrost = "Ice Age" },
    -- lancement propre : quetes, shrine, auto-delete, enchant, craft... puis seulement la tp + le hatch
    setupFirst      = true,
    setupEnchantMax = 900,        -- temps max (s) laisse a l enchant avant de lancer le hatch (15 min)
    setupCraftMax   = 120,

    -- rebirth
    autoRebirth = true,
    rebirthIndex = "max",         -- "max" = le plus haut bouton de rebirth debloque (Upgrades.RebirthButtons), ou un numero
    rebirthEvery = 30,

    -- potions / boosts
    autoPotion  = true,
    potions     = { "Coins Potion II", "Lucky Potion II" },
    potionEvery = 60,            -- re-use toutes les N s (ou quand il reste peu de temps)

    -- colosseum / wave defense (= pet defense)
    autoWave        = true,

    -- auto-delete : pets supprimes des le hatch, par oeuf, dans les variantes choisies
    autoDelete      = true,
    deleteList      = {
        ["30M Visits"] = {
            pets  = { "30M Mummy Puppy", "30M Ghostly Bunny", "30M FrankenBear", "30M Vampire Fox", "30M Midnight Cat", "30M Party Phoenix" },
            tiers = { "Normal", "Golden", "Diamond", "Shiny" },
        },
        Permafrost = {
            pets  = { "Arctic Moose", "Frostbite Mammoth", "Ice Age Polar Bear", "Frost Elk", "Woolly Mammoth" },
            tiers = { "Normal", "Golden", "Diamond", "Shiny" },
        },
        Glacier = {
            pets  = { "Glacier Kitty", "Glacier Bunny", "Ice Age Snowman", "Frosty Kitsune", "Glacier Pixie" },
            tiers = { "Normal", "Golden", "Diamond", "Shiny" },
        },
    },

    -- shrine (ile Autumn) : ShrineService.RF.Choose("Luck")
    autoShrine      = true,
    shrineChoices   = { "Luck", "Golden" },  -- "Luck" = chance, "Golden" = golden chance
    shrineAlternate = true,      -- true = Luck puis Golden puis Luck... ; false = toujours le premier qui marche
    shrineEvery     = 1800,      -- la shrine se recharge toutes les 30 min
    shrineRetry     = 60,        -- si refusee, on reessaie apres 60 s

    -- auto click : TapService.RE.TapRequested({ ClientSequence, Auto, Source })
    autoClick       = true,
    clicksPerSecond = 8,

    -- auto craft : pets identiques -> machine (6 Normal -> Golden, 5 Golden -> Diamond)
    autoCraft       = true,
    craftSize       = 6,
    craftSizes      = { Golden = 6, Diamond = 5 },
    craftWhenFull   = 0,          -- 0 = craft des qu'il y a assez de pets identiques ; 0.8 = attendre 80 % d'inventaire
    craftChain      = { Normal = "Golden", Golden = "Diamond" },
    craftSkipRarity = { "Secret" },  -- jamais crafter ces raretes
    craftEvery      = 10,
    craftAtMachine  = true,       -- dans le monde 2 : va devant la machine avant de crafter
    machinesRift    = {           -- machines de l'ile Ice Age (monde 2)
        Golden  = Vector3.new(1479, 1356, 6995),
        Diamond = Vector3.new(1488, 1375, 6773),
        Rainbow = Vector3.new(1404, 1372, 6894),
    },

    -- auto enchant : pets equipes seulement, reroll chaque slot jusqu'a un enchant de la liste
    autoEnchant     = true,
    enchantSlots    = 2,
    enchantKeep     = { "Four-Leaf", "Golden Touch", "Lucky III", "Prismatic Surge", "Secret Hunter", "Celestial Bond" },
    enchantMode     = "auto",     -- "auto" = l'auto-enchant du jeu (AutoStart), "manuel" = un roll a la fois
    enchantAutoMax  = 600,        -- temps max (s) d'auto-enchant par pet
    enchantDelay    = 2.5,        -- attente entre deux enchants (le jeu refuse si on va trop vite)
    enchantOnlyAtStart = true,    -- true = enchante toute l'equipe au lancement, puis s'arrete pour de bon
    enchantRetryMin = 10,         -- refus (plus de ressource...) : on reessaie dans 10 min sans bouger
    -- ou se tenir pour enchanter (machine de Shadow Realm, mesure en jeu)
    enchantMachinePos = Vector3.new(116, 7680, -1802),

    -- arbre de competences : SkillTreeService.RF.Unlock({ Name }) pour chaque competence pas encore prise
    autoSkills      = true,
    skillsEvery     = 30,
    skills          = {
        "Rift Click Power 1", "Rift Click Power 2", "Rift Click Power 3",
        "Rift Pet Power 1", "Rift Pet Power 2", "Rift Pet Power 3",
        "Rift Critical Power", "Rift Critical Clicks",
        "Rift Auto Clicks 1", "Rift Auto Clicks 2",
        "Rift Egg Luck 1", "Rift Egg Luck 2",
        "Rift Golden Chance 1", "Rift Golden Chance 2",
        "Rift Gem Hoard 1", "Rift Gem Hoard 2",
        "Rift Mythic Luck 1", "Rift Mythic Luck 2",
    },

    -- monde 2 (Time Rift) : TimeRiftService.RE.UnlockRequested() tant qu'il n'est pas debloque
    autoRift        = true,
    riftEvery       = 60,
    -- ou farmer : "main" = monde 1, "rift" = monde 2 (on y va par le portail apres la preparation)
    farmWorld       = "rift",
    riftEgg         = "last",
    -- zones du monde 2 : TimeRiftIslandService.RE.IslandUnlockRequested({ Action = "Purchase", Island })
    autoRiftZones   = true,
    riftZones       = { "Prehistoric Island", "Ice Age" },
    riftZonesEvery  = 60,     -- oeuf du monde 2 : "last" = le plus cher payable autour de toi, ou un nom
    portals = {
        toRift = Vector3.new(-54, -374, -1535),   -- Workspace.World2Portal (monde 1)
        toMain = Vector3.new(-64, 505, 7071),     -- Workspace.World2.ReturnPortal (monde 2)
    },

    -- quetes
    autoQuests      = true,       -- reclame toute quete terminee
    questEvery      = 30,
    waveAttackDelay = 0.05,

    -- stats / webhook
    webhookUrl       = "",        -- colle ici l'url du webhook discord (https://discord.com/api/webhooks/...)
    webhookStatusMin = 30,        -- 0 = off
    webhookSecrets   = true,
    webhookRarities  = { "Secret", "Godly", "Mythical" },  -- un message discord pour chaque hatch de ces raretes
    webhookPing      = "",        -- ex "<@123456789>" pour etre mentionne sur un secret
    secretPattern    = "secret",  -- rarete contenant ce mot = secret
    mythicPattern    = "mythic",
}

----------------------------------------------------------------------
local cloneref = cloneref or function(x) return x end
local function svc(n) return cloneref(game:GetService(n)) end

local Players           = svc("Players")
local ReplicatedStorage = svc("ReplicatedStorage")
local UserInputService  = svc("UserInputService")
local HttpService       = svc("HttpService")
local RunService        = svc("RunService")
local Lighting          = svc("Lighting")
local SoundService      = svc("SoundService")
local VirtualUser       = svc("VirtualUser")
local Workspace         = svc("Workspace")
local GuiService        = svc("GuiService")
local TeleportService   = svc("TeleportService")
local CoreGui           = svc("CoreGui")

if getgenv().PolskaKaitunCleanup then pcall(getgenv().PolskaKaitunCleanup) end

local function merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" and type(dst[k]) == "table" then merge(dst[k], v) else dst[k] = v end
    end
end
if type(getgenv().KaitunConfig) == "table" then merge(Config, getgenv().KaitunConfig) end
Config.hatchDelay = math.max(0.05, Config.hatchDelay)

local player = Players.LocalPlayer

local state = {
    alive     = true,
    status    = "demarrage",
    startedAt = os.time(),
    hatch     = { seq = 0, fired = 0, note = "idle", spot = nil, where = "-", egg = "-", known = {} },
    ready     = false,
    info      = "",
    holdTp    = false,
    setupStep = "-",
    quest     = { claimed = 0, note = "-" },
    delete    = { note = "-" },
    shrine    = { used = 0, note = "-" },
    click     = { seq = 0, sent = 0, acked = 0, lastAck = 0, note = "-" },
    craft     = { sent = 0, note = "-" },
    rift      = { tries = 0, note = "-" },
    travel    = "-",
    zones     = { note = "-" },
    skills    = { bought = 0, note = "-" },
    enchant   = { rolls = 0, last = "-", note = "-", done = {}, blind = {}, reason = "" },
    rebirth   = { count = 0, nextAt = 0 },
    potion    = { nextAt = 0, used = 0, note = "idle" },
    wave      = { running = false, kills = 0, waves = 0, note = "idle" },
    stats     = { hatched = 0, secrets = 0, mythics = 0, lastSecret = "-" },
}

local connections = {}
local function track(c) table.insert(connections, c); return c end

----------------------------------------------------------------------
-- remotes
local servicesFolder = ReplicatedStorage:WaitForChild("RemoteServices", 20)
local function resolve(path)
    if not servicesFolder then return nil end
    local node = servicesFolder
    for seg in string.gmatch(path, "[^%.]+") do node = node and node:FindFirstChild(seg) end
    return node
end

local function fireEvent(remote, ...)
    if not remote then return false end
    return pcall(remote.FireServer, remote, ...)
end
local function invoke(remote, ...)
    if not remote then return false, nil end
    return pcall(remote.InvokeServer, remote, ...)
end

-- journal : console F9 + fichier polska_kaitun_log.txt (dossier workspace de l'executor)
local function dumpValue(v, depth)
    depth = depth or 0
    if type(v) ~= "table" then return tostring(v) end
    if depth > 2 then return "{...}" end
    local parts, n = {}, 0
    for k, val in pairs(v) do
        n = n + 1
        if n > 12 then table.insert(parts, "..."); break end
        table.insert(parts, tostring(k) .. "=" .. dumpValue(val, depth + 1))
    end
    return "{" .. table.concat(parts, ", ") .. "}"
end

local function logLine(text)
    local line = os.date("%H:%M:%S") .. " " .. text
    print("[polska] " .. line)
    if appendfile then pcall(appendfile, "polska_kaitun_log.txt", line .. "\n")
    elseif writefile and readfile then
        pcall(function()
            local old = (isfile and isfile("polska_kaitun_log.txt")) and readfile("polska_kaitun_log.txt") or ""
            writefile("polska_kaitun_log.txt", old .. line .. "\n")
        end)
    end
end

----------------------------------------------------------------------
----------------------------------------------------------------------
-- webhook
local lastWebhook = 0
local function webhookOk()
    local u = Config.webhookUrl
    return type(u) == "string" and u ~= "" and (string.find(u, "discord.com/api/webhooks/", 1, true) or string.find(u, "discordapp.com/api/webhooks/", 1, true))
end
local httpRequest = request or http_request or (syn and syn.request) or (http and http.request) or (fluxus and fluxus.request)
local function sendWebhook(payload)
    if not (webhookOk() and httpRequest) then
        if webhookOk() then state.info = "webhook : ton executor n'a pas de fonction request" end
        return false
    end
    local wait = 1.2 - (os.clock() - lastWebhook)
    if wait > 0 then task.wait(wait) end
    lastWebhook = os.clock()
    local ok, res = pcall(function()
        return httpRequest({ Url = Config.webhookUrl, Method = "POST", Headers = { ["Content-Type"] = "application/json" }, Body = HttpService:JSONEncode(payload) })
    end)
    local good = ok and res and (res.StatusCode == 200 or res.StatusCode == 204)
    if not good then logLine("webhook echec : " .. tostring(ok and res and res.StatusCode or res)) end
    return good
end
local function embed(title, desc, color)
    return { username = "polska kaitun", embeds = { { title = title, description = desc, color = color or 5763719,
        footer = { text = "polska kaitun | " .. player.Name }, timestamp = DateTime.now():ToIsoDate() } } }
end

----------------------------------------------------------------------
-- stats : secrets / mythiques sur les resultats de hatch et de craft
local lastSecretAt = 0
local function collectStrings(v, out, depth)
    depth = depth or 0
    if depth > 4 then return end
    if type(v) == "string" then table.insert(out, v)
    elseif type(v) == "table" then for _, x in pairs(v) do collectStrings(x, out, depth + 1) end end
end
-- garde les noms et raretes du dernier hatch (pour le message discord)
local function onResult(...)
    local found = {}
    local function scan(t, depth)
        if type(t) ~= "table" or depth > 5 then return end
        if type(t.Name) == "string" and t.Rarity ~= nil then
            table.insert(found, { name = t.Name, rarity = tostring(t.Rarity), tier = t.Tier, mutation = t.Mutation, id = t.Id })
        end
        for _, v in pairs(t) do scan(v, depth + 1) end
    end
    scan(table.pack(...), 0)
    if #found > 0 then
        state.lastHatch = found
        state.lastHatchAt = os.clock()
    end
end

local hatchResult = resolve("EggService.RE.EggHatchResult")
if hatchResult then
    track(hatchResult.OnClientEvent:Connect(function(...)
        state.stats.hatched = state.stats.hatched + 1
        onResult(...)
    end))
end
local craftResult = resolve("MachineService.RE.MachineCraftResult")
if craftResult then
    track(craftResult.OnClientEvent:Connect(function(...) onResult(...) end))
end

----------------------------------------------------------------------
-- donnees joueur (Replica "PlayerData") : lecture seule, retrouvee en memoire
local playerReplica = nil
local lastReplicaScan = -100
local function playerData()
    if playerReplica and type(rawget(playerReplica, "Data")) == "table" then return playerReplica.Data end
    if not getgc or os.clock() - lastReplicaScan < 15 then return nil end
    lastReplicaScan = os.clock()
    local ok, objects = pcall(getgc, true)
    if not ok then return nil end
    for _, obj in ipairs(objects) do
        if type(obj) == "table" and rawget(obj, "Class") == "PlayerData" and type(rawget(obj, "Data")) == "table" then
            local tags = rawget(obj, "Tags")
            if type(tags) ~= "table" or tags.UserId == nil or tags.UserId == player.UserId then
                playerReplica = obj
                return obj.Data
            end
        end
    end
    return nil
end

-- une ile est a nous si son nom apparait comme cle "true" dans les donnees (debloquees, visitees...) ou si on y est
local function zoneUnlocked(data, name)
    local prog = data and data.Progression
    if prog and prog.Island == name then return true end
    local function scan(t, depth)
        if type(t) ~= "table" or depth > 3 then return false end
        if t[name] == true then return true end
        for k, v in pairs(t) do
            if k ~= "Quests" and k ~= "Statistics" and type(v) == "table" and scan(v, depth + 1) then return true end
        end
        return false
    end
    return scan(prog, 0) or scan(data and data.TimeRift, 0) or scan(data and data.Unlocks, 0)
end

local function eggUnlocked(name)
    local data = playerData()
    local eggs = data and data.Eggs
    local unlocked = eggs and eggs.Unlocked
    if type(unlocked) ~= "table" or unlocked[name] == true then return true end
    local zone = (Config.riftEggZones or {})[name]
    if zone then return zoneUnlocked(data, zone) end
    -- oeuf du monde 2 sans zone (spawn) : ouvert des qu'on est dans le monde 2
    return state.worldSeen == "rift" or (data and data.Progression and data.Progression.World == "TimeRift") or false
end

-- monde actuel : Data.Progression.World, ou le dernier TimeRiftService.RE.Traveled { To = ... }
local function currentWorld()
    if state.worldSeen then return state.worldSeen end
    local data = playerData()
    local w = data and data.Progression and data.Progression.World
    if w and w ~= "Main" then return "rift" end
    return "main"
end

do
    local traveled = resolve("TimeRiftService.RE.Traveled")
    if traveled then
        track(traveled.OnClientEvent:Connect(function(info)
            local to = type(info) == "table" and info.To or info
            state.worldSeen = (to == "TimeRift") and "rift" or "main"
            state.lastTravel = os.clock()
        end))
    end
end

-- oeufs : Workspace.Eggs.<Nom>.Egg + panneau EggCostSign (Price, Currency, CanAfford)
local eggPart = nil
local eggPartName = nil
local lastPick = 0

local function eggFolder()
    return Workspace:FindFirstChild("Eggs")
end

local function eggSign(model)
    local sign = model:FindFirstChild("EggCostSign")
    if not sign then return nil end
    local ok, data = pcall(function()
        return { price = tonumber(sign:GetAttribute("Price")) or 0, afford = sign:GetAttribute("CanAfford"), currency = sign:GetAttribute("Currency") }
    end)
    return ok and data or nil
end

local function skipped(name)
    for _, n in ipairs(Config.eggSkip or {}) do
        if string.lower(n) == string.lower(name) then return true end
    end
    return false
end

-- le "dernier oeuf" = le plus cher que tu peux payer
local function pickLastEgg()
    local folder = eggFolder()
    if not folder then return nil end
    local best, bestPrice = nil, -1
    for _, model in ipairs(folder:GetChildren()) do
        local info = eggSign(model)
        local near = true
        local char = player.Character
        local root = char and char:FindFirstChild("HumanoidRootPart")
        local part = model:FindFirstChild("Egg")
        if root and part and part:IsA("BasePart") then near = (part.Position - root.Position).Magnitude < 2500 end
        if near and info and info.afford ~= false and eggUnlocked(model.Name) and not skipped(model.Name) and info.price > bestPrice then
            best, bestPrice = model.Name, info.price
        end
    end
    return best
end

local function currentEgg()
    local wanted = (currentWorld() == "rift") and (Config.riftEgg or "last") or Config.egg
    if string.lower(wanted or "") ~= "last" then return wanted end
    if state.hatch.egg ~= "-" and os.clock() - lastPick < 20 then return state.hatch.egg end
    lastPick = os.clock()
    local picked = pickLastEgg()
    if picked then state.hatch.egg = picked end
    return picked
end

local function findEggPart()
    local name = currentEgg()
    if not name then return nil end
    if eggPart and eggPart.Parent and eggPartName == name then return eggPart end
    eggPart, eggPartName = nil, nil
    local folder = eggFolder()
    local model = folder and folder:FindFirstChild(name)
    if model then
        local part = model:FindFirstChild("Egg")
        if not (part and part:IsA("BasePart")) then part = model:FindFirstChildWhichIsA("BasePart", true) end
        if part then eggPart, eggPartName = part, name end
    end
    return eggPart
end

local function portalParts(model)
    local parts = {}
    if not model then return parts end
    for _, d in ipairs(model:GetDescendants()) do
        if d:IsA("BasePart") then table.insert(parts, d) end
    end
    return parts
end

-- traverse le portail : tp dedans + contact physique, puis attend le message Traveled
local function travelTo(world)
    if currentWorld() == world then return true end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false end
    local pos = (Config.portals or {})[world == "rift" and "toRift" or "toMain"]
    local model = (world == "rift") and Workspace:FindFirstChild("World2Portal")
        or (Workspace:FindFirstChild("World2") and Workspace.World2:FindFirstChild("ReturnPortal"))
    if model then
        local drift = model:FindFirstChild("DriftVolume", true)
        if drift and drift:IsA("BasePart") then pos = drift.Position end
    end
    if not pos then return false end
    state.travel = "voyage vers " .. world
    local started = os.clock()
    for attempt = 1, 3 do
        pcall(function() root.CFrame = CFrame.new(pos) end)
        pcall(function() player:RequestStreamAroundAsync(pos, 5) end)
        task.wait(0.5)
        if not model then
            model = (world == "rift") and Workspace:FindFirstChild("World2Portal")
                or (Workspace:FindFirstChild("World2") and Workspace.World2:FindFirstChild("ReturnPortal"))
        end
        if firetouchinterest then
            for _, part in ipairs(portalParts(model)) do
                pcall(function() firetouchinterest(root, part, 0); firetouchinterest(root, part, 1) end)
            end
        end
        local untilAt = os.clock() + 6
        while os.clock() < untilAt do
            if state.lastTravel and state.lastTravel > started and currentWorld() == world then
                state.travel = "arrive : " .. world
                task.wait(2)
                return true
            end
            task.wait(0.25)
        end
    end
    state.travel = "portail sans effet (" .. world .. ")"
    return false
end

local function eggCFrame()
    local part = findEggPart()
    if part then
        state.hatch.known[eggPartName] = part.Position
        return part.CFrame, true
    end
    local name = currentEgg()
    local pos = name and (state.hatch.known[name] or (Config.eggPositions or {})[name])
    if pos then return CFrame.new(pos), false end
    return nil, false
end

local function teleportToEgg()
    if not Config.teleportToEgg then state.hatch.where = "tp off"; return end
    local target, loaded = eggCFrame()
    if not target then state.hatch.where = "oeuf introuvable"; return end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then state.hatch.where = "perso absent"; return end
    local dist = (root.Position - target.Position).Magnitude
    if dist > 5 then
        pcall(function() root.CFrame = target + Vector3.new(0, 4, 0) end)
        if not loaded then
            -- l'oeuf est loin et pas encore charge : on demande au jeu de charger la zone
            pcall(function() player:RequestStreamAroundAsync(target.Position, 5) end)
            state.hatch.where = "tp zone (chargement)"
            return
        end
    end
    state.hatch.where = loaded and "sur l'oeuf" or "position connue"
end

-- hatch
local function hatchLoop()
    local remote = resolve("EggService.RE.EggHatchRequested")
    if not remote then state.hatch.note = "remote hatch absent"; return end
    while state.alive and not state.ready do
        state.hatch.note = "attente preparation"
        task.wait(0.5)
    end
    while state.alive do
        local eggName = Config.autoHatch and currentEgg() or nil
        local wantWorld = (Config.farmWorld == "rift" and state.riftOpen) and "rift" or "main"
        if state.holdTp then
            state.hatch.note = "pause (enchant)"
            task.wait(0.5)
        elseif currentWorld() ~= wantWorld then
            state.hatch.note = "voyage"
            if not travelTo(wantWorld) then task.wait(10) end
            lastPick = -100
        elseif eggName and eggName ~= "" then
            state.hatch.egg = eggName
            teleportToEgg()
            state.hatch.seq = state.hatch.seq + 1
            local ok = fireEvent(remote, { Egg = eggName, Auto = false, Count = Config.hatchCount, Seq = state.hatch.seq })
            if ok then state.hatch.fired = state.hatch.fired + 1; state.hatch.note = "actif" end
            task.wait(Config.hatchDelay)
        else
            state.hatch.note = Config.autoHatch and "aucun oeuf payable" or "off"
            task.wait(1)
        end
    end
end

-- rebirth
local function rebirthLoop()
    local remote = resolve("RebirthService.RE.RebirthRequested")
    if not remote then return end
    -- RebirthResult { Success, Index, World } : si le plus haut bouton est trop cher, on descend d'un cran
    state.rebirth.cap = state.rebirth.cap or {}
    local result = resolve("RebirthService.RE.RebirthResult")
    if result then
        track(result.OnClientEvent:Connect(function(info)
            if type(info) ~= "table" then return end
            local world = (info.World == "TimeRift") and "rift" or "main"
            if info.Success == false and tonumber(info.Index) then
                state.rebirth.cap[world] = math.max(1, info.Index - 1)
                state.rebirth.capAt = os.clock()
            elseif info.Success then
                state.rebirth.ok = (state.rebirth.ok or 0) + 1
            end
        end))
    end
    while state.alive do
        if Config.autoRebirth and os.clock() >= state.rebirth.nextAt then
            state.rebirth.nextAt = os.clock() + math.max(5, Config.rebirthEvery)
            local index = Config.rebirthIndex
            if index == "max" then
                local data = playerData()
                local up = data and data.Upgrades
                index = tonumber(up and up.RebirthButtons) or 1
                if currentWorld() == "rift" and tonumber(up and up.RiftRebirthButtons) and up.RiftRebirthButtons > 0 then
                    index = up.RiftRebirthButtons
                end
                if index < 1 then index = 1 end
            end
            -- toutes les 5 min, on retente le plus haut bouton (tu as peut-etre assez maintenant)
            if state.rebirth.capAt and os.clock() - state.rebirth.capAt > 300 then state.rebirth.cap = {}; state.rebirth.capAt = nil end
            local cap = state.rebirth.cap[currentWorld()]
            if type(index) == "number" and cap and index > cap then index = cap end
            state.rebirth.index = index
            if fireEvent(remote, { Index = index }) then state.rebirth.count = state.rebirth.count + 1 end
        end
        task.wait(1)
    end
end

-- potions / boosts
local function potionLoop()
    local remote = resolve("BoostService.RF.Use")
    if not remote then state.potion.note = "remote boost absent"; return end
    while state.alive do
        if Config.autoPotion and os.clock() >= state.potion.nextAt then
            state.potion.nextAt = os.clock() + math.max(10, Config.potionEvery)
            local used = 0
            for _, name in ipairs(Config.potions) do
                if not state.alive then break end
                local ok, res = invoke(remote, name)
                if ok and type(res) == "table" and res.Success then used = used + 1 end
                task.wait(0.3)
            end
            state.potion.used = state.potion.used + used
            state.potion.note = "derniere fois : " .. used .. " potion(s)"
        end
        task.wait(1)
    end
end

-- colosseum / wave defense
-- quetes : Data.Quests[nom] = { Completed, Claimed } -> QuestService.RF.ClaimQuest({ Quest = nom })
local function questLoop()
    local remote = resolve("QuestService.RF.ClaimQuest")
    if not remote then state.quest.note = "remote quete absent"; return end
    while state.alive do
        if Config.autoQuests then
            local data = playerData()
            local quests = data and data.Quests
            if type(quests) == "table" then
                local names = {}
                for name, q in pairs(quests) do
                    if type(q) == "table" and q.Completed == true and q.Claimed ~= true then table.insert(names, name) end
                end
                for _, name in ipairs(names) do
                    if not state.alive then break end
                    local ok = invoke(remote, { Quest = name })
                    if ok then state.quest.claimed = state.quest.claimed + 1 end
                    task.wait(0.5)
                end
                state.quest.note = (#names > 0) and ("reclame " .. #names) or "a jour"
            else
                state.quest.note = "donnees introuvables"
            end
        else
            state.quest.note = "off"
        end
        task.wait(math.max(10, Config.questEvery))
    end
end

-- auto-delete : EggService.RE.AutoDeleteRequested({ Egg, Entries }) remplace la liste de l'oeuf
local function deleteEntries(rule)
    local entries = {}
    for _, pet in ipairs(rule.pets or {}) do
        for _, tier in ipairs(rule.tiers or { "Normal" }) do
            if tier == "Normal" then table.insert(entries, pet) else table.insert(entries, pet .. "_" .. tier) end
        end
    end
    return entries
end

local function sameSet(a, b)
    if type(a) ~= "table" or type(b) ~= "table" then return false end
    local seen, n = {}, 0
    for _, v in ipairs(a) do seen[v] = true; n = n + 1 end
    local m = 0
    for _, v in ipairs(b) do
        if not seen[v] then return false end
        m = m + 1
    end
    return n == m
end

local function deleteLoop()
    local remote = resolve("EggService.RE.AutoDeleteRequested")
    if not remote then state.delete.note = "remote delete absent"; return end
    while state.alive do
        if Config.autoDelete and type(Config.deleteList) == "table" then
            local data = playerData()
            local current = data and data.Eggs and data.Eggs.AutoDelete
            local sent, ok = 0, 0
            for egg, rule in pairs(Config.deleteList) do
                local entries = deleteEntries(rule)
                local already = type(current) == "table" and sameSet(current[egg], entries)
                if already then
                    ok = ok + 1
                elseif fireEvent(remote, { Egg = egg, Entries = entries }) then
                    sent = sent + 1
                    task.wait(1)
                end
            end
            state.delete.note = (sent > 0) and ("liste envoyee (" .. sent .. ")") or (ok > 0 and "actif" or "en attente")
        else
            state.delete.note = "off"
        end
        task.wait(60)
    end
end

-- shrine
local function resultText(res)
    if type(res) == "table" then
        local parts, n = {}, 0
        for k, v in pairs(res) do
            n = n + 1
            if n > 3 then break end
            table.insert(parts, tostring(k) .. "=" .. tostring(v))
        end
        return table.concat(parts, " ")
    end
    return tostring(res)
end

local function shrineLoop()
    local remote = resolve("ShrineService.RF.Choose")
    if not remote then state.shrine.note = "remote shrine absent"; return end
    local start = 1
    while state.alive do
        local waitFor = math.max(15, Config.shrineRetry or 60)
        local choices = Config.shrineChoices or {}
        if Config.autoShrine and #choices > 0 then
            for step = 0, #choices - 1 do
                local index = ((start - 1 + step) % #choices) + 1
                local choice = choices[index]
                local ok, res = invoke(remote, choice)
                local refused = type(res) == "table" and (res.Success == false or res.success == false or res.Ok == false)
                if ok and res ~= nil and res ~= false and not refused then
                    state.shrine.used = state.shrine.used + 1
                    state.shrine.note = choice .. " ok"
                    if Config.shrineAlternate then start = (index % #choices) + 1 end
                    waitFor = math.max(60, Config.shrineEvery or 1800)
                    break
                end
                state.shrine.note = ok and (choice .. " : " .. resultText(res)) or ("erreur " .. choice)
                task.wait(1)
            end
        else
            state.shrine.note = "off"
        end
        local untilAt = os.clock() + waitFor
        while state.alive and os.clock() < untilAt do task.wait(5) end
    end
end

-- auto click : le serveur renvoie le numero de chaque clic dans TapResult, on suit le plus grand
local function clickLoop()
    local remote = resolve("TapService.RE.TapRequested")
    if not remote then state.click.note = "remote tap absent"; return end
    local result = resolve("TapService.RE.TapResult")
    if result then
        track(result.OnClientEvent:Connect(function(info)
            if type(info) == "table" and type(info.ClientSequence) == "number" then
                if info.ClientSequence > state.click.seq then state.click.seq = info.ClientSequence end
                state.click.acked = state.click.acked + 1
                state.click.lastAck = os.clock()
            end
        end))
    end
    local sinceAck = 0
    while state.alive do
        if Config.autoClick then
            state.click.seq = state.click.seq + 1
            if fireEvent(remote, { ClientSequence = state.click.seq, Auto = false, Source = "screen" }) then
                state.click.sent = state.click.sent + 1
                sinceAck = sinceAck + 1
            end
            if state.click.lastAck > 0 and os.clock() - state.click.lastAck < 3 then
                sinceAck = 0
                state.click.note = "actif"
            elseif sinceAck > 40 then
                -- aucun accuse : le serveur attend sans doute un numero plus grand que le notre
                state.click.seq = state.click.seq + 500
                sinceAck = 0
                state.click.note = "resync"
            end
            task.wait(1 / math.clamp(Config.clicksPerSecond or 8, 1, 30))
        else
            state.click.note = "off"
            task.wait(1)
        end
    end
end

-- auto craft : Pets.Owned[uuid] = { Name, Tier, Rarity, Equip, Locked }
local function craftGroups(data)
    local pets = data and data.Pets
    local owned = pets and pets.Owned
    if type(owned) ~= "table" then return nil, 0, 0 end
    local equipped = {}
    for _, id in ipairs(pets.Equipped or {}) do equipped[id] = true end
    local groups, count = {}, 0
    for id, pet in pairs(owned) do
        count = count + 1
        if type(pet) == "table" and not pet.Locked and not pet.Equip and not equipped[id] then
            local rarity = tostring(pet.Rarity or "")
            local skip = false
            for _, word in ipairs(Config.craftSkipRarity or {}) do
                if string.find(string.lower(rarity), string.lower(word), 1, true) then skip = true; break end
            end
            local tier = tostring(pet.Tier or "Normal")
            local machine = (Config.craftChain or {})[tier]
            if not skip and machine then
                -- meme nom + meme variante + meme mutation (le jeu demande des pets identiques)
                local key = tostring(pet.Name) .. "|" .. tier .. "|" .. tostring(pet.Mutation or "-")
                groups[key] = groups[key] or { machine = machine, ids = {} }
                table.insert(groups[key].ids, id)
            end
        end
    end
    return groups, count, tonumber(pets.StorageLimit) or 150
end

local function goToMachine(machine)
    if not Config.craftAtMachine or currentWorld() ~= "rift" then return false end
    local pos = (Config.machinesRift or {})[machine]
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not (pos and root) then return false end
    state.holdTp = true
    pcall(function() root.CFrame = CFrame.new(pos + Vector3.new(-6, 3, 0), pos) end)
    pcall(function() player:RequestStreamAroundAsync(pos, 5) end)
    task.wait(2)
    if firetouchinterest then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("BasePart") and obj.Name == machine and (obj.Position - pos).Magnitude < 40 then
                pcall(function() firetouchinterest(root, obj, 0); firetouchinterest(root, obj, 1) end)
            end
        end
    end
    return true
end

local function craftLoop()
    local remote = resolve("MachineService.RE.MachineCraftRequested")
    if not remote then state.craft.note = "remote craft absent"; return end
    while state.alive do
        if Config.autoCraft then
            local groups, count, limit = craftGroups(playerData())
            if not groups then
                state.craft.note = "donnees introuvables"
            elseif count < math.floor(limit * (Config.craftWhenFull or 0)) then
                state.craft.note = ("attente %d/%d"):format(count, limit)
            else
                local fired = 0
                local visited = {}
                for _, group in pairs(groups) do
                    local size = math.max(1, (Config.craftSizes or {})[group.machine] or Config.craftSize or 6)
                    if #group.ids >= size and not visited[group.machine] then
                        visited[group.machine] = true
                        if goToMachine(group.machine) then state.craft.note = "devant " .. group.machine end
                    end
                    while #group.ids >= size and state.alive do
                        local batch = {}
                        for k = 1, size do batch[k] = table.remove(group.ids) end
                        if fireEvent(remote, { PetIds = batch, Machine = group.machine, Action = "Craft" }) then
                            fired = fired + 1
                            state.craft.sent = state.craft.sent + 1
                        end
                        task.wait(1.5)
                    end
                end
                if next(visited) then state.holdTp = false end
                state.craft.note = fired > 0 and ("craft x" .. fired) or "rien a crafter"
            end
        else
            state.craft.note = "off"
        end
        task.wait(math.max(5, Config.craftEvery or 10))
    end
end

-- auto enchant : EnchantService.RF.Enchant({ PetId, Slot, RequestId })
local function enchantName(v)
    if type(v) == "string" then return v end
    if type(v) == "table" then return v.Name or v.Enchant or v.Id end
    return nil
end

local function slotEnchant(pet, slot)
    if type(pet) ~= "table" then return nil end
    local list = pet.Enchants or pet.EnchantSlots
    if type(list) == "table" then return enchantName(list[slot] or list[tostring(slot)]) end
    if slot == 1 then return enchantName(pet.Enchant) end
    return enchantName(pet["Enchant" .. slot] or pet.Enchant2 or pet.SecondEnchant)
end

local function keepEnchant(name)
    if not name then return false end
    local low = string.lower(name)
    for _, keep in ipairs(Config.enchantKeep or {}) do
        if string.lower(keep) == low then return true end
    end
    return false
end

local function resultEnchant(res)
    if type(res) ~= "table" then return enchantName(res) end
    return enchantName(res.Enchant) or enchantName(res.Result) or enchantName(res.New) or res.Name
end

-- machine d'enchant : le serveur repond "VisitEnchantMachine" si on n'est pas devant
local SPOTS_FILE = "polska_kaitun_spots.json"
local function loadSpot(name)
    if not (readfile and isfile) then return nil end
    local ok, data = pcall(function() return isfile(SPOTS_FILE) and HttpService:JSONDecode(readfile(SPOTS_FILE)) or nil end)
    local spot = ok and type(data) == "table" and data[name]
    if type(spot) == "table" and #spot == 3 then return Vector3.new(spot[1], spot[2], spot[3]) end
    return nil
end
local function saveSpot(name, pos)
    if not (writefile and readfile and isfile) then return end
    pcall(function()
        local data = isfile(SPOTS_FILE) and HttpService:JSONDecode(readfile(SPOTS_FILE)) or {}
        data[name] = { math.floor(pos.X), math.floor(pos.Y), math.floor(pos.Z) }
        writefile(SPOTS_FILE, HttpService:JSONEncode(data))
    end)
end

-- la vraie machine : la Part "Enchant" (le Model a un pivot faux, loin de la machine)
local function findEnchantMachine()
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    local best, bestDist
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj.Name == "Enchant" and obj:IsA("BasePart") then
            local d = root and (obj.Position - root.Position).Magnitude or 0
            if not bestDist or d < bestDist then best, bestDist = obj, d end
        end
    end
    if best then return best.Position, best end
    return nil
end

local function goToEnchantMachine()
    local partPos, part = findEnchantMachine()
    local stand
    if currentWorld() == "rift" then
        -- machine d'enchant d'Ice Age (monde 2)
        partPos = partPos and (partPos - Vector3.new(1711, 1355, 7052)).Magnitude < 300 and partPos or Vector3.new(1711, 1355, 7052)
        stand = partPos + Vector3.new(-11, 2, 0)
    else
        stand = Config.enchantMachinePos or loadSpot("enchant")
        if not stand and partPos then stand = partPos + Vector3.new(-11, -7, 0) end
    end
    if not stand then return false, "machine introuvable" end
    local char = player.Character
    local root = char and char:FindFirstChild("HumanoidRootPart")
    if not root then return false, "perso absent" end
    state.holdTp = true
    local look = partPos or (stand + Vector3.new(10, 0, 0))
    pcall(function() root.CFrame = CFrame.new(stand + Vector3.new(0, 3, 0), Vector3.new(look.X, stand.Y + 3, look.Z)) end)
    pcall(function() player:RequestStreamAroundAsync(stand, 5) end)
    task.wait(2.5)
    if not part then partPos, part = findEnchantMachine() end
    if part then
        saveSpot("enchant", stand)
        local model = part.Parent
        if fireproximityprompt and model then
            for _, prompt in ipairs(model:GetDescendants()) do
                if prompt:IsA("ProximityPrompt") then pcall(fireproximityprompt, prompt) end
            end
        end
        if firetouchinterest then
            local hrp = root
            pcall(function() firetouchinterest(hrp, part, 0); task.wait(0.1); firetouchinterest(hrp, part, 1) end)
        end
    end
    task.wait(0.5)
    return true, "devant la machine"
end

-- mode auto : EnchantService.RF.AutoStart({ Slot, PetId }) puis on surveille l'enchant du pet
-- EnchantService.RF.Claim() : recupere ce que l'auto-enchant a obtenu (sans argument)
local function claimEnchant()
    local remote = resolve("EnchantService.RF.Claim")
    if not remote then return nil end
    local ok, res = invoke(remote)
    if ok and res ~= nil and res ~= false and not (type(res) == "table" and res.Success == false) then
        state.enchant.claims = (state.enchant.claims or 0) + 1
        logLine("enchant claim -> " .. dumpValue(res))
    end
    return res
end

-- pendant l'auto, le pet quitte l'inventaire et part "dans l'enchanteur" : on le cherche aussi dans Data.Enchanting
local function findPetAnywhere(data, id)
    local owned = data and data.Pets and data.Pets.Owned
    if type(owned) == "table" and type(owned[id]) == "table" then return owned[id] end
    local function scan(t, depth)
        if type(t) ~= "table" or depth > 3 then return nil end
        if t.Id == id or t.PetId == id then return t end
        for _, v in pairs(t) do
            local hit = scan(v, depth + 1)
            if hit then return hit end
        end
        return nil
    end
    return scan(data and data.Enchanting, 0)
end

local function autoEnchantPass()
    local startRemote = resolve("EnchantService.RF.AutoStart")
    if not startRemote then state.enchant.note = "remote AutoStart absent"; return 30, false end
    if not state.enchant.freed then
        -- un pet peut etre reste dans l'enchanteur depuis un lancement precedent : on le recupere d'abord
        state.enchant.freed = true
        claimEnchant()
        task.wait(1)
    end
    local data = playerData()
    local pets = data and data.Pets
    if not (pets and type(pets.Owned) == "table") then state.enchant.note = "donnees introuvables"; return 5, false end
    local good, total = 0, 0
    for _, id in ipairs(pets.Equipped or {}) do
        if not state.alive then break end
        for slot = 1, math.max(1, Config.enchantSlots or 2) do
            local pet = pets.Owned[id]
            local current = slotEnchant(pet, slot)
            if slot > 1 and current == nil then
                -- slot pas debloque
            elseif keepEnchant(current) then
                good = good + 1
                total = total + 1
            else
                total = total + 1
                -- le jeu demande de confirmer le remplacement de l'enchant actuel : Replace = nom actuel
                local function startArgs(replace)
                    local args = { Slot = slot, PetId = id }
                    if replace then args.Replace = replace end
                    return args
                end
                local ok, res = invoke(startRemote, startArgs(current))
                logLine(("auto enchant start pet %s slot %d -> %s"):format(tostring(id):sub(1, 8), slot, dumpValue(res)))
                if ok and type(res) == "table" and res.Reason == "ConfirmReplace" then
                    ok, res = invoke(startRemote, startArgs(res.Enchant or current))
                end
                local refused = (not ok) or res == false or (type(res) == "table" and (res.Success == false or res.success == false))
                if refused and type(res) == "table" and res.Reason == "VisitEnchantMachine" then
                    local moved = goToEnchantMachine()
                    if not moved then state.info = "enchant : machine introuvable"; return 60, false end
                    ok, res = invoke(startRemote, startArgs(current))
                    if ok and type(res) == "table" and res.Reason == "ConfirmReplace" then
                        ok, res = invoke(startRemote, startArgs(res.Enchant or current))
                    end
                    refused = (not ok) or res == false or (type(res) == "table" and (res.Success == false or res.success == false))
                end
                if refused then
                    local why = type(res) == "table" and (res.Reason or res.Error or res.Message) or tostring(res)
                    state.enchant.note = "refuse (copie)"
                    state.info = "auto enchant refuse : " .. tostring(why) .. "  |  " .. dumpValue(res)
                    if setclipboard then pcall(setclipboard, state.info) end
                    return math.max(1, Config.enchantRetryMin or 10) * 60, true
                end
                -- on regarde l'enchant changer jusqu'a tomber sur un de la liste
                local last = current
                local untilAt = os.clock() + (Config.enchantAutoMax or 600)
                local found = false
                local nextShow = 0
                while state.alive and os.clock() < untilAt do
                    task.wait(0.3)
                    local fresh = playerData()
                    -- l'auto du jeu garde son resultat jusqu'au Claim : on guette un etat "fini / a reclamer"
                    local ench = fresh and fresh.Enchanting
                    if type(ench) == "table" then
                        if os.clock() >= nextShow then
                            nextShow = os.clock() + 3
                            state.info = "etat enchant : " .. dumpValue(ench)
                        end
                    end
                    local holder = fresh and findPetAnywhere(fresh, id)
                    local now = holder and slotEnchant(holder, slot)
                    if now and now ~= last then
                        last = now
                        state.enchant.rolls = state.enchant.rolls + 1
                        state.enchant.last = now
                        state.enchant.note = "auto pet " .. tostring(id):sub(1, 4) .. " slot " .. slot .. " (claims " .. tostring(state.enchant.claims or 0) .. ")"
                    end
                    if keepEnchant(now) then found = true; break end
                end
                -- le Claim rend le pet (et arrete l'auto) : toujours le faire avant de passer au pet suivant
                local claimed = claimEnchant()
                logLine("enchant fin pet " .. tostring(id):sub(1, 8) .. " -> trouve=" .. tostring(found) .. " claim=" .. dumpValue(claimed))
                task.wait(1.5)
                if found then good = good + 1 end
            end
        end
    end
    state.enchant.note = (good >= total) and ("ok " .. good .. " slots") or ("reroll " .. (total - good))
    return (good >= total) and 5 or 1, false
end

local function enchantLoop()
    local remote = resolve("EnchantService.RF.Enchant")
    if not remote then state.enchant.note = "remote enchant absent"; return end
    while state.alive do
        local pause = 2
        if Config.enchantOnlyAtStart and state.ready then
            state.holdTp = false
            state.enchant.note = "fini (" .. state.enchant.note .. ")"
            return
        end
        if Config.autoEnchant and Config.enchantMode == "auto" then
            state.holdTp = true
            local wait, refusedFlag = autoEnchantPass()
            if refusedFlag or string.find(state.enchant.note, "^ok") then state.holdTp = false end
            pause = wait
        elseif Config.autoEnchant then
            local data = playerData()
            local pets = data and data.Pets
            if not (pets and type(pets.Owned) == "table") then
                state.enchant.note = "donnees introuvables"
            else
                local todo, good = 0, 0
                local justVisited = false
                for _, id in ipairs(pets.Equipped or {}) do
                    local pet = pets.Owned[id]
                    for slot = 1, math.max(1, Config.enchantSlots or 2) do
                        if not state.alive then break end
                        local key = tostring(id) .. "#" .. slot
                        local current = slotEnchant(pet, slot)
                        local memo = state.enchant.done[key]
                        if current and memo and current ~= memo then state.enchant.done[key] = nil; memo = nil end
                        if slot > 1 and current == nil and not memo then
                            -- slot 2 pas encore debloque (2 % de chance par roll dans le jeu) : on ne l'envoie pas
                            good = good + 1
                        elseif keepEnchant(current) or (current == nil and memo) then
                            good = good + 1
                        elseif (state.enchant.blind[key] or 0) >= 3 then
                            state.enchant.note = "nom d'enchant illisible (slot " .. slot .. ")"
                            pause = 300
                            break
                        else
                            todo = todo + 1
                            local manualArgs = { PetId = id, Slot = slot, RequestId = HttpService:GenerateGUID(false) }
                            if current then manualArgs.Replace = current end
                            local ok, res = invoke(remote, manualArgs)
                            if ok and type(res) == "table" and res.Reason == "ConfirmReplace" then
                                manualArgs.Replace = res.Enchant or current
                                manualArgs.RequestId = HttpService:GenerateGUID(false)
                                ok, res = invoke(remote, manualArgs)
                            end
                            logLine(("enchant pet %s slot %d -> ok=%s reponse=%s"):format(tostring(id):sub(1, 8), slot, tostring(ok), dumpValue(res)))
                            if ok and res == nil then
                                -- pas de reponse : on regarde si l'enchant a change dans les donnees
                                task.wait(1)
                                local after = slotEnchant(pets.Owned[id], slot)
                                if after and after ~= current then res = { Enchant = after } end
                            end
                            local refused = (not ok) or res == nil or res == false or (type(res) == "table" and (res.Success == false or res.success == false))
                            if refused and type(res) == "table" and res.Reason == "VisitEnchantMachine" and not state.enchant.triedVisit then
                                state.enchant.triedVisit = true
                                local moved, why = goToEnchantMachine()
                                state.enchant.note = why
                                justVisited = moved
                                state.info = moved and "" or "enchant : machine introuvable. va devant une fois, le kaitun retiendra sa place."
                                pause = moved and 0.5 or 30
                                break
                            end
                            local reasonText = string.lower(tostring(type(res) == "table" and (res.Reason or res.Error or res.Message) or ""))
                            local transient = refused and (reasonText:find("busy") or reasonText:find("cooldown") or reasonText:find("wait")
                                or reasonText:find("progress") or reasonText:find("rate") or reasonText:find("pending") or reasonText:find("request"))
                            if transient and (state.enchant.transient or 0) < 5 then
                                state.enchant.transient = (state.enchant.transient or 0) + 1
                                state.enchant.note = "attente jeu (" .. reasonText .. ")"
                                state.info = "enchant attente " .. state.enchant.transient .. "/5 : " .. reasonText .. "  |  " .. dumpValue(res)
                                if setclipboard then pcall(setclipboard, state.info) end
                                pause = 3
                                break
                            end
                            if refused then
                                state.enchant.note = "refuse (copie)"
                                state.holdTp = false
                                state.enchant.triedVisit = false
                                local why = type(res) == "table" and (res.Reason or res.Error or res.Message) or nil
                                state.enchant.reason = ok and dumpValue(res) or tostring(res)
                                state.info = "enchant refuse : " .. (why and tostring(why) or "?") .. "  |  " .. state.enchant.reason
                                if setclipboard then pcall(setclipboard, state.info) end
                                pause = math.max(1, Config.enchantRetryMin or 10) * 60
                                break
                            end
                            state.enchant.rolls = state.enchant.rolls + 1
                            state.enchant.triedVisit = false
                            state.enchant.transient = 0
                            local got = resultEnchant(res)
                            if got then
                                state.enchant.last = got
                                state.enchant.blind[key] = 0
                                if keepEnchant(got) then state.enchant.done[key] = got end
                            elseif current == nil then
                                state.enchant.blind[key] = (state.enchant.blind[key] or 0) + 1
                            end
                            task.wait(math.max(0.2, Config.enchantDelay or 0.6))
                        end
                    end
                    if pause >= 3 or justVisited then break end
                end
                if todo == 0 then state.holdTp = false end
                if pause < 3 and not justVisited then
                    state.enchant.note = todo == 0 and ("ok " .. good .. " slots") or ("reroll " .. todo)
                    if todo > 0 then pause = 0.5 end
                end
            end
        else
            state.enchant.note = "off"
        end
        task.wait(pause)
    end
end

-- arbre de competences : on reessaie en boucle, l'ordre des prerequis se regle tout seul
local function skillLoop()
    local remote = resolve("SkillTreeService.RF.Unlock")
    if not remote then state.skills.note = "remote skill absent"; return end
    while state.alive do
        if Config.autoSkills then
            local data = playerData()
            local unlocked = data and data.SkillTree and data.SkillTree.Unlocked
            if type(unlocked) ~= "table" then
                state.skills.note = "donnees introuvables"
            else
                local missing, bought = 0, 0
                for _, name in ipairs(Config.skills or {}) do
                    if not unlocked[name] then
                        missing = missing + 1
                        local ok, res = invoke(remote, { Name = name })
                        if ok and res ~= false and not (type(res) == "table" and (res.Success == false or res.success == false)) then
                            bought = bought + 1
                            state.skills.bought = state.skills.bought + 1
                            logLine("skill " .. name .. " -> " .. dumpValue(res))
                        end
                        task.wait(0.5)
                    end
                end
                state.skills.note = missing == 0 and "tout pris" or (bought .. " pris, " .. (missing - bought) .. " restants")
            end
        else
            state.skills.note = "off"
        end
        task.wait(math.max(10, Config.skillsEvery or 30))
    end
end

-- zones du monde 2 : on demande au serveur de reverifier chaque ile tant qu'elle n'est pas a nous
local function riftZoneLoop()
    local remote = resolve("TimeRiftIslandService.RE.IslandUnlockRequested")
    if not remote then state.zones.note = "remote zone absent"; return end
    while state.alive do
        if Config.autoRiftZones and state.riftOpen then
            local data = playerData()
            local missing, have = {}, 0
            for _, island in ipairs(Config.riftZones or {}) do
                if zoneUnlocked(data, island) then
                    have = have + 1
                else
                    table.insert(missing, island)
                    -- "Purchase" achete l'ile (capture), "Recheck" fait reverifier le serveur
                    fireEvent(remote, { Action = "Purchase", Island = island })
                    task.wait(1)
                    fireEvent(remote, { Action = "Recheck", Island = island })
                    task.wait(1)
                end
            end
            state.zones.note = (#missing == 0) and "toutes" or (have .. " / " .. #(Config.riftZones or {}) .. " (demande : " .. table.concat(missing, ", ") .. ")")
        elseif not state.riftOpen then
            state.zones.note = "monde 2 pas ouvert"
        else
            state.zones.note = "off"
        end
        task.wait(math.max(15, Config.riftZonesEvery or 60))
    end
end

-- monde 2 : debloque la Time Rift des que possible
local function riftLoop()
    local remote = resolve("TimeRiftService.RE.UnlockRequested")
    if not remote then state.rift.note = "remote rift absent"; return end
    while state.alive do
        if Config.autoRift then
            local data = playerData()
            local worlds = data and data.Progression and data.Progression.UnlockedWorlds
            local n = 0
            if type(worlds) == "table" then for _ in pairs(worlds) do n = n + 1 end end
            if n >= 2 or state.worldSeen == "rift" then
                state.rift.note = "debloque"
                state.riftOpen = true
            else
                fireEvent(remote)
                state.rift.tries = state.rift.tries + 1
                state.rift.note = "essai " .. state.rift.tries
            end
        else
            state.rift.note = "off"
        end
        task.wait(math.max(15, Config.riftEvery or 60))
    end
end

local function waveLoop()
    local startR  = resolve("ColosseumService.RF.StartWaveDefense")
    local attackR = resolve("ColosseumService.RF.AttackOpponent")
    local claimR  = resolve("ColosseumService.RF.ClaimMinigameReward")
    local spawnedEvt = resolve("ColosseumService.RE.WaveDefenseOpponentSpawned")
    local overEvt    = resolve("ColosseumService.RE.WaveDefenseGameOver")
    if not (startR and attackR) then state.wave.note = "remotes colosseum absents"; return end

    local live = {}   -- id -> true
    if spawnedEvt then
        track(spawnedEvt.OnClientEvent:Connect(function(data)
            if type(data) == "table" and type(data.Id) == "number" then live[data.Id] = true
            elseif type(data) == "number" then live[data] = true end
        end))
    end
    local gameOver = false
    if overEvt then track(overEvt.OnClientEvent:Connect(function() gameOver = true end)) end

    while state.alive do
        if Config.autoWave and not state.wave.running then
            state.wave.running = true
            gameOver = false
            table.clear(live)
            local ok, res = invoke(startR)
            if ok and type(res) == "table" then
                if type(res.PendingSpawns) == "table" then
                    for _, e in ipairs(res.PendingSpawns) do if type(e) == "table" and e.Id then live[e.Id] = true end end
                end
                state.wave.note = "vague en cours"
                local idle = 0
                while state.alive and not gameOver and idle < 6 do
                    local any = false
                    for id in pairs(live) do
                        any = true
                        local aok, ares = invoke(attackR, id)
                        if aok and type(ares) == "table" and ares.Defeated then
                            live[id] = nil
                            state.wave.kills = state.wave.kills + 1
                        end
                        task.wait(Config.waveAttackDelay)
                    end
                    if not any then idle = idle + 1; task.wait(0.5) else idle = 0 end
                end
                state.wave.waves = state.wave.waves + 1
                if claimR then invoke(claimR) end
            else
                state.wave.note = "lancement refuse"
                task.wait(5)
            end
            state.wave.running = false
            task.wait(2)
        else
            if not Config.autoWave then state.wave.note = "off" end
            task.wait(1)
        end
    end
end

----------------------------------------------------------------------
-- perf
-- cpu saver : les boucles du jeu qui tournent a chaque image (effets, pets qui suivent, ui) sont mises en pause.
-- le kaitun n'utilise aucune de ces boucles : tout passe par les remotes et les donnees.
local frozen = {}
-- une connexion appartient au jeu si sa fonction vient d'un script du jeu (pas du kaitun)
local function isGameFunction(fn)
    if type(fn) ~= "function" then return true end
    local ok, src = pcall(debug.info, fn, "s")
    if not ok or type(src) ~= "string" then return true end
    return src:find("ReplicatedFirst", 1, true) or src:find("ReplicatedStorage", 1, true)
        or src:find("PlayerScripts", 1, true) or src:find("StarterPlayer", 1, true) or src:find("PlayerGui", 1, true)
end

local function freezeSignal(signal, onlyGame)
    local ok, list = pcall(getconnections, signal)
    local count = 0
    if ok and type(list) == "table" then
        for _, c in ipairs(list) do
            if not onlyGame or isGameFunction(c.Function) then
                local okDisable = pcall(function()
                    if c.Disable then c:Disable() else error("no disable") end
                end)
                if okDisable then table.insert(frozen, c); count = count + 1 end
            end
        end
    end
    return count
end

local function freezeGameLoops()
    if not (Config.cpuSaver and getconnections) then return end
    local loops, events = 0, 0
    if Config.freezeGameLoops then
        for _, signal in ipairs({ RunService.RenderStepped, RunService.Heartbeat, RunService.Stepped }) do
            loops = loops + freezeSignal(signal, true)
        end
    end
    if Config.freezeGameEvents then
        for _, path in ipairs({ "TapService.RE.TapResult", "EggService.RE.EggHatchResult", "RebirthService.RE.RebirthResult", "MachineService.RE.MachineCraftResult" }) do
            local remote = resolve(path)
            if remote then events = events + freezeSignal(remote.OnClientEvent, true) end
        end
    end
    logLine(("cpu saver : %d boucles et %d ecouteurs du jeu en pause"):format(loops, events))
end
local function unfreezeGameLoops()
    for _, c in ipairs(frozen) do pcall(function() c:Enable() end) end
    frozen = {}
end

local function applyPerf()
    if Config.maxOpti or Config.cpuSaver then Config.lowGfx = true; Config.mute = true end
    if Config.cpuSaver then
        if setfpscap and Config.saverFps then pcall(setfpscap, Config.saverFps) end
        -- plus d'animation du perso (rien n'est visible de toute facon)
        local function stopAnim(char)
            pcall(function()
                local animate = char:FindFirstChild("Animate")
                if animate then animate.Disabled = true end
                local hum = char:FindFirstChildOfClass("Humanoid")
                local animator = hum and hum:FindFirstChildOfClass("Animator")
                if animator then for _, t in ipairs(animator:GetPlayingAnimationTracks()) do t:Stop() end end
            end)
        end
        if player.Character then stopAnim(player.Character) end
        track(player.CharacterAdded:Connect(function(c) task.wait(1); stopAnim(c) end))
        if Config.hideOthers then
            -- les autres joueurs disparaissent seulement chez toi (rien ne change pour eux)
            local function drop(char) task.wait(1); pcall(function() char:Destroy() end) end
            local function watch(other)
                if other == player then return end
                if other.Character then task.spawn(drop, other.Character) end
                track(other.CharacterAdded:Connect(function(c) task.spawn(drop, c) end))
            end
            for _, other in ipairs(Players:GetPlayers()) do watch(other) end
            track(Players.PlayerAdded:Connect(watch))
        end
    end
    if Config.fpsCap and Config.fpsCap > 0 and setfpscap then pcall(setfpscap, Config.fpsCap) end
    if Config.disable3D then pcall(function() RunService:Set3dRenderingEnabled(false) end) end
    if Config.mute then pcall(function() SoundService.Volume = 0 end) end
    if Config.lowGfx then
        pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01 end)
        pcall(function() Lighting.GlobalShadows = false; Lighting.FogEnd = 9e9; Lighting.EnvironmentDiffuseScale = 0; Lighting.EnvironmentSpecularScale = 0 end)
        for _, fx in ipairs(Lighting:GetChildren()) do
            if fx:IsA("PostEffect") then pcall(function() fx.Enabled = false end)
            elseif fx:IsA("Atmosphere") then pcall(function() fx.Density = 0; fx.Haze = 0; fx.Glare = 0 end) end
        end
        pcall(function()
            local terrain = Workspace.Terrain
            terrain.Decoration = false
            terrain.WaterReflectance = 0; terrain.WaterTransparency = 1; terrain.WaterWaveSize = 0; terrain.WaterWaveSpeed = 0
        end)
        local function strip(i)
            if i:IsA("ParticleEmitter") or i:IsA("Trail") or i:IsA("Beam") or i:IsA("Smoke") or i:IsA("Fire") or i:IsA("Sparkles") then i.Enabled = false
            elseif i:IsA("Decal") or i:IsA("Texture") then i.Transparency = 1
            elseif i:IsA("BasePart") then i.Material = Enum.Material.Plastic; i.CastShadow = false end
        end
        task.spawn(function()
            local n = 0
            for _, i in ipairs(Workspace:GetDescendants()) do pcall(strip, i); n = n + 1; if n % 400 == 0 then task.wait() end end
        end)
        track(Workspace.DescendantAdded:Connect(function(i) pcall(strip, i) end))
    end
end
local function restorePerf()
    unfreezeGameLoops()
    if state.restoreView then pcall(state.restoreView) end
    pcall(function() RunService:Set3dRenderingEnabled(true) end)
    if setfpscap then pcall(setfpscap, 0) end
end

local function antiAfk()
    if not Config.antiAfk then return end
    track(player.Idled:Connect(function()
        pcall(function() VirtualUser:CaptureController(); VirtualUser:ClickButton2(Vector2.new()) end)
    end))
end

local rejoining = false
local function rejoin(reason)
    if rejoining or not state.alive or not Config.autoRejoin then return end
    rejoining = true
    state.status = "deconnecte : " .. tostring(reason)
    if webhookOk() then sendWebhook(embed("deconnecte", tostring(reason), 15548997)) end
    task.wait(5)
    if queue_on_teleport and readfile and isfile and isfile(Config.selfFile) then
        pcall(queue_on_teleport, 'loadstring(readfile("' .. Config.selfFile .. '"))()')
    end
    pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
    task.wait(15)
    rejoining = false
end
local function setupRejoin()
    track(GuiService.ErrorMessageChanged:Connect(function(m) if m and m ~= "" then task.spawn(rejoin, m) end end))
end

----------------------------------------------------------------------
-- HUD
local gui, cards = nil, {}
-- hud "dashboard" violet : plein ecran, cartes, RightShift ou le bouton rond pour voir le jeu
local THEME = {
    bg      = Color3.fromRGB(9, 7, 15),
    grid    = Color3.fromRGB(120, 90, 200),
    card    = Color3.fromRGB(19, 15, 30),
    stroke  = Color3.fromRGB(46, 36, 74),
    label   = Color3.fromRGB(138, 124, 172),
    value   = Color3.fromRGB(240, 236, 250),
    sub     = Color3.fromRGB(110, 98, 140),
    accent  = Color3.fromRGB(168, 112, 255),
    accent2 = Color3.fromRGB(110, 70, 220),
    warn    = Color3.fromRGB(255, 176, 96),
}

local function abbreviate(n)
    n = tonumber(n)
    if not n then return "-" end
    local suffixes = { "", "K", "M", "B", "T", "Qd", "Qn", "Sx", "Sp", "O", "N", "D", "Ud", "Dd", "Td" }
    local i = 1
    while math.abs(n) >= 1000 and i < #suffixes do n = n / 1000; i = i + 1 end
    if i == 1 then return tostring(math.floor(n)) end
    return string.format("%.2f%s", n, suffixes[i])
end

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k, v in pairs(props) do obj[k] = v end
    obj.Parent = parent
    return obj
end

local function corner(obj, r) make("UICorner", { CornerRadius = UDim.new(0, r) }, obj) end
local function strokeOf(obj, color, t) make("UIStroke", { Color = color, Thickness = t or 1, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, obj) end

local function build()
    gui = Instance.new("ScreenGui")
    gui.Name = "PolskaKaitun"; gui.ResetOnSpawn = false; gui.IgnoreGuiInset = true; gui.DisplayOrder = 999999
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    local parent = (gethui and gethui()) or CoreGui
    pcall(function() gui.Parent = parent end)
    if not gui.Parent then gui.Parent = player:WaitForChild("PlayerGui") end

    -- fond plein ecran + grille discrete
    local screen = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = THEME.bg, BorderSizePixel = 0, Visible = Config.hudVisible ~= false }, gui)
    local glow = make("Frame", { Size = UDim2.fromScale(0.7, 0.55), Position = UDim2.fromScale(0.15, -0.2), BackgroundColor3 = THEME.accent2, BackgroundTransparency = 0.86, BorderSizePixel = 0 }, screen)
    corner(glow, 600)
    make("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 1) }), Rotation = 90 }, glow)
    for x = 0, 48 do
        make("Frame", { Size = UDim2.new(0, 1, 1, 0), Position = UDim2.fromOffset(x * 44, 0), BackgroundColor3 = THEME.grid, BackgroundTransparency = 0.94, BorderSizePixel = 0 }, screen)
    end
    for y = 0, 28 do
        make("Frame", { Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, y * 44), BackgroundColor3 = THEME.grid, BackgroundTransparency = 0.94, BorderSizePixel = 0 }, screen)
    end

    -- contenu centre
    local content = make("Frame", { Size = UDim2.fromOffset(1120, 720), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }, screen)
    local scaler = make("UIScale", { Scale = 1 }, content)
    local function fit()
        local cam = Workspace.CurrentCamera
        local view = cam and cam.ViewportSize or Vector2.new(1920, 1080)
        scaler.Scale = math.clamp(math.min((view.X - 40) / 1120, (view.Y - 40) / 720), 0.45, 1)
    end
    fit()
    if Workspace.CurrentCamera then track(Workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(fit)) end

    local badge = make("Frame", { Size = UDim2.fromOffset(150, 26), BackgroundColor3 = THEME.accent2, BackgroundTransparency = 0.75, BorderSizePixel = 0 }, content)
    corner(badge, 13); strokeOf(badge, THEME.accent, 1)
    local dot = make("Frame", { Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(12, 10), BackgroundColor3 = THEME.accent, BorderSizePixel = 0 }, badge)
    corner(dot, 3)
    cards.badgeDot = dot
    cards.badge = make("TextLabel", { Size = UDim2.new(1, -26, 1, 0), Position = UDim2.fromOffset(24, 0), BackgroundTransparency = 1, Text = "AUTOFARM ACTIF", TextColor3 = THEME.accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, badge)

    make("TextLabel", { Size = UDim2.fromOffset(700, 44), Position = UDim2.fromOffset(0, 38), BackgroundTransparency = 1, Text = "Polska Kaitun", TextColor3 = THEME.value, Font = Enum.Font.GothamBlack, TextSize = 34, TextXAlignment = Enum.TextXAlignment.Left }, content)
    make("TextLabel", { Size = UDim2.fromOffset(700, 20), Position = UDim2.fromOffset(2, 82), BackgroundTransparency = 1, Text = "Tap Simulator Reborn  -  " .. player.Name, TextColor3 = THEME.label, Font = Enum.Font.Gotham, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left }, content)

    -- grille de cartes : seulement l'utile
    local defs = {
        { "status", "STATUT" }, { "elapsed", "TEMPS" },
        { "egg", "OEUF" }, { "hatch", "HATCHS" },
        { "coins", "PIECES" }, { "gems", "GEMMES" },
        { "secrets", "SECRETS" }, { "pets", "INVENTAIRE" },
        { "enchant", "ENCHANT" }, { "extra", "SHRINE / QUETES" },
    }
    local cardW, cardH, gap, top = 548, 86, 14, 124
    for idx, def in ipairs(defs) do
        local col = (idx - 1) % 2
        local row = math.floor((idx - 1) / 2)
        local card = make("Frame", { Size = UDim2.fromOffset(cardW, cardH), Position = UDim2.fromOffset(col * (cardW + gap + 10), top + row * (cardH + gap)), BackgroundColor3 = THEME.card, BackgroundTransparency = 0.08, BorderSizePixel = 0 }, content)
        corner(card, 12); strokeOf(card, THEME.stroke, 1)
        make("TextLabel", { Size = UDim2.fromOffset(400, 16), Position = UDim2.fromOffset(18, 14), BackgroundTransparency = 1, Text = def[2], TextColor3 = THEME.label, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, card)
        local icon = make("Frame", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -44, 0, 14), BackgroundColor3 = THEME.accent2, BackgroundTransparency = 0.8, BorderSizePixel = 0 }, card)
        corner(icon, 8); strokeOf(icon, THEME.stroke, 1)
        local idot = make("Frame", { Size = UDim2.fromOffset(6, 6), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundColor3 = THEME.accent, BorderSizePixel = 0 }, icon)
        corner(idot, 3)
        local value = make("TextLabel", { Size = UDim2.new(1, -80, 0, 30), Position = UDim2.fromOffset(18, 34), BackgroundTransparency = 1, Text = "-", TextColor3 = (def[1] == "status") and THEME.accent or THEME.value, Font = Enum.Font.GothamBold, TextSize = 22, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
        local sub = make("TextLabel", { Size = UDim2.new(1, -36, 0, 16), Position = UDim2.fromOffset(18, 64), BackgroundTransparency = 1, Text = "", TextColor3 = THEME.sub, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, TextTruncate = Enum.TextTruncate.AtEnd }, card)
        cards[def[1]] = value
        cards[def[1] .. "Sub"] = sub
    end

    -- bandeau d'info (refus, conseils) sous les cartes
    local infoTop = top + 5 * (cardH + gap)
    local infoBox = make("Frame", { Size = UDim2.fromOffset(cardW * 2 + gap + 10, 44), Position = UDim2.fromOffset(0, infoTop), BackgroundColor3 = THEME.card, BackgroundTransparency = 0.3, BorderSizePixel = 0, Visible = false }, content)
    corner(infoBox, 10); strokeOf(infoBox, THEME.warn, 1)
    cards.info = make("TextLabel", { Size = UDim2.new(1, -28, 1, 0), Position = UDim2.fromOffset(14, 0), BackgroundTransparency = 1, Text = "", TextColor3 = THEME.warn, Font = Enum.Font.Gotham, TextSize = 12, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left }, infoBox)
    cards.infoBox = infoBox

    make("TextLabel", { Size = UDim2.fromOffset(700, 16), Position = UDim2.fromOffset(0, 702), BackgroundTransparency = 1, Text = Config.cpuSaver and "POLSKA KAITUN   -   CPU SAVER   -   RightShift : ecran noir" or "POLSKA KAITUN   -   RightShift ou le bouton rond : voir le jeu", TextColor3 = THEME.sub, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left }, content)

    -- bouton rond en bas a droite : cache / montre le dashboard (reste visible)
    local toggle = Config.cpuSaver and nil or make("TextButton", { Size = UDim2.fromOffset(52, 52), AnchorPoint = Vector2.new(1, 1), Position = UDim2.new(1, -24, 1, -24), BackgroundColor3 = THEME.card, Text = "", AutoButtonColor = true, BorderSizePixel = 0, ZIndex = 10 }, gui)
    if toggle then
        corner(toggle, 14); strokeOf(toggle, THEME.accent, 1)
        local tdot = make("Frame", { Size = UDim2.fromOffset(8, 8), Position = UDim2.new(1, -12, 0, 4), BackgroundColor3 = THEME.accent, BorderSizePixel = 0, ZIndex = 11 }, toggle)
        corner(tdot, 4)
    end
    -- ecran noir du mode cpu saver (affiche quand le dashboard est cache)
    local black = make("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Visible = false, ZIndex = 20 }, gui)
    -- dashboard visible : on ne voit pas le jeu, donc on coupe la 3D et l'interface du jeu (gros gain cpu/gpu)
    local hiddenGuis = {}
    local function applyView(showDashboard, restoring)
        screen.Visible = showDashboard
        state.dashboardVisible = showDashboard
        local saver = Config.cpuSaver and not restoring
        black.Visible = saver and not showDashboard
        if not (Config.maxOpti or saver) then return end
        local hideGame = showDashboard or saver
        pcall(function() RunService:Set3dRenderingEnabled(not hideGame) end)
        local pg = player:FindFirstChildOfClass("PlayerGui")
        if not pg then return end
        if hideGame then
            for _, g in ipairs(pg:GetChildren()) do
                if g:IsA("ScreenGui") and g ~= gui and g.Enabled then g.Enabled = false; table.insert(hiddenGuis, g) end
            end
        else
            for _, g in ipairs(hiddenGuis) do pcall(function() g.Enabled = true end) end
            hiddenGuis = {}
        end
    end
    local function flip() applyView(not screen.Visible) end
    state.restoreView = function() applyView(false, true) end
    task.defer(applyView, Config.hudVisible ~= false)
    if toggle then track(toggle.MouseButton1Click:Connect(flip)) end
    track(UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and input.KeyCode == Enum.KeyCode.RightShift then flip() end
    end))
end

local rate = { coins = nil, gems = nil, at = 0, coinsPerSec = 0, gemsPerSec = 0 }
local function updateRates(coins, gems)
    local now = os.clock()
    if rate.at > 0 and now - rate.at >= 1 then
        local dt = now - rate.at
        if coins and rate.coins then rate.coinsPerSec = rate.coinsPerSec * 0.7 + math.max(0, (coins - rate.coins) / dt) * 0.3 end
        if gems and rate.gems then rate.gemsPerSec = rate.gemsPerSec * 0.7 + math.max(0, (gems - rate.gems) / dt) * 0.3 end
        rate.coins, rate.gems, rate.at = coins, gems, now
    elseif rate.at == 0 then
        rate.coins, rate.gems, rate.at = coins, gems, now
    end
end

local function refresh()
    if not gui then return end
    if Config.cpuSaver and state.dashboardVisible == false then return end
    local data = playerData()
    local cur = data and data.Currencies or {}
    local elapsed = math.max(1, os.time() - state.startedAt)

    cards.status.Text = state.status
    cards.statusSub.Text = state.ready and "preparation terminee" or ("etape : " .. state.setupStep)
    cards.elapsed.Text = os.date("!%H:%M:%S", elapsed)
    cards.elapsedSub.Text = "rebirths " .. tostring(state.rebirth.count) .. " (bouton " .. tostring(state.rebirth.index or "-") .. ")" .. "   -   clics " .. tostring(state.click.acked) .. "   -   monde 2 : " .. state.rift.note .. "   -   zones : " .. state.zones.note

    cards.egg.Text = tostring(state.hatch.egg)
    cards.eggSub.Text = state.hatch.where .. "   -   monde : " .. currentWorld() .. "   -   " .. tostring(state.travel)
    cards.hatch.Text = abbreviate(state.stats.hatched)
    cards.hatchSub.Text = string.format("%.0f / min   -   %s", state.stats.hatched / elapsed * 60, state.hatch.note)

    updateRates(tonumber(cur.Coins), tonumber(cur.Gems))
    cards.coins.Text = abbreviate(cur.Coins)
    cards.coinsSub.Text = abbreviate(rate.coinsPerSec) .. " / s"
    cards.gems.Text = abbreviate(cur.Gems)
    cards.gemsSub.Text = abbreviate(rate.gemsPerSec) .. " / s"

    cards.secrets.Text = tostring(state.stats.secrets)
    cards.secretsSub.Text = "dernier : " .. tostring(state.stats.lastSecret) .. "   -   mythiques " .. tostring(state.stats.mythics)

    local pets = data and data.Pets
    local owned = 0
    if pets and type(pets.Owned) == "table" then for _ in pairs(pets.Owned) do owned = owned + 1 end end
    cards.pets.Text = owned .. " / " .. tostring(pets and pets.StorageLimit or "?")
    cards.petsSub.Text = "craft " .. tostring(state.craft.sent) .. " (" .. state.craft.note .. ")   -   delete " .. state.delete.note

    cards.enchant.Text = state.enchant.note
    cards.enchantSub.Text = "rolls " .. tostring(state.enchant.rolls) .. "   -   dernier : " .. tostring(state.enchant.last)

    cards.extra.Text = state.shrine.note
    cards.extraSub.Text = "shrine x" .. tostring(state.shrine.used) .. "   -   quetes " .. tostring(state.quest.claimed) .. "   -   skills : " .. state.skills.note

    local hasInfo = state.info ~= nil and state.info ~= ""
    cards.infoBox.Visible = hasInfo
    cards.info.Text = state.info or ""
    cards.badge.Text = state.ready and "AUTOFARM ACTIF" or "PREPARATION"
end

-- lancement propre : on laisse chaque systeme faire son premier passage, dans l'ordre, avant la tp + hatch
local function waitFor(step, maxSeconds, done)
    state.setupStep = step
    local untilAt = os.clock() + maxSeconds
    while state.alive and os.clock() < untilAt do
        local ok, finished = pcall(done)
        if ok and finished then return true end
        task.wait(0.5)
    end
    return false
end

local function settled(note, patterns)
    note = string.lower(tostring(note or "-"))
    if note == "-" then return false end
    for _, p in ipairs(patterns) do
        if string.find(note, p, 1, true) == 1 then return true end
    end
    return false
end

local function setupPhase()
    if not Config.setupFirst then state.ready = true; return end
    waitFor("quetes", 15, function() return not Config.autoQuests or state.quest.note ~= "-" end)
    waitFor("shrine", 10, function() return not Config.autoShrine or state.shrine.note ~= "-" end)
    waitFor("auto-delete", 10, function() return not Config.autoDelete or state.delete.note ~= "-" end)
    waitFor("enchant", Config.setupEnchantMax or 180, function()
        return not Config.autoEnchant or settled(state.enchant.note, { "ok", "refuse", "nom d'enchant", "off", "donnees", "remote", "machine introuvable" })
    end)
    waitFor("craft", Config.setupCraftMax or 120, function()
        return not Config.autoCraft or settled(state.craft.note, { "attente", "rien", "off", "donnees", "remote" })
    end)
    state.setupStep = "fini"
    state.ready = true
    task.delay(5, freezeGameLoops)
end

-- secrets / mythiques : le jeu note l'heure du dernier hatch de chaque rarete (Statistics.RarityHatchAt)
local function rarityWatcher()
    local last = nil
    while state.alive do
        local data = playerData()
        local stats = data and data.Statistics
        local at = stats and stats.RarityHatchAt
        if type(at) == "table" then
            if last == nil then
                last = {}
                for k, v in pairs(at) do last[k] = v end
            else
                for rarity, when in pairs(at) do
                    if when ~= last[rarity] then
                        last[rarity] = when
                        local low = string.lower(tostring(rarity))
                        if low:find("secret") then state.stats.secrets = state.stats.secrets + 1 end
                        if low:find("myth") then state.stats.mythics = state.stats.mythics + 1 end
                        -- le nom : dans le dernier resultat de hatch, sinon le "rarest hatch" du jeu
                        local name, extra = nil, ""
                        for _, pet in ipairs(state.lastHatch or {}) do
                            if string.lower(pet.rarity):find(low:sub(1, 5), 1, true) then
                                name = pet.name
                                if pet.tier and pet.tier ~= "Normal" then extra = extra .. " " .. tostring(pet.tier) end
                                if pet.mutation then extra = extra .. " " .. tostring(pet.mutation) end
                                break
                            end
                        end
                        local rarest = stats.RarestHatch
                        if not name and type(rarest) == "table" and rarest.At == when then name = rarest.Name end
                        if low:find("secret") then state.stats.lastSecret = name or rarity end
                        local wanted = false
                        for _, r in ipairs(Config.webhookRarities or {}) do
                            if low:find(string.lower(r), 1, true) then wanted = true end
                        end
                        if wanted and Config.webhookSecrets and webhookOk() then
                            local color = low:find("secret") and 16766720 or (low:find("godly") and 15158332 or 10181046)
                            local chance = (type(rarest) == "table" and rarest.At == when and rarest.OneIn) and ("\n1 sur " .. abbreviate(rarest.OneIn)) or ""
                            local ping = (low:find("secret") and Config.webhookPing ~= "") and (Config.webhookPing .. " ") or ""
                            local text = ping .. "**" .. tostring(name or "?") .. extra .. "**  (" .. tostring(rarity) .. ")" .. chance
                                .. "\noeuf : " .. tostring(state.hatch.egg) .. "\nhatchs session : " .. state.stats.hatched .. "  |  secrets : " .. state.stats.secrets
                            task.spawn(function() sendWebhook(embed(tostring(rarity) .. " !", text, color)) end)
                        end
                    end
                end
            end
        end
        task.wait(2)
    end
end

local function statusLoop()
    local lastStatus = os.clock()
    while state.alive do
        if not rejoining then
            if not state.ready then state.status = "prepa : " .. state.setupStep
            elseif Config.autoHatch then state.status = "farm"
            elseif Config.autoWave then state.status = "wave"
            else state.status = "idle" end
        end
        refresh()
        local every = (Config.webhookStatusMin or 0) * 60
        if every > 0 and webhookOk() and os.clock() - lastStatus >= every then
            lastStatus = os.clock()
            task.spawn(function()
                sendWebhook(embed("status", ("hatch : %d  |  secrets : %d  |  mythiques : %d  |  rebirths : %d"):format(
                    state.stats.hatched, state.stats.secrets, state.stats.mythics, state.rebirth.count)))
            end)
        end
        task.wait(Config.cpuSaver and 1 or 0.5)
    end
end

----------------------------------------------------------------------
local function cleanup()
    state.alive = false
    for _, c in ipairs(connections) do pcall(function() c:Disconnect() end) end
    restorePerf()
    if gui then pcall(function() gui:Destroy() end) end
    getgenv().PolskaKaitunCleanup = nil
end
getgenv().PolskaKaitunCleanup = cleanup

-- ---------------------------------------------------------------- keys
local KEY_FILE = "polska_key.txt"
local function getHwid()
    local ok, id = pcall(function() return gethwid and gethwid() end)
    if ok and type(id) == "string" and #id >= 6 then return id end
    local ok2, cid = pcall(function() return game:GetService("RbxAnalyticsService"):GetClientId() end)
    if ok2 and type(cid) == "string" and #cid >= 6 then return cid end
    return "uid-" .. tostring(player.UserId)
end

local function checkKey(key)
    if not httpRequest then return false, "ton executor n'a pas de fonction request" end
    local url = Config.keyServer:gsub("/$", "") .. "/check?key=" .. HttpService:UrlEncode(key) .. "&hwid=" .. HttpService:UrlEncode(getHwid())
    local ok, res = pcall(function() return httpRequest({ Url = url, Method = "GET" }) end)
    if not ok or not res or not res.Body then return false, "serveur injoignable" end
    local okJson, data = pcall(function() return HttpService:JSONDecode(res.Body) end)
    if not okJson or type(data) ~= "table" then return false, "reponse illisible" end
    if data.ok then return true, data end
    return false, tostring(data.reason or "refusee")
end

local function keyPrompt(message)
    local done = Instance.new("BindableEvent")
    local result
    local screen = Instance.new("ScreenGui")
    screen.Name = "PolskaKey"; screen.IgnoreGuiInset = true; screen.DisplayOrder = 1000000; screen.ResetOnSpawn = false
    pcall(function() screen.Parent = (gethui and gethui()) or CoreGui end)
    if not screen.Parent then screen.Parent = player:WaitForChild("PlayerGui") end
    local bg = Instance.new("Frame", screen); bg.Size = UDim2.fromScale(1, 1); bg.BackgroundColor3 = Color3.fromRGB(9, 7, 15); bg.BorderSizePixel = 0
    local card = Instance.new("Frame", bg); card.Size = UDim2.fromOffset(420, 210); card.AnchorPoint = Vector2.new(0.5, 0.5); card.Position = UDim2.fromScale(0.5, 0.5)
    card.BackgroundColor3 = Color3.fromRGB(19, 15, 30); card.BorderSizePixel = 0
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 14)
    local stroke = Instance.new("UIStroke", card); stroke.Color = Color3.fromRGB(46, 36, 74)
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
        local key = box.Text:gsub("%s", ""):upper()
        info.Text = "verification..."
        local ok, why = checkKey(key)
        if ok then
            result = key
            done:Fire()
        else
            info.Text = "refusee : " .. tostring(why)
        end
    end)
    done.Event:Wait()
    screen:Destroy()
    return result
end

local function keyGate()
    if getgenv().PolskaKeyOk then return true end -- deja verifiee par le loader
    if Config.keyServer == "" then
        return not Config.keyRequired
    end
    local saved = getgenv().PolskaKey
    if (not saved or saved == "") and readfile and isfile then
        pcall(function() if isfile(KEY_FILE) then saved = readfile(KEY_FILE) end end)
    end
    local message
    if saved and saved ~= "" then
        local ok, why = checkKey(saved:gsub("%s", ""):upper())
        if ok then return true end
        message = "key refusee : " .. tostring(why)
    end
    local key = keyPrompt(message)
    if key and writefile then pcall(writefile, KEY_FILE, key) end
    return key ~= nil
end

if not keyGate() then
    state.alive = false
    warn("[polska] pas de key valide : le kaitun ne demarre pas")
    return
end

if Config.ui then build() end
applyPerf()
antiAfk()
setupRejoin()
task.spawn(statusLoop)
task.spawn(rarityWatcher)
task.spawn(hatchLoop)
task.spawn(rebirthLoop)
task.spawn(potionLoop)
task.spawn(waveLoop)
task.spawn(questLoop)
task.spawn(deleteLoop)
task.spawn(shrineLoop)
task.spawn(clickLoop)
task.spawn(craftLoop)
task.spawn(enchantLoop)
task.spawn(setupPhase)
task.spawn(riftLoop)
task.spawn(skillLoop)
task.spawn(riftZoneLoop)
getgenv().PolskaKaitunState = state
if webhookOk() then task.spawn(function() sendWebhook(embed("kaitun demarre", "farm sur tap simulator reborn")) end) end
