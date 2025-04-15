local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local PlanckRunService = require(ReplicatedStorage.Packages.PlanckRunService)
local Motion = require(ReplicatedStorage.Shared.Network.Packets.Motion)

local Update = PlanckRunService.Phases.Update

local function handleInput()
  
end

local system: Planck.SystemTable<nil> = {
  system = handleInput,
  phase = Update
}

return system