--!strict
--!native

local currentIdentifier = 0

export type Identifier = number

local function new(): Identifier
  currentIdentifier += 1
  return currentIdentifier
end

return {
  new = new,
}