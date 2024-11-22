local RunService = game:GetService("RunService")
local Player = game.Players.LocalPlayer
local Camera = game.Workspace.CurrentCamera

-- Advanced movement parameters
local settings = {
    -- Walking parameters
    normalBob = {
        intensity = 0.05,     -- Reduced bob intensity
        frequency = 3.5,      -- Slower frequency
        tilt = 0.01          -- Reduced tilt
    },
    
    -- Running parameters
    sprintBob = {
        intensity = 0.08,     -- Reduced running intensity
        frequency = 5.0,      -- Adjusted frequency
        tilt = 0.01          -- Reduced tilt
    },
    
    -- Smooth transition settings
    damping = {
        position = 0.08,      -- Smoother position changes
        rotation = 0.06,      -- Reduced rotation speed
        tilt = 0.01          -- Slower tilt changes
    },
    
    -- Physics response
    physics = {
        landingImpact = 0.1,  -- Reduced impact
        jumpPrep = 0.08,      -- Reduced jump preparation
        maxTilt = 0.2,        -- Reduced maximum tilt
        recoverySpeed = 0.98  -- Smoother recovery
    }
}

-- State management
local state = {
    bobOffset = Vector3.new(),
    targetBobOffset = Vector3.new(),
    rotationOffset = Vector3.new(),
    targetRotationOffset = Vector3.new(),
    velocity = Vector3.new(),
    lastPosition = Vector3.new(),
    isGrounded = true,
    lastJumpTime = 0,
    currentTilt = 0,
    targetTilt = 0,
    breathingOffset = 0,
    stepCycle = 0
}

-- Smooth interpolation function
local function smoothLerp(a, b, speed, dt)
    return a + (b - a) * (1 - math.exp(-speed * dt * 60))
end

-- Calculate breathing movement
local function calculateBreathing(dt)
    state.breathingOffset = math.sin(tick() * 1.2) * 0.03
    return state.breathingOffset
end

-- Calculate step cycle and bob
local function calculateBob(speed, dt)
    local params = speed > 20 and settings.sprintBob or settings.normalBob
    local cycle = tick() * params.frequency * (speed / 16)
    
    return Vector3.new(
        math.sin(cycle * 0.5) * params.intensity * 0.25,  -- Reduced side-to-side
        math.abs(math.sin(cycle)) * params.intensity,      -- Vertical bob
        0                                                  -- Removed forward/back bob
    )
end

-- Smooth interpolation function (add this if missing)
local function lerp(a, b, t)
    return a + (b - a) * t
end

-- Handle physics-based movements
local function handlePhysics(dt)
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or not rootPart then return end
    
    -- Calculate velocity with smoothing
    local targetVelocity = (rootPart.Position - state.lastPosition) / dt
    state.velocity = state.velocity:Lerp(targetVelocity, settings.damping.position)
    state.lastPosition = rootPart.Position
    
    -- Improved ground detection
    local wasGrounded = state.isGrounded
    state.isGrounded = humanoid:GetState() ~= Enum.HumanoidStateType.Jumping
        and humanoid:GetState() ~= Enum.HumanoidStateType.Freefall
        and humanoid:GetState() ~= Enum.HumanoidStateType.Swimming
    
    -- Smoother landing impact
    if not wasGrounded and state.isGrounded then
        local impact = math.clamp(state.velocity.Y * -settings.physics.landingImpact, 0, 0.5)
        state.targetBobOffset = state.targetBobOffset + Vector3.new(0, -impact, 0)
    end
    
    -- Smoother movement tilt
    local moveDirection = humanoid.MoveDirection
    if moveDirection.Magnitude > 0 then
        local sideMovement = Camera.CFrame:VectorToObjectSpace(moveDirection).X
        local targetTilt = -sideMovement * settings.physics.maxTilt * 
            math.min(state.velocity.Magnitude / humanoid.WalkSpeed, 1)
        state.targetTilt = lerp(state.targetTilt, targetTilt, settings.damping.tilt)
    else
        state.targetTilt = lerp(state.targetTilt, 0, settings.damping.tilt)
    end
end

-- Main update function
RunService.RenderStepped:Connect(function(dt)
    local character = Player.Character
    if not character then return end
    
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then return end
    
    -- Calculate movement speed with smoothing
    local speed = humanoid.MoveDirection.Magnitude * humanoid.WalkSpeed
    
    -- Handle physics and movement calculations
    handlePhysics(dt)
    
    -- Calculate target offsets with smoother transitions
    if speed > 0.1 and state.isGrounded then
        local params = speed > (humanoid.WalkSpeed * 0.8) and settings.sprintBob or settings.normalBob
        state.targetBobOffset = calculateBob(speed, dt)
    else
        state.targetBobOffset = Vector3.new(0, calculateBreathing(dt), 0)
    end
    
    -- Apply smooth transitions to all movements
    state.bobOffset = state.bobOffset:Lerp(state.targetBobOffset, settings.damping.position)
    state.rotationOffset = state.rotationOffset:Lerp(state.targetRotationOffset, settings.damping.rotation)
    state.currentTilt = lerp(state.currentTilt, state.targetTilt, settings.damping.tilt)
    
    -- Apply camera modifications
    if Camera then
        local finalCFrame = Camera.CFrame
        finalCFrame = finalCFrame * CFrame.new(state.bobOffset)
        finalCFrame = finalCFrame * CFrame.Angles(state.rotationOffset.X, state.rotationOffset.Y, state.currentTilt)
        Camera.CFrame = finalCFrame
    end
end)
