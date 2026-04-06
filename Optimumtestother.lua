-- Booting Rayfield & Essential Services
local Rayfield = loadstring(game:HttpGet('https://sirius.menu/rayfield'))()
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local CoreGui = game:GetService("CoreGui")
local VirtualUser = game:GetService("VirtualUser")
local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Global Variables for Features
local Flags = {
    SilentAim = false, SilentBots = false, SilentKeybind = Enum.KeyCode.S,
    Triggerbox = false, TriggerBots = false, TriggerDelay = 0, TriggerHold = false,
    Stretch = false, StretchType = "Default",
    DistanceESP = false, Desync = false,
    GodMode = false, Invisible = false, Hitbox = false, HitboxSize = 5,
    DisableNotifs = false, DisableSound = false
}

local ESP_Objects = {}
local LastTriggerTime = 0

-- Utility Functions
local function IsBot(character)
    if not character then return false end
    local player = Players:GetPlayerFromCharacter(character)
    return player == nil 
end

local function GetClosestTarget()
    local closestChar = nil
    local shortestDistance = math.huge

    local function checkEntity(character, isPlayer)
        if not character or character == LocalPlayer.Character then return end
        local root = character:FindFirstChild("HumanoidRootPart")
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        
        if root and humanoid and humanoid.Health > 0 then
            -- Team Check for Players
            if isPlayer then
                local plr = Players:GetPlayerFromCharacter(character)
                if Flags.HitboxTeamCheck and plr.Team == LocalPlayer.Team then return end
            elseif not Flags.SilentBots then
                return -- Skip bots if flag is off
            end

            local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
            if onScreen then
                local dist = (Vector2.new(Mouse.X, Mouse.Y) - Vector2.new(pos.X, pos.Y)).Magnitude
                if dist < shortestDistance then
                    shortestDistance = dist
                    closestChar = character
                end
            end
        end
    end

    -- Check Players
    for _, plr in ipairs(Players:GetPlayers()) do
        checkEntity(plr.Character, true)
    end
    -- Check Bots
    if Flags.SilentBots then
        for _, obj in ipairs(Workspace:GetDescendants()) do
            if obj:IsA("Model") and obj:FindFirstChildOfClass("Humanoid") and not Players:GetPlayerFromCharacter(obj) then
                checkEntity(obj, false)
            end
        end
    end

    return closestChar
end

-- Custom Notification Handler
local function Notify(title, content)
    if Flags.DisableAllNotifs then return end
    Rayfield:Notify({
        Title = title,
        Content = content,
        Duration = 3,
        Image = 4483345998,
    })
end

-- Creating the Main Window
local Window = Rayfield:CreateWindow({
   Name = "Optimum Script | v0.1.1",
   LoadingTitle = "Loading Optimum Script...",
   LoadingSubtitle = "Version 0.1.1",
   Theme = "Default",
   ConfigurationSaving = {
      Enabled = true,
      FolderName = "OptimumScript",
      FileName = "OptimumConfig"
   },
   KeySystem = false
})

-- ==========================================
-- 🎯 LEGIT TAB
-- ==========================================
local LegitTab = Window:CreateTab("Legit", 4483345998)

LegitTab:CreateSection("Silent Aim")

LegitTab:CreateToggle({
   Name = "Enable Silent Aim",
   CurrentValue = false,
   Flag = "SilentAimToggle",
   Callback = function(Value)
      Flags.SilentAim = Value
      Notify("Silent Aim", Value and "Enabled" or "Disabled")
   end,
})

-- BUG FIX: Changed 'CurrentKey' to 'CurrentKeybind'
LegitTab:CreateKeybind({
   Name = "Silent Aim Keybind (PC)",
   CurrentKeybind = "S", 
   HoldToInteract = false,
   Flag = "SilentAimBind",
   Callback = function(Keybind)
      Flags.SilentAim = not Flags.SilentAim
      Notify("Silent Aim", Flags.SilentAim and "Toggled ON via Keybind" or "Toggled OFF via Keybind")
   end,
})

LegitTab:CreateToggle({
   Name = "Affect Bots",
   CurrentValue = false,
   Flag = "SilentAimBots",
   Callback = function(Value) Flags.SilentBots = Value end,
})

-- Hooks for Silent Aim (Universal Metamethod Hook)
local oldNamecall
oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if Flags.SilentAim and (method == "Raycast" or method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist") then
        local target = GetClosestTarget()
        if target and target:FindFirstChild("Head") then
            local head = target.Head
            local origin
            if method == "Raycast" then
                origin = args[1]
                args[2] = (head.Position - origin).Unit * 1000 -- New Direction
            elseif method == "FindPartOnRay" or method == "FindPartOnRayWithIgnoreList" or method == "FindPartOnRayWithWhitelist" then
                origin = args[1].Origin
                args[1] = Ray.new(origin, (head.Position - origin).Unit * 1000)
            end
            return oldNamecall(self, unpack(args))
        end
    end
    return oldNamecall(self, ...)
end)

LegitTab:CreateSection("Triggerbox")

LegitTab:CreateToggle({
   Name = "Enable Triggerbox",
   CurrentValue = false,
   Flag = "TriggerboxToggle",
   Callback = function(Value) Flags.Triggerbox = Value end,
})

LegitTab:CreateToggle({
   Name = "Triggerbox Affect Bots",
   CurrentValue = false,
   Flag = "TriggerboxBots",
   Callback = function(Value) Flags.TriggerBots = Value end,
})

LegitTab:CreateSlider({
   Name = "Triggerbox Delay",
   Range = {0, 1000},
   Increment = 10,
   Suffix = "ms",
   CurrentValue = 0,
   Flag = "TriggerDelay",
   Callback = function(Value) Flags.TriggerDelay = Value end,
})

LegitTab:CreateParagraph({
   Title = "Triggerbox Info",
   Content = "PC: Hold Right-Click to activate.\nMobile: Activates automatically."
})

-- Triggerbox Logic
local isMobile = UserInputService.TouchEnabled
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Flags.TriggerHold = true end
end)
UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Flags.TriggerHold = false end
end)

RunService.RenderStepped:Connect(function()
    if Flags.Triggerbox then
        if not isMobile and not Flags.TriggerHold then return end -- PC requires hold
        
        local target = Mouse.Target
        if target and target.Parent then
            local char = target.Parent
            if char:IsA("Accessory") or char:IsA("Tool") then char = char.Parent end
            
            local humanoid = char:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local isPlayer = Players:GetPlayerFromCharacter(char) ~= nil
                
                -- Team check
                if isPlayer and Flags.HitboxTeamCheck then
                    local plr = Players:GetPlayerFromCharacter(char)
                    if plr.Team == LocalPlayer.Team then return end
                end

                if isPlayer or (Flags.TriggerBots and not isPlayer) then
                    local currentTime = tick() * 1000
                    if currentTime - LastTriggerTime >= Flags.TriggerDelay then
                        LastTriggerTime = currentTime
                        if mouse1click then
                            mouse1click()
                        else
                            VirtualUser:ClickButton1(Vector2.new(0,0))
                        end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- 👁️ VISUALS TAB
-- ==========================================
local VisualsTab = Window:CreateTab("Visuals", 4483345998)

VisualsTab:CreateSection("Screen Effects")

VisualsTab:CreateToggle({
   Name = "Enable Stretch Screen",
   CurrentValue = false,
   Flag = "StretchToggle",
   Callback = function(Value) Flags.Stretch = Value end,
})

VisualsTab:CreateDropdown({
   Name = "Stretch Resolution Selector",
   Options = {"Default", "4:3 (Classic)", "16:10", "Ultra-Wide", "Square"},
   CurrentOption = {"Default"},
   MultipleOptions = false,
   Flag = "StretchDropdown",
   Callback = function(Option) Flags.StretchType = Option[1] end,
})

-- Stretch Screen Logic
RunService.RenderStepped:Connect(function()
    if Flags.Stretch then
        local cam = Workspace.CurrentCamera
        if Flags.StretchType == "4:3 (Classic)" then
            cam.FieldOfView = 90
        elseif Flags.StretchType == "16:10" then
            cam.FieldOfView = 80
        elseif Flags.StretchType == "Ultra-Wide" then
            cam.FieldOfView = 120
        elseif Flags.StretchType == "Square" then
            cam.FieldOfView = 140
        else
            cam.FieldOfView = 70
        end
    end
end)

VisualsTab:CreateSection("ESP")

VisualsTab:CreateToggle({
   Name = "Distance ESP",
   CurrentValue = false,
   Flag = "DistanceESP",
   Callback = function(Value)
      Flags.DistanceESP = Value
      if not Value then
          for _, esp in pairs(ESP_Objects) do
              esp:Remove()
          end
          ESP_Objects = {}
      end
   end,
})

-- Distance ESP Logic
RunService.RenderStepped:Connect(function()
    if Flags.DistanceESP then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                local root = plr.Character.HumanoidRootPart
                local pos, onScreen = Camera:WorldToViewportPoint(root.Position)
                
                if not ESP_Objects[plr] then
                    local text = Drawing.new("Text")
                    text.Color = Color3.new(1, 1, 1)
                    text.Size = 18
                    text.Center = true
                    text.Outline = true
                    ESP_Objects[plr] = text
                end

                if onScreen and plr.Character.Humanoid.Health > 0 then
                    local dist = math.floor((LocalPlayer.Character.HumanoidRootPart.Position - root.Position).Magnitude)
                    ESP_Objects[plr].Position = Vector2.new(pos.X, pos.Y)
                    ESP_Objects[plr].Text = plr.Name .. " [" .. tostring(dist) .. "s]"
                    ESP_Objects[plr].Visible = true
                else
                    ESP_Objects[plr].Visible = false
                end
            elseif ESP_Objects[plr] then
                ESP_Objects[plr].Visible = false
            end
        end
    end
end)

Players.PlayerRemoving:Connect(function(plr)
    if ESP_Objects[plr] then
        ESP_Objects[plr]:Remove()
        ESP_Objects[plr] = nil
    end
end)

-- ==========================================
-- 👤 PLAYER TAB
-- ==========================================
local PlayerTab = Window:CreateTab("Player", 4483345998)

-- Desync UI Creation
local DesyncGui = Instance.new("ScreenGui")
DesyncGui.Parent = CoreGui
DesyncGui.Enabled = false
local DesyncFrame = Instance.new("Frame", DesyncGui)
DesyncFrame.Size = UDim2.new(0, 200, 0, 100)
DesyncFrame.Position = UDim2.new(0.5, -100, 0.1, 0)
DesyncFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
DesyncFrame.Active = true
DesyncFrame.Draggable = true 
local DesyncLabel = Instance.new("TextLabel", DesyncFrame)
DesyncLabel.Size = UDim2.new(1, 0, 1, 0)
DesyncLabel.Text = "Desync Active\n(Spoofing Velocity)"
DesyncLabel.TextColor3 = Color3.new(1, 1, 1)
DesyncLabel.BackgroundTransparency = 1

PlayerTab:CreateToggle({
   Name = "Desync UI (Toggle & Resize)",
   CurrentValue = false,
   Flag = "DesyncUI",
   Callback = function(Value)
      Flags.Desync = Value
      DesyncGui.Enabled = Value
   end,
})

-- Desync Logic (Velocity Spoofing)
RunService.Heartbeat:Connect(function()
    if Flags.Desync and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local root = LocalPlayer.Character.HumanoidRootPart
        local oldVel = root.Velocity
        root.Velocity = Vector3.new(math.random(-500, 500), math.random(-500, 500), math.random(-500, 500))
        RunService.RenderStepped:Wait()
        root.Velocity = oldVel
    end
end)

PlayerTab:CreateToggle({
   Name = "GodMode (Immune to Killbricks)",
   CurrentValue = false,
   Flag = "GodModeToggle",
   Callback = function(Value)
      Flags.GodMode = Value
      if Value then
          for _, obj in ipairs(Workspace:GetDescendants()) do
              if obj:IsA("TouchTransmitter") then
                  obj:Destroy()
              end
          end
      end
   end,
})

PlayerTab:CreateToggle({
   Name = "Invisible Character (Client Illusion)",
   CurrentValue = false,
   Flag = "InvisibleToggle",
   Callback = function(Value)
      Flags.Invisible = Value
      local char = LocalPlayer.Character
      if Value and char and char:FindFirstChild("LowerTorso") then
          local root = char:FindFirstChild("HumanoidRootPart")
          if root then
              local clone = root:Clone()
              clone.Parent = char
              root:Destroy()
          end
          Notify("Invisible", "Invisibility applied. You may need to reset to undo.")
      end
   end,
})

-- ==========================================
-- ⚔️ HITBOX TAB
-- ==========================================
local HitboxTab = Window:CreateTab("Hitbox", 4483345998)

HitboxTab:CreateToggle({
   Name = "Enable Hitbox Expander",
   CurrentValue = false,
   Flag = "HitboxToggle",
   Callback = function(Value) Flags.Hitbox = Value end,
})

HitboxTab:CreateToggle({
   Name = "Hitbox TeamCheck",
   CurrentValue = false,
   Flag = "HitboxTeamCheck",
   Callback = function(Value) Flags.HitboxTeamCheck = Value end,
})

HitboxTab:CreateSlider({
   Name = "Hitbox Size",
   Range = {2, 50},
   Increment = 1,
   Suffix = "Studs",
   CurrentValue = 5,
   Flag = "HitboxSize",
   Callback = function(Value) Flags.HitboxSize = Value end,
})

-- Hitbox Logic
RunService.RenderStepped:Connect(function()
    if Flags.Hitbox then
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                -- Team Check
                if Flags.HitboxTeamCheck and plr.Team == LocalPlayer.Team then
                    plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                    plr.Character.HumanoidRootPart.Transparency = 1
                    continue
                end
                
                plr.Character.HumanoidRootPart.Size = Vector3.new(Flags.HitboxSize, Flags.HitboxSize, Flags.HitboxSize)
                plr.Character.HumanoidRootPart.Transparency = 0.5
                plr.Character.HumanoidRootPart.BrickColor = BrickColor.new("Really red")
                plr.Character.HumanoidRootPart.CanCollide = false
            end
        end
    else
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
                plr.Character.HumanoidRootPart.Size = Vector3.new(2, 2, 1)
                plr.Character.HumanoidRootPart.Transparency = 1
            end
        end
    end
end)

-- ==========================================
-- ⚙️ MISC TAB
-- ==========================================
local MiscTab = Window:CreateTab("Misc", 4483345998)

MiscTab:CreateSection("Character & UI")

-- Fast Reset Mobile UI
local MobileResetGui = Instance.new("ScreenGui")
MobileResetGui.Parent = CoreGui
MobileResetGui.Enabled = false
local ResetBtn = Instance.new("TextButton", MobileResetGui)
ResetBtn.Size = UDim2.new(0, 100, 0, 50)
ResetBtn.Position = UDim2.new(0.8, 0, 0.1, 0)
ResetBtn.Text = "FAST RESET"
ResetBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
ResetBtn.TextColor3 = Color3.new(1, 1, 1)

ResetBtn.MouseButton1Click:Connect(function()
    local char = LocalPlayer.Character
    if char and char:FindFirstChild("Humanoid") then
        char.Humanoid.Health = 0
    end
end)

MiscTab:CreateToggle({
   Name = "Fast Reset Character UI (Mobile)",
   CurrentValue = false,
   Flag = "MobileResetUI",
   Callback = function(Value) MobileResetGui.Enabled = Value end,
})

-- BUG FIX: Changed 'CurrentKey' to 'CurrentKeybind'
MiscTab:CreateKeybind({
   Name = "Fast Reset Keybind (PC)",
   CurrentKeybind = "R", 
   HoldToInteract = false,
   Flag = "PCResetBind",
   Callback = function(Keybind)
      local char = LocalPlayer.Character
      if char and char:FindFirstChild("Humanoid") then
          char.Humanoid.Health = 0
      end
   end,
})

-- Font Changer Function
local function ChangeFonts(fontName)
    local targetFont = Enum.Font.SourceSans
    if fontName == "Minecraft" then targetFont = Enum.Font.Arcade
    elseif fontName == "Gothic" then targetFont = Enum.Font.Gothic
    elseif fontName == "Sci-Fi" then targetFont = Enum.Font.SciFi
    elseif fontName == "Comic" then targetFont = Enum.Font.Cartoon
    end

    local function scanAndChange(parent)
        for _, obj in ipairs(parent:GetDescendants()) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.Font = targetFont
            end
        end
    end
    
    scanAndChange(LocalPlayer.PlayerGui)
end

MiscTab:CreateDropdown({
   Name = "Text Font Changer",
   Options = {"Default", "Minecraft", "Gothic", "Sci-Fi", "Comic"},
   CurrentOption = {"Default"},
   MultipleOptions = false,
   Flag = "FontChanger",
   Callback = function(Option)
      ChangeFonts(Option[1])
   end,
})

-- ==========================================
-- 🔔 NOTIFICATIONS & SOUND SETTINGS
-- ==========================================
local SettingsTab = Window:CreateTab("Settings", 4483345998)

SettingsTab:CreateToggle({
   Name = "Disable Notifications & Sound",
   CurrentValue = false,
   Flag = "DisableAllNotifs",
   Callback = function(Value) Flags.DisableAllNotifs = Value end,
})

SettingsTab:CreateToggle({
   Name = "Disable Notification Sounds Only",
   CurrentValue = false,
   Flag = "DisableNotifSound",
   Callback = function(Value)
      Flags.DisableSound = Value
      for _, snd in pairs(CoreGui:GetDescendants()) do
          if snd:IsA("Sound") then
              snd.Volume = Value and 0 or 1
          end
      end
   end,
})

-- Load Configuration
Rayfield:LoadConfiguration()
