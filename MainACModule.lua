-- MainACModule.lua
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local SpeedCheckModule = require(script.Parent.SpeedCheckModule)
local PositionMonitoringModule = require(script.Parent.PositionMonitoringModule)
local FunctionHooksModule = require(script.Parent.FunctionHooksModule)
local ACSettingsModule = require(script.Parent.ACSettingsModule)
local ACEnumsModule = require(script.Parent.ACEnumsModule)

local sensitiveFunctions = {
	RemoteFunction = ReplicatedStorage:FindFirstChild("TestRemoteFunction"),
	RemoteEvent = ReplicatedStorage:FindFirstChild("TestRemoteEvent"),
}

-- Apply settings
local speedThreshold = ACSettingsModule.config.speedThreshold
local rubberBanding = ACSettingsModule.config.rubberBanding
local positionThreshold = ACSettingsModule.config.positionThreshold
local gracePeriod = ACSettingsModule.config.gracePeriod

-- Monitor functions
FunctionHooksModule.monitorHooks(sensitiveFunctions)

-- Player added event
Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Start speed check and position monitoring for the player
		spawn(function() SpeedCheckModule.checkSpeed(player, speedThreshold, rubberBanding) end)
		spawn(function() PositionMonitoringModule.monitorPosition(player, positionThreshold) end)
	end)
end)

print("Anti-Cheat System Initialized")
