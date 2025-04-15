--!strict
local PropertyFactory = {}

type PropsProvider<T> = { 
  [keyof<T>]: any,
  read Attributes: { [string?]: any }?,
}

type ExtendableInstance<T> = T & Instance & {
  [string]: any,
}

function PropertyFactory.via<T>(instance: ExtendableInstance<T>): (PropsProvider<T>) -> T
  return function(props: PropsProvider<T>): T
    if props.Attributes then
      for attrName: string, attrValue in props.Attributes do
        instance:SetAttribute(attrName, attrValue)
      end
    end
  
    for propName, propValue in props do
      if propName == "Attributes" then
        continue
      end
      instance[propName] = propValue
    end
    return instance
  end
end

return PropertyFactory