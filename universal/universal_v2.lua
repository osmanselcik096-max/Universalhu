-- =========================================================================
-- [ UNIVERSAL HUB v2 | ALL GAMES ]
-- [ ESP + CHAMS + AIMBOT + WORLD + MISC ]
-- =========================================================================

-- =========================================================================
-- [ SERVICES ]
-- =========================================================================

local Players        = game:GetService("Players")
local Workspace      = game:GetService("Workspace")
local RunService     = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService   = game:GetService("TweenService")
local Lighting       = game:GetService("Lighting")

local LP     = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

-- =========================================================================
-- [ LIBRARY INIT ]
-- =========================================================================

local repo = "https://raw.githubusercontent.com/deividcomsono/Obsidian/refs/heads/main/"
local Library     = loadstring(game:HttpGet(repo .. "Library.lua"))()
local ThemeManager = loadstring(game:HttpGet(repo .. "addons/ThemeManager.lua"))()
local SaveManager  = loadstring(game:HttpGet(repo .. "addons/SaveManager.lua"))()

Library.Font = Enum.Font.Roboto

local Options = Library.Options
local Toggles = Library.Toggles

local Window = Library:CreateWindow({
    Title = '<font color="#ff3030"><b>UNIVERSAL</b></font><font color="#ffffff"><b> HUB</b></font>',
    Center = true,
    AutoShow = true,
    TabPadding = 8,
    MenuFadeTime = 0.2,
    Size = UDim2.new(0, 650, 0, 520)
})

local Tabs = {
    Combat   = Window:AddTab("Combat",   "swords"),
    Visuals  = Window:AddTab("Visuals",  "eye"),
    World    = Window:AddTab("World",    "globe"),
    Misc     = Window:AddTab("Misc",     "activity"),
    Settings = Window:AddTab("Settings", "settings"),
}

-- =========================================================================
-- [ SETTINGS TAB ]
-- =========================================================================

local SettingsGroup = Tabs.Settings:AddLeftGroupbox("Interface", "settings")

SettingsGroup:AddLabel("Menu Keybind"):AddKeyPicker("MenuKeybind", {
    Text    = "MenuKeybind",
    Default = "RightShift",
    Mode    = "Toggle",
    Callback = function() Library:Toggle() end
})

-- =========================================================================
-- [ HELPERS ]
-- =========================================================================

local function lerpColor(a, b, t)
    return Color3.new(
        a.R + (b.R - a.R) * t,
        a.G + (b.G - a.G) * t,
        a.B + (b.B - a.B) * t
    )
end

-- Generic team check: tries Team property, then parent-folder match
local function areTeammates(charA, charB)
    if not charA or not charB then return false end
    local pA = Players:GetPlayerFromCharacter(charA)
    local pB = Players:GetPlayerFromCharacter(charB)
    if pA and pB then
        if pA.Team and pB.Team then
            return pA.Team == pB.Team
        end
    end
    -- Fallback: same parent folder = same team
    if charA.Parent and charB.Parent and charA.Parent == charB.Parent then
        return true
    end
    return false
end

local function isEnemy(char)
    local myChar = LP.Character
    if not myChar or not char then return false end
    if char == myChar then return false end
    return not areTeammates(myChar, char)
end

-- Universal character scanner: finds all humanoid models in Workspace
-- NPC tarama tablosu (ESP engine tarafından doldurulur, event tabanlı)
local npcList = {}

local function getAllEnemyCharacters()
    local result = {}

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if isEnemy(char) then
                    table.insert(result, char)
                end
            end
        end
    end

    for char in pairs(npcList) do
        if char and char.Parent then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                table.insert(result, char)
            end
        end
    end

    return result
end

local function getCharacterRoot(char)
    return char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
end

-- Pre-allocated raycast params (her çağrıda new() yaratmak lag yapar)
local _visParams = RaycastParams.new()
_visParams.FilterType = Enum.RaycastFilterType.Exclude

local function isVisible(target)
    if not target then return false end
    local myChar = LP.Character
    _visParams.FilterDescendantsInstances = myChar and {myChar} or {}
    local origin = Camera.CFrame.Position
    local dir    = target.Position - origin
    local result = Workspace:Raycast(origin, dir, _visParams)
    if not result then return true end
    local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
    if hitModel == target.Parent then return true end
    return false
end

-- =========================================================================
-- [ MISC TAB - MOVEMENT ]
-- =========================================================================

local MiscBox = Tabs.Misc:AddLeftGroupbox("Movement", "activity")

MiscBox:AddToggle("AutoBhop",    { Text = "Auto Bhop",     Default = false })
MiscBox:AddSlider("BhopSpeed",   { Text = "Bhop Speed",    Default = 18, Min = 5, Max = 30, Rounding = 1, Suffix = "spd" })
MiscBox:AddToggle("NoFallDamage",{ Text = "No Fall Damage", Default = false })
MiscBox:AddToggle("InfiniteJump",{ Text = "Infinite Jump",  Default = false })

local function getMoveDir()
    local dir = Vector3.zero
    local lv  = Camera.CFrame.LookVector
    local rv  = Camera.CFrame.RightVector
    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + lv end
    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - lv end
    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - rv end
    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + rv end
    return Vector3.new(dir.X, 0, dir.Z).Unit
end

-- Pre-allocated bhop raycast params
local _bhopParams = RaycastParams.new()
_bhopParams.FilterType = Enum.RaycastFilterType.Exclude

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not root or not hum then return end

        -- Bhop
        if Toggles.AutoBhop and Toggles.AutoBhop.Value then
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
                _bhopParams.FilterDescendantsInstances = {char}
                local ground = Workspace:Raycast(root.Position, Vector3.new(0, -4, 0), _bhopParams)
                if ground then hum.Jump = true end
            end
            local dir = getMoveDir()
            if dir.Magnitude > 0 then
                local spd = math.clamp(Options.BhopSpeed and Options.BhopSpeed.Value or 18, 5, 30)
                local vel = root.AssemblyLinearVelocity
                root.AssemblyLinearVelocity = Vector3.new(
                    vel.X + (dir.X * spd - vel.X) * 0.2,
                    vel.Y,
                    vel.Z + (dir.Z * spd - vel.Z) * 0.2
                )
            end
        end
    end)
end)

-- NoFallDamage: callback'te bir kez ayarla, her frame değil
local function applyNoFallDamage(enabled)
    local char = LP.Character
    if not char then return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    pcall(function()
        hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, not enabled)
        hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,     not enabled)
    end)
end

Toggles.NoFallDamage:OnChanged(function(v) applyNoFallDamage(v) end)

-- Karakter yenilenince tekrar uygula
LP.CharacterAdded:Connect(function(char)
    task.wait(0.5)
    if Toggles.NoFallDamage and Toggles.NoFallDamage.Value then
        applyNoFallDamage(true)
    end
end)

-- Infinite Jump
UserInputService.JumpRequest:Connect(function()
    if Toggles.InfiniteJump and Toggles.InfiniteJump.Value then
        local char = LP.Character
        if char then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
        end
    end
end)

-- =========================================================================
-- [ MISC TAB - SPEED / NOCLIP ]
-- =========================================================================

local MiscBox2 = Tabs.Misc:AddRightGroupbox("Speed & Fly", "activity")

MiscBox2:AddToggle("SpeedEnabled", { Text = "Speed Hack",  Default = false })
MiscBox2:AddSlider("SpeedAmount",  { Text = "Speed",       Default = 24, Min = 8, Max = 100, Rounding = 0 })
MiscBox2:AddToggle("FlyEnabled",   { Text = "Fly",         Default = false })
MiscBox2:AddSlider("FlySpeed",     { Text = "Fly Speed",   Default = 50, Min = 5, Max = 200, Rounding = 0 })
MiscBox2:AddToggle("NoclipEnabled",{ Text = "Noclip",      Default = false })

local flyBody = nil

RunService.Heartbeat:Connect(function()
    pcall(function()
        local char = LP.Character
        if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        local root = char:FindFirstChild("HumanoidRootPart")
        if not root or not hum then return end

        -- Speed
        if Toggles.SpeedEnabled and Toggles.SpeedEnabled.Value then
            hum.WalkSpeed = Options.SpeedAmount and Options.SpeedAmount.Value or 24
        else
            if hum.WalkSpeed > 50 then hum.WalkSpeed = 16 end
        end

        -- Fly
        if Toggles.FlyEnabled and Toggles.FlyEnabled.Value then
            if not flyBody or not flyBody.Parent then
                flyBody = Instance.new("BodyVelocity")
                flyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
                flyBody.Velocity = Vector3.zero
                flyBody.Parent = root
            end
            local dir = Vector3.zero
            local cf  = Camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
            if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
            local spd = Options.FlySpeed and Options.FlySpeed.Value or 50
            flyBody.Velocity = dir.Magnitude > 0 and dir.Unit * spd or Vector3.zero
            hum.PlatformStand = true
        else
            if flyBody and flyBody.Parent then flyBody:Destroy() flyBody = nil end
            if hum.PlatformStand then hum.PlatformStand = false end
        end
    end)
end)

-- Noclip: her frame GetDescendants yerine event tabanlı part cache
local _noclipParts = {}
local _noclipChar  = nil

local function buildNoclipCache(char)
    _noclipParts = {}
    _noclipChar  = char
    if not char then return end
    for _, p in ipairs(char:GetDescendants()) do
        if p:IsA("BasePart") then _noclipParts[#_noclipParts+1] = p end
    end
    char.DescendantAdded:Connect(function(d)
        if d:IsA("BasePart") then _noclipParts[#_noclipParts+1] = d end
    end)
end

LP.CharacterAdded:Connect(function(c) task.wait(0.2); buildNoclipCache(c) end)
if LP.Character then buildNoclipCache(LP.Character) end

RunService.Heartbeat:Connect(function()
    if not (Toggles.NoclipEnabled and Toggles.NoclipEnabled.Value) then return end
    if LP.Character ~= _noclipChar then return end
    for _, p in ipairs(_noclipParts) do
        pcall(function() if p.Parent then p.CanCollide = false end end)
    end
end)

-- =========================================================================
-- [ WORLD TAB ]
-- =========================================================================

local WorldBox = Tabs.World:AddLeftGroupbox("World", "globe")

-- Skyboxes
local skyboxtable = {
    ["Night"] = {
        SkyboxBk="rbxassetid://1514717643",SkyboxDn="rbxassetid://1514716936",
        SkyboxFt="rbxassetid://1514715910",SkyboxLf="rbxassetid://1514714945",
        SkyboxRt="rbxassetid://1514714011",SkyboxUp="rbxassetid://1514713374"
    },
    ["Deep Space"] = {
        SkyboxBk="http://www.roblox.com/asset/?id=159248188",SkyboxDn="http://www.roblox.com/asset/?id=159248183",
        SkyboxFt="http://www.roblox.com/asset/?id=159248187",SkyboxLf="http://www.roblox.com/asset/?id=159248173",
        SkyboxRt="http://www.roblox.com/asset/?id=159248192",SkyboxUp="http://www.roblox.com/asset/?id=159248176"
    },
    ["Ocean Sunset"] = {
        SkyboxBk="rbxassetid://17525686840",SkyboxDn="rbxassetid://17525678473",
        SkyboxFt="rbxassetid://17525684686",SkyboxLf="rbxassetid://17525680663",
        SkyboxRt="rbxassetid://17525682665",SkyboxUp="rbxassetid://17525674545"
    },
    ["Minecraft"] = {
        SkyboxBk="http://www.roblox.com/asset/?id=8735166756",SkyboxDn="http://www.roblox.com/asset/?id=8735166707",
        SkyboxFt="http://www.roblox.com/asset/?id=8735231668",SkyboxLf="http://www.roblox.com/asset/?id=8735166755",
        SkyboxRt="http://www.roblox.com/asset/?id=8735166751",SkyboxUp="http://www.roblox.com/asset/?id=8735166729"
    },
    ["Purple Nebula"] = {
        SkyboxBk="http://www.roblox.com/asset/?id=15983968922",SkyboxDn="http://www.roblox.com/asset/?id=15983966825",
        SkyboxFt="http://www.roblox.com/asset/?id=15983965025",SkyboxLf="http://www.roblox.com/asset/?id=15983967420",
        SkyboxRt="http://www.roblox.com/asset/?id=15983966246",SkyboxUp="http://www.roblox.com/asset/?id=15983964246"
    },
    ["Clouded Sky"] = {
        SkyboxBk="http://www.roblox.com/asset/?id=252760981",SkyboxDn="http://www.roblox.com/asset/?id=252763035",
        SkyboxFt="http://www.roblox.com/asset/?id=252761439",SkyboxLf="http://www.roblox.com/asset/?id=252760980",
        SkyboxRt="http://www.roblox.com/asset/?id=252760986",SkyboxUp="http://www.roblox.com/asset/?id=252762652"
    },
}
local skyNames = {}
for k in pairs(skyboxtable) do table.insert(skyNames, k) end
table.sort(skyNames)

local function UpdateSkybox(name)
    local data = skyboxtable[name]
    if not data then return end
    for _, v in ipairs(Lighting:GetChildren()) do
        if v:IsA("Atmosphere") or v:IsA("Clouds") then v:Destroy() end
    end
    local sky = Lighting:FindFirstChild("UniversalHub_Sky")
    if not sky then
        for _, v in ipairs(Lighting:GetChildren()) do
            if v:IsA("Sky") then v:Destroy() end
        end
        sky = Instance.new("Sky")
        sky.Name = "UniversalHub_Sky"
        sky.Parent = Lighting
    end
    sky.SkyboxBk = data.SkyboxBk; sky.SkyboxDn = data.SkyboxDn
    sky.SkyboxFt = data.SkyboxFt; sky.SkyboxLf = data.SkyboxLf
    sky.SkyboxRt = data.SkyboxRt; sky.SkyboxUp = data.SkyboxUp
    sky.SunTextureId = ""; sky.MoonTextureId = ""; sky.StarCount = 0
end

WorldBox:AddToggle("EnableSkybox", {
    Text = "Enable Skybox", Default = false,
    Callback = function(v) if v then UpdateSkybox(Options.SkyboxPreset.Value) end end
})
WorldBox:AddDropdown("SkyboxPreset", {
    Text = "Skybox Preset", Values = skyNames, Default = "Night",
    Callback = function(v) if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then UpdateSkybox(v) end end
})

-- Weather
local WeatherPart = nil
local function UpdateWeather(wType)
    if WeatherPart then WeatherPart:Destroy(); WeatherPart = nil end
    if wType == "None" then return end
    WeatherPart = Instance.new("Part")
    WeatherPart.Size = Vector3.new(200, 1, 200)
    WeatherPart.Transparency = 1; WeatherPart.Anchored = true
    WeatherPart.CanCollide = false; WeatherPart.Parent = Workspace.CurrentCamera
    local emitter = Instance.new("ParticleEmitter", WeatherPart)
    emitter.EmissionDirection = Enum.NormalId.Bottom; emitter.Enabled = true
    if wType == "Rain" then
        emitter.Texture = "rbxassetid://241868005"; emitter.Rate = 10000
        emitter.Size = NumberSequence.new(3, 5); emitter.Speed = NumberRange.new(80, 100)
        emitter.Lifetime = NumberRange.new(2, 2.5); emitter.Transparency = NumberSequence.new(0)
        emitter.Acceleration = Vector3.new(0, -50, 0); emitter.SpreadAngle = Vector2.new(0, 0)
    elseif wType == "Snow" then
        emitter.Texture = "rbxassetid://99851851"; emitter.Rate = 200
        emitter.Size = NumberSequence.new(0.25, 0.35); emitter.Speed = NumberRange.new(20, 30)
        emitter.Lifetime = NumberRange.new(5, 10); emitter.LightEmission = 0.5
        emitter.SpreadAngle = Vector2.new(50, 50)
    elseif wType == "Hell Fire" then
        emitter.Texture = "rbxassetid://242205518"; emitter.Rate = 400
        emitter.Color = ColorSequence.new(Color3.fromRGB(255,100,0), Color3.fromRGB(150,0,0))
        emitter.Size = NumberSequence.new(2, 4); emitter.Speed = NumberRange.new(40, 60)
        emitter.Lifetime = NumberRange.new(2, 3); emitter.RotSpeed = NumberRange.new(50, 100)
    end
end

WorldBox:AddDropdown("WeatherType", {
    Text = "Weather", Values = {"None","Rain","Snow","Hell Fire"}, Default = "None",
    Callback = function(v) UpdateWeather(v) end
})

RunService.RenderStepped:Connect(function()
    if WeatherPart then
        WeatherPart.CFrame = Workspace.CurrentCamera.CFrame * CFrame.new(0, 30, 0)
    end
end)

-- Lighting controls
local DefaultLighting = {
    ClockTime = Lighting.ClockTime, Brightness = Lighting.Brightness,
    Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient
}

WorldBox:AddToggle("EnableTime",      { Text = "Custom Time",       Default = false })
WorldBox:AddSlider("WorldClockTime",  { Text = "Clock Time",        Default = 14, Min = 0, Max = 24, Rounding = 1, Suffix = "h" })
WorldBox:AddToggle("EnableBrightness",{ Text = "Custom Brightness", Default = false })
WorldBox:AddSlider("WorldBrightness", { Text = "Brightness",        Default = 2, Min = 0, Max = 10, Rounding = 1 })
WorldBox:AddToggle("FullBright",      { Text = "Full Bright",       Default = false })

task.spawn(function()
    while task.wait(0.5) do
        pcall(function()
            if Toggles.FullBright and Toggles.FullBright.Value then
                Lighting.Brightness = 10
                Lighting.ClockTime  = 14
                Lighting.FogEnd     = 1e8
                Lighting.GlobalShadows = false
                Lighting.Ambient    = Color3.new(1,1,1)
                Lighting.OutdoorAmbient = Color3.new(1,1,1)
            else
                if Toggles.EnableTime and Toggles.EnableTime.Value then
                    Lighting.ClockTime = Options.WorldClockTime.Value
                else
                    Lighting.ClockTime = DefaultLighting.ClockTime
                end
                if Toggles.EnableBrightness and Toggles.EnableBrightness.Value then
                    Lighting.Brightness = Options.WorldBrightness.Value
                else
                    Lighting.Brightness = DefaultLighting.Brightness
                end
            end
            if Toggles.EnableSkybox and Toggles.EnableSkybox.Value then
                UpdateSkybox(Options.SkyboxPreset.Value)
            end
        end)
    end
end)

-- World Color (Night Mode)
local WorldColorBox = Tabs.World:AddRightGroupbox("World Color", "moon")
local WorldColorSettings = { Enabled = false, Color = Color3.fromRGB(255,255,255) }

WorldColorBox:AddToggle("WorldColorToggle", {
    Text = "Enable World Color", Default = false,
    Callback = function(state)
        WorldColorSettings.Enabled = state
        for _, obj in ipairs(Workspace:GetDescendants()) do
            pcall(function()
                if obj:IsA("BasePart") then
                    if state then
                        if not obj:GetAttribute("OrigColor") then obj:SetAttribute("OrigColor", obj.Color) end
                        obj.Color = WorldColorSettings.Color
                    else
                        if obj:GetAttribute("OrigColor") then obj.Color = obj:GetAttribute("OrigColor") end
                    end
                end
            end)
        end
    end
}):AddColorPicker("WorldColorPicker", {
    Default = Color3.fromRGB(255,255,255), Title = "World Color",
    Callback = function(c)
        WorldColorSettings.Color = c
        if WorldColorSettings.Enabled then
            for _, obj in ipairs(Workspace:GetDescendants()) do
                pcall(function() if obj:IsA("BasePart") then obj.Color = c end end)
            end
        end
    end
})

WorldColorBox:AddToggle("NoFog", {
    Text = "Remove Fog", Default = false,
    Callback = function(v)
        Lighting.FogEnd   = v and 1e8 or 100000
        Lighting.FogStart = v and 1e8 or 0
    end
})

-- Atmosphere
local AtmoBox = Tabs.World:AddRightGroupbox("Atmosphere", "globe")
AtmoBox:AddToggle("AtmoEnabled",     { Text = "Enable Atmosphere",     Default = false })
AtmoBox:AddSlider("AtmoDensity",     { Text = "Density",               Default = 0.3, Min = 0, Max = 1, Rounding = 2 })
AtmoBox:AddSlider("AtmoHaze",        { Text = "Haze",                  Default = 0, Min = 0, Max = 10, Rounding = 1 })
AtmoBox:AddToggle("ColorCorrEnabled",{ Text = "Color Correction",      Default = false })
AtmoBox:AddSlider("CCsaturation",    { Text = "Saturation",            Default = 0, Min = -1, Max = 1, Rounding = 2 })
AtmoBox:AddSlider("CCcontrast",      { Text = "Contrast",              Default = 0, Min = -1, Max = 1, Rounding = 1 })

task.spawn(function()
    while task.wait(0.2) do
        pcall(function()
            local atmo = Lighting:FindFirstChildOfClass("Atmosphere")
            if Toggles.AtmoEnabled and Toggles.AtmoEnabled.Value then
                if not atmo then atmo = Instance.new("Atmosphere", Lighting) end
                atmo.Density = Options.AtmoDensity and Options.AtmoDensity.Value or 0.3
                atmo.Haze    = Options.AtmoHaze and Options.AtmoHaze.Value or 0
            else
                if atmo then atmo:Destroy() end
            end
            local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect")
            if Toggles.ColorCorrEnabled and Toggles.ColorCorrEnabled.Value then
                if not cc then cc = Instance.new("ColorCorrectionEffect", Lighting) end
                cc.Enabled    = true
                cc.Saturation = Options.CCsaturation and Options.CCsaturation.Value or 0
                cc.Contrast   = Options.CCcontrast and Options.CCcontrast.Value or 0
            else
                if cc then cc.Enabled = false end
            end
        end)
    end
end)

-- =========================================================================
-- [ VISUAL TAB - ESP ]
-- =========================================================================

local VisualsESPBox = Tabs.Visuals:AddLeftGroupbox("ESP", "eye")

VisualsESPBox:AddToggle("ESPEnabled",   { Text = "ESP Enabled",  Default = false })
VisualsESPBox:AddToggle("ESPTeamCheck", { Text = "Team Check",   Default = true  })

VisualsESPBox:AddDropdown("ESPBoxType", {
    Text = "Box ESP", Values = {"2D Box","3D Box","Corner Box","Disabled"}, Default = "2D Box"
})
VisualsESPBox:AddLabel("Box Color A"):AddColorPicker("ESPBoxColorA", { Default = Color3.fromRGB(255,255,255), Title = "Box Color A" })
VisualsESPBox:AddLabel("Box Color B"):AddColorPicker("ESPBoxColorB", { Default = Color3.fromRGB(0,200,255),   Title = "Box Color B" })
VisualsESPBox:AddToggle("ESPFillGradient", { Text = "Fill Gradient", Default = false })
VisualsESPBox:AddLabel("Fill A"):AddColorPicker("ESPFillColorA", { Default = Color3.fromRGB(255,50,50), Title = "Fill A" })
VisualsESPBox:AddLabel("Fill B"):AddColorPicker("ESPFillColorB", { Default = Color3.fromRGB(50,50,255), Title = "Fill B" })

VisualsESPBox:AddToggle("ESPName",     { Text = "Name",           Default = false })
VisualsESPBox:AddLabel("Name Color"):AddColorPicker("ESPNameColor", { Default = Color3.new(1,1,1), Title = "Name Color" })

VisualsESPBox:AddToggle("ESPHealth",   { Text = "Health Bar",     Default = false })
VisualsESPBox:AddLabel("HP Top"):AddColorPicker("ESPHPTopColor",    { Default = Color3.fromRGB(0,255,0),   Title = "HP Top"    })
VisualsESPBox:AddLabel("HP Bot"):AddColorPicker("ESPHPBotColor",    { Default = Color3.fromRGB(255,0,0),   Title = "HP Bottom" })

VisualsESPBox:AddToggle("ESPDistance", { Text = "Distance",       Default = false })
VisualsESPBox:AddLabel("Dist Color"):AddColorPicker("ESPDistColor", { Default = Color3.new(1,1,1), Title = "Distance Color" })

VisualsESPBox:AddToggle("ESPTracer",   { Text = "Tracer",         Default = false })
VisualsESPBox:AddLabel("Tracer A"):AddColorPicker("ESPTracerColorA", { Default = Color3.new(1,1,1),           Title = "Tracer A" })
VisualsESPBox:AddLabel("Tracer B"):AddColorPicker("ESPTracerColorB", { Default = Color3.fromRGB(255,0,128),   Title = "Tracer B" })
VisualsESPBox:AddDropdown("ESPTracerOrigin", {
    Text = "Tracer Origin", Values = {"Bottom","Top","Center"}, Default = "Bottom"
})

VisualsESPBox:AddToggle("ESPSkeleton", { Text = "Skeleton",       Default = false })
VisualsESPBox:AddLabel("Skel A"):AddColorPicker("ESPSkelColorA", { Default = Color3.new(1,1,1),         Title = "Skel A" })
VisualsESPBox:AddLabel("Skel B"):AddColorPicker("ESPSkelColorB", { Default = Color3.fromRGB(0,255,255), Title = "Skel B" })

-- =========================================================================
-- [ ESP RENDER ENGINE ]
-- =========================================================================

local abs, huge, floor, clamp = math.abs, math.huge, math.floor, math.clamp
local sin, cos, pi = math.sin, math.cos, math.pi

local SKELETON_R15 = {
    {"Head","UpperTorso"},{"UpperTorso","LowerTorso"},
    {"UpperTorso","LeftUpperArm"},{"LeftUpperArm","LeftLowerArm"},{"LeftLowerArm","LeftHand"},
    {"UpperTorso","RightUpperArm"},{"RightUpperArm","RightLowerArm"},{"RightLowerArm","RightHand"},
    {"LowerTorso","LeftUpperLeg"},{"LeftUpperLeg","LeftLowerLeg"},{"LeftLowerLeg","LeftFoot"},
    {"LowerTorso","RightUpperLeg"},{"RightUpperLeg","RightLowerLeg"},{"RightLowerLeg","RightFoot"},
}
local SKELETON_R6 = {
    {"Head","Torso"},{"Torso","Left Arm"},{"Torso","Right Arm"},
    {"Torso","Left Leg"},{"Torso","Right Leg"},
}
local BOX_3D_EDGES = {
    {1,2},{2,4},{4,3},{3,1},{5,6},{6,8},{8,7},{7,5},{1,5},{2,6},{3,7},{4,8}
}

-- Hızlı 2D box: Head ve HumanoidRootPart kullanarak 8 köşeyi ekrana projeksiyon et
-- GetDescendants yerine sadece 2 part kullanır, çok daha hafif
local function getBox2D(char)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
    if not head and not root then return nil end

    -- Karakterin tahmini AABB'sini Head ve Root'tan hesapla
    local topPos    = head and (head.Position + Vector3.new(0, head.Size.Y * 0.5, 0))
                            or (root.Position + Vector3.new(0, 3, 0))
    local bottomPos = root and (root.Position - Vector3.new(0, root.Size.Y * 0.5 + 1, 0))
                            or (head.Position - Vector3.new(0, 5, 0))

    -- 8 köşeyi ekrana proyect et (basit yaklaşım: sadece center yükseklikten 2 nokta al)
    local topScreen,    topVis    = Camera:WorldToViewportPoint(topPos)
    local bottomScreen, bottomVis = Camera:WorldToViewportPoint(bottomPos)
    local rootScreen,   rootVis   = Camera:WorldToViewportPoint(
        root and root.Position or head.Position
    )

    if not topVis and not bottomVis and not rootVis then return nil end
    if topScreen.Z <= 0 and bottomScreen.Z <= 0 then return nil end

    -- Ekran koordinatları
    local screenTop    = Vector2.new(topScreen.X,    topScreen.Y)
    local screenBottom = Vector2.new(bottomScreen.X, bottomScreen.Y)

    local screenH = math.abs(screenBottom.Y - screenTop.Y)
    if screenH < 2 then return nil end  -- çok küçük, çizme

    -- Genişlik yüksekliğin yarısı kadar (humanoid oranı)
    local screenW = screenH * 0.45

    local minX = math.min(screenTop.X, screenBottom.X) - screenW * 0.5
    local minY = math.min(screenTop.Y, screenBottom.Y)
    local maxX = minX + screenW
    local maxY = math.max(screenTop.Y, screenBottom.Y)

    return minX, minY, maxX - minX, maxY - minY  -- x, y, w, h
end

-- 3D Box için AABB: sadece önemli parçalar taranır
local function get3DCorners(char)
    local head = char:FindFirstChild("Head")
    local root = char:FindFirstChild("HumanoidRootPart")
        or char:FindFirstChild("Torso")
        or char:FindFirstChild("UpperTorso")
    if not head and not root then return nil end

    local topPos    = head and (head.Position + Vector3.new(0, head.Size.Y * 0.5, 0))
                            or (root.Position + Vector3.new(0, 3, 0))
    local bottomPos = root and (root.Position - Vector3.new(0, root.Size.Y * 0.5 + 1, 0))
                            or (head.Position - Vector3.new(0, 5, 0))

    -- Yaklaşık karakter genişliği
    local halfW = (root and root.Size.X * 0.5) or 0.5

    local x0 = topPos.X - halfW; local x1 = topPos.X + halfW
    local y0 = bottomPos.Y;      local y1 = topPos.Y
    local z0 = topPos.Z - halfW; local z1 = topPos.Z + halfW

    local corners = {}
    local onScreen = false
    local signs = {
        {x0,y0,z0},{x1,y0,z0},{x0,y1,z0},{x1,y1,z0},
        {x0,y0,z1},{x1,y0,z1},{x0,y1,z1},{x1,y1,z1},
    }
    for i, s in ipairs(signs) do
        local sp, vis = Camera:WorldToViewportPoint(Vector3.new(s[1], s[2], s[3]))
        corners[i] = Vector2.new(sp.X, sp.Y)
        if vis then onScreen = true end
    end
    return corners, onScreen
end

-- Drawing helper
local function newLine(th)
    local l = Drawing.new("Line"); l.Thickness=th; l.Transparency=1; l.Visible=false; return l
end
local function newSquare(th, fill)
    local s = Drawing.new("Square"); s.Thickness=th; s.Filled=fill; s.Transparency=1; s.Visible=false; return s
end
local function newText()
    local t = Drawing.new("Text"); t.Outline=true; t.Font=1; t.Transparency=1; t.Visible=false; return t
end

-- Per-character drawing objects
local espObjects = {}

-- NPC tarama: her frame yerine event + interval ile
local npcScanTimer = 0

local function scanNPCs()
    npcList = {}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj ~= LP.Character then
            local hum  = obj:FindFirstChildOfClass("Humanoid")
            local root = obj:FindFirstChild("HumanoidRootPart")
            if hum and root and not Players:GetPlayerFromCharacter(obj) then
                npcList[obj] = true
            end
        end
    end
end

-- İlk tarama
task.spawn(scanNPCs)
-- Workspace değiştiğinde yeniden tara
Workspace.DescendantAdded:Connect(function(obj)
    if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
        if not Players:GetPlayerFromCharacter(obj) then
            npcList[obj] = true
        end
    end
end)
Workspace.DescendantRemoving:Connect(function(obj)
    if npcList[obj] then npcList[obj] = nil end
end)

local function addESPObj(char)
    if espObjects[char] then return end
    local obj = {}

    -- Box lines (gradient: 4 kenar × 4 segment = 16)
    obj.gradLines  = {}; for i=1,16 do obj.gradLines[i] = newLine(1.5) end
    obj.fillLines  = {}; for i=1,60 do obj.fillLines[i] = newLine(4)   end
    obj.cornerLines= {}; for i=1,8  do obj.cornerLines[i] = newLine(3) end
    obj.box3dLines = {}; for i=1,12 do obj.box3dLines[i]  = newLine(2) end

    -- Health bar: arka plan + bar
    obj.hpBg  = newLine(5)  -- kalın arka plan çizgi
    obj.hpBar = newLine(3)  -- gerçek hp çizgisi

    -- Labels
    obj.nameText = newText(); obj.nameText.Center = true;  obj.nameText.Size = 14
    obj.distText = newText(); obj.distText.Center = true;  obj.distText.Size = 13

    -- Tracer
    obj.tracerLine = newLine(1.5)

    -- Skeleton
    local isR15 = char:FindFirstChild("UpperTorso") ~= nil
    local bones = isR15 and SKELETON_R15 or SKELETON_R6
    obj.skelLines = {}
    obj.skelBones = {}
    for i, pair in ipairs(bones) do
        obj.skelLines[i] = newLine(1.5)
        obj.skelBones[i] = {char:FindFirstChild(pair[1]), char:FindFirstChild(pair[2])}
    end

    espObjects[char] = obj
end

local function removeESPObj(char)
    local obj = espObjects[char]
    if not obj then return end
    local function rm(d)
        if d then pcall(function() d:Remove() end) end
    end
    rm(obj.hpBg); rm(obj.hpBar)
    rm(obj.nameText); rm(obj.distText); rm(obj.tracerLine)
    for _, l in ipairs(obj.gradLines)   do rm(l) end
    for _, l in ipairs(obj.fillLines)   do rm(l) end
    for _, l in ipairs(obj.cornerLines) do rm(l) end
    for _, l in ipairs(obj.box3dLines)  do rm(l) end
    for _, l in ipairs(obj.skelLines)   do rm(l) end
    espObjects[char] = nil
end

local function hideESPObj(obj)
    if not obj then return end
    obj.hpBg.Visible = false; obj.hpBar.Visible = false
    obj.nameText.Visible = false; obj.distText.Visible = false
    obj.tracerLine.Visible = false
    for _, l in ipairs(obj.gradLines)   do l.Visible = false end
    for _, l in ipairs(obj.fillLines)   do l.Visible = false end
    for _, l in ipairs(obj.cornerLines) do l.Visible = false end
    for _, l in ipairs(obj.box3dLines)  do l.Visible = false end
    for _, l in ipairs(obj.skelLines)   do l.Visible = false end
end

local GRAD_STEPS = 4
local rotAngle = 0

local function drawGradientBox(obj, x, y, w, h, cA, cB, rotOff)
    local sides = {{x,y,x+w,y},{x+w,y,x+w,y+h},{x+w,y+h,x,y+h},{x,y+h,x,y}}
    local idx = 0
    for si, s in ipairs(sides) do
        local x1,y1,x2,y2 = s[1],s[2],s[3],s[4]
        for step = 0, GRAD_STEPS-1 do
            idx = idx + 1
            local tA = step/GRAD_STEPS; local tB = (step+1)/GRAD_STEPS
            local tMid = (((si-1)/4) + (tA/4) + rotOff) % 1
            local line = obj.gradLines[idx]
            if line then
                line.From  = Vector2.new(x1+(x2-x1)*tA, y1+(y2-y1)*tA)
                line.To    = Vector2.new(x1+(x2-x1)*tB, y1+(y2-y1)*tB)
                line.Color = lerpColor(cA, cB, tMid)
                line.Visible = true
            end
        end
    end
    for i = idx+1, #obj.gradLines do obj.gradLines[i].Visible = false end
end

local function drawFillGradient(obj, x, y, w, h, cA, cB, angle)
    local dx, dy = cos(angle), sin(angle)
    local cx, cy = x + w*.5, y + h*.5
    local maxDot = math.max((abs(dx)*w + abs(dy)*h)*.5, 1)
    local rows = math.clamp(floor(h*.8), 8, #obj.fillLines)
    local rowH = h / rows
    for i = 1, rows do
        local py = y + (i-.5)*rowH
        local t  = clamp(((x - cx)*dx + (py - cy)*dy)/maxDot*.5+.5, 0, 1)
        local l  = obj.fillLines[i]
        l.Color  = lerpColor(cA, cB, t)
        l.Thickness = math.clamp(rowH+1.5, 2, 6)
        l.From   = Vector2.new(x+1, py)
        l.To     = Vector2.new(x+w-1, py)
        l.Visible = true
    end
    for i = rows+1, #obj.fillLines do obj.fillLines[i].Visible = false end
end

RunService.RenderStepped:Connect(function(dt)
    rotAngle = (rotAngle + dt * 2) % (pi * 2)

    if not (Toggles.ESPEnabled and Toggles.ESPEnabled.Value) then
        for _, obj in pairs(espObjects) do hideESPObj(obj) end
        return
    end

    local teamCheck = Toggles.ESPTeamCheck and Toggles.ESPTeamCheck.Value
    local boxType   = Options.ESPBoxType and Options.ESPBoxType.Value or "2D Box"
    local cA        = Options.ESPBoxColorA and Options.ESPBoxColorA.Value or Color3.new(1,1,1)
    local cB        = Options.ESPBoxColorB and Options.ESPBoxColorB.Value or Color3.fromRGB(0,200,255)
    local fA        = Options.ESPFillColorA and Options.ESPFillColorA.Value or Color3.fromRGB(255,50,50)
    local fB        = Options.ESPFillColorB and Options.ESPFillColorB.Value or Color3.fromRGB(50,50,255)
    local doFill    = Toggles.ESPFillGradient and Toggles.ESPFillGradient.Value
    local camPos    = Camera.CFrame.Position
    local vp        = Camera.ViewportSize
    local rotOff    = rotAngle / (pi * 2)

    -- Aktif karakter listesi oluştur (sadece Players API)
    local activeChars = {}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LP and p.Character then
            local char = p.Character
            local hum  = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                if not teamCheck or isEnemy(char) then
                    addESPObj(char)
                    activeChars[char] = true
                end
            end
        end
    end
    -- NPC listesi (event tabanlı, her frame taranmaz)
    for char in pairs(npcList) do
        if char and char.Parent then
            local hum = char:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then
                addESPObj(char)
                activeChars[char] = true
            end
        else
            npcList[char] = nil
        end
    end

    -- Eski nesneleri temizle
    for char in pairs(espObjects) do
        if not activeChars[char] then removeESPObj(char) end
    end

    -- Çiz
    for char, obj in pairs(espObjects) do
        pcall(function()
            if not char or not char.Parent then
                removeESPObj(char); return
            end

            -- Hızlı 2D box hesabı
            local bx, by, bw, bh = getBox2D(char)
            local onscreen = bx ~= nil

            -- BOX
            if boxType ~= "Disabled" and onscreen then
                if boxType == "2D Box" then
                    for _, l in ipairs(obj.box3dLines)  do l.Visible=false end
                    for _, l in ipairs(obj.cornerLines) do l.Visible=false end
                    if doFill then
                        drawFillGradient(obj, bx, by, bw, bh, fA, fB, rotAngle)
                    else
                        for _, l in ipairs(obj.fillLines) do l.Visible=false end
                    end
                    drawGradientBox(obj, bx, by, bw, bh, cA, cB, rotOff)

                elseif boxType == "Corner Box" then
                    for _, l in ipairs(obj.gradLines)  do l.Visible=false end
                    for _, l in ipairs(obj.box3dLines) do l.Visible=false end
                    if doFill then
                        drawFillGradient(obj, bx, by, bw, bh, fA, fB, rotAngle)
                    else
                        for _, l in ipairs(obj.fillLines) do l.Visible=false end
                    end
                    local len = math.min(bw, bh) * .28
                    local corners = {
                        {Vector2.new(bx,by),         Vector2.new(bx+len,by)      },
                        {Vector2.new(bx,by),         Vector2.new(bx,by+len)      },
                        {Vector2.new(bx+bw-len,by),  Vector2.new(bx+bw,by)       },
                        {Vector2.new(bx+bw,by),      Vector2.new(bx+bw,by+len)   },
                        {Vector2.new(bx,by+bh),      Vector2.new(bx+len,by+bh)   },
                        {Vector2.new(bx,by+bh-len),  Vector2.new(bx,by+bh)       },
                        {Vector2.new(bx+bw-len,by+bh),Vector2.new(bx+bw,by+bh)  },
                        {Vector2.new(bx+bw,by+bh-len),Vector2.new(bx+bw,by+bh)  },
                    }
                    for i=1,8 do
                        obj.cornerLines[i].From  = corners[i][1]
                        obj.cornerLines[i].To    = corners[i][2]
                        obj.cornerLines[i].Color = lerpColor(cA,cB,(i-1)/8)
                        obj.cornerLines[i].Visible = true
                    end

                elseif boxType == "3D Box" then
                    for _, l in ipairs(obj.gradLines)   do l.Visible=false end
                    for _, l in ipairs(obj.fillLines)   do l.Visible=false end
                    for _, l in ipairs(obj.cornerLines) do l.Visible=false end
                    local c3d, on3d = get3DCorners(char)
                    if c3d and #c3d == 8 then
                        for i=1,12 do
                            local e = BOX_3D_EDGES[i]
                            obj.box3dLines[i].From    = c3d[e[1]]
                            obj.box3dLines[i].To      = c3d[e[2]]
                            obj.box3dLines[i].Color   = lerpColor(cA,cB,(i-1)/12)
                            obj.box3dLines[i].Visible = on3d
                        end
                    else
                        for _, l in ipairs(obj.box3dLines) do l.Visible=false end
                    end
                end
            else
                hideESPObj(obj); return
            end

            local midX = bx + bw * 0.5

            -- HEALTH BAR
            if Toggles.ESPHealth and Toggles.ESPHealth.Value then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    local hpFrac = clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
                    local hpTop  = Options.ESPHPTopColor and Options.ESPHPTopColor.Value or Color3.fromRGB(0,255,0)
                    local hpBot  = Options.ESPHPBotColor and Options.ESPHPBotColor.Value or Color3.fromRGB(255,0,0)
                    local barX   = bx - 5
                    -- Arka plan
                    obj.hpBg.From      = Vector2.new(barX, by)
                    obj.hpBg.To        = Vector2.new(barX, by + bh)
                    obj.hpBg.Color     = Color3.new(0,0,0)
                    obj.hpBg.Thickness = 4
                    obj.hpBg.Visible   = true
                    -- HP çizgisi (alttan yukarı)
                    obj.hpBar.From     = Vector2.new(barX, by + bh)
                    obj.hpBar.To       = Vector2.new(barX, by + bh * (1 - hpFrac))
                    obj.hpBar.Color    = lerpColor(hpBot, hpTop, hpFrac)
                    obj.hpBar.Thickness = 3
                    obj.hpBar.Visible  = true
                end
            else
                obj.hpBg.Visible = false; obj.hpBar.Visible = false
            end

            -- NAME
            if Toggles.ESPName and Toggles.ESPName.Value then
                local p    = Players:GetPlayerFromCharacter(char)
                local name = p and p.Name or char.Name
                local hum  = char:FindFirstChildOfClass("Humanoid")
                local hpStr = hum and string.format(" [%d]", floor(hum.Health)) or ""
                obj.nameText.Text     = name .. hpStr
                obj.nameText.Color    = Options.ESPNameColor and Options.ESPNameColor.Value or Color3.new(1,1,1)
                obj.nameText.Position = Vector2.new(midX, by - 16)
                obj.nameText.Visible  = true
            else
                obj.nameText.Visible = false
            end

            -- DISTANCE
            if Toggles.ESPDistance and Toggles.ESPDistance.Value then
                local root = getCharacterRoot(char)
                local dist = root and floor((camPos - root.Position).Magnitude) or 0
                obj.distText.Text     = dist .. "m"
                obj.distText.Color    = Options.ESPDistColor and Options.ESPDistColor.Value or Color3.new(1,1,1)
                obj.distText.Position = Vector2.new(midX, by + bh + 3)
                obj.distText.Visible  = true
            else
                obj.distText.Visible = false
            end

            -- TRACER
            if Toggles.ESPTracer and Toggles.ESPTracer.Value then
                local originMode = Options.ESPTracerOrigin and Options.ESPTracerOrigin.Value or "Bottom"
                local fromPos
                if originMode == "Top" then
                    fromPos = Vector2.new(vp.X/2, 0)
                elseif originMode == "Center" then
                    fromPos = Vector2.new(vp.X/2, vp.Y/2)
                else
                    fromPos = Vector2.new(vp.X/2, vp.Y)
                end
                local root = getCharacterRoot(char)
                local dist = root and clamp((camPos-root.Position).Magnitude/200, 0, 1) or 0
                local tA = Options.ESPTracerColorA and Options.ESPTracerColorA.Value or Color3.new(1,1,1)
                local tB = Options.ESPTracerColorB and Options.ESPTracerColorB.Value or Color3.fromRGB(255,0,128)
                obj.tracerLine.From    = fromPos
                obj.tracerLine.To      = Vector2.new(midX, by + bh)
                obj.tracerLine.Color   = lerpColor(tA, tB, dist)
                obj.tracerLine.Visible = true
            else
                obj.tracerLine.Visible = false
            end

            -- SKELETON
            if Toggles.ESPSkeleton and Toggles.ESPSkeleton.Value then
                local sA = Options.ESPSkelColorA and Options.ESPSkelColorA.Value or Color3.new(1,1,1)
                local sB = Options.ESPSkelColorB and Options.ESPSkelColorB.Value or Color3.fromRGB(0,255,255)
                for i, bone in ipairs(obj.skelBones) do
                    local pA, pB = bone[1], bone[2]
                    local l = obj.skelLines[i]
                    if pA and pB and pA.Parent and pB.Parent then
                        local spA, vA = Camera:WorldToViewportPoint(pA.Position)
                        local spB, vB = Camera:WorldToViewportPoint(pB.Position)
                        if vA or vB then
                            l.From    = Vector2.new(spA.X, spA.Y)
                            l.To      = Vector2.new(spB.X, spB.Y)
                            l.Color   = lerpColor(sA, sB, (i-1)/math.max(#obj.skelBones,1))
                            l.Visible = true
                        else
                            l.Visible = false
                        end
                    else
                        l.Visible = false
                    end
                end
            else
                for _, l in ipairs(obj.skelLines) do l.Visible = false end
            end
        end)
    end
end)

-- =========================================================================
-- [ VISUAL TAB - CHAMS ]
-- =========================================================================

local ChamsBox = Tabs.Visuals:AddRightGroupbox("Chams", "eye")

ChamsBox:AddToggle("ChamsEnabled",   { Text = "Enabled",   Default = false })
ChamsBox:AddToggle("ChamsTeamCheck", { Text = "Team Check",Default = true  })

ChamsBox:AddLabel("Visible Color"):AddColorPicker("ChamsColorVis", {
    Default = Color3.fromRGB(0,200,0), Title = "Visible Color"
})
ChamsBox:AddSlider("ChamsAlphaVis", { Text = "Fill Alpha (Visible)",   Default = 0.3, Min = 0, Max = 1, Rounding = 2 })

ChamsBox:AddDivider()

ChamsBox:AddLabel("Occluded Color"):AddColorPicker("ChamsColorOcc", {
    Default = Color3.fromRGB(200,0,0), Title = "Occluded Color"
})
ChamsBox:AddSlider("ChamsAlphaOcc", { Text = "Fill Alpha (Occluded)", Default = 0.3, Min = 0, Max = 1, Rounding = 2 })

task.spawn(function()
    -- CoreGui'ye parent olmayı dene, olmazsa Workspace'e koy
    local chamParent = game:GetService("CoreGui")
    pcall(function()
        local test = Instance.new("Folder", game:GetService("CoreGui"))
        test:Destroy()
    end)

    local ESPFolder = Instance.new("Folder")
    ESPFolder.Name = "UniversalHub_Chams"
    pcall(function() ESPFolder.Parent = game:GetService("CoreGui") end)
    if not ESPFolder.Parent then
        ESPFolder.Parent = Workspace
    end

    local Highlights = {}

    local function removeChams(char)
        if not char then return end
        local hl = Highlights[char]
        if hl then
            pcall(function() if hl.vis and hl.vis.Parent then hl.vis:Destroy() end end)
            pcall(function() if hl.occ and hl.occ.Parent then hl.occ:Destroy() end end)
            Highlights[char] = nil
        end
    end

    local rayP = RaycastParams.new()
    rayP.FilterType = Enum.RaycastFilterType.Exclude

    -- Visibility throttle: her frame raycast değil, 10 frame'de bir
    local _visCache    = {}   -- char -> bool
    local _visFrame    = 0
    local VIS_INTERVAL = 6    -- her 6 frame'de bir güncelle (~10Hz at 60fps)
    local _visFilter   = {}   -- reuse table, iki slot: [1]=myChar [2]=char

    local function charVisible(char)
        return _visCache[char] ~= false  -- nil veya true ise görünür sayılır
    end

    local function updateVisibility(char)
        local root = getCharacterRoot(char) or char:FindFirstChild("Head")
        if not root then _visCache[char] = true; return end
        local myChar = LP.Character
        _visFilter[1] = myChar
        _visFilter[2] = char
        rayP.FilterDescendantsInstances = _visFilter
        local origin = Camera.CFrame.Position
        local dir    = root.Position - origin
        local result = Workspace:Raycast(origin, dir, rayP)
        _visCache[char] = (result == nil)
    end

    RunService.Heartbeat:Connect(function()
        _visFrame = _visFrame + 1
        local enabled   = Toggles.ChamsEnabled and Toggles.ChamsEnabled.Value
        local teamCheck = Toggles.ChamsTeamCheck and Toggles.ChamsTeamCheck.Value

        local colVis  = Options.ChamsColorVis and Options.ChamsColorVis.Value or Color3.fromRGB(0,200,0)
        local colOcc  = Options.ChamsColorOcc and Options.ChamsColorOcc.Value or Color3.fromRGB(200,0,0)
        local alpVis  = Options.ChamsAlphaVis and Options.ChamsAlphaVis.Value or 0.3
        local alpOcc  = Options.ChamsAlphaOcc and Options.ChamsAlphaOcc.Value or 0.3

        -- Aktif düşman listesi oluştur
        local currentChars = {}
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LP and p.Character then
                local char = p.Character
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    if enabled and (not teamCheck or isEnemy(char)) then
                        currentChars[char] = true
                    end
                end
            end
        end

        -- Silinmesi gerekenleri temizle
        for char in pairs(Highlights) do
            if not currentChars[char] then removeChams(char); _visCache[char] = nil end
        end

        -- Throttle: her VIS_INTERVAL frame'de bir visibility güncelle
        if _visFrame % VIS_INTERVAL == 0 then
            for char in pairs(currentChars) do
                updateVisibility(char)
            end
        end

        -- Yeni highlight oluştur veya güncelle
        for char in pairs(currentChars) do
            if not Highlights[char] then
                -- Önce highlight oluştur, sonra adornee set et (sıra önemli)
                local hlVis = Instance.new("Highlight")
                hlVis.DepthMode          = Enum.HighlightDepthMode.Occluded
                hlVis.FillTransparency   = alpVis
                hlVis.OutlineTransparency = 1
                hlVis.FillColor          = colVis
                hlVis.OutlineColor       = colVis
                hlVis.Adornee            = char
                hlVis.Parent             = ESPFolder

                local hlOcc = Instance.new("Highlight")
                hlOcc.DepthMode          = Enum.HighlightDepthMode.AlwaysOnTop
                hlOcc.FillTransparency   = alpOcc
                hlOcc.OutlineTransparency = 1
                hlOcc.FillColor          = colOcc
                hlOcc.OutlineColor       = colOcc
                hlOcc.Adornee            = char
                hlOcc.Parent             = ESPFolder

                Highlights[char] = {vis = hlVis, occ = hlOcc}

                char.AncestryChanged:Connect(function(_, newP)
                    if not newP then removeChams(char) end
                end)
            end

            local hl   = Highlights[char]
            if not hl then continue end

            local seen = charVisible(char)

            -- Sadece değişince yaz (gereksiz renderer dirty işaretlemeyi önler)
            if hl.vis.FillColor ~= colVis then hl.vis.FillColor = colVis end
            if hl.vis.OutlineColor ~= colVis then hl.vis.OutlineColor = colVis end
            if hl.vis.FillTransparency ~= alpVis then hl.vis.FillTransparency = alpVis end
            if hl.vis.Enabled ~= seen then hl.vis.Enabled = seen end

            if hl.occ.FillColor ~= colOcc then hl.occ.FillColor = colOcc end
            if hl.occ.OutlineColor ~= colOcc then hl.occ.OutlineColor = colOcc end
            if hl.occ.FillTransparency ~= alpOcc then hl.occ.FillTransparency = alpOcc end
            if hl.occ.Enabled ~= (not seen) then hl.occ.Enabled = not seen end
        end
    end)

    Players.PlayerRemoving:Connect(function(p)
        task.defer(function()
            if p.Character then removeChams(p.Character) end
        end)
    end)
end)

-- =========================================================================
-- [ COMBAT TAB - AIMBOT (Universal) ]
-- =========================================================================

local CombatBox = Tabs.Combat:AddLeftGroupbox("Aimbot", "crosshair")

CombatBox:AddToggle("AimbotEnabled", { Text = "Aimbot",           Default = false }):AddKeyPicker("AimbotKey", {
    Text = "Hold Key", Default = "C", Mode = "Hold"
})
CombatBox:AddToggle("AimbotVisCheck",{ Text = "Visible Check",    Default = true  })
CombatBox:AddToggle("AimbotTeamCheck",{ Text = "Team Check",      Default = true  })
CombatBox:AddToggle("AimbotLock",    { Text = "Target Lock",      Default = false })
CombatBox:AddSlider("AimbotSmooth",  { Text = "Smoothness",       Default = 10, Min = 1, Max = 50, Rounding = 1 })
CombatBox:AddSlider("AimbotFOV",     { Text = "FOV Radius",       Default = 150, Min = 10, Max = 600, Rounding = 0 })
CombatBox:AddToggle("AimbotFOVCircle",{ Text = "Show FOV Circle", Default = true }):AddColorPicker("AimbotFOVColor", {
    Default = Color3.fromRGB(255,255,255), Title = "FOV Color"
})
CombatBox:AddDropdown("AimbotPart",  {
    Text = "Target Part",
    Values = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"},
    Default = "Head"
})

-- FOV Circle Drawing
local fovCircle = Drawing.new("Circle")
fovCircle.NumSides    = 128
fovCircle.Thickness   = 1
fovCircle.Filled      = false
fovCircle.Visible     = false
-- FOV circle güncelleme aimbot RenderStepped'e taşındı, ayrı connection yok

local aimbotLockedTarget = nil

local function findAimbotTarget()
    local screenCenter = Camera.ViewportSize / 2
    local fovRadius    = Options.AimbotFOV and Options.AimbotFOV.Value or 150
    local partName     = Options.AimbotPart and Options.AimbotPart.Value or "Head"
    local teamCheck    = Toggles.AimbotTeamCheck and Toggles.AimbotTeamCheck.Value
    local visCheck     = Toggles.AimbotVisCheck and Toggles.AimbotVisCheck.Value

    local bestDist = fovRadius
    local bestPart = nil

    for _, char in ipairs(getAllEnemyCharacters()) do
        if teamCheck and not isEnemy(char) then continue end

        local target = char:FindFirstChild(partName)
            or char:FindFirstChild("Head")
            or char:FindFirstChild("HumanoidRootPart")
        if not target then continue end

        local screenPos, onScreen = Camera:WorldToViewportPoint(target.Position)
        if not onScreen then continue end

        local dist = (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude
        if dist < bestDist then
            if visCheck and not isVisible(target) then continue end
            bestDist = dist
            bestPart = target
        end
    end
    return bestPart
end

-- Aimbot: Camera.CFrame'i doğrudan set et (CameraType Scriptable gerektirir)
local aimbotActive = false

RunService.RenderStepped:Connect(function()
    pcall(function()
        local enabled = Toggles.AimbotEnabled and Toggles.AimbotEnabled.Value
        fovCircle.Visible = enabled
            and Toggles.AimbotFOVCircle and Toggles.AimbotFOVCircle.Value

        if not enabled then
            if aimbotActive then
                -- Eski CameraType'a dön
                Camera.CameraType = Enum.CameraType.Custom
                aimbotActive = false
            end
            aimbotLockedTarget = nil
            return
        end

        -- Key kontrolü: Hold mode
        local keyHeld = false
        pcall(function()
            local kp = Options.AimbotKey
            if kp then
                keyHeld = kp:GetState()
            end
        end)

        if not keyHeld then
            if aimbotActive then
                Camera.CameraType = Enum.CameraType.Custom
                aimbotActive = false
            end
            if not (Toggles.AimbotLock and Toggles.AimbotLock.Value) then
                aimbotLockedTarget = nil
            end
            return
        end

        -- Lock-on: hedef hâlâ geçerli mi?
        if Toggles.AimbotLock and Toggles.AimbotLock.Value then
            if aimbotLockedTarget and aimbotLockedTarget.Parent then
                local char = aimbotLockedTarget.Parent
                local hum  = char:FindFirstChildOfClass("Humanoid")
                if not hum or hum.Health <= 0 then aimbotLockedTarget = nil end
            else
                aimbotLockedTarget = nil
            end
        else
            aimbotLockedTarget = nil
        end

        local target = aimbotLockedTarget or findAimbotTarget()
        if not target or not target.Parent then
            if aimbotActive then
                Camera.CameraType = Enum.CameraType.Custom
                aimbotActive = false
            end
            return
        end
        if Toggles.AimbotLock and Toggles.AimbotLock.Value then
            aimbotLockedTarget = target
        end

        -- Camera'yı Scriptable yap (sadece bir kez)
        if not aimbotActive then
            Camera.CameraType = Enum.CameraType.Scriptable
            aimbotActive = true
        end

        local smooth = math.max(Options.AimbotSmooth and Options.AimbotSmooth.Value or 10, 1)
        local currentCF = Camera.CFrame
        local goalCF    = CFrame.new(currentCF.Position, target.Position)
        Camera.CFrame   = currentCF:Lerp(goalCF, 1 / smooth)
    end)
end)

-- =========================================================================
-- [ COMBAT TAB - TRIGGERBOT ]
-- =========================================================================

local TriggerBox = Tabs.Combat:AddRightGroupbox("Triggerbot", "zap")

TriggerBox:AddToggle("TriggerEnabled", { Text = "Triggerbot",   Default = false })
TriggerBox:AddSlider("TriggerDelay",   { Text = "Delay",        Default = 0.05, Min = 0, Max = 1, Rounding = 3, Suffix = "s" })
TriggerBox:AddToggle("TriggerTeamCheck",{ Text = "Team Check",  Default = true })

task.spawn(function()
    local trigParams = RaycastParams.new()
    trigParams.FilterType = Enum.RaycastFilterType.Exclude
    while true do
        task.wait(Options.TriggerDelay and Options.TriggerDelay.Value or 0.05)
        pcall(function()
            if not (Toggles.TriggerEnabled and Toggles.TriggerEnabled.Value) then return end
            local char = LP.Character
            if not char then return end
            trigParams.FilterDescendantsInstances = {char}
            local result = Workspace:Raycast(
                Camera.CFrame.Position,
                Camera.CFrame.LookVector * 1000,
                trigParams
            )
            if not result then return end
            local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
            if not hitModel then return end
            local hum = hitModel:FindFirstChildOfClass("Humanoid")
            if not hum or hum.Health <= 0 then return end
            if Toggles.TriggerTeamCheck and Toggles.TriggerTeamCheck.Value then
                if not isEnemy(hitModel) then return end
            end
            -- Mouse1 click simülasyonu (executor uyumlu)
            local fired = false
            pcall(function() mouse1click(); fired = true end)
            if not fired then
                pcall(function() fireclickdetector(result.Instance) end)
            end
        end)
    end
end)

-- =========================================================================
-- [ COMBAT TAB - SILENT AIM (Universal hook method) ]
-- =========================================================================

local SilentBox = Tabs.Combat:AddLeftGroupbox("Silent Aim", "crosshair")

SilentBox:AddToggle("SilentAimEnabled", {
    Text = "Silent Aim",
    Default = false,
    Disabled = typeof(hookfunction) ~= "function",
    DisabledTooltip = "Not supported on your executor."
})
SilentBox:AddToggle("SilentAimTeamCheck", { Text = "Team Check",  Default = true })
SilentBox:AddSlider("SilentAimFOV",       { Text = "FOV Radius",  Default = 200, Min = 10, Max = 600, Rounding = 0 })
SilentBox:AddDropdown("SilentAimPart",    {
    Text = "Hit Part",
    Values = {"Head","HumanoidRootPart","UpperTorso","LowerTorso","Torso"},
    Default = "Head"
})

local silentTarget = nil

RunService.Heartbeat:Connect(function()
    if not (Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value) then
        silentTarget = nil; return
    end
    local screenCenter = Camera.ViewportSize / 2
    local fov    = Options.SilentAimFOV and Options.SilentAimFOV.Value or 200
    local part   = Options.SilentAimPart and Options.SilentAimPart.Value or "Head"
    local tc     = Toggles.SilentAimTeamCheck and Toggles.SilentAimTeamCheck.Value
    local bestD  = fov
    local bestP  = nil
    for _, char in ipairs(getAllEnemyCharacters()) do
        if tc and not isEnemy(char) then continue end
        local tp = char:FindFirstChild(part) or char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
        if not tp then continue end
        local sp, on = Camera:WorldToViewportPoint(tp.Position)
        if on then
            local d = (Vector2.new(sp.X,sp.Y) - screenCenter).Magnitude
            if d < bestD then bestD=d; bestP=tp end
        end
    end
    silentTarget = bestP
end)

-- Hook mouse ray for silent aim
-- Yöntem: WorldToScreenPoint'in tersini override et (executor uyumlu)
pcall(function()
    if typeof(hookfunction) ~= "function" then return end

    -- WorldToScreenPoint hook: bullet direction'ı değiştirmek için
    -- Çoğu oyun Camera:ScreenPointToRay veya ViewportPointToRay kullanır
    local oldScreenPointToRay
    local ok1 = pcall(function()
        oldScreenPointToRay = hookfunction(Camera.ScreenPointToRay, function(self, x, y, depth)
            if Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value
                and silentTarget and silentTarget.Parent then
                local origin = Camera.CFrame.Position
                local dir = (silentTarget.Position - origin).Unit
                local sp = Camera:WorldToViewportPoint(silentTarget.Position)
                return oldScreenPointToRay(self, sp.X, sp.Y, depth or 1)
            end
            return oldScreenPointToRay(self, x, y, depth)
        end)
    end)

    if not ok1 then
        -- Fallback: ViewportPointToRay hook
        pcall(function()
            local oldVPRay
            oldVPRay = hookfunction(Camera.ViewportPointToRay, function(self, x, y, depth)
                if Toggles.SilentAimEnabled and Toggles.SilentAimEnabled.Value
                    and silentTarget and silentTarget.Parent then
                    local sp = Camera:WorldToViewportPoint(silentTarget.Position)
                    return oldVPRay(self, sp.X, sp.Y, depth or 1)
                end
                return oldVPRay(self, x, y, depth)
            end)
        end)
    end
end)

-- =========================================================================
-- [ HIT SOUND ]
-- =========================================================================

local SoundBox = Tabs.Misc:AddLeftGroupbox("Hit Sound", "volume-2")
local SoundService = game:GetService("SoundService")

SoundBox:AddToggle("HitSoundEnabled", { Text = "Enable Hit Sound", Default = false })
SoundBox:AddSlider("HitSoundVolume",  { Text = "Volume",           Default = 1, Min = 0.1, Max = 5, Rounding = 1, Suffix = "x" })
SoundBox:AddDropdown("HitSoundPreset", {
    Text   = "Preset",
    Values = {"Neverlose","Skeet","Bell","Bubble","Rust","Coins"},
    Default = "Neverlose"
})

local HitSoundPresets = {
    ["Neverlose"] = "rbxassetid://139452805868562",
    ["Skeet"]     = "rbxassetid://83717596220569",
    ["Bell"]      = "rbxassetid://96481309571950",
    ["Bubble"]    = "rbxassetid://104824514322839",
    ["Rust"]      = "rbxassetid://1255040462",
    ["Coins"]     = "rbxassetid://5613553529",
}

local function PlayHitSound()
    if not (Toggles.HitSoundEnabled and Toggles.HitSoundEnabled.Value) then return end
    pcall(function()
        local id  = HitSoundPresets[Options.HitSoundPreset.Value] or HitSoundPresets["Neverlose"]
        local snd = Instance.new("Sound")
        snd.SoundId  = id
        snd.Volume   = Options.HitSoundVolume and Options.HitSoundVolume.Value or 1
        snd.Parent   = SoundService
        snd:Play()
        task.spawn(function() snd.Ended:Wait(); snd:Destroy() end)
    end)
end

-- Listen to any damage events universally
-- Hooks Humanoid.HealthChanged for all enemies
local function attachHitListener(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    local lastHp = hum.Health
    hum.HealthChanged:Connect(function(hp)
        if hp < lastHp and isEnemy(char) then
            PlayHitSound()
        end
        lastHp = hp
    end)
end

Players.PlayerAdded:Connect(function(p)
    p.CharacterAdded:Connect(function(c)
        task.wait(0.5)
        attachHitListener(c)
    end)
end)
for _, p in ipairs(Players:GetPlayers()) do
    if p ~= LP and p.Character then attachHitListener(p.Character) end
end

-- =========================================================================
-- [ MISC - ANTI-AFK ]
-- =========================================================================

local MiscBox3 = Tabs.Misc:AddRightGroupbox("Anti AFK", "activity")

MiscBox3:AddToggle("AntiAfk", { Text = "Anti AFK", Default = true })

task.spawn(function()
    local VirtualUser = game:GetService("VirtualUser")
    game:GetService("Players").LocalPlayer.Idled:Connect(function()
        if Toggles.AntiAfk and Toggles.AntiAfk.Value then
            if VirtualUser then
                VirtualUser:CaptureController()
                VirtualUser:ClickButton2(Vector2.new())
            end
        end
    end)
end)

-- =========================================================================
-- [ MISC - CUSTOM CAMERA ]
-- =========================================================================

local CamBox = Tabs.Misc:AddRightGroupbox("Camera", "video")

CamBox:AddToggle("CustomFOV", { Text = "Custom FOV", Default = false })
CamBox:AddSlider("FOVAmount",  { Text = "FOV",        Default = 90, Min = 50, Max = 120, Rounding = 0, Suffix = "°" })

local function applyFOV()
    if Toggles.CustomFOV and Toggles.CustomFOV.Value then
        Camera.FieldOfView = Options.FOVAmount and Options.FOVAmount.Value or 90
    else
        Camera.FieldOfView = 70  -- Roblox default
    end
end
Toggles.CustomFOV:OnChanged(applyFOV)
Options.FOVAmount:OnChanged(applyFOV)

-- =========================================================================
-- [ MISC - VEHICLE HACKS ]
-- =========================================================================

local VehicleBox = Tabs.Misc:AddLeftGroupbox("Vehicle", "activity")

VehicleBox:AddToggle("CarFlyEnabled",  { Text = "Car Fly",          Default = false }):AddKeyPicker("CarFlyKey", {
    Text = "Car Fly Key", Default = "F", Mode = "Toggle"
})
VehicleBox:AddSlider("CarFlySpeed",    { Text = "Car Fly Speed",    Default = 100, Min = 10, Max = 500, Rounding = 0 })

VehicleBox:AddDivider()

VehicleBox:AddToggle("CarSpeedEnabled",{ Text = "Car Speed Multiplier", Default = false })
VehicleBox:AddSlider("CarSpeedMult",   { Text = "Speed Multiplier",  Default = 2, Min = 1, Max = 10, Rounding = 1, Suffix = "x" })

VehicleBox:AddDivider()

VehicleBox:AddToggle("CarBoostEnabled", { Text = "Speed Boost",       Default = false }):AddKeyPicker("CarBoostKey", {
    Text = "Boost Key", Default = "LeftShift", Mode = "Hold"
})
VehicleBox:AddSlider("CarBoostPower",   { Text = "Boost Gücü",        Default = 120, Min = 20, Max = 500, Rounding = 0 })
VehicleBox:AddSlider("CarBoostCooldown",{ Text = "Boost Cooldown",    Default = 0, Min = 0, Max = 5, Rounding = 1, Suffix = "s" })

VehicleBox:AddDivider()

VehicleBox:AddToggle("BikeAngleEnabled",{ Text = "Bike Angle Lock",  Default = false })
VehicleBox:AddSlider("BikeAngleX",      { Text = "Tilt X (Pitch)",  Default = 0, Min = -45, Max = 45, Rounding = 1, Suffix = "°" })
VehicleBox:AddSlider("BikeAngleY",      { Text = "Tilt Y (Roll)",   Default = 0, Min = -45, Max = 45, Rounding = 1, Suffix = "°" })

-- Araç tespiti: LocalPlayer'ın oturduğu VehicleSeat'i bul
-- Cache: seat değişince event tetikler, her frame GetDescendants çalışmaz
local _cachedSeat = nil
local _cachedHum  = nil

local function refreshSeatCache()
    local char = LP.Character
    if not char then _cachedSeat = nil; _cachedHum = nil; return end
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then _cachedSeat = nil; _cachedHum = nil; return end
    _cachedHum = hum
    local sp = hum.SeatPart
    _cachedSeat = (sp and sp:IsA("VehicleSeat")) and sp or nil
end

-- SeatPart değişince cache'i güncelle
LP.CharacterAdded:Connect(function(char)
    task.wait(0.3)
    refreshSeatCache()
    local hum = char:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:GetPropertyChangedSignal("SeatPart"):Connect(refreshSeatCache)
    end
end)
if LP.Character then
    refreshSeatCache()
    local hum = LP.Character:FindFirstChildOfClass("Humanoid")
    if hum then
        hum:GetPropertyChangedSignal("SeatPart"):Connect(refreshSeatCache)
    end
end

local function getVehicleSeat()
    return _cachedSeat
end

-- Araç modelinin kök Part'ını bul (VehicleSeat'in parent Model'i)
local function getVehicleRoot(seat)
    if not seat then return nil end
    local model = seat:FindFirstAncestorOfClass("Model")
    if not model then return seat end
    return model.PrimaryPart or seat
end

-- Car Fly: BodyVelocity + BodyGyro ile aracı havada tut
local carFlyBody     = nil
local carFlyGyro     = nil
local carFlyAttached = nil  -- hangi part'a bağlı

local function detachCarFly()
    if carFlyBody  and carFlyBody.Parent  then carFlyBody:Destroy()  end
    if carFlyGyro  and carFlyGyro.Parent  then carFlyGyro:Destroy()  end
    carFlyBody     = nil
    carFlyGyro     = nil
    carFlyAttached = nil
end

RunService.Heartbeat:Connect(function()
    pcall(function()
        local seat       = getVehicleSeat()
        local root       = getVehicleRoot(seat)
        local flyEnabled = Toggles.CarFlyEnabled and Toggles.CarFlyEnabled.Value
        local flyActive  = Options.CarFlyKey and Options.CarFlyKey:GetState() or flyEnabled

        if not flyActive or not root then
            detachCarFly()
            return
        end

        -- Body nesnelerini root'a ekle (bir kez)
        if carFlyAttached ~= root then
            detachCarFly()
            carFlyBody = Instance.new("BodyVelocity")
            carFlyBody.MaxForce = Vector3.new(1e9, 1e9, 1e9)
            carFlyBody.Velocity = Vector3.zero
            carFlyBody.Parent   = root

            carFlyGyro = Instance.new("BodyGyro")
            carFlyGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            carFlyGyro.P         = 5000
            carFlyGyro.D         = 100
            carFlyGyro.CFrame    = root.CFrame
            carFlyGyro.Parent    = root

            carFlyAttached = root
        end

        local spd = Options.CarFlySpeed and Options.CarFlySpeed.Value or 100
        local dir = Vector3.zero
        local cf  = Camera.CFrame

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - cf.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + cf.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
            dir = dir + Vector3.new(0, 1, 0)
        end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then
            dir = dir - Vector3.new(0, 1, 0)
        end

        local vel = dir.Magnitude > 0 and (Vector3.new(dir.X, 0, dir.Z).Unit * spd + Vector3.new(0, dir.Y * spd, 0))
                                       or Vector3.zero
        -- Yatay hareket varsa o yönde, yoksa havada dur
        if dir == Vector3.zero then
            carFlyBody.Velocity = Vector3.zero
        else
            carFlyBody.Velocity = vel
        end

        -- Aracı düz tut (devrilmesin)
        carFlyGyro.CFrame = CFrame.new(root.Position, root.Position + cf.LookVector)
                          * CFrame.Angles(0, 0, 0)
    end)
end)

-- Car Speed Multiplier: VehicleSeat.MaxSpeed'i override et
task.spawn(function()
    local lastSeat     = nil
    local origMaxSpeed = nil
    local origTorque   = nil

    while true do
        task.wait(0.1)
        pcall(function()
            local seat    = getVehicleSeat()
            local enabled = Toggles.CarSpeedEnabled and Toggles.CarSpeedEnabled.Value
            local mult    = Options.CarSpeedMult and Options.CarSpeedMult.Value or 2

            if seat and seat ~= lastSeat then
                origMaxSpeed = seat.MaxSpeed
                origTorque   = seat.Torque
                lastSeat     = seat
            end

            if seat and enabled and origMaxSpeed then
                seat.MaxSpeed = origMaxSpeed * mult
                seat.Torque   = origTorque   * mult
            elseif lastSeat and origMaxSpeed and not enabled then
                pcall(function()
                    if lastSeat.Parent then
                        lastSeat.MaxSpeed = origMaxSpeed
                        lastSeat.Torque   = origTorque
                    end
                end)
            end

            if not seat then
                lastSeat     = nil
                origMaxSpeed = nil
                origTorque   = nil
            end
        end)
    end
end)

-- =========================================================================
-- [ CAR SPEED BOOST ]
-- Tuşa basınca aracın forward yönüne anlık velocity patlaması verir.
-- Cooldown ile spam önlenir.
-- =========================================================================
task.spawn(function()
    local boostCooldownTimer = 0
    local TICK = 0.05

    while true do
        task.wait(TICK)
        pcall(function()
            if not (Toggles.CarBoostEnabled and Toggles.CarBoostEnabled.Value) then return end

            -- Cooldown say
            if boostCooldownTimer > 0 then
                boostCooldownTimer = boostCooldownTimer - TICK
                return
            end

            -- Tuş basılı mı?
            local keyHeld = false
            pcall(function()
                if Options.CarBoostKey then
                    keyHeld = Options.CarBoostKey:GetState()
                end
            end)
            if not keyHeld then return end

            local seat = getVehicleSeat()
            local root = getVehicleRoot(seat)
            if not seat or not root or not root.Parent then return end

            local power = Options.CarBoostPower and Options.CarBoostPower.Value or 120
            local cd    = Options.CarBoostCooldown and Options.CarBoostCooldown.Value or 0

            -- Forward yönünde anlık velocity ekle
            local fwd = root.CFrame.LookVector
            root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + fwd * power

            boostCooldownTimer = cd
        end)
    end
end)

-- Bike Angle Lock: motosikletin devrilmesini engelle, pitch/roll ayarla
local bikeGyro     = nil
local bikeAttached = nil

RunService.Heartbeat:Connect(function()
    pcall(function()
        local seat    = getVehicleSeat()
        local root    = getVehicleRoot(seat)
        local enabled = Toggles.BikeAngleEnabled and Toggles.BikeAngleEnabled.Value

        if not enabled or not root then
            if bikeGyro and bikeGyro.Parent then bikeGyro:Destroy() end
            bikeGyro     = nil
            bikeAttached = nil
            return
        end

        if bikeAttached ~= root then
            if bikeGyro and bikeGyro.Parent then bikeGyro:Destroy() end
            bikeGyro = Instance.new("BodyGyro")
            bikeGyro.MaxTorque = Vector3.new(1e9, 1e9, 1e9)
            bikeGyro.P         = 8000
            bikeGyro.D         = 200
            bikeGyro.Parent    = root
            bikeAttached       = root
        end

        local ax = math.rad(Options.BikeAngleX and Options.BikeAngleX.Value or 0)
        local ay = math.rad(Options.BikeAngleY and Options.BikeAngleY.Value or 0)

        -- Mevcut yaw (Y ekseni rotasyonu) koru, sadece pitch ve roll kilitle
        local _, yaw, _ = root.CFrame:ToEulerAnglesYXZ()
        bikeGyro.CFrame = CFrame.new(root.Position)
                        * CFrame.Angles(0, yaw, 0)  -- yaw korunur
                        * CFrame.Angles(ax, 0, ay)  -- pitch & roll ayarlanır
    end)
end)

-- =========================================================================
-- [ BIKE UNIVERSE - AUTO FARM ]
-- =========================================================================
-- Nasıl çalışır:
--   Bisikleti yüksek kaldır → düşerken throttle'ı baslı tut → yere çarpma
--   anında tekrar kaldır. Her atlama/iniş cash combo tetikler.
--   VehicleSeat.ThrottleFloat + AssemblyLinearVelocity ile bisiklet hareket etmez,
--   sadece yukarı/aşağı gider. Bike bulduktan sonra tamamen AFK çalışır.
-- =========================================================================

local FarmBox = Tabs.Misc:AddLeftGroupbox("Bike Universe Farm", "activity")

FarmBox:AddToggle("BikeAutoFarm", { Text = "Auto Farm (Cash)",   Default = false })
FarmBox:AddSlider("FarmJumpHeight",{ Text = "Jump Height",       Default = 140, Min = 50, Max = 400, Rounding = 0, Suffix = " st" })
FarmBox:AddSlider("FarmCooldown",  { Text = "Jump Cooldown",     Default = 3,   Min = 0.5, Max = 10, Rounding = 1, Suffix = "s"   })
FarmBox:AddToggle("FarmAutoWheellie",{ Text = "Auto Wheelie",    Default = false })
FarmBox:AddToggle("FarmNoCrash",   { Text = "No Crash / Ragdoll",Default = false })
FarmBox:AddToggle("FarmGhostCops", { Text = "Ghost Cops",        Default = false })

-- -----------------------------------------------------------------------
-- Bisiklet bulma
-- -----------------------------------------------------------------------
local function findBike()
    local char = LP.Character
    if not char then return nil, nil end
    -- Önce SeatPart cache'den dene
    local seat = getVehicleSeat()
    if seat then
        local model = seat:FindFirstAncestorOfClass("Model")
        local root  = model and (model.PrimaryPart
                              or model:FindFirstChild("RootPart")
                              or model:FindFirstChild("MainFrame")
                              or model:FindFirstChildWhichIsA("BasePart"))
        return seat, root
    end
    -- Fallback: yakındaki VehicleSeat tara
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if hrp then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("VehicleSeat")
               and (obj.Position - hrp.Position).Magnitude < 10 then
                local model = obj:FindFirstAncestorOfClass("Model")
                local root  = model and (model.PrimaryPart
                                      or model:FindFirstChildWhichIsA("BasePart"))
                return obj, root
            end
        end
    end
    return nil, nil
end

-- -----------------------------------------------------------------------
-- AUTO WHEELIE: Heartbeat ile sürekli pitch kilitle
-- Her frame bisikletin pitch'ini –35° tutarsa wheelie animasyonu aktif kalır
-- -----------------------------------------------------------------------
local _wheelieConn = nil
local _wheelieSeat = nil
local _wheelieRoot = nil

local function startWheellie(seat, root)
    if _wheelieConn then _wheelieConn:Disconnect() end
    _wheelieSeat = seat
    _wheelieRoot = root

    _wheelieConn = RunService.Heartbeat:Connect(function()
        if not (Toggles.FarmAutoWheellie and Toggles.FarmAutoWheellie.Value) then
            if _wheelieConn then _wheelieConn:Disconnect(); _wheelieConn = nil end
            return
        end
        local r = _wheelieRoot
        if not r or not r.Parent then return end
        pcall(function()
            local _, yaw, _ = r.CFrame:ToEulerAnglesYXZ()
            -- pitch –40°: arka tekerlek yerde, ön havada
            r.CFrame = CFrame.new(r.Position)
                     * CFrame.Angles(0, yaw, 0)
                     * CFrame.Angles(math.rad(-40), 0, 0)
            r.AssemblyAngularVelocity = Vector3.zero
        end)
    end)
end

local function stopWheellie()
    if _wheelieConn then _wheelieConn:Disconnect(); _wheelieConn = nil end
    _wheelieSeat = nil; _wheelieRoot = nil
end

Toggles.FarmAutoWheellie:OnChanged(function(v)
    if not v then stopWheellie() end
end)

-- -----------------------------------------------------------------------
-- NO CRASH: Heartbeat ile ragdoll state'leri kapat +
-- bisiklet üzerindeki weld'lerin kırılmasını engelle
-- -----------------------------------------------------------------------
local _noCrashConn = nil

local function startNoCrash()
    if _noCrashConn then _noCrashConn:Disconnect() end
    _noCrashConn = RunService.Heartbeat:Connect(function()
        if not (Toggles.FarmNoCrash and Toggles.FarmNoCrash.Value) then return end
        local char = LP.Character
        if not char then return end
        local hum  = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        -- Ragdoll / FallingDown state'leri kapat
        pcall(function()
            hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll,      false)
            hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown,   false)
            hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp,     false)
        end)
        -- Eğer ragdoll'a girildiyse zorla çık
        local state = hum:GetState()
        if state == Enum.HumanoidStateType.Ragdoll
        or state == Enum.HumanoidStateType.FallingDown then
            pcall(function() hum:ChangeState(Enum.HumanoidStateType.Running) end)
        end
        -- Bisiklet üzerindeki weld'lerin Break'i hookla (executor destekliyorsa)
        local seat = getVehicleSeat()
        if seat then
            for _, c in ipairs(seat:GetDescendants()) do
                if c:IsA("WeldConstraint") or c:IsA("Weld") then
                    pcall(function()
                        if not c.Enabled then c.Enabled = true end
                    end)
                end
            end
        end
    end)
end

-- Başlangıçta ve toggle değişince uygula
startNoCrash()
Toggles.FarmNoCrash:OnChanged(function(v)
    if v then startNoCrash()
    else
        if _noCrashConn then _noCrashConn:Disconnect(); _noCrashConn = nil end
    end
end)

-- -----------------------------------------------------------------------
-- GHOST COPS: Polis NPC modellerini cache'le, her frame scan etme
-- -----------------------------------------------------------------------
local _copCache     = {}   -- part -> true
local _copScanTick  = 0

local function scanCops()
    _copCache = {}
    local keywords = {"cop","police","officer","sheriff","patrol","npc","agent","pursuit"}
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("BasePart") then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                local n = model.Name:lower()
                for _, kw in ipairs(keywords) do
                    if n:find(kw) then
                        _copCache[obj] = true
                        break
                    end
                end
            end
        end
    end
end

-- Başlangıçta bir kez tara, sonra her 3 saniyede tazele
task.spawn(function()
    while true do
        task.wait(3)
        if Toggles.FarmGhostCops and Toggles.FarmGhostCops.Value then
            scanCops()
        end
    end
end)

-- Workspace'e yeni model eklenince tazele
Workspace.DescendantAdded:Connect(function(obj)
    if Toggles.FarmGhostCops and Toggles.FarmGhostCops.Value then
        if obj:IsA("BasePart") then
            local model = obj:FindFirstAncestorOfClass("Model")
            if model then
                local n = model.Name:lower()
                local kws = {"cop","police","officer","sheriff","patrol","npc","agent"}
                for _, kw in ipairs(kws) do
                    if n:find(kw) then _copCache[obj] = true; break end
                end
            end
        end
    end
end)

-- Heartbeat: cache'deki partlara CanCollide = false uygula (hafif)
RunService.Heartbeat:Connect(function()
    if not (Toggles.FarmGhostCops and Toggles.FarmGhostCops.Value) then return end
    for part in pairs(_copCache) do
        if part and part.Parent then
            if part.CanCollide then
                pcall(function() part.CanCollide = false end)
            end
        else
            _copCache[part] = nil
        end
    end
end)

Toggles.FarmGhostCops:OnChanged(function(v)
    if v then scanCops()
    else
        -- CanCollide'ı geri yükle
        for part in pairs(_copCache) do
            pcall(function() if part and part.Parent then part.CanCollide = true end end)
        end
        _copCache = {}
    end
end)

-- -----------------------------------------------------------------------
-- ANA FARM DÖNGÜSÜ
-- -----------------------------------------------------------------------
task.spawn(function()
    local farmSeat = nil
    local farmRoot = nil

    while true do
        task.wait(0.1)

        if not (Toggles.BikeAutoFarm and Toggles.BikeAutoFarm.Value) then
            -- Farm kapandıysa temizle
            pcall(function()
                if farmSeat and farmSeat.Parent then farmSeat.ThrottleFloat = 0 end
            end)
            stopWheellie()
            farmSeat = nil; farmRoot = nil
            task.wait(0.5)
            continue
        end

        -- Bisiklet geçerli mi kontrol et
        if not farmSeat or not farmSeat.Parent then
            farmSeat, farmRoot = findBike()
            if not farmSeat then
                task.wait(2)
                farmSeat, farmRoot = findBike()
                if not farmSeat then task.wait(3); continue end
            end
        end

        local jumpH    = Options.FarmJumpHeight and Options.FarmJumpHeight.Value or 140
        local cooldown = Options.FarmCooldown   and Options.FarmCooldown.Value   or 3

        -- 1) Bisiklete otur
        pcall(function()
            local char = LP.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum and farmSeat.Occupant ~= hum then
                    farmSeat:Sit(hum)
                end
            end
        end)
        task.wait(0.2)

        -- 2) Bisikleti yukarı kaldır
        pcall(function()
            if farmRoot and farmRoot.Parent then
                farmRoot.CFrame = farmRoot.CFrame + Vector3.new(0, jumpH, 0)
                farmRoot.AssemblyLinearVelocity  = Vector3.new(0, -2, 0)
                farmRoot.AssemblyAngularVelocity = Vector3.zero
            end
        end)

        -- 3) Throttle bas + wheelie başlat
        pcall(function()
            if farmSeat and farmSeat.Parent then
                farmSeat.ThrottleFloat = 1
            end
        end)
        if Toggles.FarmAutoWheellie and Toggles.FarmAutoWheellie.Value then
            startWheellie(farmSeat, farmRoot)
        end

        -- 4) Cooldown (düşüş + yerde bekleme)
        task.wait(cooldown)

        -- 5) Throttle sıfırla
        pcall(function()
            if farmSeat and farmSeat.Parent then
                farmSeat.ThrottleFloat = 0
            end
        end)
    end
end)

-- =========================================================================
-- [ BIKE UNIVERSE - AUTO RIDE ]
-- Highway'de şerit takibi yaparak sürer, trafik araçlarından kaçar.
-- Görüntüden: geniş düz highway, 2-3 şerit, trafik araçları var.
-- Strateji:
--   • 5 noktalı fan ray (sol90°→sağ90°) ile trafik/duvar tespiti
--   • Şerit bazlı kaçınma: sola/sağa yumuşak steer
--   • Yol dışı tespiti: alttan aşağı ray atar, asphalt yoksa döner
--   • Sıkışma kurtarma: geri + ters dönüş
-- =========================================================================

FarmBox:AddDivider()
FarmBox:AddToggle("BikeAutoRide",    { Text = "🏍 Auto Ride",          Default = false })
FarmBox:AddSlider("AutoRideThrottle",{ Text = "Hız",                   Default = 1,  Min = 0.1, Max = 1,  Rounding = 2 })
FarmBox:AddSlider("AutoRideReact",   { Text = "Reaksiyon Mesafesi",    Default = 18, Min = 5,   Max = 60, Rounding = 0, Suffix = " st" })

task.spawn(function()
    local rp = RaycastParams.new()
    rp.FilterType = Enum.RaycastFilterType.Exclude

    -- Yol tespiti için ayrı params (sadece terrain/road kontrol eder)
    local roadRp = RaycastParams.new()
    roadRp.FilterType = Enum.RaycastFilterType.Exclude

    local seat, root = nil, nil
    local stuckT   = 0
    local stuckDir = 1      -- sıkışma kurtarma yönü
    local lastPos  = nil
    local steerSmooth = 0   -- smoothed steer değeri (titreme önler)

    -- Fan ray: bisikletin önüne belirli açılarda ray at
    -- açılar: -90, -45, -20, 0, +20, +45, +90 (sol=negatif, sağ=pozitif)
    local ANGLES = {-90, -50, -22, 0, 22, 50, 90}
    -- Her açı için tehdit skoru (sağ=+, sol=- steer ister)
    local WEIGHTS = { 0.9,  0.7,  0.4, 0, -0.4, -0.7, -0.9}

    local function castFan(origin, cf, dist)
        local scores = {}
        rp.FilterDescendantsInstances = {root, LP.Character}
        for i, ang in ipairs(ANGLES) do
            local dir = (cf * CFrame.Angles(0, math.rad(ang), 0)).LookVector
            local hit = Workspace:Raycast(origin + dir * 1.5, dir * dist, rp)
            -- Ne kadar yakınsa o kadar tehditkar
            local threat = 0
            if hit then
                -- Zemin değil, bir obje (araba, duvar vb.)
                -- Altında olup olmadığını kontrol et
                if math.abs(hit.Normal.Y) < 0.8 then  -- yatay normal = duvar/araç
                    threat = 1 - (hit.Distance / dist)
                end
            end
            scores[i] = threat
        end
        return scores
    end

    -- Yol kontrolü: bisikletin altında yol var mı?
    local function onRoad()
        if not root or not root.Parent then return true end
        roadRp.FilterDescendantsInstances = {root, LP.Character}
        local hit = Workspace:Raycast(root.Position, Vector3.new(0, -5, 0), roadRp)
        if not hit then return false end
        -- Yüzey ismi "Asphalt", "Road", ya da materyal Enum.Material.SmoothPlastic / Asphalt
        local mat = hit.Material
        if mat == Enum.Material.SmoothPlastic
        or mat == Enum.Material.Concrete
        or mat == Enum.Material.Asphalt
        or mat == Enum.Material.Pavement then
            return true
        end
        -- İsme bak
        local inst = hit.Instance
        local n = (inst and inst.Name or ""):lower()
        if n:find("road") or n:find("street") or n:find("asphalt")
        or n:find("lane") or n:find("highway") or n:find("pavement") then
            return true
        end
        return false
    end

    while true do
        task.wait(0.05)  -- 20 Hz

        if not (Toggles.BikeAutoRide and Toggles.BikeAutoRide.Value) then
            pcall(function()
                if seat and seat.Parent then
                    seat.ThrottleFloat = 0
                    seat.SteerFloat    = 0
                end
            end)
            seat = nil; root = nil
            stuckT = 0; lastPos = nil; steerSmooth = 0
            task.wait(0.3)
            continue
        end

        -- Bisiklet bul
        if not seat or not seat.Parent then
            seat, root = findBike()
            if not seat then task.wait(1); continue end
            stuckT = 0; lastPos = nil; steerSmooth = 0
        end

        if not seat.Parent or not root or not root.Parent then
            seat = nil; root = nil; continue
        end

        -- Bisiklete otur
        pcall(function()
            local char = LP.Character
            local hum  = char and char:FindFirstChildOfClass("Humanoid")
            if hum and seat.Occupant ~= hum then seat:Sit(hum) end
        end)

        local throttle = Options.AutoRideThrottle and Options.AutoRideThrottle.Value or 1
        local reactDist= Options.AutoRideReact    and Options.AutoRideReact.Value    or 18

        local cf     = root.CFrame
        local origin = root.Position + Vector3.new(0, 0.8, 0)
        local curPos = root.Position

        -- Sıkışma tespiti
        if lastPos and (curPos - lastPos).Magnitude < 0.3 then
            stuckT = stuckT + 0.05
        else
            stuckT = math.max(0, stuckT - 0.1)
        end
        lastPos = curPos

        -- SIKIŞ KURTARMA
        if stuckT > 1.0 then
            pcall(function()
                seat.ThrottleFloat = -0.9
                seat.SteerFloat    = stuckDir * 0.9
                if stuckT > 2.5 then
                    stuckDir = -stuckDir
                    stuckT   = 0
                end
            end)
            continue
        end

        -- FAN RAY ile engel tarama
        local scores = castFan(origin, cf, reactDist)

        -- Net steer hesabı: ağırlıklı ortalama
        -- Soldaki tehditler sağa dönmeyi (pozitif), sağdakiler sola (negatif) ister
        local netSteer   = 0
        local maxThreat  = 0
        for i, threat in ipairs(scores) do
            if threat > 0 then
                netSteer  = netSteer  - WEIGHTS[i] * threat  -- WEIGHTS[i] sağa yönlü → negatif steer
                if threat > maxThreat then maxThreat = threat end
            end
        end
        netSteer = math.clamp(netSteer, -1, 1)

        -- Yol kontrolü: yoldan çıktıysa düz dön
        local roadOk = onRoad()
        if not roadOk then
            -- Yol yok altımızda: sola veya sağa dön (highway ortasına geri dön)
            -- Sağ tarafta yol var mı?
            rp.FilterDescendantsInstances = {root, LP.Character}
            local chkL = Workspace:Raycast(origin - cf.RightVector * 4, Vector3.new(0,-5,0), rp)
            local chkR = Workspace:Raycast(origin + cf.RightVector * 4, Vector3.new(0,-5,0), rp)
            local leftIsRoad  = chkL and (chkL.Material == Enum.Material.SmoothPlastic
                                       or chkL.Material == Enum.Material.Asphalt
                                       or chkL.Material == Enum.Material.Concrete)
            local rightIsRoad = chkR and (chkR.Material == Enum.Material.SmoothPlastic
                                       or chkR.Material == Enum.Material.Asphalt
                                       or chkR.Material == Enum.Material.Concrete)
            if rightIsRoad and not leftIsRoad then
                netSteer = -0.8  -- sağa dön
            elseif leftIsRoad and not rightIsRoad then
                netSteer =  0.8  -- sola dön
            else
                netSteer = stuckDir * 0.7  -- bilinmiyor, alternatif dön
            end
        end

        -- Smooth steer (ani sarsıntı önle)
        steerSmooth = steerSmooth + (netSteer - steerSmooth) * 0.35

        -- Hız: önde engel ne kadar yakınsa o kadar yavaşla
        local speedMult = 1 - maxThreat * 0.5  -- max %50 yavaşlatır
        local finalThrottle = throttle * speedMult

        pcall(function()
            seat.ThrottleFloat = finalThrottle
            seat.SteerFloat    = steerSmooth
        end)
    end
end)

-- =========================================================================

SettingsGroup:AddButton("Unload", function()
    Library:Unload()
end)

ThemeManager:SetLibrary(Library)
SaveManager:SetLibrary(Library)
SaveManager:IgnoreThemeSettings()
SaveManager:SetIgnoreIndexes({"MenuKeybind"})

ThemeManager:SetFolder("universalhub")
SaveManager:SetFolder("universalhub/config")
SaveManager:SetSubFolder("universalhub")

SaveManager:BuildConfigSection(Tabs.Settings)
ThemeManager:ApplyToTab(Tabs.Settings)
SaveManager:LoadAutoloadConfig()

-- =========================================================================
-- [ LOAD NOTIFICATION ]
-- =========================================================================

task.spawn(function()
    local CoreGui = game:GetService("CoreGui")

    local notifGui = Instance.new("ScreenGui")
    notifGui.Name           = "UniversalHub_Notif"
    notifGui.ResetOnSpawn   = false
    notifGui.DisplayOrder   = 9999
    notifGui.IgnoreGuiInset = true
    pcall(function() notifGui.Parent = CoreGui end)

    local frame = Instance.new("Frame")
    frame.Size              = UDim2.new(0, 380, 0, 60)
    frame.Position          = UDim2.new(1, 400, 0, 20)
    frame.BackgroundColor3  = Color3.fromRGB(15, 15, 20)
    frame.BorderSizePixel   = 0
    frame.Parent            = notifGui
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

    local stroke = Instance.new("UIStroke", frame)
    stroke.Thickness = 2; stroke.Color = Color3.fromRGB(255,50,50); stroke.Transparency = 0.3

    local accent = Instance.new("Frame", frame)
    accent.Size = UDim2.new(0,4,1,0); accent.BackgroundColor3 = Color3.fromRGB(255,50,50); accent.BorderSizePixel=0
    Instance.new("UICorner", accent).CornerRadius = UDim.new(0,8)

    local title = Instance.new("TextLabel", frame)
    title.Size = UDim2.new(1,-20,0,22); title.Position = UDim2.new(0,15,0,8)
    title.BackgroundTransparency = 1; title.Text = "UNIVERSAL HUB"
    title.TextColor3 = Color3.fromRGB(255,80,80); title.Font = Enum.Font.GothamBold
    title.TextSize = 14; title.TextXAlignment = Enum.TextXAlignment.Left

    local sub = Instance.new("TextLabel", frame)
    sub.Size = UDim2.new(1,-20,0,20); sub.Position = UDim2.new(0,15,0,32)
    sub.BackgroundTransparency = 1; sub.Text = "Loaded | " .. game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId).Name
    sub.TextColor3 = Color3.fromRGB(200,200,200); sub.Font = Enum.Font.Gotham
    sub.TextSize = 12; sub.TextXAlignment = Enum.TextXAlignment.Left

    TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
        {Position = UDim2.new(1,-400,0,20)}):Play()

    task.wait(5)

    local out = TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quart, Enum.EasingDirection.In),
        {Position = UDim2.new(1,400,0,20)})
    out:Play()
    out.Completed:Connect(function() notifGui:Destroy() end)
end)

-- =========================================================================
-- [ END | UNIVERSAL HUB v2 ]
-- =========================================================================
