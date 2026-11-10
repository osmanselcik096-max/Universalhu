-- =========================================================================
-- [ UNIVERSAL HUB - LOADER v3 ]
-- Executor'a yapıştır. Key sitesinden alınan key ile çalışır.
-- =========================================================================

-- ── AYARLAR ───────────────────────────────────────────────────────────────
local SCRIPT_URL  = "https://raw.githubusercontent.com/b86138092-maker/universalhub/refs/heads/main/universal_v2.lua"
local VERIFY_URL  = "https://YOUR_VERCEL_APP.vercel.app/api/verify"  -- ← Vercel URL'ini yaz
local KEY_SITE    = "https://YOUR_VERCEL_APP.vercel.app/getkey"       -- ← Key alma sayfası
local KEY_FILE    = "uhub_key.txt"
-- ──────────────────────────────────────────────────────────────────────────

local Players      = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local CoreGui      = game:GetService("CoreGui")
local HttpService  = game:GetService("HttpService")
local LP           = Players.LocalPlayer

-- Eski GUI temizle
pcall(function()
    local old = CoreGui:FindFirstChild("UniversalHub_Loader")
    if old then old:Destroy() end
end)

-- =========================================================================
-- HWID: executor'un makine kimliği
-- =========================================================================
local function getHWID()
    -- Executorlar genellikle identifyexecutor veya getexecutorname sağlar
    -- HWID için: syn → syn_id(), diğerleri → UserID + PlaceId kombinasyonu
    local ok, id = pcall(function()
        if syn and syn.request then
            return tostring(game:GetService("RbxAnalyticsService"):GetClientId())
        end
    end)
    if ok and id and id ~= "" then return id end
    -- Fallback: UserID tabanlı
    return tostring(LP.UserId) .. "_" .. tostring(game.PlaceId)
end

-- =========================================================================
-- GUI KURULUM
-- =========================================================================
local gui = Instance.new("ScreenGui")
gui.Name           = "UniversalHub_Loader"
gui.ResetOnSpawn   = false
gui.DisplayOrder   = 99999
gui.IgnoreGuiInset = true
pcall(function() gui.Parent = CoreGui end)

local overlay = Instance.new("Frame", gui)
overlay.Size             = UDim2.new(1,0,1,0)
overlay.BackgroundColor3 = Color3.fromRGB(8,8,12)
overlay.BorderSizePixel  = 0
overlay.ZIndex           = 1

local function mkFrame(p, sz, pos, col, zi, r)
    local f = Instance.new("Frame", p)
    f.Size = sz; f.Position = pos
    f.BackgroundColor3 = col or Color3.fromRGB(14,14,20)
    f.BorderSizePixel = 0; f.ZIndex = zi or 2
    if r then Instance.new("UICorner",f).CornerRadius = UDim.new(0,r) end
    return f
end
local function mkLabel(p, sz, pos, txt, fnt, ts, col, xa, zi)
    local l = Instance.new("TextLabel", p)
    l.Size = sz; l.Position = pos
    l.BackgroundTransparency = 1; l.Text = txt or ""
    l.Font = fnt or Enum.Font.Gotham; l.TextSize = ts or 13
    l.TextColor3 = col or Color3.fromRGB(200,200,200)
    l.TextXAlignment = xa or Enum.TextXAlignment.Left; l.ZIndex = zi or 3
    return l
end
local function mkStroke(p, th, col, tr)
    local s = Instance.new("UIStroke", p)
    s.Thickness = th or 1.5; s.Color = col or Color3.fromRGB(255,50,50)
    s.Transparency = tr or 0.4; return s
end

-- Ana kart (key ekranı veya loader ekranı)
local card = mkFrame(gui,
    UDim2.new(0,380,0,240),
    UDim2.new(0.5,0,0.5,0),
    Color3.fromRGB(14,14,20), 2, 14)
card.AnchorPoint = Vector2.new(0.5,0.5)
mkStroke(card, 1.5, Color3.fromRGB(255,50,50), 0.35)

-- Sol accent
mkFrame(card, UDim2.new(0,4,1,0), UDim2.new(0,0,0,0), Color3.fromRGB(230,57,70), 3, 14)

-- Başlık
mkLabel(card, UDim2.new(1,-24,0,28), UDim2.new(0,18,0,16),
    "UNIVERSAL HUB", Enum.Font.GothamBold, 20, Color3.fromRGB(255,65,65),
    Enum.TextXAlignment.Left, 3)

mkLabel(card, UDim2.new(1,-24,0,16), UDim2.new(0,18,0,44),
    "v2  •  All Games", Enum.Font.Gotham, 12, Color3.fromRGB(100,100,120),
    Enum.TextXAlignment.Left, 3)

mkFrame(card, UDim2.new(1,-32,0,1), UDim2.new(0,16,0,66), Color3.fromRGB(30,30,42), 3)

-- Oyun adı
local gameLabel = mkLabel(card, UDim2.new(1,-24,0,14), UDim2.new(0,18,0,220),
    "", Enum.Font.Gotham, 11, Color3.fromRGB(60,60,80),
    Enum.TextXAlignment.Left, 3)
pcall(function()
    local info = game:GetService("MarketplaceService"):GetProductInfo(game.PlaceId)
    gameLabel.Text = info.Name
end)

-- ── KEY EKRANI ────────────────────────────────────────────────────────────
local keySection = Instance.new("Frame", card)
keySection.Size = UDim2.new(1,0,1,0)
keySection.BackgroundTransparency = 1; keySection.ZIndex = 3

mkLabel(keySection, UDim2.new(1,-24,0,16), UDim2.new(0,18,0,76),
    "Key Gir", Enum.Font.GothamBold, 14, Color3.fromRGB(220,220,230),
    Enum.TextXAlignment.Left, 4)

mkLabel(keySection, UDim2.new(1,-24,0,13), UDim2.new(0,18,0,94),
    KEY_SITE, Enum.Font.Gotham, 11, Color3.fromRGB(80,80,110),
    Enum.TextXAlignment.Left, 4)

local inputBg = mkFrame(keySection,
    UDim2.new(1,-32,0,34), UDim2.new(0,16,0,114),
    Color3.fromRGB(20,20,28), 4, 8)
mkStroke(inputBg, 1, Color3.fromRGB(50,50,70), 0)

local keyInput = Instance.new("TextBox", inputBg)
keyInput.Size = UDim2.new(1,-12,1,0); keyInput.Position = UDim2.new(0,8,0,0)
keyInput.BackgroundTransparency = 1; keyInput.Text = ""
keyInput.PlaceholderText = "UHUB-XXXXXXXX"
keyInput.PlaceholderColor3 = Color3.fromRGB(55,55,75)
keyInput.TextColor3 = Color3.fromRGB(230,230,240)
keyInput.Font = Enum.Font.GothamBold; keyInput.TextSize = 14
keyInput.ClearTextOnFocus = false; keyInput.ZIndex = 5

local confirmBtn = mkFrame(keySection,
    UDim2.new(1,-32,0,32), UDim2.new(0,16,0,154),
    Color3.fromRGB(200,40,40), 4, 8)
local confirmLabel = mkLabel(confirmBtn,
    UDim2.new(1,0,1,0), UDim2.new(0,0,0,0),
    "ONAYLA", Enum.Font.GothamBold, 14, Color3.fromRGB(255,255,255),
    Enum.TextXAlignment.Center, 5)

local keyStatusLabel = mkLabel(keySection,
    UDim2.new(1,-24,0,14), UDim2.new(0,18,0,192),
    "", Enum.Font.Gotham, 11, Color3.fromRGB(255,80,80),
    Enum.TextXAlignment.Left, 4)

-- ── LOADER EKRANI ─────────────────────────────────────────────────────────
local loaderSection = Instance.new("Frame", card)
loaderSection.Size = UDim2.new(1,0,1,0)
loaderSection.BackgroundTransparency = 1; loaderSection.ZIndex = 3
loaderSection.Visible = false

local statusLabel = mkLabel(loaderSection,
    UDim2.new(1,-24,0,16), UDim2.new(0,18,0,80),
    "Bağlanıyor...", Enum.Font.Gotham, 12, Color3.fromRGB(160,160,180),
    Enum.TextXAlignment.Left, 4)

local barBg = mkFrame(loaderSection,
    UDim2.new(1,-32,0,6), UDim2.new(0,16,0,106),
    Color3.fromRGB(22,22,32), 4, 3)
local bar = mkFrame(barBg,
    UDim2.new(0,0,1,0), UDim2.new(0,0,0,0),
    Color3.fromRGB(230,57,70), 5, 3)

local pctLabel = mkLabel(loaderSection,
    UDim2.new(0,50,0,14), UDim2.new(1,-66,0,78),
    "0%", Enum.Font.GothamBold, 11, Color3.fromRGB(230,57,70),
    Enum.TextXAlignment.Right, 4)

-- =========================================================================
-- YARDIMCI FONKSİYONLAR
-- =========================================================================
local function setProgress(v, text)
    v = math.clamp(v, 0, 1)
    TweenService:Create(bar, TweenInfo.new(0.3, Enum.EasingStyle.Quad), {
        Size = UDim2.new(v, 0, 1, 0)
    }):Play()
    pctLabel.Text    = math.floor(v*100) .. "%"
    statusLabel.Text = text or ""
end

local function closeAll(d)
    task.delay(d or 0, function()
        TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0,380,0,0), Position = UDim2.new(0.5,0,0.5,80)
        }):Play()
        TweenService:Create(overlay, TweenInfo.new(0.4, Enum.EasingStyle.Quad), {
            BackgroundTransparency = 1
        }):Play()
        task.delay(0.5, function() gui:Destroy() end)
    end)
end

local function showKeyError(msg)
    keyStatusLabel.Text       = "✗  " .. msg
    keyStatusLabel.TextColor3 = Color3.fromRGB(255,80,80)
    TweenService:Create(inputBg, TweenInfo.new(0.12), {
        BackgroundColor3 = Color3.fromRGB(40,15,15)
    }):Play()
    task.delay(0.35, function()
        TweenService:Create(inputBg, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(20,20,28)
        }):Play()
    end)
end

-- Kayıtlı key oku / yaz
local function getSaved()
    local ok, v = pcall(readfile, KEY_FILE)
    if ok and v and v ~= "" then return v:gsub("[\r\n]","") end
    return nil
end
local function saveKey(k)
    pcall(writefile, KEY_FILE, k)
end

-- Vercel API'ye key doğrulama isteği
local function verifyKey(key)
    local hwid = getHWID()
    local url  = VERIFY_URL .. "?key=" .. key .. "&hwid=" .. HttpService:UrlEncode(hwid)
    local ok, res = pcall(function()
        return HttpService:JSONDecode(game:HttpGet(url, true))
    end)
    if not ok then return false, "Sunucuya ulaşılamadı" end
    if res and res.valid then return true, nil end
    return false, (res and res.reason) or "Geçersiz key"
end

-- Script yükle
local function loadScript()
    keySection.Visible    = false
    loaderSection.Visible = true

    setProgress(0.1, "Bağlanıyor...")
    task.wait(0.3)
    setProgress(0.4, "Script indiriliyor...")

    local ok, raw = pcall(game.HttpGet, game, SCRIPT_URL, true)
    if not ok or not raw or raw == "" then
        setProgress(1, "⚠ Bağlantı hatası!")
        bar.BackgroundColor3 = Color3.fromRGB(220,50,50)
        closeAll(1.5)
        return
    end

    setProgress(0.75, "Yükleniyor...")
    task.wait(0.15)

    local execOk, execErr = pcall(loadstring(raw))
    if not execOk then
        setProgress(1, "⚠ Yükleme hatası!")
        bar.BackgroundColor3 = Color3.fromRGB(220,50,50)
        warn("[UniversalHub] " .. tostring(execErr))
        closeAll(1.5)
        return
    end

    setProgress(1, "Hazır! ✓")
    bar.BackgroundColor3  = Color3.fromRGB(46,200,100)
    pctLabel.TextColor3   = Color3.fromRGB(46,200,100)
    closeAll(0.9)
end

-- =========================================================================
-- ANA AKIŞ
-- =========================================================================
task.spawn(function()
    -- Giriş animasyonu
    card.Size = UDim2.new(0,380,0,0)
    card.Position = UDim2.new(0.5,0,0.5,80)
    task.wait(0.08)
    TweenService:Create(card, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0,380,0,240), Position = UDim2.new(0.5,0,0.5,0)
    }):Play()
    task.wait(0.5)

    -- 1) Kayıtlı key varsa direkt doğrula
    local saved = getSaved()
    if saved then
        keySection.Visible    = false
        loaderSection.Visible = true
        setProgress(0.2, "Kayıtlı key kontrol ediliyor...")

        local valid, reason = verifyKey(saved)
        if valid then
            setProgress(0.5, "Key onaylandı ✓")
            task.wait(0.3)
            loadScript()
            return
        else
            -- Geçersizse sil, key ekranına dön
            pcall(writefile, KEY_FILE, "")
            loaderSection.Visible = false
            keySection.Visible    = true
            keyStatusLabel.Text       = "Kayıtlı key geçersiz: " .. (reason or "")
            keyStatusLabel.TextColor3 = Color3.fromRGB(255,160,60)
        end
    else
        keySection.Visible    = true
        loaderSection.Visible = false
    end

    -- 2) Key girişi
    local checking = false

    local function tryKey()
        if checking then return end
        local key = keyInput.Text:gsub("%s",""):upper()
        if key == "" then showKeyError("Key boş olamaz."); return end

        checking          = true
        confirmLabel.Text = "..."
        keyStatusLabel.Text       = "⏳ Doğrulanıyor..."
        keyStatusLabel.TextColor3 = Color3.fromRGB(160,160,180)

        task.spawn(function()
            local valid, reason = verifyKey(key)
            checking          = false
            confirmLabel.Text = "ONAYLA"

            if valid then
                keyStatusLabel.Text       = "✓ Key onaylandı!"
                keyStatusLabel.TextColor3 = Color3.fromRGB(46,200,100)
                saveKey(key)
                task.wait(0.5)
                loadScript()
            else
                showKeyError(reason or "Geçersiz key.")
            end
        end)
    end

    -- Hover efekti
    confirmBtn.MouseEnter:Connect(function()
        TweenService:Create(confirmBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(230,55,55)
        }):Play()
    end)
    confirmBtn.MouseLeave:Connect(function()
        TweenService:Create(confirmBtn, TweenInfo.new(0.12), {
            BackgroundColor3 = Color3.fromRGB(200,40,40)
        }):Play()
    end)

    confirmBtn.InputBegan:Connect(function(inp)
        if inp.UserInputType == Enum.UserInputType.MouseButton1
        or inp.UserInputType == Enum.UserInputType.Touch then
            TweenService:Create(confirmBtn, TweenInfo.new(0.08), {
                BackgroundColor3 = Color3.fromRGB(150,25,25)
            }):Play()
            task.delay(0.12, function()
                TweenService:Create(confirmBtn, TweenInfo.new(0.1), {
                    BackgroundColor3 = Color3.fromRGB(200,40,40)
                }):Play()
            end)
            tryKey()
        end
    end)

    keyInput.FocusLost:Connect(function(enterPressed)
        if enterPressed then tryKey() end
    end)
end)
