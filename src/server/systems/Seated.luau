local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Planck = require(ReplicatedStorage.Packages.Planck)
local components = require(ReplicatedStorage.Shared.components)
local ref = require(ReplicatedStorage.Shared.std.ref)
local world = require(ReplicatedStorage.Shared.world)

local Player = components.Player
local Driving = components.Driving

local newEvent, collectEvents =
	Planck.onEvent(Workspace.VehicleSeat, Workspace.VehicleSeat:GetPropertyChangedSignal("Occupant"))

local function checkIfSeated() 
  for _ in collectEvents() do
    local occupant = Workspace.VehicleSeat.Occupant
    if occupant == nil or not occupant.Parent then
      for _i, player in world:query(Player):with(Driving) do
        world:remove(ref(player.UserId), Driving)
      end
      continue
    end

    local player = Players:GetPlayerFromCharacter(occupant.Parent)
    if player == nil then
      continue
    end

    local id = ref(player.UserId)
    world:set(id, Driving)
  end
end

return {
	system = checkIfSeated,
	runConditions = { newEvent },
}