-- Debug function
local function debug(message)
	print("VCRMenu Debug:", message)
end

debug("Script started")

-- Get services and wait for player
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local ContentProvider = game:GetService("ContentProvider")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
debug("Got services")

-- At the start of the script, enable cursor movement for menu
UserInputService.MouseBehavior = Enum.MouseBehavior.Default
UserInputService.MouseIconEnabled = true

-- Constants (update these)
local SCAN_LINE_TRANSPARENCY = 0.8
local FLICKER_CHANCE = 0.15  -- Increased slightly
local TEXT_COLOR = Color3.fromRGB(255, 255, 255)
local BACKGROUND_COLOR = Color3.fromRGB(0, 0, 0)
local GLITCH_OFFSET = 5  -- Pixels to offset during glitch
local VCR_BLUE = Color3.fromRGB(4, 0, 239)  -- #0400EF
local SCAN_LINE_COUNT = 100  -- More lines for higher resolution
local NOISE_TRANSPARENCY = 0.97  -- Very subtle noise
local TRACKING_LINE_CHANCE = 0.001  -- Rare tracking issues

-- At the top of the script
game:GetService("ReplicatedFirst"):RemoveDefaultLoadingScreen()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)  -- Hide all core GUIs

-- Create VCRLoading as a global variable
local VCRLoading
local background
local blueBackground
local menuContainer
local gameLogo

-- At the top with other variables
local noiseEffect
local cursorLocked = false  -- Add this flag to track cursor state
local menuActive = true  -- New flag to track if we're in menu state

-- Add this helper function to gather all assets
local function gatherAssets(instance)
	local assets = {}

	-- Check if this instance has content to load
	if instance:IsA("Model") or instance:IsA("Decal") or instance:IsA("Sound") or 
		instance:IsA("MeshPart") or instance:IsA("Texture") or instance:IsA("Animation") then
		table.insert(assets, instance)
	end

	-- Recursively check all children
	for _, child in ipairs(instance:GetChildren()) do
		local childAssets = gatherAssets(child)
		for _, asset in ipairs(childAssets) do
			table.insert(assets, asset)
		end
	end

	return assets
end

local function gatherEssentialAssets()
	local assets = {}

	-- Add UI elements that need to be loaded immediately
	for _, child in ipairs(game:GetDescendants()) do
		if child:IsA("ImageLabel") or child:IsA("ImageButton") then
			-- UI images are essential
			table.insert(assets, child)
		elseif child:IsA("Sound") and child.Name:match("^UI_") then
			-- UI sounds are essential
			table.insert(assets, child)
		elseif child:IsA("Model") and child.Name:match("^UI_") then
			-- UI models are essential
			table.insert(assets, child)
		elseif child:IsA("Texture") and child.Name:match("^UI_") then
			-- UI textures are essential
			table.insert(assets, child)
		end
	end

	-- Add specific assets we know we need
	local specificAssets = {
		noiseImage,  -- Make sure these variables are defined
		noiseImage2,
		noiseImage3,
		-- Add other specific assets here
	}

	for _, asset in ipairs(specificAssets) do
		if asset then
			table.insert(assets, asset)
		end
	end

	debug("Found " .. #assets .. " essential assets")
	return assets
end

-- At the top of your script, add:
local runningEffects = {}

-- First define createVCREffects
local function createVCREffects(parent)
	if not TweenService then
		warn("TweenService not found!")
		return
	end

	-- Create scan lines container
	local scanLinesContainer = Instance.new("Frame")
	scanLinesContainer.Name = "ScanLines"
	scanLinesContainer.BackgroundTransparency = 1
	scanLinesContainer.Size = UDim2.fromScale(1, 1)
	scanLinesContainer.ZIndex = 10
	scanLinesContainer.Parent = parent

	-- Create interlaced scan lines
	for i = 1, SCAN_LINE_COUNT do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = SCAN_LINE_TRANSPARENCY
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 0, i * 2)
		line.Parent = scanLinesContainer
	end

	-- Create noise effect
	noiseEffect = Instance.new("Frame")
	noiseEffect.Name = "NoiseEffect"
	noiseEffect.BackgroundTransparency = 1
	noiseEffect.Size = UDim2.fromScale(1, 1)
	noiseEffect.ZIndex = 11
	noiseEffect.Parent = parent

	-- Create tracking lines
	local trackingLines = Instance.new("Frame")
	trackingLines.Name = "TrackingLines"
	trackingLines.BackgroundTransparency = 1
	trackingLines.Size = UDim2.fromScale(1, 1)
	trackingLines.ZIndex = 12
	trackingLines.Parent = parent

	-- Animate noise and tracking effects
	table.insert(runningEffects, task.spawn(function()
		while true do
			-- Update noise
			for i = 1, 10 do  -- Create 10 noise particles
				local noise = Instance.new("Frame")
				noise.BackgroundColor3 = Color3.new(1, 1, 1)
				noise.BackgroundTransparency = NOISE_TRANSPARENCY
				noise.BorderSizePixel = 0
				noise.Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3))
				noise.Position = UDim2.fromScale(math.random(), math.random())
				noise.Parent = noiseEffect

				-- Remove noise after brief moment
				task.delay(0.1, function()
					noise:Destroy()
				end)
			end

			-- Random tracking lines
			if math.random() < TRACKING_LINE_CHANCE then
				local tracking = Instance.new("Frame")
				tracking.BackgroundColor3 = Color3.new(1, 1, 1)
				tracking.BackgroundTransparency = 0.7
				tracking.BorderSizePixel = 0
				tracking.Size = UDim2.new(1, 0, 0, math.random(2, 5))
				tracking.Position = UDim2.fromScale(0, math.random())
				tracking.Parent = trackingLines

				-- Animate tracking line
				local offset = math.random(-20, 20)
				TweenService:Create(tracking, TweenInfo.new(0.2), {
					Position = UDim2.new(0, offset, tracking.Position.Y.Scale, 0)
				}):Play()

				-- Remove tracking line
				task.delay(0.2, function()
					tracking:Destroy()
				end)
			end

			task.wait(0.05)  -- Update effects every 0.05 seconds
		end
	end))

	-- Add screen jitter effect
	table.insert(runningEffects, task.spawn(function()
		while true do
			if math.random() < 0.05 then  -- 5% chance of screen jitter
				local originalPosition = parent.Position
				local jitterOffset = math.random(-2, 2)

				parent.Position = UDim2.new(
					originalPosition.X.Scale, 
					jitterOffset,
					originalPosition.Y.Scale, 
					0
				)

				-- Only reset cursor if it's not supposed to be locked
				if not cursorLocked then
					UserInputService.MouseBehavior = Enum.MouseBehavior.Default
					UserInputService.MouseIconEnabled = true
				end

				task.wait(0.05)
				parent.Position = originalPosition
			end
			task.wait(0.1)
		end
	end))

	-- Add color distortion effect
	local colorDistortion = Instance.new("Frame")
	colorDistortion.Name = "ColorDistortion"
	colorDistortion.BackgroundTransparency = 0.98
	colorDistortion.Size = UDim2.fromScale(1, 1)
	colorDistortion.ZIndex = 9
	colorDistortion.Parent = parent

	-- Animate color distortion
	table.insert(runningEffects, task.spawn(function()
		while true do
			if math.random() < 0.1 then  -- 10% chance of color shift
				colorDistortion.BackgroundColor3 = Color3.fromRGB(
					math.random(0, 255),
					math.random(0, 255),
					math.random(0, 255)
				)
				task.wait(0.05)
				colorDistortion.BackgroundTransparency = 0.98
			end
			task.wait(0.1)
		end
	end))
end

-- Add near the top with other functions
local function fadeOutUI()
	local player = game.Players.LocalPlayer
	local gui = player.PlayerGui:FindFirstChild("VCRLoading")
	if not gui then return end

	-- Disable all menu items immediately to prevent multiple clicks
	if menuContainer then
		menuContainer.Active = false
		for _, item in ipairs(menuContainer:GetDescendants()) do
			if item:IsA("TextButton") or item:IsA("TextLabel") then
				item.Active = false
			end
		end
	end

	-- Create fade out effect for all elements
	local tweens = {}

	-- Create fade out effect for blue background
	if blueBackground then
		local tween = TweenService:Create(blueBackground, TweenInfo.new(1.5), {
			BackgroundTransparency = 1
		})
		table.insert(tweens, tween)
		tween:Play()
	end

	-- Fade out menu items
	if menuContainer then
		for _, item in ipairs(menuContainer:GetDescendants()) do
			if item:IsA("TextLabel") or item:IsA("TextButton") then
				local tween = TweenService:Create(item, TweenInfo.new(1.5), {
					TextTransparency = 1,
					BackgroundTransparency = 1
				})
				table.insert(tweens, tween)
				tween:Play()
			elseif item:IsA("Frame") then
				local tween = TweenService:Create(item, TweenInfo.new(1.5), {
					BackgroundTransparency = 1
				})
				table.insert(tweens, tween)
				tween:Play()
			end
		end
	end

	-- Fade out VCR effects
	for _, effect in ipairs(gui:GetDescendants()) do
		if effect:IsA("ImageLabel") or effect:IsA("ImageButton") then
			local tween = TweenService:Create(effect, TweenInfo.new(1.5), {
				BackgroundTransparency = 1,
				ImageTransparency = 1
			})
			table.insert(tweens, tween)
			tween:Play()
		elseif effect:IsA("Frame") then
			local tween = TweenService:Create(effect, TweenInfo.new(1.5), {
				BackgroundTransparency = 1
			})
			table.insert(tweens, tween)
			tween:Play()
		elseif effect:IsA("TextLabel") or effect:IsA("TextButton") then
			local tween = TweenService:Create(effect, TweenInfo.new(1.5), {
				TextTransparency = 1,
				BackgroundTransparency = 1
			})
			table.insert(tweens, tween)
			tween:Play()
		end
	end

	-- Fade out loading music if it exists
	local loadingMusic = game.Workspace.SFX:FindFirstChild("LoadingSong")
	if loadingMusic and loadingMusic:IsA("Sound") then
		local initialVolume = loadingMusic.Volume
		local tween = TweenService:Create(loadingMusic, TweenInfo.new(1.5), {
			Volume = 0
		})
		table.insert(tweens, tween)
		tween:Play()

		task.delay(1.5, function()
			loadingMusic:Stop()
			loadingMusic.Volume = initialVolume
		end)
	end

	-- Clean up any remaining effects
	task.spawn(function()
		-- Stop any VCR effects that might be running
		if gui:FindFirstChild("NoiseEffect") then
			gui.NoiseEffect:Destroy()
		end
		if gui:FindFirstChild("ScanLines") then
			gui.ScanLines:Destroy()
		end
		if gui:FindFirstChild("TrackingLines") then
			gui.TrackingLines:Destroy()
		end
		if gui:FindFirstChild("ColorDistortion") then
			gui.ColorDistortion:Destroy()
		end
	end)

	-- Wait for all tweens to complete, then destroy GUI
	task.delay(1.5, function()
		-- Enable core GUIs
		StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

		-- Stop all running effects
		for _, connection in ipairs(runningEffects) do
			if typeof(connection) == "RBXScriptConnection" then
				connection:Disconnect()
			elseif typeof(connection) == "thread" then
				task.cancel(connection)
			end
		end

		-- Final cleanup and GUI destruction
		if gui and gui.Parent then
			gui:Destroy()
			debug("VCRLoading GUI destroyed")
		end
	end)
end

-- Define the transition function before it's used
local function transitionToFirstPerson()
	-- Only proceed if cursorLocked is true
	if not cursorLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
		return
	end

	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local camera = workspace.CurrentCamera

	-- Set camera properties
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	-- Only lock mouse if cursorLocked is true
	if cursorLocked then
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		UserInputService.MouseIconEnabled = false
	end

	-- Modify character added function
	local function onCharacterAdded(newCharacter)
		task.wait()
		if cursorLocked then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
			player.CameraMinZoomDistance = 0.5
			player.CameraMaxZoomDistance = 0.5
		end
	end

	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Add this function to manage cursor state
local function setCursorState(locked)
	cursorLocked = locked
	if menuActive then
		-- Always keep cursor free while in menu
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		UserInputService.MouseIconEnabled = true
	else
		-- Only lock if we're not in menu and supposed to be locked
		if locked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		else
			UserInputService.MouseBehavior = Enum.MouseBehavior.Default
			UserInputService.MouseIconEnabled = true
		end
	end
end

-- Define cleanup function before it's used
local function cleanupEffects()
	for _, effect in ipairs(runningEffects) do
		task.cancel(effect)
	end
	table.clear(runningEffects)

	-- Use the cursor state manager
	setCursorState(cursorLocked)
end

-- In your fadeOutToGame function
local function fadeOutToGame()
	menuActive = false  -- We're leaving the menu
	-- Create fade effect
	local fadeFrame = Instance.new("Frame")
	fadeFrame.Name = "FadeOverlay"
	fadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
	fadeFrame.BackgroundTransparency = 1
	fadeFrame.Size = UDim2.fromScale(1, 1)
	fadeFrame.Position = UDim2.fromScale(0, 0)
	fadeFrame.ZIndex = 100  -- Ensure it's above everything
	fadeFrame.Parent = VCRLoading

	-- Disable all menu interactions
	if menuContainer then
		menuContainer.Active = false
		for _, item in ipairs(menuContainer:GetDescendants()) do
			if item:IsA("TextButton") or item:IsA("TextLabel") then
				item.Active = false
			end
		end
	end

	-- Play click sound if it exists
	local clickSound = game.Workspace.SFX:FindFirstChild("MenuClick")
	if clickSound and clickSound:IsA("Sound") then
		clickSound:Play()
	end

	-- Fade out menu music with proper error handling
	local menuMusic = game.Workspace.SFX:FindFirstChild("MenuMusic")
	if menuMusic and menuMusic:IsA("Sound") then
		local initialVolume = menuMusic.Volume
		debug("Starting music fade out from volume: " .. initialVolume)

		local musicTween = TweenService:Create(menuMusic, TweenInfo.new(1.5), {
			Volume = 0
		})

		musicTween.Completed:Connect(function()
			menuMusic:Stop()
			menuMusic.Volume = initialVolume  -- Reset volume for future use
			debug("Music fade out complete")
		end)

		musicTween:Play()
	else
		debug("Menu music not found or not a Sound object")
	end

	-- Fade out menu items first
	local menuTweens = {}
	if menuContainer then
		for _, item in ipairs(menuContainer:GetDescendants()) do
			-- Check specific instance types and apply appropriate properties
			if item:IsA("TextButton") or item:IsA("TextLabel") then
				-- For text elements
				local tween = TweenService:Create(item, TweenInfo.new(0.5), {
					TextTransparency = 1,
					BackgroundTransparency = 1
				})
				table.insert(menuTweens, tween)
				tween:Play()
			elseif item:IsA("Frame") then
				-- For frame elements
				local tween = TweenService:Create(item, TweenInfo.new(0.5), {
					BackgroundTransparency = 1
				})
				table.insert(menuTweens, tween)
				tween:Play()
			elseif item:IsA("ImageLabel") or item:IsA("ImageButton") then
				-- For image elements
				local tween = TweenService:Create(item, TweenInfo.new(0.5), {
					ImageTransparency = 1,
					BackgroundTransparency = 1
				})
				table.insert(menuTweens, tween)
				tween:Play()
			end
		end
	end

	-- Fade out game logo if it exists
	if gameLogo then
		local tween = TweenService:Create(gameLogo, TweenInfo.new(0.5), {
			ImageTransparency = 1
		})
		table.insert(menuTweens, tween)
		tween:Play()
	end

	-- Wait for menu fade out
	task.wait(0.5)

	-- Fade in the black overlay
	local overlayTween = TweenService:Create(fadeFrame, TweenInfo.new(1), {
		BackgroundTransparency = 0
	})
	overlayTween:Play()

	-- Wait for overlay fade in
	task.wait(1)

	-- Stop all running effects
	for _, connection in ipairs(runningEffects) do
		if typeof(connection) == "RBXScriptConnection" then
			connection:Disconnect()
		elseif typeof(connection) == "thread" then
			task.cancel(connection)
		end
	end

	-- Fade out any background music
	local menuMusic = game.Workspace.SFX:FindFirstChild("MenuMusic")
	if menuMusic and menuMusic:IsA("Sound") then
		local initialVolume = menuMusic.Volume
		TweenService:Create(menuMusic, TweenInfo.new(1), {
			Volume = 0
		}):Play()
		task.delay(1, function()
			menuMusic:Stop()
			menuMusic.Volume = initialVolume
		end)
	end

	-- Re-enable core GUIs
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, true)

	-- Final cleanup and transition
	task.delay(0.5, function()
		-- Destroy the VCRLoading GUI
		if VCRLoading and VCRLoading.Parent then
			VCRLoading:Destroy()
			debug("VCRLoading GUI destroyed")
		end

		-- Create fade out from black effect
		local fadeOutFrame = Instance.new("ScreenGui")
		fadeOutFrame.Name = "FadeFromBlack"
		fadeOutFrame.IgnoreGuiInset = true
		fadeOutFrame.DisplayOrder = 999
		fadeOutFrame.Parent = game.Players.LocalPlayer.PlayerGui

		local blackScreen = Instance.new("Frame")
		blackScreen.Name = "BlackScreen"
		blackScreen.BackgroundColor3 = Color3.new(0, 0, 0)
		blackScreen.BackgroundTransparency = 0
		blackScreen.Size = UDim2.fromScale(1, 1)
		blackScreen.Position = UDim2.fromScale(0, 0)
		blackScreen.Parent = fadeOutFrame

		-- Fade out to game
		TweenService:Create(blackScreen, TweenInfo.new(1.5), {
			BackgroundTransparency = 1
		}):Play()

		-- Clean up fade out frame
		task.delay(1.5, function()
			fadeOutFrame:Destroy()
		end)
	end)

	-- After fading out, transition to first person
	transitionToFirstPerson()
	-- Clean up effects
	cleanupEffects()

	-- Move the cursor lock to after the fade
	task.delay(1.5, function()
		if cursorLocked then
			UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
			UserInputService.MouseIconEnabled = false
		end
	end)
end

-- Update the createMenuSystem function to add click functionality
local function createMenuSystem(parent)
	-- Create menu container
	menuContainer = Instance.new("Frame")
	menuContainer.Name = "MenuContainer"
	menuContainer.BackgroundTransparency = 1
	menuContainer.Size = UDim2.fromScale(0.3, 0.7)
	menuContainer.Position = UDim2.fromScale(0.1, 0.2)
	menuContainer.Parent = parent
	menuContainer.Visible = false  -- Start hidden

	-- Create menu items
	local menuItems = {
		"PLAY",
		"SELECT SCENE",
		"LOAD",
		"SETTINGS",
		"BONUS FEATURES",
		"STATS",
		"MODIFICATIONS",
		"SKINS",
		"SHUT DOWN"
	}

	-- Create menu items with hover line effect
	for i, itemText in ipairs(menuItems) do
		-- Create container for menu item and line
		local itemContainer = Instance.new("Frame")
		itemContainer.Name = itemText:gsub(" ", "") .. "Container"
		itemContainer.BackgroundTransparency = 1
		itemContainer.Size = UDim2.fromScale(1, 0.1)
		itemContainer.Position = UDim2.fromScale(0, (i-1) * 0.11)
		itemContainer.ZIndex = 2
		itemContainer.Parent = menuContainer

		-- Create the menu item as a TextButton instead of TextLabel
		local menuItem = Instance.new("TextButton")  -- Changed to TextButton
		menuItem.Name = itemText:gsub(" ", "") .. "MenuItem"
		menuItem.Text = itemText
		menuItem.TextColor3 = Color3.new(1, 1, 1)
		menuItem.TextSize = 30
		menuItem.Font = Enum.Font.Code
		menuItem.BackgroundTransparency = 1
		menuItem.Size = UDim2.fromScale(1, 1)
		menuItem.Position = UDim2.fromScale(0, 0)
		menuItem.TextXAlignment = Enum.TextXAlignment.Left
		menuItem.ZIndex = 2
		menuItem.AutoButtonColor = false  -- Disable default button color
		menuItem.Parent = itemContainer

		-- Create the hover line (initially invisible)
		local hoverLine = Instance.new("Frame")
		hoverLine.Name = "HoverLine"
		hoverLine.BackgroundColor3 = Color3.new(1, 1, 1)
		hoverLine.BorderSizePixel = 0
		hoverLine.Size = UDim2.new(0, 0, 0, 1)
		hoverLine.Position = UDim2.new(0, 0, 0.9, 0)
		hoverLine.ZIndex = 2
		hoverLine.Parent = itemContainer

		-- Calculate text width (add this after the text label is created)
		local textWidth = game:GetService("TextService"):GetTextSize(
			itemText,
			menuItem.TextSize,
			menuItem.Font,
			Vector2.new(1000, 100)
		).X

		-- Store the target width for the line
		local targetWidth = textWidth + 10  -- Add small padding

		-- Add click functionality directly to the button
		menuItem.MouseButton1Click:Connect(function()
			if itemText == "PLAY" then
				print("Play button clicked")
				setCursorState(true)  -- This won't lock immediately due to menuActive flag
				fadeOutToGame()
			else
				print("Clicked:", itemText)
				setCursorState(false)
			end
		end)

		-- Keep existing hover effects
		itemContainer.MouseEnter:Connect(function()
			menuItem.TextColor3 = Color3.fromRGB(200, 200, 200)
			TweenService:Create(itemContainer, TweenInfo.new(0.2), {
				Position = UDim2.new(0.05, 0, (i-1) * 0.11, 0)
			}):Play()

			TweenService:Create(hoverLine, TweenInfo.new(0.2), {
				Size = UDim2.new(0, targetWidth, 0, 1)
			}):Play()
		end)

		itemContainer.MouseLeave:Connect(function()
			menuItem.TextColor3 = Color3.new(1, 1, 1)
			TweenService:Create(itemContainer, TweenInfo.new(0.2), {
				Position = UDim2.new(0, 0, (i-1) * 0.11, 0)
			}):Play()

			TweenService:Create(hoverLine, TweenInfo.new(0.2), {
				Size = UDim2.new(0, 0, 0, 1)
			}):Play()
		end)
	end

	-- Create logo with smaller size
	gameLogo = Instance.new("ImageLabel")
	gameLogo.Name = "GameLogo"
	gameLogo.Image = "rbxassetid://120604953342352"
	gameLogo.BackgroundTransparency = 1
	gameLogo.Size = UDim2.fromOffset(482, 62)  -- Reduced from 600x300 to 400x200
	gameLogo.Position = UDim2.new(0.7, 0, 0.4, 0)  -- Changed from 0.5 to 0.7 to move right
	gameLogo.AnchorPoint = Vector2.new(0.5, 0.5)  -- Keep centered around position point
	gameLogo.ZIndex = 2
	gameLogo.Parent = parent
	gameLogo.Visible = false

	-- Now we can call createVCREffects
	createVCREffects(parent)
end

-- Update the fadeOutVCRScreen function
local function fadeOutVCRScreen()
	if not VCRLoading then 
		warn("VCRLoading not found")
		return 
	end

	debug("Starting glitchy fade out")

	-- Find the play icon and time display
	local playIcon = background:FindFirstChild("PlayIcon")
	local timeDisplay = background:FindFirstChild("TimeDisplay")

	-- Create copies of the elements we want to preserve
	local preservedPlayIcon
	if playIcon then
		preservedPlayIcon = playIcon:Clone()
		preservedPlayIcon.Parent = blueBackground
		preservedPlayIcon.ZIndex = 2
		preservedPlayIcon.ImageTransparency = 0
		playIcon:Destroy()  -- Remove the original play icon
		debug("Play icon preserved")
	end

	local preservedTimeDisplay
	if timeDisplay then
		preservedTimeDisplay = timeDisplay:Clone()
		preservedTimeDisplay.Parent = blueBackground
		preservedTimeDisplay.ZIndex = 2
		preservedTimeDisplay.ImageTransparency = 0
		timeDisplay:Destroy()  -- Remove the original time display
		debug("Time display preserved")
	end

	-- Create menu system but keep it hidden initially
	createMenuSystem(blueBackground)
	if menuContainer then
		menuContainer.Visible = false
	end

	-- Create glitchy fade out sequence for remaining elements
	for i = 1, 5 do
		task.spawn(function()
			for _, element in ipairs(background:GetDescendants()) do
				-- Only glitch the elements on the black background
				if element ~= background and element ~= playIcon and element ~= timeDisplay then
					local randomOffset = math.random(-GLITCH_OFFSET, GLITCH_OFFSET)
					local originalPosition = element.Position

					TweenService:Create(element, TweenInfo.new(0.1), {
						Position = UDim2.new(
							originalPosition.X.Scale, 
							originalPosition.X.Offset + randomOffset,
							originalPosition.Y.Scale,
							originalPosition.Y.Offset
						)
					}):Play()

					if element:IsA("ImageLabel") then
						element.ImageTransparency = math.random()
					elseif element:IsA("TextLabel") then
						element.TextTransparency = math.random()
					elseif element:IsA("Frame") then
						element.BackgroundTransparency = math.random()
					end
				end
			end
		end)
		task.wait(0.15)
	end

	-- Fade out all elements on black background except preserved ones
	task.wait(0.5)
	for _, element in ipairs(background:GetDescendants()) do
		if element ~= background and element ~= playIcon and element ~= timeDisplay then
			if element:IsA("Frame") then
				TweenService:Create(element, TweenInfo.new(0.3), {
					BackgroundTransparency = 1
				}):Play()
			elseif element:IsA("TextLabel") then
				TweenService:Create(element, TweenInfo.new(0.3), {
					TextTransparency = 1
				}):Play()
			elseif element:IsA("ImageLabel") then
				TweenService:Create(element, TweenInfo.new(0.3), {
					ImageTransparency = 1
				}):Play()
			end
		end
	end

	-- Finally fade out the black background and show menu
	task.wait(0.5)
	TweenService:Create(background, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	}):Play()

	-- Show menu items after background starts fading
	task.wait(0.2)
	if menuContainer then
		menuContainer.Visible = true
	end

	-- Wait a few seconds then do glitchy transition to background image
	task.wait(2)

	-- Create the background image with solid black backing
	local backgroundImage = Instance.new("ImageLabel")
	backgroundImage.Name = "BackgroundImage"
	backgroundImage.Image = "rbxassetid://111953656726108"
	backgroundImage.BackgroundColor3 = Color3.fromRGB(0, 0, 0)  -- Solid black background
	backgroundImage.BackgroundTransparency = 0  -- Fully opaque
	backgroundImage.Size = UDim2.fromScale(1, 1)
	backgroundImage.Position = UDim2.fromScale(0, 0)
	backgroundImage.ZIndex = 0
	backgroundImage.ImageTransparency = 1
	backgroundImage.Parent = VCRLoading

	-- Create a solid black safety background behind everything
	local safetyBackground = Instance.new("Frame")
	safetyBackground.Name = "SafetyBackground"
	safetyBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	safetyBackground.BackgroundTransparency = 0
	safetyBackground.Size = UDim2.fromScale(1, 1)
	safetyBackground.Position = UDim2.fromScale(0, 0)
	safetyBackground.ZIndex = -1  -- Behind everything
	safetyBackground.Parent = VCRLoading

	-- Glitchy transition
	for i = 1, 10 do  -- 10 glitch frames
		-- Random glitch offset
		local offsetX = math.random(-20, 20)
		local offsetY = math.random(-20, 20)

		-- Glitch both layers
		blueBackground.Position = UDim2.new(0, offsetX, 0, offsetY)
		backgroundImage.Position = UDim2.new(0, -offsetX, 0, -offsetY)

		-- Random transparency between blue and image (but never fully transparent)
		blueBackground.BackgroundTransparency = math.random() * 0.5  -- Max 0.5 transparency
		backgroundImage.ImageTransparency = math.random() * 0.5  -- Max 0.5 transparency

		task.wait(0.05)  -- Quick glitch frames
	end

	-- Reset positions and finalize transition
	blueBackground.Position = UDim2.fromScale(0, 0)
	backgroundImage.Position = UDim2.fromScale(0, 0)
	blueBackground.BackgroundTransparency = 1
	backgroundImage.ImageTransparency = 0

	-- Keep safety background until transition is complete
	task.wait(0.1)
	safetyBackground:Destroy()

	-- Make sure menu stays visible
	if menuContainer then
		menuContainer.ZIndex = 2
	end

	-- After fading out, transition to first person
	transitionToFirstPerson()

	-- Disable core GUIs except what's needed
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.All, false)
	StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) -- Keep chat if needed

	-- Clean up effects
	cleanupEffects()
end

-- Add these services at the top
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")

-- Add these variables near the top
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera
local menuAudio -- Reference to your menu audio

-- At the top with your other services
local StarterPlayer = game:GetService("StarterPlayer")

-- Set first person lock in StarterPlayer
StarterPlayer.CameraMode = Enum.CameraMode.LockFirstPerson
StarterPlayer.EnableMouseLockOption = true
StarterPlayer.CameraMaxZoomDistance = 0.5
StarterPlayer.CameraMinZoomDistance = 0.5

-- Set initial camera state for menu (free look)
local function setupMenuCamera()
	local player = game.Players.LocalPlayer
	player.CameraMode = Enum.CameraMode.Classic
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 128
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
end

-- Function to lock camera when play is pressed
local function lockCamera()
	local player = game.Players.LocalPlayer
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
end

-- Call this when the menu first loads
setupMenuCamera()

-- Function to handle play button click
local function handlePlayButton()
	lockCamera()
	fadeOutVCRScreen()
	-- ... rest of your play button logic ...
end

-- Find your play button creation code and update it:
local playButton = Instance.new("TextButton")
playButton.Name = "PlayButton"
-- ... rest of your play button setup ...
playButton.MouseButton1Click:Connect(handlePlayButton)

-- Add this to your cleanup function
local function cleanup()
	cleanupEffects()
	if menuAudio then
		menuAudio:Stop()
	end
end

local success, err = pcall(function()
	local player = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
	debug("Player loaded: " .. player.Name)

	-- Create the ScreenGui if it doesn't exist
	VCRLoading = Instance.new("ScreenGui")
	VCRLoading.Name = "VCRLoading"
	VCRLoading.IgnoreGuiInset = true
	VCRLoading.ResetOnSpawn = false
	VCRLoading.DisplayOrder = 999
	VCRLoading.Parent = player.PlayerGui
	debug("Created VCRLoading GUI")

	-- Create the blue screen background first (it will be behind everything)
	blueBackground = Instance.new("Frame")
	blueBackground.Name = "BlueBackground"
	blueBackground.BackgroundColor3 = VCR_BLUE
	blueBackground.Size = UDim2.fromScale(1, 1)
	blueBackground.Position = UDim2.fromScale(0, 0)
	blueBackground.BorderSizePixel = 0
	blueBackground.ZIndex = 0
	blueBackground.Parent = VCRLoading

	-- Create menu system on blue background
	createMenuSystem(blueBackground)

	-- Add scan lines to the entire screen
	local blueScreenLines = Instance.new("Frame")
	blueScreenLines.Name = "BlueScreenLines"
	blueScreenLines.BackgroundTransparency = 1
	blueScreenLines.Size = UDim2.fromScale(1, 1)
	blueScreenLines.Position = UDim2.fromScale(0, 0)
	blueScreenLines.ZIndex = 1
	blueScreenLines.Parent = VCRLoading

	-- Create many thin scan lines
	for i = 1, 540 do  -- More lines for higher density
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.new(0, 0, 0)  -- Dark lines
		line.BackgroundTransparency = 0.85  -- More subtle
		line.BorderSizePixel = 0
		line.Size = UDim2.new(1, 0, 0, 1)  -- 1 pixel height
		line.Position = UDim2.new(0, 0, 0, i * 2)  -- 2 pixel gap
		line.Parent = blueScreenLines
	end

	-- Animate scan lines scrolling
	task.spawn(function()
		while true do
			for _, line in ipairs(blueScreenLines:GetChildren()) do
				local newY = line.Position.Y.Offset + 2  -- Moderate speed

				if newY > 1080 then
					newY = -2
				end

				line.Position = UDim2.new(0, 0, 0, newY)
			end

			-- Subtle flicker
			if math.random() < 0.05 then  -- Reduced flicker frequency
				for _, line in ipairs(blueScreenLines:GetChildren()) do
					line.BackgroundTransparency = 0.85 + math.random() * 0.1  -- More subtle variation
				end
			end

			task.wait(0.016)
		end
	end)

	-- Create the background
	background = Instance.new("Frame")
	background.Name = "Background"
	background.BackgroundColor3 = BACKGROUND_COLOR
	background.Size = UDim2.fromScale(1, 1)
	background.Position = UDim2.fromScale(0, 0)
	background.BorderSizePixel = 0
	background.ZIndex = 1
	background.Parent = VCRLoading
	debug("Background created")

	-- Create PLAY icon
	local playIcon = Instance.new("ImageLabel")
	playIcon.Name = "PlayIcon"
	playIcon.BackgroundTransparency = 1
	playIcon.Image = "rbxassetid://72696902735362"
	playIcon.ImageColor3 = TEXT_COLOR
	playIcon.Size = UDim2.fromOffset(300, 150)
	playIcon.Position = UDim2.fromOffset(40, 40)
	playIcon.ZIndex = 10
	playIcon.Parent = background
	debug("Play icon created")

	-- Create VCR time display
	local timeDisplay = Instance.new("ImageLabel")
	timeDisplay.Name = "TimeDisplay"
	timeDisplay.BackgroundTransparency = 1
	timeDisplay.Image = "rbxassetid://71471244772781"
	timeDisplay.ImageColor3 = TEXT_COLOR
	timeDisplay.Size = UDim2.fromOffset(300, 150)
	timeDisplay.Position = UDim2.new(1, -340, 0, 40)
	timeDisplay.AnchorPoint = Vector2.new(0, 0)
	timeDisplay.ZIndex = 10
	timeDisplay.Parent = background
	debug("Time display created")

	-- Create noise effect
	local noiseImage = Instance.new("ImageLabel")
	noiseImage.Name = "NoiseEffect"
	noiseImage.BackgroundTransparency = 1
	noiseImage.ImageTransparency = 0.5
	noiseImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
	noiseImage.ScaleType = Enum.ScaleType.Stretch
	noiseImage.Size = UDim2.fromScale(1, 1)
	noiseImage.ZIndex = 10
	noiseImage.Parent = background

	-- Create first additional noise effect
	local noiseImage2 = Instance.new("ImageLabel")
	noiseImage2.Name = "NoiseEffect2"
	noiseImage2.BackgroundTransparency = 1
	noiseImage2.Image = "rbxgameasset://Images/ap550x55012x121transparentt2"
	noiseImage2.ImageTransparency = 0
	noiseImage2.ScaleType = Enum.ScaleType.Stretch
	noiseImage2.Size = UDim2.fromScale(1, 1)
	noiseImage2.ZIndex = 10
	noiseImage2.Parent = background

	-- Create second additional noise effect
	local noiseImage3 = Instance.new("ImageLabel")
	noiseImage3.Name = "NoiseEffect3"
	noiseImage3.BackgroundTransparency = 1
	noiseImage3.Image = "rbxgameasset://Images/ap550x55012x121transparentt2"
	noiseImage3.ImageTransparency = 0
	noiseImage3.ScaleType = Enum.ScaleType.Stretch
	noiseImage3.Size = UDim2.fromScale(1, 1)
	noiseImage3.ZIndex = 10
	noiseImage3.Parent = background

	-- Create loading text
	local loadingText = Instance.new("TextLabel")
	loadingText.Name = "LoadingText"
	loadingText.Text = "UNVEILING YOUR FROZEN FATE"
	loadingText.TextColor3 = TEXT_COLOR
	loadingText.Font = Enum.Font.Code
	loadingText.TextSize = 36
	loadingText.BackgroundTransparency = 1
	loadingText.Position = UDim2.fromScale(0.5, 0.45)
	loadingText.Size = UDim2.fromOffset(200, 50)
	loadingText.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingText.ZIndex = 2
	loadingText.Parent = background
	debug("Loading text created")

	-- Create Cold Blood logo in bottom left
	local coldBloodLogo = Instance.new("ImageLabel")
	coldBloodLogo.Name = "ColdBloodLogo"
	coldBloodLogo.Image = "rbxassetid://120604953342352"
	coldBloodLogo.BackgroundTransparency = 1
	coldBloodLogo.Size = UDim2.fromOffset(241, 31)
	coldBloodLogo.Position = UDim2.new(0, 40, 0.95, 0)
	coldBloodLogo.AnchorPoint = Vector2.new(0, 1)
	coldBloodLogo.ZIndex = 10
	coldBloodLogo.ScaleType = Enum.ScaleType.Fit
	coldBloodLogo.Parent = background
	debug("Cold Blood logo created")

	-- Create loading counter in bottom right
	local counter = Instance.new("TextLabel")
	counter.Name = "Counter"
	counter.Text = "0/0"
	counter.TextColor3 = TEXT_COLOR
	counter.Font = Enum.Font.Code
	counter.TextSize = 24
	counter.BackgroundTransparency = 1
	counter.Position = UDim2.new(0.95, 0, 0.95, 0)
	counter.Size = UDim2.fromOffset(200, 50)
	counter.AnchorPoint = Vector2.new(1, 1)
	counter.ZIndex = 10
	counter.Parent = background
	debug("Counter created")



	if coldBloodLogo then
		coldBloodLogo.Changed:Connect(function(prop)
			if prop == "IsLoaded" then
				debug("Cold Blood logo loaded: " .. tostring(coldBloodLogo.IsLoaded))
			end
		end)
	end

	-- Create scan lines
	local scanLines = Instance.new("Frame")
	scanLines.Name = "ScanLines"
	scanLines.BackgroundTransparency = 1
	scanLines.Size = UDim2.fromScale(1, 1)
	scanLines.ZIndex = 40
	scanLines.Parent = background

	-- Create scan line pattern
	for i = 1, 50 do
		local line = Instance.new("Frame")
		line.BackgroundColor3 = Color3.new(0, 0, 0)
		line.BackgroundTransparency = SCAN_LINE_TRANSPARENCY
		line.Size = UDim2.new(1, 0, 0, 1)
		line.Position = UDim2.new(0, 0, 0, i * 4)
		line.Parent = scanLines
	end
	debug("Scan lines created")

	-- Replace the old flickerEffect with this new noise effect
	local function calculateNoise()
		if not noiseEffect then return end -- Guard clause

		-- Create noise particles
		for i = 1, 5 do
			local noise = Instance.new("Frame")
			noise.BackgroundColor3 = Color3.new(1, 1, 1)
			noise.BackgroundTransparency = NOISE_TRANSPARENCY
			noise.BorderSizePixel = 0
			noise.Size = UDim2.fromOffset(math.random(1, 3), math.random(1, 3))
			noise.Position = UDim2.fromScale(math.random(), math.random())
			noise.Parent = noiseEffect

			-- Remove noise after brief moment
			task.delay(0.1, function()
				if noise and noise.Parent then
					noise:Destroy()
				end
			end)
		end
	end

	-- Update the loading function to use the old asset gathering method
	local function updateLoadingProgress()
		debug("Starting asset loading")
		local clock = os.clock()

		-- Get all assets first (using old method)
		local assets = game.Workspace:GetDescendants()
		local totalAssets = #assets
		debug("Found " .. totalAssets .. " assets")

		-- Create progress bar container
		local progressBarContainer = Instance.new("Frame")
		progressBarContainer.Name = "ProgressBarContainer"
		progressBarContainer.BackgroundColor3 = Color3.new(1, 1, 1)
		progressBarContainer.BackgroundTransparency = 0
		progressBarContainer.BorderSizePixel = 0
		progressBarContainer.Size = UDim2.new(0.35, 0, 0.002, 0)
		progressBarContainer.Position = UDim2.new(0.5, 0, 0.52, 0)
		progressBarContainer.AnchorPoint = Vector2.new(0.5, 0.5)
		progressBarContainer.ZIndex = 2
		progressBarContainer.Parent = background

		-- Create progress bar fill
		local progressBarFill = Instance.new("Frame")
		progressBarFill.Name = "ProgressBarFill"
		progressBarFill.BackgroundColor3 = Color3.fromRGB(140, 0, 0)
		progressBarFill.BorderSizePixel = 0
		progressBarFill.Size = UDim2.new(0, 0, 1, 0)
		progressBarFill.Position = UDim2.new(0, 0, 0, 0)
		progressBarFill.ZIndex = 3
		progressBarFill.Parent = progressBarContainer

		-- Create skip text
		local skipText = Instance.new("TextLabel")
		skipText.Name = "SkipText"
		skipText.Text = "PRESS E TO SKIP"
		skipText.TextColor3 = TEXT_COLOR
		skipText.Font = Enum.Font.GothamBold
		skipText.TextSize = 14
		skipText.BackgroundTransparency = 1
		skipText.Position = UDim2.new(0.615, 0, 0.52, 15)
		skipText.Size = UDim2.fromOffset(200, 20)
		skipText.AnchorPoint = Vector2.new(0.5, 0.5)
		skipText.ZIndex = 2
		skipText.Parent = background

		-- Initialize counter
		counter.Text = "0/" .. totalAssets

		-- Track loading state
		local isLoading = true
		local lastSuccessfulLoad = tick()
		local STUCK_THRESHOLD = 5

		-- Monitor for stuck loading
		task.spawn(function()
			while isLoading do
				task.wait(1)
				if tick() - lastSuccessfulLoad > STUCK_THRESHOLD then
					debug("Loading seems stuck - attempting to continue...")
					lastSuccessfulLoad = tick()
				end
			end
		end)

		-- Handle skip key
		local UserInputService = game:GetService("UserInputService")
		local skipConnection
		skipConnection = UserInputService.InputBegan:Connect(function(input)
			if input.KeyCode == Enum.KeyCode.E then
				isLoading = false
				skipConnection:Disconnect()
				fadeOutVCRScreen()
			end
		end)

		-- Load assets with error handling
		for i = 1, totalAssets do
			if not isLoading then break end

			local success, err = pcall(function()
				local asset = assets[i]
				local percentage = i / totalAssets

				-- Update counter and progress bar
				counter.Text = i .. "/" .. totalAssets
				TweenService:Create(progressBarFill, TweenInfo.new(0.1), {
					Size = UDim2.new(percentage, 0, 1, 0)
				}):Play()

				debug(string.format("Loading asset %d of %d (%d%%)", i, totalAssets, math.round(percentage * 100)))

				-- Preload with timeout
				task.spawn(function()
					local loadSuccess = pcall(function()
						ContentProvider:PreloadAsync({asset})
					end)
					if loadSuccess then
						lastSuccessfulLoad = tick()
					end
				end)

				if i % 25 == 0 then
					task.wait()
				end
			end)

			if not success then
				warn("Error loading asset:", err)
			end
		end

		isLoading = false
		debug(string.format("Loading complete! Took %.2f seconds", os.clock() - clock))

		-- Clean up skip connection if it wasn't used
		if skipConnection then
			skipConnection:Disconnect()
		end

		-- Show brief completion state
		progressBarFill.Size = UDim2.new(1, 0, 1, 0)  -- Ensure bar is full
		counter.Text = "COMPLETE"
		task.wait(2)

		-- Fade out the loading screen
		fadeOutVCRScreen()
	end

	-- Start the animations
	task.spawn(function()
		while true do
			task.wait()
			calculateNoise()
		end
	end)
	task.spawn(updateLoadingProgress)

	-- Add these two animation functions
	task.spawn(function()
		while true do
			noiseImage2.Visible = true
			task.wait(6)
			noiseImage2.Visible = false
			task.wait()
		end
	end)

	task.spawn(function()
		while true do
			noiseImage3.Visible = false
			task.wait(6)
			noiseImage3.Visible = true
			task.wait(12)
			noiseImage3.Visible = false
			task.wait()
		end
	end)

	debug("Script setup complete")
end)

if not success then
	warn("VCRMenu Error:", err)
end

-- Add this to your cleanup
local function cleanupEffects()
	for _, effect in ipairs(runningEffects) do
		task.cancel(effect)
	end
	table.clear(runningEffects)

	-- Use the cursor state manager
	setCursorState(cursorLocked)
end

-- Function to handle transition to first person
local function transitionToFirstPerson()
	local player = game.Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	local camera = workspace.CurrentCamera

	-- Set camera properties
	camera.CameraType = Enum.CameraType.Custom
	player.CameraMode = Enum.CameraMode.LockFirstPerson
	player.CameraMinZoomDistance = 0.5
	player.CameraMaxZoomDistance = 0.5

	-- Lock mouse
	UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter

	-- Disable third person
	local function onCharacterAdded(newCharacter)
		task.wait() -- Wait a frame for character to load
		player.CameraMode = Enum.CameraMode.LockFirstPerson
		player.CameraMinZoomDistance = 0.5
		player.CameraMaxZoomDistance = 0.5
	end

	-- Connect to CharacterAdded to maintain first person
	player.CharacterAdded:Connect(onCharacterAdded)
end

-- Function to lock first person
local function lockFirstPerson()
	local player = game.Players.LocalPlayer

	-- Connect to camera mode changes
	player:GetPropertyChangedSignal("CameraMode"):Connect(function()
		if player.CameraMode ~= Enum.CameraMode.LockFirstPerson then
			player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
	end)

	-- Connect to camera min/max zoom changes
	player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(function()
		if player.CameraMinZoomDistance ~= 0.5 then
			player.CameraMinZoomDistance = 0.5
		end
	end)

	player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(function()
		if player.CameraMaxZoomDistance ~= 0.5 then
			player.CameraMaxZoomDistance = 0.5
		end
	end)
end

-- At the start of the script, ensure cursor is free for menu
task.spawn(function()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true
end)

-- Function to fade out the loading song
local function fadeOutLoadingSong()
	local loadingSong = workspace.SFX.LoadingSong
	if loadingSong then
		-- Create a tween to fade out the volume
		local fadeOut = TweenService:Create(loadingSong, TweenInfo.new(1.5), {
			Volume = 0
		})
		
		-- Connect to the completed event to stop the sound
		fadeOut.Completed:Connect(function()
			loadingSong:Stop()
		end)
		
		-- Play the fade out tween
		fadeOut:Play()
	end
end

-- Update your fadeOutVCRScreen function
local function fadeOutVCRScreen()
	-- Fade out the loading song
	fadeOutLoadingSong()
	
	-- Rest of your existing fade out code...
	local fadeOut = TweenService:Create(background, TweenInfo.new(1.5), {
		BackgroundTransparency = 1
	})
	
	fadeOut.Completed:Connect(function()
		-- Your existing cleanup code...
	end)
	
	fadeOut:Play()
end

