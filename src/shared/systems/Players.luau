local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Planck = require(ReplicatedStorage.Packages.Planck)
local Components = require(ReplicatedStorage.Shared.components)
local world = require(ReplicatedStorage.Shared.world)
local ref = require(ReplicatedStorage.Shared.std.ref)

local Phase = Planck.Phase

local connections = {}

local function playerAdded(player: Player)
  local id = ref(player.UserId)
  world:set(id, Components.Player, player)

  local characterAdded = player.CharacterAdded
  connections[id] = characterAdded:Connect(function(model)
    world:set(id, Components.Character, model)
  end)
end

local function playerRemoved(player: Player)
  local id = ref(player.UserId)
  world:clear(id)

  local connection = connections[id]
  connection:Disconnect()
  connections[id] = nil
end

local function startupSystem()
  -- goofy ah
  Players.PlayerAdded:Connect(playerAdded)
  Players.PlayerRemoving:Connect(playerRemoved)
end

return {
  system = startupSystem,
  phase = Phase.Startup
}