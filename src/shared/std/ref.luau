local ReplicatedStorage = game:GetService("ReplicatedStorage")

local jecs = require(ReplicatedStorage.Packages.jecs)
local world = require(ReplicatedStorage.Shared.world)
local refs: { [any]: jecs.Entity<any> } = {}

--- Creates a reference to a new or cached entity with the given key.
--- 
--- @param key T? -- The key used to reference the entity. Can be nil.
--- @return jecs.Entity<T> -- The entity associated with the given key.
local function ref<T>(key: T?): jecs.Entity<T>
  if not key then
    return world:entity()
  end
  local refObject = refs[key]
  if not refObject then
    refObject = world:entity()
    refs[key] = refObject
  end
  return refObject
end

return ref