local ReplicatedStorage = game:GetService("ReplicatedStorage")

local attributes = require(ReplicatedStorage.Shared.attributes)
local Motion = require(ReplicatedStorage.Shared.Network.Packets.Motion)

local InputReceiver = {}

local function handleInputs()
  for _i, player, W, A, S, D in Motion:query() do
    if player == nil then
      continue
    end

    local isDriving = player:GetAttribute(attributes.kart.PlayerIsDriving)
    if not isDriving then
      continue
    end

    
  end
end

InputReceiver.handleInputs = handleInputs

return InputReceiver