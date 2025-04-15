--!strict
--!native
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local PropertyFactory = require(ReplicatedStorage.Shared.Factories.PropertyFactory)
local MathStuff = require(ReplicatedStorage.Shared.MathStuff)

local serverCacheObjects: Folder = Workspace.ServerCacheObjects

local WHEELS: { WheelNames } = { "FrontLeft", "FrontRight", "BackLeft", "BackRight" }

local frontWheelCurve = Instance.new("FloatCurve")
frontWheelCurve:SetKeys({
	FloatCurveKey.new(0.0, 0.8, Enum.KeyInterpolationMode.Cubic),
  FloatCurveKey.new(0.15, 0.9, Enum.KeyInterpolationMode.Cubic),
	FloatCurveKey.new(0.5, 0.5, Enum.KeyInterpolationMode.Cubic),
	FloatCurveKey.new(1.0, 0.2, Enum.KeyInterpolationMode.Cubic),
})

local backWheelCurve = Instance.new("FloatCurve")
backWheelCurve:SetKeys({
	FloatCurveKey.new(0.0, 0.5, Enum.KeyInterpolationMode.Cubic), -- Slightly higher start/peak?
  FloatCurveKey.new(0.1, 0.4, Enum.KeyInterpolationMode.Cubic),-- Peak grip slightly later/higher than front
	FloatCurveKey.new(0.5, 0.3, Enum.KeyInterpolationMode.Cubic), -- Gradual drop, maybe slightly more grip than front
	FloatCurveKey.new(1.0, 0.1, Enum.KeyInterpolationMode.Cubic), -- Still some grip
})

local Kart = {}
Kart.Impl = {}
Kart.Impl.__index = Kart.Impl
Kart.Constructor = {}

type WheelNames = "FrontLeft" | "FrontRight" | "BackLeft" | "BackRight"

type KartProps = {
	startLocation: Vector3,
	currentLocation: Vector3,
	serverObject: Part,
	wheels: { [WheelNames]: Attachment },
	impulse: number,
	rotation: number,
}

export type Kart = KartProps & typeof(Kart.Impl)

local function getKartHolder(): Folder
	local kartHolder = serverCacheObjects:FindFirstChild("Karts")
	if kartHolder == nil then
		kartHolder = Instance.new("Folder")
		kartHolder.Name = "Karts"
		kartHolder.Parent = serverCacheObjects
	end
	return kartHolder :: Folder
end

local function newWheel(wheelName: WheelNames, kartBody: Part): Attachment
	local kartSize = kartBody.Size

	local wheel = PropertyFactory.via(Instance.new("Attachment"))({
		WorldOrientation = Vector3.zero,
		Name = wheelName,
		Position = Vector3.new(-kartSize.X / 2, 0, -kartSize.Z / 2),
		Attributes = {
			IsWheel = true,
		},
	})

	local gizmo = PropertyFactory.via(Instance.new("Part"))({
		Name = `{wheelName}_Gizmo`,
		Color = Color3.fromHSV(0.360784, 1.000000, 1.000000),
		Size = Vector3.new(0.1, 0.5, 0.1),
		Anchored = true,
		CanCollide = false,
		Massless = false,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
	})

	local gizmoY = PropertyFactory.via(Instance.new("Part"))({
		Name = `{wheelName}_GizmoY`,
		Color = Color3.fromHSV(0.000000, 1.000000, 1.000000),
		Size = Vector3.new(0.1, 0.1, 0.1),
		Anchored = true,
		CanCollide = false,
		Massless = false,
		Material = Enum.Material.Neon,
		Transparency = 0.4,
	})

	local fakeWheel = PropertyFactory.via(Instance.new("Part"))({
		Name = `{wheelName}_FakeWheel`,
		Size = Vector3.new(0.5, 3, 3),
		Orientation = Vector3.new(0, 90, 0),
		Anchored = true,
		CanCollide = false,
		Shape = Enum.PartType.Cylinder,
		Transparency = 0.2,
		Color = Color3.fromRGB(255, 255, 255),
		Massless = true,
	})

	if wheelName == "FrontLeft" then
		wheel.Position *= Vector3.new(-1, 0, 1)
	elseif wheelName == "BackLeft" then
		wheel.Position *= Vector3.new(-1, 0, -1)
	elseif wheelName == "BackRight" then
		wheel.Position *= Vector3.new(1, 0, -1)
	end

	wheel.Parent = kartBody
	gizmo.Position = wheel.Position
	gizmo.Parent = kartBody
	gizmoY.Position = wheel.Position
	gizmoY.Parent = kartBody
	fakeWheel.Parent = kartBody
	return wheel
end

local function defineWheelControllers(kartBody: Part): { [WheelNames]: Attachment }
	return {
		FrontLeft = newWheel("FrontLeft", kartBody),
		FrontRight = newWheel("FrontRight", kartBody),
		BackLeft = newWheel("BackLeft", kartBody),
		BackRight = newWheel("BackRight", kartBody),
	}
end

local function createKartModel(location: Vector3): Part
	local kartHolder = getKartHolder()

	local kartModel = PropertyFactory.via(Instance.new("Part"))({
		Size = Vector3.new(5, 3, 12),
		Name = "Kart",
		Position = location,
		Anchored = false,
		Transparency = 0.7,
		Parent = kartHolder,
		CustomPhysicalProperties = PhysicalProperties.new(0.7, 0, 1),
	})

	local lookAt = PropertyFactory.via(Instance.new("Attachment"))({
		Name = "LookAt",
		Position = Vector3.zero,
		Parent = kartModel,
	})

	PropertyFactory.via(Instance.new("Part"))({
		Name = "Center",
		Color = Color3.fromRGB(0, 0, 255),
		Size = Vector3.new(2, 1, 2),
		Position = lookAt.WorldPosition,
		Anchored = true,
		CanCollide = false,
		Massless = true,
		Parent = kartModel
	})

	return kartModel
end

local GIZMO_SUSPENSION_FORCE_SCALE = 0.05
local GIZMO_STEERING_ACCEL_SCALE = 0.1

local SUSPENSION_REST_DIST = 6
local SPRING_DAMPER = 2
local SPRING_STRENGTH = 40

function Kart.Impl.startPhysics(self: Kart)
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { self.serverObject :: Instance }

	-- TODO: REMOVE THIS!!
	RunService.Heartbeat:Connect(function(_deltaTime)
		for _, wheelName in WHEELS do
			local wheel = self:getWheel(wheelName)
			local raycast =
				Workspace:Raycast(wheel.WorldCFrame.Position, -wheel.WorldCFrame.UpVector * 5, raycastParams)

			local suspensionGizmo = self.serverObject:FindFirstChild(`{wheelName}_Gizmo`) :: Part
			local steeringGizmo = self.serverObject:FindFirstChild(`{wheelName}_GizmoY`) :: Part
			local bodyCenter = self.serverObject:FindFirstChild("Center") :: Part
			local lookAt = self.serverObject:FindFirstChild("LookAt") :: Attachment

			bodyCenter.Position = lookAt.WorldPosition
			bodyCenter.Orientation = self.serverObject.Orientation

			if (wheelName == "FrontLeft" or wheelName == "FrontRight") and Workspace.VehicleSeat.Occupant then
				wheel.Orientation = Vector3.new(0, self.rotation and self.rotation / 2, 0)
			end

			if raycast ~= nil then
				local tireTransform = wheel
				local tireWorldPos = tireTransform.WorldPosition
				local tireWorldVel = MathStuff.Physics.getAttachmentVelocity(wheel)

				-- Suspension
				local springDir = tireTransform.WorldCFrame.UpVector

				local offset = SUSPENSION_REST_DIST - raycast.Distance
				local velAlongSpring = springDir:Dot(tireWorldVel)
				local suspensionForceMag = (offset * SPRING_STRENGTH) - (velAlongSpring * SPRING_DAMPER)
				local suspensionForceVector = springDir * suspensionForceMag

				self.serverObject:ApplyImpulseAtPosition(suspensionForceVector, wheel.WorldPosition)

				-- Steering Force / Friction
				local steeringDir = tireTransform.WorldCFrame.RightVector
				local steeringVel = steeringDir:Dot(tireWorldVel)

				-- slip ratio
				local totalSpeed = tireWorldVel.Magnitude
				local slipRatio = 0
				if totalSpeed > 0.01 then
					slipRatio = math.abs(steeringVel) / totalSpeed
					slipRatio = math.clamp(slipRatio, 0, 1)
				end

				local tireGripFactor = 1.0
				local gripCurve = frontWheelCurve
				if wheelName == "BackLeft" or wheelName == "BackRight" then
					gripCurve = backWheelCurve
				end

				tireGripFactor = gripCurve:GetValueAtTime(slipRatio)
				tireGripFactor = math.clamp(tireGripFactor, 0, 1)
				
				local desiredVelChange = -steeringVel * tireGripFactor
				local desiredAccel = desiredVelChange

				local tireMass = (self.serverObject.AssemblyMass / 4)
				local steeringForceVector = steeringDir * tireMass * desiredAccel

				self.serverObject:ApplyImpulseAtPosition(steeringForceVector, tireWorldPos)

				-- Fake wheels
				local fakeWheel = self.serverObject:FindFirstChild(`{wheelName}_FakeWheel`) :: Part
				if fakeWheel then
					fakeWheel.Position = wheel.WorldPosition - Vector3.new(0, raycast.Distance - 1.5, 0)
					fakeWheel.Orientation = self.serverObject.Orientation
				end

				if suspensionGizmo then
					local gizmoHeight = math.abs(suspensionForceMag * GIZMO_SUSPENSION_FORCE_SCALE)
					local gizmoOffset = springDir * (suspensionForceMag * GIZMO_SUSPENSION_FORCE_SCALE / 2)
					PropertyFactory.via(suspensionGizmo)({
						Size = Vector3.new(0.1, gizmoHeight, 0.1),
						Position = tireWorldPos + gizmoOffset,
						Orientation = Vector3.zero
					})
				end

				if steeringGizmo then
					local gizmoLength = math.abs(desiredAccel * GIZMO_STEERING_ACCEL_SCALE)
					PropertyFactory.via(steeringGizmo)({
						Size = Vector3.new(gizmoLength, 0.1, 0.1),
						Orientation = tireTransform.WorldCFrame.LookVector,
						Position = tireWorldPos
					})
				end
			end
		end

		if Workspace.VehicleSeat.Occupant then
			self.serverObject:ApplyImpulse(self.serverObject.CFrame.LookVector * self.impulse)
		end
	end)
end

function Kart.Impl.setPosition(self: Kart, position: Vector3)
	self.currentLocation = position
	self.serverObject.Position = position
end

function Kart.Impl.getWheel(self: Kart, wheelName: WheelNames): Attachment
	return self.wheels[wheelName]
end

function Kart.Constructor.new(spawnLocation: Vector3): Kart
	local serverObject = createKartModel(spawnLocation)

	local self: KartProps = {
		startLocation = spawnLocation,
		currentLocation = spawnLocation,
		serverObject = serverObject,
		wheels = defineWheelControllers(serverObject),
		impulse = 0,
		rotation = 0,
	}

	return setmetatable(self, Kart.Impl) :: Kart
end

return Kart.Constructor
