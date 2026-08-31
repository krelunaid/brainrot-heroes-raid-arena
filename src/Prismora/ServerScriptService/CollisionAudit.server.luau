local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

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

-- Gate 1 character probes. They deliberately stress the same failure modes
-- reported during play: spawning below the map and being launched over an edge.
local probeStarted = false
local function waitForSafeCharacter(root, humanoid, timeout)
	local started = os.clock()
	repeat
		task.wait(0.05)
		local position = root.Position
		if position.Y > 24
			and math.abs(position.X) < 390
			and math.abs(position.Z) < 390
			and humanoid.FloorMaterial ~= Enum.Material.Air then
			return true, os.clock() - started
		end
	until os.clock() - started >= timeout or not root.Parent or humanoid.Health <= 0
	return false, os.clock() - started
end

local function runCharacterProbes(player, character)
	if probeStarted then return end
	probeStarted = true
	local humanoid = character:WaitForChild("Humanoid", 10)
	local root = character:WaitForChild("HumanoidRootPart", 10)
	if not humanoid or not root then
		warn("PRISMORA_CHARACTER_AUDIT unavailable=no_character")
		return
	end

	task.wait(2)
	local spawn = workspace:GetAttribute("PrismoraSpawnPoint") or root.Position
	local teleportPass = 0
	local teleportTotal = 0
	local worstRecovery = 0
	for _, y in { -300, -50, -2 } do
		for _ = 1, 3 do
			teleportTotal += 1
			character:PivotTo(CFrame.new(spawn.X, y, spawn.Z))
			root.AssemblyLinearVelocity = Vector3.zero
			local passed, elapsed = waitForSafeCharacter(root, humanoid, 2)
			worstRecovery = math.max(worstRecovery, elapsed)
			if passed then teleportPass += 1 end
		end
	end

	local knockbackPass = 0
	local knockbackTotal = 16
	for index = 1, knockbackTotal do
		local angle = ((index - 1) / knockbackTotal) * math.pi * 2
		character:PivotTo(CFrame.new(spawn + Vector3.new(0, 4, 0)))
		root.AssemblyLinearVelocity = Vector3.new(math.cos(angle) * 200, 60, math.sin(angle) * 200)
		local passed, elapsed = waitForSafeCharacter(root, humanoid, 2)
		worstRecovery = math.max(worstRecovery, elapsed)
		if passed then knockbackPass += 1 end
	end

	print(string.format(
		"PRISMORA_CHARACTER_AUDIT teleport=%d/%d knockback=%d/%d worstRecovery=%.2fs",
		teleportPass,
		teleportTotal,
		knockbackPass,
		knockbackTotal,
		worstRecovery
	))
	if teleportPass ~= teleportTotal or knockbackPass ~= knockbackTotal then
		warn("PRISMORA_GATE1_FAIL character_recovery")
	else
		print("PRISMORA_GATE1_CHARACTER_PASS")
	end
end

local function watchPlayer(player)
	player.CharacterAdded:Connect(function(character)
		task.spawn(runCharacterProbes, player, character)
	end)
	if player.Character then
		task.spawn(runCharacterProbes, player, player.Character)
	end
end

Players.PlayerAdded:Connect(watchPlayer)
for _, player in Players:GetPlayers() do
	watchPlayer(player)
end
