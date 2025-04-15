local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Squash = require(ReplicatedStorage.Packages.squash)
local Packet = require(ReplicatedStorage.Shared.Network.Dergser.Packet)

local motion: Packet.Packet<boolean, boolean, boolean, boolean> = Packet.new()

motion:incoming(function(buf: buffer)
	local cursor = Squash.frombuffer(buf)
	return select(5, Squash.boolean().des(cursor))
end)

motion:outgoing(function(...)
	local cursor = Squash.cursor(1)
	Squash.boolean().ser(cursor, false, false, false, false, ...)
	return Squash.tobuffer(cursor)
end)

return motion