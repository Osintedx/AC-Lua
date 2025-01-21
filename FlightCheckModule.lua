-- FlightCheckModule.lua
local RunService = game:GetService("RunService")

local FlightCheckModule = {}

-- Settings
local verticalSpeedThreshold = 50  -- Maximum allowed vertical speed (studs per second)
local flightDurationThreshold = 2  -- Time duration to detect consistent flight (seconds)
local groundCheckDistance = 5      -- Distance below the player to check for the ground (studs)
local freezeDuration = 5           -- Duration to freeze the player after detection (seconds)

local playersBeingMonitored = {}

-- Detect flight behavior
function FlightCheckModule.checkFlight(player)
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Humanoid") then return end

	local humanoid = character.Humanoid
	local humanoidRootPart = character.HumanoidRootPart
	local lastPosition = humanoidRootPart.Position
	local lastTime = tick()
	local flightStartTime = nil
	local isFrozen = false
	local freezeStartTime = 0

	-- Function to check if the player is on the ground using raycasts
	local function isGrounded(position)
		local rayOrigin = position
		local rayDirection = Vector3.new(0, -groundCheckDistance, 0)
		local ray = Ray.new(rayOrigin, rayDirection)
		local hitPart, _ = workspace:FindPartOnRay(ray)
		return hitPart ~= nil
	end

	-- Monitor player movement
	local function onHeartbeat()
		if not character or not character:FindFirstChild("HumanoidRootPart") then
			FlightCheckModule.stopMonitoring(player)
			return
		end

		local currentTime = tick()
		local deltaTime = currentTime - lastTime
		local currentPosition = humanoidRootPart.Position

		-- Prevent extremely small deltaTime values
		if deltaTime < 0.1 then return end

		-- Calculate vertical speed
		local verticalSpeed = math.abs(currentPosition.Y - lastPosition.Y) / deltaTime

		-- Check if the player is grounded using raycasts
		local grounded = isGrounded(humanoidRootPart.Position)

		-- Allow jumping and normal movement
		if grounded or humanoid:GetState() == Enum.HumanoidStateType.Jumping then
			flightStartTime = nil -- Reset flight detection timer
		elseif verticalSpeed > verticalSpeedThreshold then
			-- Detect flight only when not grounded or jumping
			if not flightStartTime then
				flightStartTime = currentTime
			elseif currentTime - flightStartTime >= flightDurationThreshold then
				-- Flight detected
				if not isFrozen then
					isFrozen = true
					freezeStartTime = currentTime
					humanoidRootPart.CFrame = CFrame.new(lastPosition)
					print(player.Name .. ": Flight detected, freezing for " .. freezeDuration .. " seconds.")
				end
			end
		else
			flightStartTime = nil -- Reset flight detection timer if vertical speed is below the threshold
		end

		-- Freeze logic
		if isFrozen then
			if currentTime - freezeStartTime >= freezeDuration then
				isFrozen = false
				print(player.Name .. ": Freeze duration ended.")
			else
				humanoidRootPart.Velocity = Vector3.zero -- Stop velocity
				humanoidRootPart.CFrame = CFrame.new(lastPosition)
			end
		end

		-- Update position and time for the next check
		lastPosition = currentPosition
		lastTime = currentTime
	end

	-- Start monitoring
	if not playersBeingMonitored[player] then
		playersBeingMonitored[player] = RunService.Heartbeat:Connect(onHeartbeat)
	end
end

-- Stop monitoring a player
function FlightCheckModule.stopMonitoring(player)
	if playersBeingMonitored[player] then
		playersBeingMonitored[player]:Disconnect()
		playersBeingMonitored[player] = nil
		print(player.Name .. ": Flight monitoring stopped.")
	end
end

return FlightCheckModule
