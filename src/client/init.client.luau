local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Bridge = require(ReplicatedStorage.Shared.Network.Dergser.Bridge)
local Motion = require(ReplicatedStorage.Shared.Network.Packets.Motion)
local startup = require(ReplicatedStorage.Shared.startup)

local serverCacheObjects: Folder = Workspace.ServerCacheObjects
local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera
local humanoid = nil

local inputMap = {
  [Enum.KeyCode.W] = 1,
  [Enum.KeyCode.A] = 2,
  [Enum.KeyCode.S] = 3,
  [Enum.KeyCode.D] = 4,
}

local keyBitflags = {false, false, false, false} -- WASD

local function onForwards(_, state: Enum.UserInputState, input: InputObject)
	if humanoid == nil then
		return Enum.ContextActionResult.Pass
	end

  if not inputMap[input.KeyCode] then
    return Enum.ContextActionResult.Pass
  end

  keyBitflags[inputMap[input.KeyCode]] = state == Enum.UserInputState.Begin
	Motion:send(keyBitflags[1], keyBitflags[2], keyBitflags[3], keyBitflags[4])

	return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction(
	"ForwardMove",
	onForwards,
	false,
	Enum.KeyCode.W,
	Enum.KeyCode.A,
	Enum.KeyCode.S,
	Enum.KeyCode.D
)

local angles = {
  CFrame.identity + Vector3.new(0, 5, 20),
  CFrame.identity * CFrame.Angles(0, math.rad(90), 0) + Vector3.new(20, 5, 0),
  CFrame.identity * CFrame.Angles(0, math.rad(-90), 0) + Vector3.new(-20, 5, 0)
}
local angleCount = 1
local cameraAngle = CFrame.identity + Vector3.new(0, 5, 20)

local function changeCamera(_, state: Enum.UserInputState, _input: InputObject)
  if state == Enum.UserInputState.Begin then
    angleCount += 1
    if angleCount > #angles then
      angleCount = 1
    end

    cameraAngle = angles[angleCount]
  end

  return Enum.ContextActionResult.Pass
end

ContextActionService:BindAction("ChangeCam", changeCamera, false, Enum.KeyCode.E)

humanoid = Players.LocalPlayer.Character
Players.LocalPlayer.CharacterAdded:Connect(function(character)
	humanoid = character:FindFirstAncestorWhichIsA("Humanoid") or character:WaitForChild("Humanoid")
end)

local karts = serverCacheObjects:WaitForChild("Karts")
local kart = karts:WaitForChild("Kart") :: Part
local kartCentral = kart:WaitForChild("Center") :: Part

RunService.RenderStepped:Connect(function()
  Bridge:startQuery()
	Bridge:endQuery()

  if not Workspace:FindFirstChild("VehicleSeat") then
    return
  end

  if humanoid == nil or not Workspace:FindFirstChild("VehicleSeat").Occupant then
    camera.CameraType = Enum.CameraType.Custom
    return
  end

  --camera.CameraType = Enum.CameraType.Scriptable
  if camera then
    local kartCFrame = kartCentral.CFrame
    local baseCFrame = kart.CFrame
    --camera.Focus = 
    camera.CFrame = kartCFrame:Lerp(baseCFrame, 0.5) * cameraAngle
  end
end)

startup({})