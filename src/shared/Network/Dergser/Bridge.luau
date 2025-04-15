--!strict
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Identifier = require(script.Parent.Identifier)
local Squash = require(ReplicatedStorage.Packages.squash)

local REMOTES_FOLDER_NAME: "Remotes" = "Remotes"
local RELIABLE_REMOTE_NAME = "Reliable"
local UNRELIABLE_REMOTE_NAME = "Unreliable"
local DEFAULT_TIMEOUT = 5

type Identifier = Identifier.Identifier
type Environment = "Server" | "Client"
type Remotes = "Reliable" | "Unreliable"
type Indexer<T> = { [string]: T }

export type OutgoingPacket = {
	identifier: Identifier,
	data: buffer,
	to: Environment,
	type: Remotes,
}

type OutgoingPayload = {
	Reliable: { OutgoingPacket },
	Unreliable: { OutgoingPacket },
} & Indexer<{ OutgoingPacket }>

type IncomingPacketData = {
	sender: Player?,
	data: buffer,
}

type BridgeProps = {
	reliable: RemoteEvent,
	unreliable: UnreliableRemoteEvent,
	_packetQueue: OutgoingPayload,
	_snapshotCache: { [Identifier]: {IncomingPacketData} },
	_incomingPackets: { [Identifier]: {IncomingPacketData} },
	_environment: Environment,
}

local sT = Squash.T

local payloadSerdeDefinition = Squash.record {
	identifier = sT(Squash.uint(2)),
	data = sT(Squash.buffer())
}
type PayloadSerde = typeof(sT(payloadSerdeDefinition))
local arraySerde = Squash.array(payloadSerdeDefinition)

local function getEnvironment(): Environment
	if RunService:IsServer() then
		return "Server"
	elseif RunService:IsClient() then
		return "Client"
	else
		warn("[Dergser:Bridge]: Unable to determine environment. Defaulting to Server.")
		return "Server"
	end
end

local function getRemotes()
	if ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME) == nil then
		local remotes = Instance.new("Folder")
		remotes.Name = REMOTES_FOLDER_NAME
		remotes.Parent = ReplicatedStorage
	end

  local remotes = ReplicatedStorage:FindFirstChild(REMOTES_FOLDER_NAME) :: Folder

	local reliableRemote, unreliableRemote =
		remotes:FindFirstChild(RELIABLE_REMOTE_NAME) :: RemoteEvent?,
		remotes:FindFirstChild(UNRELIABLE_REMOTE_NAME) :: UnreliableRemoteEvent?

	if reliableRemote and unreliableRemote then
		return reliableRemote, unreliableRemote
	end

	if getEnvironment() == "Server" then
		reliableRemote = Instance.new("RemoteEvent")
		reliableRemote.Name = RELIABLE_REMOTE_NAME
		reliableRemote.Parent = remotes

		unreliableRemote = Instance.new("UnreliableRemoteEvent")
		unreliableRemote.Name = UNRELIABLE_REMOTE_NAME
		unreliableRemote.Parent = remotes

		return reliableRemote, unreliableRemote
	end

	return remotes:WaitForChild("Reliable") :: RemoteEvent, remotes:WaitForChild("Unreliable") :: UnreliableRemoteEvent
end

local function serializePackets(payload: { OutgoingPacket }): Squash.Cursor
	local finalArray = table.create(#payload) :: { PayloadSerde }
	
	for _, data in payload do
		table.insert(finalArray, {
			identifier = data.identifier,
			data = data.data
		})
	end

	local cursor = Squash.cursor()
	arraySerde.ser(cursor, finalArray)

	return cursor
end

local Bridge = {}
Bridge.Impl = {}
Bridge.Impl.__index = Bridge.Impl

type IncomingPayload = {
	sender: Player?,
	data: buffer
}

export type Bridge = typeof(setmetatable({} :: BridgeProps, {} :: typeof(Bridge.Impl)))

function Bridge.Impl.dispatch(self: Bridge, payload: OutgoingPayload)
	local channels: Indexer<any> = {
		Reliable = self.reliable,
		Unreliable = self.unreliable
	}

	if self._environment == "Client" then
		for channel, remote in channels do
			local packetCount = 0
			for _ in payload[channel] do
				packetCount += 1
			end

			if packetCount == 0 then
				continue
			end

			local cursor = serializePackets(payload[channel])
			local buf = Squash.tobuffer(cursor)

			remote:FireServer(buf)
		end
	end
end

function Bridge.Impl.processPacket(self: Bridge, type: Remotes, sender: Player?, packet: buffer)
	local cursor = Squash.frombuffer(packet)
	local packets = arraySerde.des(cursor)

	self._incomingPackets = {}

	for _, payload in packets do
		if self._incomingPackets[payload.identifier] == nil then
			self._incomingPackets[payload.identifier] = {} :: { IncomingPayload }
		end
		local processedPayload = {
			sender = sender,
			data = payload.data
		}
		table.insert(self._incomingPackets[payload.identifier], processedPayload)
	end
end

function Bridge.Impl.startQuery(self: Bridge)
	self._snapshotCache = self._incomingPackets
	self._incomingPackets = {}
end

function Bridge.Impl.endQuery(self: Bridge)
	if #self._packetQueue.Reliable == 0 and #self._packetQueue.Unreliable == 0 then
		return
	end

	self:dispatch(self._packetQueue)
	self._packetQueue = {
		Reliable = {},
		Unreliable = {}
	}
end

function Bridge.Impl.initalize(self: Bridge)
	if getEnvironment() == "Server" then
		self.reliable.OnServerEvent:Connect(function(player, packet)
			self:processPacket("Reliable", player, packet)
		end)

		self.unreliable.OnServerEvent:Connect(function(player, packet)
			self:processPacket("Unreliable", player, packet)
		end)
	end
end

function Bridge.Impl._addToQueue(self: Bridge, packet: OutgoingPacket)
	if packet.to == getEnvironment() then
		return
	end
	table.insert(self._packetQueue[packet.type], packet)
end

Bridge.Constructor = {}

-- Bridge is a singleton
-- The constructor is kept incase multiple remote channels are required in the future
function Bridge.Constructor.new(): Bridge
	local reliable, unreliable = getRemotes()

	local props: BridgeProps = {
		reliable = reliable,
		unreliable = unreliable,
		_packetQueue = { Reliable = {}, Unreliable = {} },
		_incomingPackets = {},
		_snapshotCache = {},
		_environment = getEnvironment(),
	}

	local self = setmetatable(props, Bridge.Impl)
	self:initalize()

	return self
end

return Bridge.Constructor.new()