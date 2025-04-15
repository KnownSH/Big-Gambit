local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local PlanckRunService = require(ReplicatedStorage.Packages.PlanckRunService)
local Bridge = require(ReplicatedStorage.Shared.Network.Dergser.Bridge)

local First = PlanckRunService.Phases.First
local Last = PlanckRunService.Phases.Last

local startQuery: Planck.SystemTable<nil> = {
  system = function()
    Bridge:startQuery()
  end,
  phase = First,
}

local endQuery: Planck.SystemTable<nil> = {
  system = function()
    Bridge:endQuery()
  end,
  phase = Last
}

return {startQuery, endQuery}