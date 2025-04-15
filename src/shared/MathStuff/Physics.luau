local Physics = {}

function Physics.getVelocityAtPoint<T>(object: T & BasePart, point: Vector3): Vector3
  return object.AssemblyLinearVelocity + object.AssemblyAngularVelocity:Cross(point - object.Position)
end

function Physics.getAttachmentVelocity(attachment: Attachment): Vector3
  return Physics.getVelocityAtPoint(attachment.Parent :: BasePart, attachment.WorldPosition)
end

return Physics