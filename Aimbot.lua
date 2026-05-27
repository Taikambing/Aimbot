-- Remove any pre-existing instance to prevent overlaps
if game.CoreGui:FindFirstChild("CeroAimAssistUI") then
    game.CoreGui.CeroAimAssistUI:Destroy()
end

-- =============================================================================
-- [GLOBAL SETTINGS & AIM CONFIGURATION STATE]
-- =============================================================================
_G.AimbotEnabled = false
_G.TeamCheck = false
_G.AimPart = "Head"
_G.Smoothness = 0.15
_G.FOVCircleRadius = 120
_G.ShowFOV = true

-- ESP Master Variable States
_G.ESP_Boxes = false
_G.ESP_Names = false
_G.ESP_Tracers = false
_G.ESP_Chams = false
_G.ESP_TeamCheck = true -- Hides your own teammates from showing up on ESP/Chams
_G.ESP_MaxDistance = 800

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- =============================================================================
-- [VISUAL FOV DRAWING PERIMETER]
-- =============================================================================
local FOVCircle = Drawing.new("Circle")
FOVCircle.Thickness = 1.5
FOVCircle.Color = Color3.fromRGB(255, 165, 0)
FOVCircle.Filled = false
FOVCircle.Transparency = 0.7
FOVCircle.Visible = false

-- Storage cache mapping for drawing objects
local ESP_Cache = {}
local Chams_Folder = Instance.new("Folder")
Chams_Folder.Name = "Cero_Chams_Storage"
Chams_Folder.Parent = game.CoreGui

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "CeroAimAssistUI"
ScreenGui.Parent = game.CoreGui

-- Main Panel window
local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 520, 0, 420)
MainFrame.Position = UDim2.new(0.3, 0, 0.25, 0)
MainFrame.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
MainFrame.BorderSizePixel = 0
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui
Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 8)

-- Header bar
local TopBar = Instance.new("Frame")
TopBar.Size = UDim2.new(1, 0, 0, 40)
TopBar.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
TopBar.BorderSizePixel = 0
TopBar.Parent = MainFrame
local TopCorner = Instance.new("UICorner")
TopCorner.CornerRadius = UDim.new(0, 8)
TopCorner.Parent = TopBar

local TitleText = Instance.new("TextLabel")
TitleText.Size = UDim2.new(0, 250, 1, 0)
TitleText.Position = UDim2.new(0, 15, 0, 0)
TitleText.BackgroundTransparency = 1
TitleText.Text = "| Cero's Complete Hack"
TitleText.TextColor3 = Color3.fromRGB(240, 240, 240)
TitleText.Font = Enum.Font.SourceSansBold
TitleText.TextSize = 18
TitleText.TextXAlignment = Enum.TextXAlignment.Left
TitleText.Parent = TopBar

-- Pure Floating UI Toggle Button Frame
local FloatBtn = Instance.new("TextButton")
FloatBtn.Size = UDim2.new(0, 60, 0, 60)
FloatBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
FloatBtn.Text = "Cero Menu"
FloatBtn.TextColor3 = Color3.fromRGB(255, 165, 0)
FloatBtn.Font = Enum.Font.SourceSansBold
FloatBtn.TextSize = 11
FloatBtn.Active = true
FloatBtn.Draggable = true
FloatBtn.Parent = ScreenGui
local FloatCorner = Instance.new("UICorner")
FloatCorner.CornerRadius = UDim.new(1, 0)
FloatCorner.Parent = FloatBtn

local UIStroke = Instance.new("UIStroke")
UIStroke.Thickness = 2
UIStroke.Color = Color3.fromRGB(230, 50, 50)
UIStroke.Parent = FloatBtn

MainFrame.Visible = true
FloatBtn.Text = "Close"
FloatBtn.TextColor3 = Color3.fromRGB(230, 50, 50)

FloatBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = not MainFrame.Visible
    FloatBtn.Text = MainFrame.Visible and "Close" or "Cero Menu"
    FloatBtn.TextColor3 = MainFrame.Visible and Color3.fromRGB(230, 50, 50) or Color3.fromRGB(255, 165, 0)
    UIStroke.Color = MainFrame.Visible and Color3.fromRGB(230, 50, 50) or Color3.fromRGB(255, 165, 0)
end)

-- Sidebar control layout setup
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 130, 1, -40)
Sidebar.Position = UDim2.new(0, 0, 0, 40)
Sidebar.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame

local TabBtn = Instance.new("TextButton")
TabBtn.Size = UDim2.new(0.9, 0, 0, 35)
TabBtn.Position = UDim2.new(0.05, 0, 0, 10)
TabBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
TabBtn.Text = "Main Interface"
TabBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
TabBtn.Font = Enum.Font.SourceSansBold
TabBtn.TextSize = 13
TabBtn.Parent = Sidebar
Instance.new("UICorner", TabBtn).CornerRadius = UDim.new(0, 4)

-- Option Canvas Scrolling Container Frame
local ContentFrame = Instance.new("ScrollingFrame")
ContentFrame.Size = UDim2.new(1, -150, 1, -55)
ContentFrame.Position = UDim2.new(0, 140, 0, 45)
ContentFrame.BackgroundTransparency = 1
ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 750) -- Expanded further for chams additions
ContentFrame.ScrollBarThickness = 3
ContentFrame.Parent = MainFrame

local Layout = Instance.new("UIListLayout")
Layout.Padding = UDim.new(0, 8)
Layout.Parent = ContentFrame
-- =============================================================================
-- [DYNAMIC ADVANCED SLIDER & TEXTBOX UI COMPONENT BUILDERS]
-- =============================================================================
local function createDropdown(parent, labelText, currentVal, options, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 38)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.4, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = labelText
    lbl.TextColor3 = Color3.fromRGB(180, 180, 180)
    lbl.Font = Enum.Font.SourceSans
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0.5, 0, 0.75, 0)
    btn.Position = UDim2.new(0.45, 0, 0.125, 0)
    btn.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    btn.Text = tostring(currentVal)
    btn.TextColor3 = Color3.fromRGB(240, 240, 240)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 13
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    local index = 1
    for i, o in ipairs(options) do if o == currentVal then index = i end end
    
    btn.MouseButton1Click:Connect(function()
        index = index + 1
        if index > #options then index = 1 end
        btn.Text = tostring(options[index])
        callback(options[index])
    end)
end

local function createToggle(parent, titleText, varName)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 42)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 4)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 1, 0)
    lbl.Position = UDim2.new(0, 10, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText
    lbl.TextColor3 = Color3.fromRGB(255, 255, 255)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 14
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 60, 0, 24)
    btn.Position = UDim2.new(1, -75, 0, 9)
    btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    btn.Text = "OFF"
    btn.TextColor3 = Color3.fromRGB(255, 255, 255)
    btn.Font = Enum.Font.SourceSansBold
    btn.TextSize = 11
    btn.Parent = frame
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 4)
    
    btn.MouseButton1Click:Connect(function()
        _G[varName] = not _G[varName]
        if _G[varName] then
            btn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
            btn.Text = "ON"
        else
            btn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
            btn.Text = "OFF"
        end
    end)
end

local function createAdvancedSlider(parent, titleText, minVal, maxVal, defaultVal, isDecimal, callback)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(1, -5, 0, 52)
    frame.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    frame.Parent = parent
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 5)
    
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(0.6, 0, 0, 22)
    lbl.Position = UDim2.new(0, 10, 0, 4)
    lbl.BackgroundTransparency = 1
    lbl.Text = titleText .. ": " .. tostring(defaultVal)
    lbl.TextColor3 = Color3.fromRGB(200, 200, 200)
    lbl.Font = Enum.Font.SourceSansBold
    lbl.TextSize = 13
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = frame
    
    local inputBox = Instance.new("TextBox")
    inputBox.Size = UDim2.new(0, 55, 0, 20)
    inputBox.Position = UDim2.new(1, -70, 0, 5)
    inputBox.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    inputBox.Text = tostring(defaultVal)
    inputBox.TextColor3 = Color3.fromRGB(255, 165, 0)
    inputBox.Font = Enum.Font.SourceSansBold
    inputBox.TextSize = 12
    inputBox.ClearTextOnFocus = true
    inputBox.Parent = frame
    Instance.new("UICorner", inputBox).CornerRadius = UDim.new(0, 4)
    
    local sliderBar = Instance.new("TextButton")
    sliderBar.Size = UDim2.new(0.9, 0, 0, 6)
    sliderBar.Position = UDim2.new(0.05, 0, 0, 36)
    sliderBar.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
    sliderBar.Text = ""
    sliderBar.Parent = frame
    Instance.new("UICorner", sliderBar).CornerRadius = UDim.new(0, 3)
    
    local sliderFill = Instance.new("Frame")
    local initPercent = (defaultVal - minVal) / (maxVal - minVal)
    sliderFill.Size = UDim2.new(initPercent, 0, 1, 0)
    sliderFill.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderBar
    Instance.new("UICorner", sliderFill).CornerRadius = UDim.new(0, 3)
    
    local function setValues(rawPercent)
        local pct = math.clamp(rawPercent, 0, 1)
        sliderFill.Size = UDim2.new(pct, 0, 1, 0)
        
        local exactCalculated = minVal + (pct * (maxVal - minVal))
        if not isDecimal then
            exactCalculated = math.floor(exactCalculated)
        else
            exactCalculated = math.floor(exactCalculated * 100) / 100
        end
        
        lbl.Text = titleText .. ": " .. tostring(exactCalculated)
        inputBox.Text = tostring(exactCalculated)
        callback(exactCalculated)
    end
    
    local isSliding = false
    sliderBar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = true
            local p = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            setValues(p)
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if isSliding and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local p = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
            setValues(p)
        end
    end)
    
    sliderBar.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            isSliding = false
        end
    end)
    
    inputBox.FocusLost:Connect(function(enterPressed)
        local numericVal = tonumber(inputBox.Text)
        if numericVal then
            local clampedVal = math.clamp(numericVal, minVal, maxVal)
            local targetPercent = (clampedVal - minVal) / (maxVal - minVal)
            setValues(targetPercent)
        end
    end)
end
-- =============================================================================
-- [RENDER THE INTERACTIVE UI CONTROLS & CONFIG MANAGER]
-- =============================================================================
local headAIM = Instance.new("TextLabel", ContentFrame)
headAIM.Size = UDim2.new(1, 0, 0, 20)
headAIM.Text = "--- AIMBOT ASSIST CONFIGS ---"
headAIM.TextColor3 = Color3.fromRGB(120, 120, 120)
headAIM.Font = Enum.Font.SourceSansBold
headAIM.TextSize = 12
headAIM.BackgroundTransparency = 1

createToggle(ContentFrame, "Enable Aim Assist Master", "AimbotEnabled")
createToggle(ContentFrame, "Aimbot: Ignore Teammates", "TeamCheck")
createToggle(ContentFrame, "Render FOV Target Ring", "ShowFOV")
createDropdown(ContentFrame, "Lock-On Target Bone:", _G.AimPart, {"Head", "HumanoidRootPart", "UpperTorso"}, function(v) _G.AimPart = v end)

createAdvancedSlider(ContentFrame, "FOV Ring Target Radius", 30, 500, _G.FOVCircleRadius, false, function(v) _G.FOVCircleRadius = v end)
createAdvancedSlider(ContentFrame, "Tracking Smoothness Scale", 0.01, 1.0, _G.Smoothness, true, function(v) _G.Smoothness = v end)

local headESP = Instance.new("TextLabel", ContentFrame)
headESP.Size = UDim2.new(1, 0, 0, 20)
headESP.Text = "--- VISUAL SENSOR MODS (ESP) ---"
headESP.TextColor3 = Color3.fromRGB(120, 120, 120)
headESP.Font = Enum.Font.SourceSansBold
headESP.TextSize = 12
headESP.BackgroundTransparency = 1

createToggle(ContentFrame, "ESP: Hide Teammates (Team Filter)", "ESP_TeamCheck")
createToggle(ContentFrame, "Enable 2D Wireframe Boxes", "ESP_Boxes")
createToggle(ContentFrame, "Enable Name + Distance Text", "ESP_Names")
createToggle(ContentFrame, "Enable Center Snap Tracers", "ESP_Tracers")
createToggle(ContentFrame, "Enable Wall-Hack See Through Chams", "ESP_Chams")

createAdvancedSlider(ContentFrame, "Max Sensor Rendering Limit", 100, 3000, _G.ESP_MaxDistance, false, function(v) _G.ESP_MaxDistance = v end)

local headSYSTEM = Instance.new("TextLabel", ContentFrame)
headSYSTEM.Size = UDim2.new(1, 0, 0, 20)
headSYSTEM.Text = "--- CONFIGURATION MANAGER ---"
headSYSTEM.TextColor3 = Color3.fromRGB(120, 120, 120)
headSYSTEM.Font = Enum.Font.SourceSansBold
headSYSTEM.TextSize = 12
headSYSTEM.BackgroundTransparency = 1

-- Container for the buttons
local ConfigActionFrame = Instance.new("Frame")
ConfigActionFrame.Size = UDim2.new(1, -5, 0, 45)
ConfigActionFrame.BackgroundTransparency = 1
ConfigActionFrame.Parent = ContentFrame

local SaveBtn = Instance.new("TextButton")
SaveBtn.Size = UDim2.new(0.46, 0, 0, 35)
SaveBtn.Position = UDim2.new(0, 0, 0, 5)
SaveBtn.BackgroundColor3 = Color3.fromRGB(40, 140, 240)
SaveBtn.Text = "SAVE CONFIG"
SaveBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
SaveBtn.Font = Enum.Font.SourceSansBold
SaveBtn.TextSize = 12
SaveBtn.Parent = ConfigActionFrame
Instance.new("UICorner", SaveBtn).CornerRadius = UDim.new(0, 4)

local LoadBtn = Instance.new("TextButton")
LoadBtn.Size = UDim2.new(0.46, 0, 0, 35)
LoadBtn.Position = UDim2.new(0.54, 0, 0, 5)
LoadBtn.BackgroundColor3 = Color3.fromRGB(40, 160, 40)
LoadBtn.Text = "LOAD CONFIG"
LoadBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
LoadBtn.Font = Enum.Font.SourceSansBold
LoadBtn.TextSize = 12
LoadBtn.Parent = ConfigActionFrame
Instance.new("UICorner", LoadBtn).CornerRadius = UDim.new(0, 4)

-- Config File Handling System
local HttpService = game:GetService("HttpService")
local fileName = "Cero_Aimbot_Config.json"

SaveBtn.MouseButton1Click:Connect(function()
    local currentSettings = {
        AimbotEnabled = _G.AimbotEnabled,
        TeamCheck = _G.TeamCheck,
        AimPart = _G.AimPart,
        Smoothness = _G.Smoothness,
        FOVCircleRadius = _G.FOVCircleRadius,
        ShowFOV = _G.ShowFOV,
        ESP_Boxes = _G.ESP_Boxes,
        ESP_Names = _G.ESP_Names,
        ESP_Tracers = _G.ESP_Tracers,
        ESP_Chams = _G.ESP_Chams,
        ESP_TeamCheck = _G.ESP_TeamCheck,
        ESP_MaxDistance = _G.ESP_MaxDistance
    }
    
    local success, encoded = pcall(function()
        return HttpService:JSONEncode(currentSettings)
    end)
    
    if success and writefile then
        writefile(fileName, encoded)
        SaveBtn.Text = "SAVED SUCCESS!"
        task.wait(1.5)
        SaveBtn.Text = "SAVE CONFIG"
    else
        SaveBtn.Text = "SAVE FAILED"
        task.wait(1.5)
        SaveBtn.Text = "SAVE CONFIG"
    end
end)

LoadBtn.MouseButton1Click:Connect(function()
    if readfile and isfile and isfile(fileName) then
        local success, decoded = pcall(function()
            return HttpService:JSONDecode(readfile(fileName))
        end)
        
        if success then
            -- Safely unpack settings back into states
            _G.AimbotEnabled = decoded.AimbotEnabled or false
            _G.TeamCheck = decoded.TeamCheck or false
            _G.AimPart = decoded.AimPart or "Head"
            _G.Smoothness = decoded.Smoothness or 0.15
            _G.FOVCircleRadius = decoded.FOVCircleRadius or 120
            _G.ShowFOV = decoded.ShowFOV or false
            _G.ESP_Boxes = decoded.ESP_Boxes or false
            _G.ESP_Names = decoded.ESP_Names or false
            _G.ESP_Tracers = decoded.ESP_Tracers or false
            _G.ESP_Chams = decoded.ESP_Chams or false
            _G.ESP_TeamCheck = decoded.ESP_TeamCheck or false
            _G.ESP_MaxDistance = decoded.ESP_MaxDistance or 800
            
            LoadBtn.Text = "LOADED SUCCESS!"
            task.wait(1.5)
            LoadBtn.Text = "LOAD CONFIG"
            
            -- Force user interface display refresh
            if ScreenGui and game.CoreGui:FindFirstChild("CeroAimAssistUI") then
                -- Closes and re-opens quickly to visual-refresh the ON/OFF switches
                MainFrame.Visible = false
                task.wait(0.1)
                MainFrame.Visible = true
            end
        else
            LoadBtn.Text = "DECODE ERROR"
            task.wait(1.5)
            LoadBtn.Text = "LOAD CONFIG"
        end
    else
        LoadBtn.Text = "NO FILE FOUND"
        task.wait(1.5)
        LoadBtn.Text = "LOAD CONFIG"
    end
end)
-- =============================================================================
-- [ESP GRAPHICS PROCESSING GENERATION AND CORE LIFECYCLES]
-- =============================================================================
local function createPlayerESP(targetPlayer)
    if ESP_Cache[targetPlayer] then return end
    
    local lines = {
        Box = Drawing.new("Square"),
        Name = Drawing.new("Text"),
        Tracer = Drawing.new("Line"),
        Cham = Instance.new("Highlight")
    }
    
    lines.Box.Thickness = 1
    lines.Box.Filled = false
    lines.Box.Transparency = 0.8
    
    lines.Name.Size = 13
    lines.Name.Center = true
    lines.Name.Outline = true
    lines.Name.Transparency = 0.9
    
    lines.Tracer.Thickness = 1.2
    lines.Tracer.Transparency = 0.6
    
    -- Configure Chams parameters container safely
    lines.Cham.Name = "Cham_" .. targetPlayer.Name
    lines.Cham.FillTransparency = 0.5
    lines.Cham.OutlineTransparency = 0.1
    lines.Cham.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    lines.Cham.Enabled = false
    lines.Cham.Parent = Chams_Folder
    
    ESP_Cache[targetPlayer] = lines
end

local function cleanESPInstance(targetPlayer)
    if ESP_Cache[targetPlayer] then
        for _, object in pairs(ESP_Cache[targetPlayer]) do
            pcall(function() object:Remove() end)
            pcall(function() object:Destroy() end)
        end
        ESP_Cache[targetPlayer] = nil
    end
end

Players.PlayerAdded:Connect(createPlayerESP)
Players.PlayerRemoving:Connect(cleanESPInstance)
for _, p in ipairs(Players:GetPlayers()) do if p ~= LocalPlayer then createPlayerESP(p) end end

local function getClosestPlayerToCrosshair()
    local targetBodyPart = nil
    local shortestDistance = _G.FOVCircleRadius
    
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            if not _G.TeamCheck or player.Team ~= LocalPlayer.Team then
                local bodyPart = player.Character:FindFirstChild(_G.AimPart)
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                
                if bodyPart and humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(bodyPart.Position)
                    if onScreen then
                        local mousePos = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            targetBodyPart = bodyPart
                        end
                    end
                end
            end
        end
    end
    return targetBodyPart
end

local isMouseButton2Down = false
UserInputService.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then isMouseButton2Down = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then isMouseButton2Down = false end end)

-- Main Pipeline Frame Link Execution Engine
game:GetService("RunService").RenderStepped:Connect(function()
    -- Sync dynamic drawing overlay values frame-by-frame
    if _G.ShowFOV and _G.AimbotEnabled then
        local mouseLocation = UserInputService:GetMouseLocation()
        FOVCircle.Position = Vector2.new(mouseLocation.X, mouseLocation.Y)
        FOVCircle.Radius = _G.FOVCircleRadius
        FOVCircle.Visible = true
    else
        FOVCircle.Visible = false
    end
    
    if _G.AimbotEnabled and isMouseButton2Down then
        local targetPart = getClosestPlayerToCrosshair()
        if targetPart then
            local lookAtMatrix = CFrame.new(Camera.CFrame.Position, targetPart.Position)
            Camera.CFrame = Camera.CFrame:Lerp(lookAtMatrix, _G.Smoothness)
        end
    end
    
    -- Processing ESP loop engine states
    for vPlayer, vObjects in pairs(ESP_Cache) do
        local character = vPlayer.Character
        local rootPart = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        
        -- Team Filter Integration check logic
        local isTeammate = (vPlayer.Team == LocalPlayer.Team)
        local shouldRender = true
        if _G.ESP_TeamCheck and isTeammate then
            shouldRender = false
        end
        
        if rootPart and humanoid and humanoid.Health > 0 and shouldRender then
            local worldPos = rootPart.Position
            local screenPos, onScreen = Camera:WorldToViewportPoint(worldPos)
            local totalStuds = math.floor((Camera.CFrame.Position - worldPos).Magnitude)
            
            if totalStuds <= _G.ESP_MaxDistance then
                -- Color Calibration Matrix (Teammate Blue vs Enemy Red)
                local colorValue = isTeammate and Color3.fromRGB(40, 140, 240) or Color3.fromRGB(240, 40, 40)
                
                -- 1. Wall-Hack Chams Processing Frame Updates
                if _G.ESP_Chams then
                    vObjects.Cham.Adornee = character
                    vObjects.Cham.FillColor = colorValue
                    vObjects.Cham.OutlineColor = Color3.fromRGB(255, 255, 255)
                    vObjects.Cham.Enabled = true
                else vObjects.Cham.Enabled = false end
                
                if onScreen then
                    local factor = 1000 / (screenPos.Z * 3)
                    local boxWidth, boxHeight = 4 * factor, 6 * factor
                    
                    -- 2. 2D Wireframe Box Update
                    if _G.ESP_Boxes then
                        vObjects.Box.Size = Vector2.new(boxWidth, boxHeight)
                        vObjects.Box.Position = Vector2.new(screenPos.X - (boxWidth / 2), screenPos.Y - (boxHeight / 2))
                        vObjects.Box.Color = colorValue
                        vObjects.Box.Visible = true
                    else vObjects.Box.Visible = false end
                    
                    -- 3. Distance and Name Labels Update
                    if _G.ESP_Names then
                        vObjects.Name.Text = vPlayer.Name .. " [" .. tostring(totalStuds) .. "s]"
                        vObjects.Name.Position = Vector2.new(screenPos.X, screenPos.Y - (boxHeight / 2) - 18)
                        vObjects.Name.Color = colorValue
                        vObjects.Name.Visible = true
                    else vObjects.Name.Visible = false end
                    
                    -- 4. Snap Vector Tracer Trackers Update
                    if _G.ESP_Tracers then
                        vObjects.Tracer.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                        vObjects.Tracer.To = Vector2.new(screenPos.X, screenPos.Y + (boxHeight / 2))
                        vObjects.Tracer.Color = colorValue
                        vObjects.Tracer.Visible = true
                    else vObjects.Tracer.Visible = false end
                else
                    vObjects.Box.Visible, vObjects.Name.Visible, vObjects.Tracer.Visible = false, false, false
                end
            else
                vObjects.Box.Visible, vObjects.Name.Visible, vObjects.Tracer.Visible, vObjects.Cham.Enabled = false, false, false, false
            end
        else
            vObjects.Box.Visible, vObjects.Name.Visible, vObjects.Tracer.Visible, vObjects.Cham.Enabled = false, false, false, false
        end
    end
end)

print("Cero's Ultimate Aim Assist, Chams & Color Team ESP Online!")
