local ReplicatedStorage = game:GetService("ReplicatedStorage")

local World = require(ReplicatedStorage.Shared.world)

local KartSystem = {}

KartSystem.tags = {}
KartSystem.tags.Vehicle = World:component()

return KartSystem