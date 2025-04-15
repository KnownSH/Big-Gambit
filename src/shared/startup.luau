local scheduler = require(script.Parent.scheduler)
local systems = require(script.Parent.systems)

local function startup(envSystems)
  scheduler:addSystems(systems :: any)
  
  if #envSystems ~= 0 then
    scheduler:addSystems(envSystems)
  end
end

return startup