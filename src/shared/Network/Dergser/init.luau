--!strict
--!native

local Bridge = require(script.Bridge)
local Packet = require(script.Packet)

export type Packet<T...> = Packet.Packet<T...>
export type Bridge = Bridge.Bridge

return {
  Packet = Packet,
  Bridge = Bridge,
}