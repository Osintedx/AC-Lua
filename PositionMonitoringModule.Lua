-- PositionMonitoringModule.lua
local RunService = game:GetService("RunService")

local PositionMonitoringModule = {}

-- Position monitoring function
function PositionMonitoringModule.monitorPosition(player, positionThreshold)
	local lastPosition = player.Character.HumanoidRootPart.Position

	RunService.Heartbeat:Connect(function()
		if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then return end

		local currentPosition = player.Character.HumanoidRootPart.Position
		local distanceMoved = (currentPosition - lastPosition).magnitude

		if distanceMoved > positionThreshold then
			player.Character:SetPrimaryPartCFrame(CFrame.new(lastPosition))
			warn(player.Name .. ": Unusual movement detected, teleporting back.")
		end

		lastPosition = currentPosition
	end)
end

return PositionMonitoringModule
