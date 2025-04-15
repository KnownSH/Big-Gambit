--!strict
--!native
local RunService = game:GetService("RunService")

local Bridge = require(script.Parent.Bridge)
local Identifier = require(script.Parent.Identifier)
type Identifier = Identifier.Identifier

local isClient = RunService:IsClient()

local BASE_PACKET_SETTINGS: PacketSettings = {
  RemoteType = "Reliable"
}

type PacketSettings = {
  RemoteType: "Reliable" | "Unreliable"
}

type PacketProps<T...> = {
  PacketSettings: PacketSettings?,
  outgoingProcessor: (T...) -> buffer,
  incomingProcessor: (buffer) -> T...,
  identifier: Identifier,
}

type PacketImpl<T...> = {
  __index: PacketImpl<T...>,
  __iter: (self: Packet<T...>) -> () -> (number | any, Player?, T...),
  incoming: (self: Packet<T...>, incoming: (buffer) -> T...) -> (),
  outgoing: (self: Packet<T...>, outgoing: (T...) -> buffer) -> (),
  send: (self: Packet<T...>, T...) -> (),
  query: (self: Packet<T...>) -> () -> (number | any, Player?, T...),

  new: (settings: PacketSettings?) -> Packet<T...>
}

export type Packet<T...> = typeof(setmetatable({} :: PacketProps<T...>, {} :: PacketImpl<T...>))

local Packet = {}
Packet.__index = Packet

function Packet:incoming<T...>(incoming: (buffer) -> T...)
  self.incomingProcessor = incoming
end

function Packet:outgoing<T...>(outgoing: (T...) -> buffer)
  self.outgoingProcessor = outgoing
end

function Packet.__iter<T...>(self: Packet<T...>): () -> (number | any, Player?, T...)
  local i = 0
  return function()
    i += 1

    local packet = Bridge._snapshotCache[self.identifier]
    if not packet then
      return
    end

    local subpacket = packet[i]
    
    if not subpacket then
      return
    end

    return i, subpacket.sender, self.incomingProcessor(subpacket.data)
  end
end

function Packet:query()
  return self:__iter()
end

function Packet:send<T...>(...)
  local packet = {
    data = self.outgoingProcessor(...),
    to = if isClient then "Server" else "Client",
    type = self.PacketSettings.RemoteType or "Reliable",
    identifier = self.identifier
  }
  Bridge:_addToQueue(packet :: Bridge.OutgoingPacket)
end

function Packet.new<T...>(settings: PacketSettings?): Packet<T...>
  local props = {
    PacketSettings = settings or BASE_PACKET_SETTINGS,
    identifier = Identifier.new()
  }
  return setmetatable(props, Packet) :: any
end

return Packet