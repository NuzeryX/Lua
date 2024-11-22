local Player = game:GetService("Players").LocalPlayer
local Camera = workspace.CurrentCamera
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Settings for fine-tuning
local SETTINGS = {
    smoothing = {
        camera = 0.125,
        movement = 0.08
    },
    limits = {
        maxVelocity = 20
    }
}

-- State management
local state = {
    lookVector = Vector3.new()
}

local function lerp(a, b, t)
    return a + (b - a) * math.clamp(t, 0, 1)
end

local connection = RunService.RenderStepped:Connect(function(deltaTime)
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart or humanoid.Health <= 0 then
        connection:Disconnect()
        return
    end

    -- Update look vector smoothly
    state.lookVector = lerp(state.lookVector, Camera.CFrame.LookVector, SETTINGS.smoothing.camera * deltaTime)
    
    -- Set camera zoom limits
    Player.CameraMaxZoomDistance = 128
    Player.CameraMinZoomDistance = 0.5
end)