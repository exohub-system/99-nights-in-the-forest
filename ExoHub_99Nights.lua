-- ╔═══════════════════════════════════════════════╗
--   EXO HUB | 99 Nights In The Forest
--   Delta Ready  ·  discord.gg/TzNds43vb
-- ╚═══════════════════════════════════════════════╝

if not game:IsLoaded() then
    game.Loaded:Wait()
end

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local character = player.Character or player.CharacterAdded:Wait()

-- Lobby check
if game.PlaceId == 79546208627805 then
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "EXO HUB | 99 Nights",
        Text = "Go in-game for Exo Hub to load! discord.gg/TzNds43vb",
        Duration = 10
    })
    return
end

-- ╔══════════════════╗
--   STATES
-- ╚══════════════════╝

local states = {
    godMode       = false,
    speed         = false,
    fly           = false,
    espPlayers    = false,
    espMonsters   = false,
    stamina       = false,
    fullbright    = false,
    noclip        = false,
}

local flyActive   = false
local tpwalking   = false
local flySpeed    = 1
local noclipConn  = nil
local healthConns = {}
local espObjs     = {}
local origAmbient = Lighting.Ambient
local origBrightness = Lighting.Brightness
local staminaConn = nil

-- ╔══════════════════╗
--   GOD MODE
-- ╚══════════════════╝

local function setupGodMode(char)
    if not char then return end
    for _, c in pairs(healthConns) do if c then c:Disconnect() end end
    healthConns = {}
    local hum = char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    hum.BreakJointsOnDeath = false
    hum:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
    local ff = Instance.new("ForceField")
    ff.Visible = false
    ff.Parent = char
    local c = hum:GetPropertyChangedSignal("Health"):Connect(function()
        if states.godMode and hum.Health <= 0 then
            task.wait(0.05)
            hum.Health = hum.MaxHealth
        end
    end)
    table.insert(healthConns, c)
end

local function stopGodMode()
    for _, c in pairs(healthConns) do if c then c:Disconnect() end end
    healthConns = {}
    local char = player.Character
    if char then
        local ff = char:FindFirstChildOfClass("ForceField")
        if ff then ff:Destroy() end
        local hum = char:FindFirstChildOfClass("Humanoid")
        if hum then hum:SetStateEnabled(Enum.HumanoidStateType.Dead, true) end
    end
end

-- ╔══════════════════╗
--   SPEED
-- ╚══════════════════╝

local function setSpeed(on)
    local char = player.Character
    local hum = char and char:FindFirstChildWhichIsA("Humanoid")
    if hum then hum.WalkSpeed = on and 40 or 16 end
end

-- ╔══════════════════╗
--   INFINITE STAMINA
-- ╚══════════════════╝

local function startStamina()
    staminaConn = RunService.Heartbeat:Connect(function()
        if not states.stamina then return end
        local char = player.Character
        if not char then return end
        -- Try common stamina attribute names
        for _, attr in ipairs({"Stamina", "stamina", "Energy", "energy", "Sprint"}) do
            if char:GetAttribute(attr) ~= nil then
                char:SetAttribute(attr, 100)
            end
        end
        if player:GetAttribute("Stamina") ~= nil then
            player:SetAttribute("Stamina", 100)
        end
    end)
end

local function stopStamina()
    if staminaConn then staminaConn:Disconnect(); staminaConn = nil end
end

-- ╔══════════════════╗
--   FLY
-- ╚══════════════════╝

local function startTpWalking()
    tpwalking = false
    for i = 1, flySpeed do
        spawn(function()
            local hb = RunService.Heartbeat
            tpwalking = true
            local chr = player.Character
            local hum = chr and chr:FindFirstChildWhichIsA("Humanoid")
            while tpwalking and hb:Wait() and chr and hum and hum.Parent do
                if hum.MoveDirection.Magnitude > 0 then chr:TranslateBy(hum.MoveDirection) end
            end
        end)
    end
end

local function startFly()
    local char = player.Character
    if not char then return end
    local hum = char:FindFirstChildWhichIsA("Humanoid")
    if not hum then return end
    local isR6 = hum.RigType == Enum.HumanoidRigType.R6
    local torso = isR6 and char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso")
    if not torso then return end

    char.Animate.Disabled = true
    for _, t in pairs(hum:GetPlayingAnimationTracks()) do t:AdjustSpeed(0) end
    for _, s in pairs(Enum.HumanoidStateType:GetEnumItems()) do
        pcall(function() hum:SetStateEnabled(s, false) end)
    end
    hum:ChangeState(Enum.HumanoidStateType.Swimming)
    startTpWalking()
    hum.PlatformStand = true

    local bg = Instance.new("BodyGyro", torso)
    bg.P = 9e4
    bg.maxTorque = Vector3.new(9e9,9e9,9e9)
    bg.cframe = torso.CFrame

    local bv = Instance.new("BodyVelocity", torso)
    bv.velocity = Vector3.new(0,0.1,0)
    bv.maxForce = Vector3.new(9e9,9e9,9e9)

    local ctrl = {f=0,b=0,l=0,r=0}
    local lastctrl = {f=0,b=0,l=0,r=0}
    local maxspeed = 50
    local spd = 0
    local conn

    conn = RunService.RenderStepped:Connect(function()
        if not flyActive then
            conn:Disconnect()
            pcall(function() bg:Destroy() end)
            pcall(function() bv:Destroy() end)
            hum.PlatformStand = false
            char.Animate.Disabled = false
            tpwalking = false
            for _, s in pairs(Enum.HumanoidStateType:GetEnumItems()) do
                pcall(function() hum:SetStateEnabled(s, true) end)
            end
            hum:ChangeState(Enum.HumanoidStateType.RunningNoPhysics)
            return
        end
        ctrl.f = UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0
        ctrl.b = UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0
        ctrl.l = UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0
        ctrl.r = UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0
        if ctrl.l+ctrl.r ~= 0 or ctrl.f+ctrl.b ~= 0 then
            spd = math.min(spd+0.5+(spd/maxspeed), maxspeed)
        else
            spd = math.max(spd-1, 0)
        end
        local cam = workspace.CurrentCamera.CoordinateFrame
        if (ctrl.l+ctrl.r) ~= 0 or (ctrl.f+ctrl.b) ~= 0 then
            bv.velocity = ((cam.lookVector*(ctrl.f+ctrl.b))+((cam*CFrame.new(ctrl.l+ctrl.r,(ctrl.f+ctrl.b)*.2,0).p)-cam.p))*spd
            lastctrl = {f=ctrl.f,b=ctrl.b,l=ctrl.l,r=ctrl.r}
        elseif spd ~= 0 then
            bv.velocity = ((cam.lookVector*(lastctrl.f+lastctrl.b))+((cam*CFrame.new(lastctrl.l+lastctrl.r,(lastctrl.f+lastctrl.b)*.2,0).p)-cam.p))*spd
        else
            bv.velocity = Vector3.new(0,0,0)
        end
        bg.cframe = cam*CFrame.Angles(-math.rad((ctrl.f+ctrl.b)*50*spd/maxspeed),0,0)
    end)
end

-- ╔══════════════════╗
--   NOCLIP
-- ╚══════════════════╝

local function startNoclip()
    noclipConn = RunService.Stepped:Connect(function()
        if not states.noclip then return end
        local char = player.Character
        if char then
            for _, p in ipairs(char:GetDescendants()) do
                if p:IsA("BasePart") then p.CanCollide = false end
            end
        end
    end)
end

local function stopNoclip()
    if noclipConn then noclipConn:Disconnect(); noclipConn = nil end
end

-- ╔══════════════════╗
--   FULLBRIGHT
-- ╚══════════════════╝

local function setFullbright(on)
    if on then
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.Brightness = 2
        Lighting.GlobalShadows = false
        Lighting.FogEnd = 100000
    else
        Lighting.Ambient = origAmbient
        Lighting.Brightness = origBrightness
        Lighting.GlobalShadows = true
    end
end

-- ╔══════════════════╗
--   ESP
-- ╚══════════════════╝

local function clearESP()
    for _, obj in pairs(espObjs) do
        pcall(function() obj:Destroy() end)
    end
    espObjs = {}
end

local function makeESPBox(part, color, label)
    local box = Instance.new("SelectionBox")
    box.Color3 = color
    box.LineThickness = 0.04
    box.SurfaceTransparency = 0.7
    box.SurfaceColor3 = color
    box.Adornee = part
    box.Parent = workspace

    local bill = Instance.new("BillboardGui")
    bill.Size = UDim2.new(0, 100, 0, 30)
    bill.StudsOffset = Vector3.new(0, 3, 0)
    bill.AlwaysOnTop = true
    bill.Adornee = part
    bill.Parent = workspace

    local txt = Instance.new("TextLabel", bill)
    txt.Size = UDim2.new(1, 0, 1, 0)
    txt.BackgroundTransparency = 1
    txt.Text = label
    txt.TextColor3 = color
    txt.TextSize = 12
    txt.Font = Enum.Font.GothamBold
    txt.TextStrokeTransparency = 0

    table.insert(espObjs, box)
    table.insert(espObjs, bill)
end

local function updateESP()
    clearESP()
    -- Player ESP
    if states.espPlayers then
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= player and p.Character then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    makeESPBox(hrp, Color3.fromRGB(0, 200, 255), p.Name)
                end
            end
        end
    end
    -- Monster/NPC ESP
    if states.espMonsters then
        for _, obj in ipairs(workspace:GetDescendants()) do
            if obj:IsA("Model") and obj ~= player.Character then
                local hum = obj:FindFirstChildOfClass("Humanoid")
                local hrp = obj:FindFirstChild("HumanoidRootPart")
                if hum and hrp and not Players:GetPlayerFromCharacter(obj) then
                    makeESPBox(hrp, Color3.fromRGB(255, 50, 80), obj.Name)
                end
            end
        end
    end
end

RunService.Heartbeat:Connect(function()
    if states.espPlayers or states.espMonsters then
        updateESP()
    else
        clearESP()
    end
end)

-- ╔══════════════════════════════════════════╗
--   GUI
-- ╚══════════════════════════════════════════╝

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ExoHub99Nights"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = player.PlayerGui

-- Glow
local glowFrame = Instance.new("Frame")
glowFrame.Size = UDim2.new(0, 274, 0, 580)
glowFrame.Position = UDim2.new(0, 8, 0.5, -280)
glowFrame.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
glowFrame.BackgroundTransparency = 0.85
glowFrame.BorderSizePixel = 0
glowFrame.Parent = ScreenGui
Instance.new("UICorner", glowFrame).CornerRadius = UDim.new(0, 18)

-- Main frame
local frame = Instance.new("Frame")
frame.Size = UDim2.new(0, 270, 0, 576)
frame.Position = UDim2.new(0, 10, 0.5, -278)
frame.BackgroundColor3 = Color3.fromRGB(4, 8, 20)
frame.BorderSizePixel = 0
frame.Parent = ScreenGui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 16)

local innerGrad = Instance.new("UIGradient")
innerGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(4, 14, 30)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(4, 8, 20)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(2, 4, 14)),
})
innerGrad.Rotation = 135
innerGrad.Parent = frame

local borderStroke = Instance.new("UIStroke")
borderStroke.Color = Color3.fromRGB(0, 200, 255)
borderStroke.Thickness = 1.5
borderStroke.Transparency = 0.2
borderStroke.Parent = frame

-- Slash accents
local slash1 = Instance.new("Frame")
slash1.Size = UDim2.new(0, 80, 0, 4)
slash1.Position = UDim2.new(0, -15, 0, 0)
slash1.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
slash1.BorderSizePixel = 0
slash1.Rotation = -15
slash1.Parent = frame

local slash2 = Instance.new("Frame")
slash2.Size = UDim2.new(0, 50, 0, 4)
slash2.Position = UDim2.new(0, 68, 0, 0)
slash2.BackgroundColor3 = Color3.fromRGB(0, 255, 180)
slash2.BorderSizePixel = 0
slash2.Rotation = -15
slash2.Parent = frame

local slash3 = Instance.new("Frame")
slash3.Size = UDim2.new(0, 30, 0, 3)
slash3.Position = UDim2.new(0, 122, 0, 0)
slash3.BackgroundColor3 = Color3.fromRGB(80, 140, 255)
slash3.BackgroundTransparency = 0.4
slash3.BorderSizePixel = 0
slash3.Rotation = -15
slash3.Parent = frame

-- Corner accents
local c1 = Instance.new("Frame")
c1.Size = UDim2.new(0, 30, 0, 2)
c1.Position = UDim2.new(1, -34, 1, -12)
c1.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
c1.BackgroundTransparency = 0.3
c1.BorderSizePixel = 0
c1.Parent = frame

local c2 = Instance.new("Frame")
c2.Size = UDim2.new(0, 2, 0, 20)
c2.Position = UDim2.new(1, -6, 1, -24)
c2.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
c2.BackgroundTransparency = 0.3
c2.BorderSizePixel = 0
c2.Parent = frame

-- Header
local headerBg = Instance.new("Frame")
headerBg.Size = UDim2.new(1, 0, 0, 76)
headerBg.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
headerBg.BackgroundTransparency = 0.92
headerBg.BorderSizePixel = 0
headerBg.Active = true
headerBg.Parent = frame

local logoLabel = Instance.new("TextLabel")
logoLabel.Size = UDim2.new(1, -10, 0, 38)
logoLabel.Position = UDim2.new(0, 10, 0, 4)
logoLabel.BackgroundTransparency = 1
logoLabel.Text = "✦ EXO HUB"
logoLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
logoLabel.TextSize = 26
logoLabel.Font = Enum.Font.GothamBold
logoLabel.TextXAlignment = Enum.TextXAlignment.Left
logoLabel.Parent = headerBg

local logoGrad = Instance.new("UIGradient")
logoGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(0, 220, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 255, 180)),
})
logoGrad.Parent = logoLabel

local gameLabel = Instance.new("TextLabel")
gameLabel.Size = UDim2.new(1, -10, 0, 16)
gameLabel.Position = UDim2.new(0, 10, 0, 40)
gameLabel.BackgroundTransparency = 1
gameLabel.Text = "🌲  99 NIGHTS IN THE FOREST"
gameLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
gameLabel.TextSize = 10
gameLabel.Font = Enum.Font.GothamBold
gameLabel.TextXAlignment = Enum.TextXAlignment.Left
gameLabel.Parent = headerBg

local discordLabel = Instance.new("TextLabel")
discordLabel.Size = UDim2.new(1, -10, 0, 14)
discordLabel.Position = UDim2.new(0, 10, 0, 58)
discordLabel.BackgroundTransparency = 1
discordLabel.Text = "discord.gg/TzNds43vb"
discordLabel.TextColor3 = Color3.fromRGB(0, 100, 140)
discordLabel.TextSize = 9
discordLabel.Font = Enum.Font.Gotham
discordLabel.TextXAlignment = Enum.TextXAlignment.Left
discordLabel.Parent = headerBg

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 26, 0, 26)
closeBtn.Position = UDim2.new(1, -34, 0, 8)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 50, 80)
closeBtn.BackgroundTransparency = 0.3
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 11
closeBtn.Font = Enum.Font.GothamBold
closeBtn.BorderSizePixel = 0
closeBtn.Parent = frame
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 7)

local headerDiv = Instance.new("Frame")
headerDiv.Size = UDim2.new(1, -20, 0, 1)
headerDiv.Position = UDim2.new(0, 10, 0, 76)
headerDiv.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
headerDiv.BackgroundTransparency = 0.6
headerDiv.BorderSizePixel = 0
headerDiv.Parent = frame

-- Reopen button
local reopenBtn = Instance.new("TextButton")
reopenBtn.Size = UDim2.new(0, 120, 0, 30)
reopenBtn.Position = UDim2.new(0, 10, 0, 10)
reopenBtn.BackgroundColor3 = Color3.fromRGB(4, 8, 20)
reopenBtn.Text = "✦ EXO HUB"
reopenBtn.TextColor3 = Color3.fromRGB(0, 200, 255)
reopenBtn.TextSize = 12
reopenBtn.Font = Enum.Font.GothamBold
reopenBtn.BorderSizePixel = 0
reopenBtn.Visible = false
reopenBtn.Parent = ScreenGui
Instance.new("UICorner", reopenBtn).CornerRadius = UDim.new(0, 8)
local rs = Instance.new("UIStroke", reopenBtn)
rs.Color = Color3.fromRGB(0, 200, 255)
rs.Thickness = 1.5

closeBtn.MouseButton1Click:Connect(function()
    frame.Visible = false
    glowFrame.Visible = false
    reopenBtn.Visible = true
end)
reopenBtn.MouseButton1Click:Connect(function()
    frame.Visible = true
    glowFrame.Visible = true
    reopenBtn.Visible = false
end)

-- Scroll
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Size = UDim2.new(1, -20, 1, -168)
scrollFrame.Position = UDim2.new(0, 10, 0, 84)
scrollFrame.BackgroundTransparency = 1
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 3
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(0, 200, 255)
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
scrollFrame.Parent = frame

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 8)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- Features
local features = {
    {key="godMode",      name="God Mode",         desc="Cannot be killed — health locks at max",     icon="🛡️", color=Color3.fromRGB(0,200,255),   onEnable=function() setupGodMode(player.Character) end, onDisable=stopGodMode},
    {key="speed",        name="Speed Hack",        desc="Run faster than anything in the forest",     icon="⚡",  color=Color3.fromRGB(255,200,0),   onEnable=function() setSpeed(true) end, onDisable=function() setSpeed(false) end},
    {key="fly",          name="Fly",               desc="Fly above the forest — WASD to move",        icon="🛸",  color=Color3.fromRGB(120,80,255),  onEnable=function() flyActive=true; startFly() end, onDisable=function() flyActive=false end},
    {key="noclip",       name="Noclip",            desc="Walk through walls and trees",               icon="👻",  color=Color3.fromRGB(180,0,255),   onEnable=startNoclip, onDisable=stopNoclip},
    {key="stamina",      name="Inf Stamina",       desc="Never run out of stamina or energy",         icon="💨",  color=Color3.fromRGB(0,255,140),   onEnable=startStamina, onDisable=stopStamina},
    {key="fullbright",   name="Fullbright",        desc="See clearly in the dark forest",             icon="🔦",  color=Color3.fromRGB(255,220,0),   onEnable=function() setFullbright(true) end, onDisable=function() setFullbright(false) end},
    {key="espPlayers",   name="Player ESP",        desc="See all players through walls",              icon="👁",  color=Color3.fromRGB(0,180,255),   onEnable=function() end, onDisable=clearESP},
    {key="espMonsters",  name="Monster ESP",       desc="Track monsters and NPCs at all times",       icon="👾",  color=Color3.fromRGB(255,50,80),   onEnable=function() end, onDisable=clearESP},
}

local function makeCard(feature, index)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, 0, 0, 68)
    card.BackgroundColor3 = feature.color
    card.BackgroundTransparency = 0.92
    card.BorderSizePixel = 0
    card.LayoutOrder = index
    card.Parent = scrollFrame
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 10)

    local cardStroke = Instance.new("UIStroke")
    cardStroke.Color = feature.color
    cardStroke.Thickness = 1
    cardStroke.Transparency = 0.7
    cardStroke.Parent = card

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 44, 0, 44)
    iconBg.Position = UDim2.new(0, 10, 0.5, -22)
    iconBg.BackgroundColor3 = feature.color
    iconBg.BackgroundTransparency = 0.7
    iconBg.BorderSizePixel = 0
    iconBg.Parent = card
    Instance.new("UICorner", iconBg).CornerRadius = UDim.new(0, 10)

    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(1, 0, 1, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = feature.icon
    iconLabel.TextSize = 22
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = iconBg

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -120, 0, 22)
    nameLabel.Position = UDim2.new(0, 62, 0, 10)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = feature.name
    nameLabel.TextColor3 = Color3.fromRGB(220, 220, 240)
    nameLabel.TextSize = 13
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.Parent = card

    local descLabel = Instance.new("TextLabel")
    descLabel.Size = UDim2.new(1, -120, 0, 28)
    descLabel.Position = UDim2.new(0, 62, 0, 32)
    descLabel.BackgroundTransparency = 1
    descLabel.Text = feature.desc
    descLabel.TextColor3 = Color3.fromRGB(100, 100, 140)
    descLabel.TextSize = 9
    descLabel.Font = Enum.Font.Gotham
    descLabel.TextXAlignment = Enum.TextXAlignment.Left
    descLabel.TextWrapped = true
    descLabel.Parent = card

    local pill = Instance.new("Frame")
    pill.Size = UDim2.new(0, 40, 0, 22)
    pill.Position = UDim2.new(1, -50, 0.5, -11)
    pill.BackgroundColor3 = Color3.fromRGB(20, 10, 35)
    pill.BorderSizePixel = 0
    pill.Parent = card
    Instance.new("UICorner", pill).CornerRadius = UDim.new(1, 0)
    Instance.new("UIStroke", pill).Color = feature.color

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 16, 0, 16)
    dot.Position = UDim2.new(0, 3, 0.5, -8)
    dot.BackgroundColor3 = Color3.fromRGB(180, 180, 200)
    dot.BorderSizePixel = 0
    dot.Parent = pill
    Instance.new("UICorner", dot).CornerRadius = UDim.new(1, 0)

    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Size = UDim2.new(1, 0, 1, 0)
    toggleBtn.BackgroundTransparency = 1
    toggleBtn.Text = ""
    toggleBtn.Parent = card

    toggleBtn.MouseButton1Click:Connect(function()
        states[feature.key] = not states[feature.key]
        local on = states[feature.key]
        TweenService:Create(pill, TweenInfo.new(0.2), {BackgroundColor3 = on and feature.color or Color3.fromRGB(20,10,35)}):Play()
        TweenService:Create(dot, TweenInfo.new(0.2), {
            Position = on and UDim2.new(0,21,0.5,-8) or UDim2.new(0,3,0.5,-8),
            BackgroundColor3 = on and Color3.fromRGB(255,255,255) or Color3.fromRGB(180,180,200)
        }):Play()
        TweenService:Create(cardStroke, TweenInfo.new(0.2), {Transparency = on and 0.2 or 0.7}):Play()
        TweenService:Create(iconBg, TweenInfo.new(0.2), {BackgroundTransparency = on and 0.3 or 0.7}):Play()
        if on then feature.onEnable() else feature.onDisable() end
    end)

    card.MouseEnter:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency=0.85}):Play() end)
    card.MouseLeave:Connect(function() TweenService:Create(card, TweenInfo.new(0.15), {BackgroundTransparency=0.92}):Play() end)
end

for i, feat in ipairs(features) do makeCard(feat, i) end
scrollFrame.CanvasSize = UDim2.new(0, 0, 0, #features * 76)

-- Discord banner
local discordBanner = Instance.new("Frame")
discordBanner.Size = UDim2.new(1, -20, 0, 44)
discordBanner.Position = UDim2.new(0, 10, 1, -52)
discordBanner.BackgroundColor3 = Color3.fromRGB(88, 101, 242)
discordBanner.BackgroundTransparency = 0.3
discordBanner.BorderSizePixel = 0
discordBanner.Parent = frame
Instance.new("UICorner", discordBanner).CornerRadius = UDim.new(0, 10)
Instance.new("UIStroke", discordBanner).Color = Color3.fromRGB(88, 101, 242)

local dIcon = Instance.new("TextLabel", discordBanner)
dIcon.Size = UDim2.new(0, 40, 1, 0)
dIcon.BackgroundTransparency = 1
dIcon.Text = "💬"
dIcon.TextSize = 20
dIcon.Font = Enum.Font.GothamBold

local dText = Instance.new("TextLabel", discordBanner)
dText.Size = UDim2.new(1, -50, 0, 18)
dText.Position = UDim2.new(0, 42, 0, 4)
dText.BackgroundTransparency = 1
dText.Text = "Join our Discord!"
dText.TextColor3 = Color3.fromRGB(255, 255, 255)
dText.TextSize = 12
dText.Font = Enum.Font.GothamBold
dText.TextXAlignment = Enum.TextXAlignment.Left

local dLink = Instance.new("TextLabel", discordBanner)
dLink.Size = UDim2.new(1, -50, 0, 14)
dLink.Position = UDim2.new(0, 42, 0, 24)
dLink.BackgroundTransparency = 1
dLink.Text = "discord.gg/TzNds43vb"
dLink.TextColor3 = Color3.fromRGB(180, 190, 255)
dLink.TextSize = 10
dLink.Font = Enum.Font.Gotham
dLink.TextXAlignment = Enum.TextXAlignment.Left

-- ╔══════════════════╗
--   DRAGGING
-- ╚══════════════════╝

local dragging = false
local dragStart = nil
local startPos = nil

headerBg.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = frame.Position
        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then dragging = false end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        local newPos = UDim2.new(startPos.X.Scale, startPos.X.Offset+delta.X, startPos.Y.Scale, startPos.Y.Offset+delta.Y)
        frame.Position = newPos
        glowFrame.Position = UDim2.new(newPos.X.Scale, newPos.X.Offset-2, newPos.Y.Scale, newPos.Y.Offset-2)
    end
end)

-- ╔══════════════════╗
--   IDLE ANIMATION
-- ╚══════════════════╝

local t = 0
RunService.Heartbeat:Connect(function(dt)
    t = t + dt
    local pulse = (math.sin(t*2)+1)/2
    borderStroke.Transparency = 0.1 + pulse*0.3
    glowFrame.BackgroundTransparency = 0.8 + pulse*0.1
    slash1.BackgroundTransparency = 0.2 + pulse*0.4
    slash2.BackgroundTransparency = 0.4 + pulse*0.3
    slash3.BackgroundTransparency = 0.5 + pulse*0.3
    logoGrad.Rotation = (t*15) % 360
end)

-- Respawn
player.CharacterAdded:Connect(function(char)
    character = char
    task.wait(0.5)
    if states.godMode then setupGodMode(char) end
    if states.speed then setSpeed(true) end
    if states.fly then flyActive = true; startFly() end
    if states.noclip then startNoclip() end
    if states.fullbright then setFullbright(true) end
end)

-- Notify
game:GetService("StarterGui"):SetCore("SendNotification", {
    Title = "✦ EXO HUB",
    Text = "99 Nights In The Forest loaded! discord.gg/TzNds43vb",
    Duration = 6
})

print("[ExoHub] 99 Nights In The Forest Loaded ✓  |  discord.gg/TzNds43vb")
