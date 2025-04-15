
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterPlayer = game:GetService("StarterPlayer")

local Bridge = require(ReplicatedStorage.Shared.Network.Dergser.Bridge)
local Motion = require(ReplicatedStorage.Shared.Network.Packets.Motion)
local components = require(ReplicatedStorage.Shared.components)
local startup = require(ReplicatedStorage.Shared.startup)
local ref = require(ReplicatedStorage.Shared.std.ref)
local world = require(ReplicatedStorage.Shared.world)
local Kart = require(script.Libraries.Builders.Kart)
local systems = require(script.systems)

local Driving = components.Driving

local gokart = Kart.new(Vector3.new(0, 3, 0))
gokart:startPhysics()

local ACCELERATION = 55

-- Main clock
RunService.Heartbeat:Connect(function()
  Bridge:startQuery()

  for _, player, W, A, S, D in Motion:query() do
    if player == nil then
      continue
    end
    if world:has(ref(player.UserId), Driving) then
      gokart.impulse = if W then ACCELERATION elseif S then -(ACCELERATION / 3) else 0
      gokart.rotation = if A then 35 elseif D then -35 else 0
    end
  end

  Bridge:endQuery()
end)

startup(systems :: any)