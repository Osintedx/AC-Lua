-- SpeedCheckModule.lua
local RunService = game:GetService("RunService")

local SpeedCheckModule = {}

-- Settings
local speedThreshold = 20  -- Speed threshold for detection (in studs per second)
local rubberBanding = true  -- Whether to apply rubberbanding
local freezeDuration = 5  -- How long to keep the player frozen after detection (in seconds)
local positionCheckInterval = 1  -- How often we check for movement (in seconds)
local stopMovementThreshold = 0.1  -- Threshold for determining if player is stopped (in studs)
local verticalMovementThreshold = 5  -- Maximum vertical speed for jumping (in studs per second)
local debounceTime = 0.5  -- Minimum time between flagging messages to prevent spam

local lastFlagTime = 0  -- Time of last flagging event to debounce it

-- Speed check function
function SpeedCheckModule.checkSpeed(player)
	local lastPosition = player.Character.HumanoidRootPart.Position
	local lastTime = tick()
	local lastMoveCheckTime = tick()
	local isFrozen = false  -- Flag to track if the player is frozen
	local freezeStartTime = 0  -- Time when freezing started

	RunService.Heartbeat:Connect(function()
		-- Ensure the player has a valid character and HumanoidRootPart
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

		local humanoidRootPart = player.Character.HumanoidRootPart
		local currentTime = tick()
		local currentPosition = humanoidRootPart.Position
		local deltaTime = currentTime - lastTime
		local timeSinceLastMoveCheck = currentTime - lastMoveCheckTime

		-- Prevent extremely small deltaTime values that could cause issues
		if deltaTime < 0.1 then return end

		-- If the player is frozen, keep them in place
		if isFrozen then
			if currentTime - freezeStartTime >= freezeDuration then
				isFrozen = false  -- Unfreeze after the duration
				print(player.Name .. ": Freeze duration ended.")
			else
				humanoidRootPart.Velocity = Vector3.zero  -- Stop velocity
				humanoidRootPart.CFrame = CFrame.new(lastPosition)  -- Lock position
				return
			end
		end

		local distance = (currentPosition - lastPosition).magnitude
		local speed = distance / deltaTime

		-- Handle stop movement check
		if distance < stopMovementThreshold and timeSinceLastMoveCheck > positionCheckInterval then
			-- Player has stopped moving, don't apply rubberbanding anymore
			lastMoveCheckTime = currentTime
			lastPosition = currentPosition
			return
		end

		-- Separate horizontal and vertical movement
		local horizontalSpeed = (Vector3.new(currentPosition.X, 0, currentPosition.Z) - Vector3.new(lastPosition.X, 0, lastPosition.Z)).magnitude / deltaTime
		local verticalSpeed = (currentPosition.Y - lastPosition.Y) / deltaTime

		-- If the vertical speed is within the normal jumping range, we ignore it
		if math.abs(verticalSpeed) < verticalMovementThreshold then
			verticalSpeed = 0  -- Set vertical speed to zero if it's within the allowed range
		end

		-- If the horizontal speed exceeds the threshold, flag it
		if horizontalSpeed > speedThreshold then
			-- Only flag if enough time has passed to avoid spamming
			if currentTime - lastFlagTime > debounceTime then
				lastFlagTime = currentTime

				-- Freeze the player in place
				if rubberBanding then
					isFrozen = true
					freezeStartTime = currentTime
					humanoidRootPart.CFrame = CFrame.new(lastPosition)
					print(player.Name .. ": Speed exceeded threshold, freezing for " .. freezeDuration .. " seconds.")
				end
			end
		end

		-- Update the position and time for the next check
		lastPosition = currentPosition
		lastTime = currentTime
	end)
end

return SpeedCheckModule
