local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.jecs)
local world = require(script.Parent.world)

type Entity<T = unknown> = jecs.Entity<T>
type Components = {
  Player: Entity,
  Character: Entity<Model>,
  Driving: Entity
} 

local components: Components = {
  Player = world:component(),
  Character = world:component(),
  Driving = world:component(),
} :: Components

for name, component in components :: { [string]: Entity } do
  world:set(component, jecs.Name, name)
end

return table.freeze(components)