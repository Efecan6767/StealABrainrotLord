-- Premium Multi-Tool GUI by KDML (Mobil uyumlu)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
if not player then return end

-- ===== CONFIG =====
local NEON_CONFIG = {
    Size = Vector3.new(10,1.5,10),
    FootOffset = 3.25,
    PosSmooth = 12,
    VertSpeed = 10,
    MinY = -1000,
    MaxY = 1000,
    Color = Color3.fromRGB(0,170,255),
    Material = Enum.Material.Neon,
    Transparency = 0.5,
    EdgeThickness = 0.2,
    ImageId = "rbxassetid://125568515406668"
}
local BASE_CONFIG = {
    Size = Vector3.new(999,1,999),
    StartOffset = Vector3.new(0,-1,0),
    Color = Color3.fromRGB(107,142,35)
}

-- ===== VARIABLES =====
local character, humanoid, hrp
local neonPlatform, neonEdges = nil, {}
local neonEnabled = false
local basePlatform, baseEnabled = nil, false

-- ===== CHARACTER =====
local function bindCharacter(char)
    character = char
    humanoid = char:FindFirstChildOfClass("Humanoid")
    hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart",5)
    if basePlatform and hrp then
        basePlatform.Position = hrp.Position + BASE_CONFIG.StartOffset
    end
end
if player.Character then bindCharacter(player.Character) end
player.CharacterAdded:Connect(bindCharacter)

-- ===== NEON FUNCTIONS =====
local function createNeonEdges(parent)
    for _,e in pairs(neonEdges) do if e and e.Parent then e:Destroy() end end
    neonEdges = {}
    local s = NEON_CONFIG.Size
    local t = NEON_CONFIG.EdgeThickness
    local positions = {
        Vector3.new(-s.X/2,0,-s.Z/2), Vector3.new(-s.X/2,0,s.Z/2),
        Vector3.new(s.X/2,0,-s.Z/2), Vector3.new(s.X/2,0,s.Z/2)
    }
    local function makeEdge(p1,p2)
        local edge = Instance.new("Part")
        edge.Anchored = true
        edge.CanCollide = false
        edge.Material = Enum.Material.Neon
        edge.Color = NEON_CONFIG.Color
        edge.Transparency = 0
        edge.Size = Vector3.new((p2-p1).Magnitude, t, t)
        edge.CFrame = CFrame.new((p1+p2)/2,(p1+p2)/2+(p2-p1).Unit)
        edge.Parent = parent
        table.insert(neonEdges,edge)
    end
    makeEdge(positions[1],positions[2])
    makeEdge(positions[2],positions[4])
    makeEdge(positions[4],positions[3])
    makeEdge(positions[3],positions[1])
end

local function createNeonPlatform()
    if neonPlatform then neonPlatform:Destroy() end
    for _,e in pairs(neonEdges) do if e and e.Parent then e:Destroy() end end
    neonEdges = {}
    neonPlatform = Instance.new("Part")
    neonPlatform.Name = "NeonFollowPlatform"
    neonPlatform.Size = NEON_CONFIG.Size
    neonPlatform.Anchored = true
    neonPlatform.CanCollide = true
    neonPlatform.Material = Enum.Material.ForceField
    neonPlatform.Color = NEON_CONFIG.Color
    neonPlatform.Transparency = NEON_CONFIG.Transparency
    neonPlatform.Parent = workspace
    createNeonEdges(neonPlatform)
    if hrp then
        neonPlatform.CFrame = CFrame.new(hrp.Position.X, hrp.Position.Y-NEON_CONFIG.FootOffset, hrp.Position.Z)
    end
end

local function destroyNeonPlatform()
    if neonPlatform then neonPlatform:Destroy() neonPlatform=nil end
    for _,e in pairs(neonEdges) do if e and e.Parent then e:Destroy() end end
    neonEdges={}
end

-- ===== BASEPLATE FUNCTIONS =====
local function createBasePlatform()
    if basePlatform then basePlatform:Destroy() end
    basePlatform = Instance.new("Part")
    basePlatform.Name = "InfiniteBasePlatform"
    basePlatform.Size = BASE_CONFIG.Size
    basePlatform.Anchored = true
    basePlatform.CanCollide = false
    basePlatform.Color = BASE_CONFIG.Color
    basePlatform.Material = Enum.Material.Grass
    basePlatform.Transparency = 1
    basePlatform.Parent = workspace
    if hrp then
        basePlatform.Position = hrp.Position + BASE_CONFIG.StartOffset
    end
end
local function destroyBasePlatform() if basePlatform then basePlatform:Destroy() basePlatform=nil end end

-- ===== UTIL =====
local function isAirborne(h)
    if not h then return false end
    local s = h:GetState()
    return s==Enum.HumanoidStateType.Freefall or s==Enum.HumanoidStateType.Jumping or s==Enum.HumanoidStateType.FallingDown
end

-- ===== UPDATE =====
RunService.Heartbeat:Connect(function(dt)
    if neonEnabled and neonPlatform and hrp and humanoid then
        local targetPos = Vector3.new(hrp.Position.X, hrp.Position.Y-NEON_CONFIG.FootOffset, hrp.Position.Z)
        if isAirborne(humanoid) and targetPos.Y>neonPlatform.Position.Y then
            targetPos=Vector3.new(targetPos.X,neonPlatform.Position.Y,targetPos.Z)
        end
        local t = 1 - math.exp(-NEON_CONFIG.PosSmooth*dt)
        local newX = neonPlatform.Position.X + (targetPos.X - neonPlatform.Position.X)*t
        local newZ = neonPlatform.Position.Z + (targetPos.Z - neonPlatform.Position.Z)*t
        local vertT = math.min(NEON_CONFIG.VertSpeed*dt,1)
        local newY = neonPlatform.Position.Y + (targetPos.Y - neonPlatform.Position.Y)*vertT
        neonPlatform.CFrame = CFrame.new(newX,newY,newZ)
        for _,e in pairs(neonEdges) do if e and e.Parent then
            local offset = e.Position - neonPlatform.Position
            e.CFrame = CFrame.new(newX,newY,newZ) + offset
        end end
    end
end)

-- ===== GUI =====
local gui = Instance.new("ScreenGui")
gui.Name = "PremiumMultiToolGUI"
gui.ResetOnSpawn=false
gui.Parent=player:WaitForChild("PlayerGui")

local mainFrame = Instance.new("Frame")
mainFrame.Size = UDim2.new(0,320,0,180)
mainFrame.Position = UDim2.new(0.5,-160,0.5,-90)
mainFrame.AnchorPoint=Vector2.new(0.5,0.5)
mainFrame.BackgroundColor3=Color3.fromRGB(20,20,25)
mainFrame.BorderSizePixel=0
mainFrame.Active=true
mainFrame.Draggable=true
mainFrame.Parent=gui

local corner = Instance.new("UICorner")
corner.CornerRadius=UDim.new(0,12)
corner.Parent=mainFrame

-- Header
local header = Instance.new("Frame")
header.Size = UDim2.new(1,0,0,40)
header.Position = UDim2.new(0,0,0,0)
header.BackgroundColor3=Color3.fromRGB(0,170,255)
header.BackgroundTransparency=0.9
header.BorderSizePixel=0
header.Parent=mainFrame

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1,-50,1,0)
title.Position=UDim2.new(0,15,0,0)
title.BackgroundTransparency=1
title.Text="🚀 PREMIUM MULTI-TOOL"
title.TextColor3=Color3.fromRGB(255,255,255)
title.TextSize=16
title.Font=Enum.Font.GothamBold
title.TextXAlignment=Enum.TextXAlignment.Left
title.Parent=header

local closeBtn=Instance.new("TextButton")
closeBtn.Size=UDim2.new(0,30,0,30)
closeBtn.Position=UDim2.new(1,-35,0,5)
closeBtn.BackgroundColor3=Color3.fromRGB(255,60,60)
closeBtn.Text="✕"
closeBtn.TextColor3=Color3.fromRGB(255,255,255)
closeBtn.TextSize=14
closeBtn.Font=Enum.Font.GothamBold
closeBtn.BorderSizePixel=0
closeBtn.Parent=header

-- Butonları görünür yapmak için AnchorPoint ve Pozisyon ayarlandı
