local ACSettingsModule = {}

--// Default configuration
ACSettingsModule.config = {
	speedThreshold = 40, -- Max allowed speed (studs per second)
	rubberBanding = true, -- Enable or disable rubber-banding
	positionThreshold = 50, -- Max allowed position change per frame (studs)
	maxViolations = 5, -- Max number of violations before kicking
}

--// Table to track violations for each player
local playerViolations = {}

--// Function to monitor speed and movement of the player
local function monitorPlayer(player)
	local lastPosition = player.Character and player.Character:FindFirstChild("HumanoidRootPart") and player.Character.HumanoidRootPart.Position
	local lastTime = tick()

	--// Initialize player's violation count if not already initialized
	if not playerViolations[player.UserId] then
		playerViolations[player.UserId] = 0
	end

	--// Check if the player is moving too fast or has abnormal movement
	game:GetService("RunService").Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
			return
		end

		local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
		local humanoidRootPart = player.Character.HumanoidRootPart
		local currentPosition = humanoidRootPart.Position
		local currentTime = tick()
		local deltaTime = currentTime - lastTime

		--// Prevent extremely small deltaTime values
		if deltaTime < 0.1 then return end

		--// Calculate the player's speed
		local distance = (currentPosition - lastPosition).Magnitude
		local speed = distance / deltaTime

		--// Calculate the player's position change
		local positionChange = (currentPosition - lastPosition).Magnitude

		--// Ignore checks if the player is jumping or falling
		if humanoid and humanoid:GetState() == Enum.HumanoidStateType.Physics then
			-- The player is not in a jumping/falling state, so we check their movement
			if speed > ACSettingsModule.config.speedThreshold or positionChange > ACSettingsModule.config.positionThreshold then
				-- Increment violation count
				playerViolations[player.UserId] = playerViolations[player.UserId] + 1

				-- Check if player has exceeded max violations
				if playerViolations[player.UserId] >= ACSettingsModule.config.maxViolations then
					-- Kick the player after 5 violations
					player:Kick("Abnormal movement detected. You have been kicked for exploiting.")
					print(player.Name .. " was kicked for exceeding the maximum number of violations.")
					playerViolations[player.UserId] = nil --// Reset violation count after kick
				else
					--// Notify about the violation (optional)
					print(player.Name .. " violated movement thresholds. Violation count: " .. playerViolations[player.UserId])
				end
			end
		end

		--// Update position and time for the next check
		lastPosition = currentPosition
		lastTime = currentTime
	end)
end

--// Start monitoring the player
game.Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		--// Initialize the violation count for the player if not already done
		if not playerViolations[player.UserId] then
			playerViolations[player.UserId] = 0
		end
		monitorPlayer(player)
	end)
end)

return ACSettingsModule
