local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
	return
end

repeat task.wait(0.1) until workspace:GetAttribute("PrismoraReady")

local world = workspace:WaitForChild("PrismoraWorld")
local surfaces = {}
for _, item in world:GetDescendants() do
	if item:IsA("BasePart") and string.find(item.Name, "PlayableSurface", 1, true) then
		table.insert(surfaces, item)
	end
end

local samples = 0
local holes = 0
local maxDeviation = 0
for _, surface in surfaces do
	local expectedY = surface.Position.Y + (surface.Size.Y * 0.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { surface }
	for x = -surface.Size.X * 0.48, surface.Size.X * 0.48, 4 do
		for z = -surface.Size.Z * 0.48, surface.Size.Z * 0.48, 4 do
			samples += 1
			local origin = surface.CFrame:PointToWorldSpace(Vector3.new(x, 18, z))
			local result = workspace:Raycast(origin, Vector3.new(0, -40, 0), params)
			if not result then
				holes += 1
			else
				maxDeviation = math.max(maxDeviation, math.abs(result.Position.Y - expectedY))
			end
		end
	end
end

local spawnPosition = workspace:GetAttribute("PrismoraSpawnPoint")
local visibleCyan = {}
if typeof(spawnPosition) == "Vector3" then
	for _, item in workspace:GetPartBoundsInRadius(spawnPosition, 24) do
		if item:IsA("BasePart") and item.Transparency < 0.9 and item.Color.B > 0.75 and item.Color.G > 0.65 and item.Color.R < 0.65 then
			table.insert(visibleCyan, item:GetFullName())
		end
	end
end

print(string.format(
	"PRISMORA_COLLISION_AUDIT surfaces=%d samples=%d holes=%d maxDeviation=%.3f visibleCyan=%d",
	#surfaces,
	samples,
	holes,
	maxDeviation,
	#visibleCyan
))
if #visibleCyan > 0 then
	warn("PRISMORA_VISIBLE_CYAN " .. table.concat(visibleCyan, " | "))
end
