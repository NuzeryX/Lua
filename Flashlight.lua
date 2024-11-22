-- Add services at the top
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Variables
local sound = game.Workspace.SFX
local player = game.Players.LocalPlayer
local camera = game.Workspace.CurrentCamera

-- Settings
local settings = {
    -- Light settings
    brightness = 0.8,
    range = 80,
    angle = 90,  -- Narrower angle for better atmosphere
    
    -- Movement settings
    followSpeed = 0.12,     -- Slightly slower follow for more weight
    swayAmount = {          -- Separate sway amounts per axis
        idle = Vector3.new(0.15, 0.1, 0.05),    -- Idle breathing sway
        walk = Vector3.new(0.3, 0.25, 0.15),    -- Walking sway
        sprint = Vector3.new(0.45, 0.4, 0.25)   -- Running sway
    },
    swaySpeed = {           -- Different speeds for different movements
        idle = 1.5,         -- Slower for breathing
        walk = 2.5,         -- Normal walking pace
        sprint = 4          -- Faster for running
    },
    
    -- Inertia settings
    maxInertia = 0.8,      -- Increased for more dramatic movement
    inertiaDecay = 0.85,   -- Slower decay for smoother transitions
    
    -- Flicker settings
    flickerChance = 0.03,        -- 3% chance per frame
    flickerIntensityMin = 0.7,   -- Minimum brightness during flicker
    flickerIntensityMax = 0.9,   -- Maximum brightness during flicker
    
    -- Glitch settings
    glitch = {
        minInterval = 3,    -- Minimum time between glitches
        maxInterval = 8,    -- Maximum time between glitches
        duration = 0.2,     -- How long each glitch lasts
        chance = 0.3,       -- Chance of glitch occurring when interval hits
        
        -- Intensity ranges
        flickerSpeed = {min = 0.05, max = 0.15},  -- How fast it flickers during glitch
        brightnessRange = {min = 0.3, max = 1.2}, -- Brightness variation during glitch
        angleRange = {min = 110, max = 130},      -- Angle variation during glitch
        rangeRange = {min = 70, max = 90},        -- Range variation during glitch
        
        -- Color variation during glitch
        colorShift = {
            enabled = true,
            colors = {
                Color3.new(1, 1, 1),      -- Normal
                Color3.new(1, 0.9, 0.8),  -- Warm
                Color3.new(0.8, 0.9, 1),  -- Cool
            }
        }
    }
}

-- State
local state = {
    isFlashlightOn = false,
    lastCameraRotation = CFrame.new(),
    currentInertia = Vector3.new(),
    targetPosition = Vector3.new(),
    
    -- Glitch state
    lastGlitchTime = 0,
    isGlitching = false,
    nextGlitchInterval = math.random(settings.glitch.minInterval, settings.glitch.maxInterval),
    glitchConnection = nil
}

-- Create flashlight parts
local flashlightPart = Instance.new("Part")
flashlightPart.Parent = camera
flashlightPart.Anchored = true
flashlightPart.CanCollide = false
flashlightPart.Size = Vector3.new(0.1, 0.1, 0.1)
flashlightPart.Transparency = 1

local flashlight = Instance.new("SpotLight")
flashlight.Parent = flashlightPart
flashlight.Enabled = false
flashlight.Brightness = settings.brightness
flashlight.Range = settings.range
flashlight.Angle = settings.angle

-- Smooth lerp function with delta time
local function smoothLerp(a, b, speed, dt)
    return a + (b - a) * (1 - math.exp(-speed * dt))
end

-- Function to calculate sway
local function calculateSway(time, character)
    local humanoid = character and character:FindFirstChild("Humanoid")
    local velocity = humanoid and humanoid.RootPart and humanoid.RootPart.Velocity or Vector3.new()
    local speed = velocity.Magnitude
    
    -- Determine movement state
    local currentSwayAmount
    local currentSwaySpeed
    
    if speed < 0.1 then
        currentSwayAmount = settings.swayAmount.idle
        currentSwaySpeed = settings.swaySpeed.idle
    elseif speed < 14 then
        currentSwayAmount = settings.swayAmount.walk
        currentSwaySpeed = settings.swaySpeed.walk
    else
        currentSwayAmount = settings.swayAmount.sprint
        currentSwaySpeed = settings.swaySpeed.sprint
    end
    
    -- Calculate multi-layered sway
    local sway = Vector3.new(
        math.sin(time * currentSwaySpeed) * currentSwayAmount.X +
        math.sin(time * currentSwaySpeed * 0.5) * currentSwayAmount.X * 0.3,
        
        math.sin(time * currentSwaySpeed * 1.2 + 0.5) * currentSwayAmount.Y +
        math.cos(time * currentSwaySpeed * 0.7) * currentSwayAmount.Y * 0.2,
        
        math.sin(time * currentSwaySpeed * 0.8 + 1) * currentSwayAmount.Z +
        math.cos(time * currentSwaySpeed * 0.3) * currentSwayAmount.Z * 0.4
    )
    
    return sway
end

-- Glitch effect functions
local function startGlitchEffect()
    if state.isGlitching then return end
    state.isGlitching = true
    
    -- Create rapid update connection for glitch effect
    state.glitchConnection = RunService.RenderStepped:Connect(function()
        -- Randomize properties
        flashlight.Brightness = math.random(
            settings.glitch.brightnessRange.min * 100,
            settings.glitch.brightnessRange.max * 100
        ) / 100
        
        flashlight.Angle = math.random(
            settings.glitch.angleRange.min,
            settings.glitch.angleRange.max
        )
        
        flashlight.Range = math.random(
            settings.glitch.rangeRange.min,
            settings.glitch.rangeRange.max
        )
        
        -- Random color shift
        if settings.glitch.colorShift.enabled then
            flashlight.Color = settings.glitch.colorShift.colors[
                math.random(1, #settings.glitch.colorShift.colors)
            ]
        end
        
        -- Random enable/disable for flicker effect
        if math.random() < 0.3 then
            flashlight.Enabled = not flashlight.Enabled
        end
    end)
    
    -- Stop glitch effect after duration
    task.delay(settings.glitch.duration, function()
        if state.glitchConnection then
            state.glitchConnection:Disconnect()
            state.glitchConnection = nil
        end
        
        -- Reset to normal values
        if state.isFlashlightOn then
            flashlight.Enabled = true
            flashlight.Brightness = settings.brightness
            flashlight.Range = settings.range
            flashlight.Angle = settings.angle
            flashlight.Color = settings.glitch.colorShift.colors[1]
        end
        
        state.isGlitching = false
    end)
end

-- Check for glitch intervals
local function updateGlitchCheck(dt)
    if not state.isFlashlightOn or state.isGlitching then return end
    
    local timeSinceLastGlitch = tick() - state.lastGlitchTime
    if timeSinceLastGlitch >= state.nextGlitchInterval then
        if math.random() < settings.glitch.chance then
            startGlitchEffect()
            state.lastGlitchTime = tick()
        end
        state.nextGlitchInterval = math.random(
            settings.glitch.minInterval,
            settings.glitch.maxInterval
        )
    end
end

-- Toggle flashlight function with smooth fade
local function toggleFlashlight()
    state.isFlashlightOn = not state.isFlashlightOn
    
    if state.isFlashlightOn then
        flashlight.Enabled = true
        if sound and sound.Flashlight and sound.Flashlight["Flashlight On"] then
            sound.Flashlight["Flashlight On"]:Play()
        end
        
        TweenService:Create(flashlight, TweenInfo.new(0.3), {
            Brightness = settings.brightness
        }):Play()
    else
        local fadeOut = TweenService:Create(flashlight, TweenInfo.new(0.3), {
            Brightness = 0
        })
        
        fadeOut.Completed:Connect(function()
            flashlight.Enabled = false
        end)
        
        fadeOut:Play()
        if sound and sound.Flashlight and sound.Flashlight["Flashlight Off"] then
            sound.Flashlight["Flashlight Off"]:Play()
        end
    end
end

-- Connect toggle input
player:GetMouse().KeyDown:Connect(function(key)
    if key:lower() == "f" then
        toggleFlashlight()
    end
end)

-- Main update loop
RunService.RenderStepped:Connect(function(dt)
    if not state.isFlashlightOn then return end
    
    local character = player.Character
    
    updateGlitchCheck(dt)
    
    -- Calculate camera movement
    local cameraCFrame = camera.CFrame
    local cameraRotation = cameraCFrame.Rotation
    local rotationDelta = cameraRotation:ToObjectSpace(state.lastCameraRotation)
    state.lastCameraRotation = cameraRotation
    
    -- Update inertia based on camera movement
    local rotationSpeed = Vector3.new(
        rotationDelta:ToOrientation()
    ) * (60 * dt)
    
    state.currentInertia = smoothLerp(
        state.currentInertia,
        rotationSpeed * settings.maxInertia,
        settings.inertiaDecay,
        dt
    )
    
    -- Calculate target position with improved sway and inertia
    local basePosition = cameraCFrame.Position + cameraCFrame.LookVector * 1.5
    local sway = calculateSway(tick(), character)
    local inertiaOffset = state.currentInertia
    
    -- Add slight downward tilt
    local downwardTilt = cameraCFrame.UpVector * -0.1
    
    state.targetPosition = basePosition + sway + inertiaOffset + downwardTilt
    
    -- Smooth position update
    flashlightPart.Position = smoothLerp(
        flashlightPart.Position,
        state.targetPosition,
        settings.followSpeed / dt,
        dt
    )
    
    -- Update orientation to follow camera
    flashlightPart.CFrame = CFrame.lookAt(
        flashlightPart.Position,
        flashlightPart.Position + cameraCFrame.LookVector
    )
    
    -- Subtle random flicker
    if math.random() < settings.flickerChance then
        flashlight.Brightness = math.random() * 
            (settings.flickerIntensityMax - settings.flickerIntensityMin) + 
            settings.flickerIntensityMin
    else
        -- Smoothly return to normal brightness
        flashlight.Brightness = smoothLerp(
            flashlight.Brightness,
            settings.brightness,
            0.1,
            dt
        )
    end
end)
