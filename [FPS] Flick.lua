local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local localPlayer = Players.LocalPlayer
local camera = Workspace.CurrentCamera

local FOV_RADIUS = 500
local FOV_COLOR = Color3.fromRGB(255, 255, 255)
local SHOW_FOV = true

local isAlive = false

local fovCircle = nil
local drawingSuccess, drawingLib = pcall(function()
    return Drawing
end)

if drawingSuccess and drawingLib and SHOW_FOV then
    local c = drawingLib.new("Circle")
    c.Color = FOV_COLOR
    c.Thickness = 1
    c.NumSides = 32
    c.Radius = FOV_RADIUS
    c.Filled = false
    c.Visible = true
    fovCircle = c
end

if fovCircle then
    RunService.RenderStepped:Connect(function()
        if SHOW_FOV and isAlive and camera then
            local viewportSize = camera.ViewportSize
            if viewportSize then
                fovCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
                fovCircle.Visible = true
            else
                fovCircle.Visible = false
            end
        else
            fovCircle.Visible = false
        end
    end)
end

local function monitorCharacter(character)
    isAlive = true
    local humanoid = character:WaitForChild("Humanoid", 5)
    if humanoid then
        humanoid.Died:Connect(function()
            isAlive = false
        end)
    end
end

if localPlayer.Character then 
    monitorCharacter(localPlayer.Character) 
end
localPlayer.CharacterAdded:Connect(monitorCharacter)
localPlayer.CharacterRemoving:Connect(function() 
    isAlive = false 
end)

local function getClosestHeadInFOV()
    if not isAlive or not camera then 
        return nil 
    end

    local closestHead = nil
    local shortestDistance = FOV_RADIUS
    local viewportSize = camera.ViewportSize
    local screenCenter = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= localPlayer then
            local char = player.Character
            if char then
                local humanoid = char:FindFirstChildOfClass("Humanoid")
                local head = char:FindFirstChild("Head")

                if humanoid and head and humanoid.Health > 0 then
                    local screenPosition, onScreen = camera:WorldToViewportPoint(head.Position)
                    if onScreen then
                        local targetPos2D = Vector2.new(screenPosition.X, screenPosition.Y)
                        local distance = (targetPos2D - screenCenter).Magnitude
                        if distance < shortestDistance then
                            shortestDistance = distance
                            closestHead = head
                        end
                    end
                end
            end
        end
    end
    return closestHead
end

local BulletHandlerModule = nil

local replicatedStorageModules = ReplicatedStorage:FindFirstChild("ModuleScripts")
if replicatedStorageModules then
    local gunModules = replicatedStorageModules:FindFirstChild("GunModules")
    if gunModules then
        local foundHandler = gunModules:FindFirstChild("BulletHandler")
        if foundHandler then
            BulletHandlerModule = require(foundHandler)
        end
    end
end

if not BulletHandlerModule and type(getloadedmodules) == "function" then
    for _, mod in ipairs(getloadedmodules()) do
        if mod.Name == "BulletHandler" then
            BulletHandlerModule = require(mod)
            break
        end
    end
end

if BulletHandlerModule and type(BulletHandlerModule.Fire) == "function" then
    local originalFire = BulletHandlerModule.Fire

    BulletHandlerModule.Fire = function(p6)
        if isAlive and type(p6) == "table" then
            if p6.Origin and p6.Direction then
                local targetHead = getClosestHeadInFOV()
                if targetHead then
                    local targetPosition = targetHead.Position
                    local newDirection = (targetPosition - p6.Origin).Unit
                    
                    
                    if newDirection.X == newDirection.X then
                        p6.Direction = newDirection
                    end
                end
            end
        end
        return originalFire(p6)
    end
end
