local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

-- Film grain settings
local GRAIN_INTENSITY = 0.97 -- Higher = more transparent (0.95-0.98 recommended)
local GRAIN_PARTICLE_COUNT = 300 -- More particles for smoother grain
local GRAIN_SCALE = 0.008 -- Very small particles
local UPDATE_FREQUENCY = 0.03 -- How often particles update position

-- Create the grain effect UI
local PlayerGui = game.Players.LocalPlayer:WaitForChild("PlayerGui")
local grainGui = Instance.new("ScreenGui")
grainGui.Name = "FilmGrain"
grainGui.IgnoreGuiInset = true
grainGui.Parent = PlayerGui

-- Create the grain container
local grainFrame = Instance.new("Frame")
grainFrame.Name = "GrainLayer"
grainFrame.Size = UDim2.fromScale(1, 1)
grainFrame.BackgroundTransparency = 1
grainFrame.BorderSizePixel = 0
grainFrame.Parent = grainGui

-- Create grain particles
local grainParticles = {}
for i = 1, GRAIN_PARTICLE_COUNT do
    local grain = Instance.new("Frame")
    grain.BorderSizePixel = 0
    grain.Size = UDim2.fromScale(GRAIN_SCALE, GRAIN_SCALE)
    grain.BackgroundColor3 = Color3.new(0, 0, 0) -- Black grain
    grain.BackgroundTransparency = GRAIN_INTENSITY
    grain.Position = UDim2.fromScale(math.random(), math.random())
    grain.Parent = grainFrame
    grainParticles[i] = grain
end

-- Update grain effect
local function updateGrain()
    for _, grain in ipairs(grainParticles) do
        if math.random() < UPDATE_FREQUENCY then
            grain.Position = UDim2.fromScale(math.random(), math.random())
            grain.BackgroundTransparency = GRAIN_INTENSITY + (math.random() * 0.02 - 0.01)
        end
    end
end

-- Connect the update function
local connection = RunService.RenderStepped:Connect(updateGrain)

-- Cleanup function
local function cleanup()
    connection:Disconnect()
    grainGui:Destroy()
end

-- Intensity control function
local function setIntensity(intensity)
    intensity = math.clamp(intensity, 0, 1)
    GRAIN_INTENSITY = 0.95 + (intensity * 0.04)
end

return {
    cleanup = cleanup,
    setIntensity = setIntensity
} 