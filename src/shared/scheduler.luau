local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local PlanckRunService = require(ReplicatedStorage.Packages.PlanckRunService)
local world = require(script.Parent.world)

local Scheduler = Planck.Scheduler
local runServicePlugin = PlanckRunService.Plugin.new()

local scheduler = Scheduler.new(world)
  :addPlugin(runServicePlugin :: any)

return scheduler