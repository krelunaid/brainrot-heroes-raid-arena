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
	local isVerticalCylinder = surface.Shape == Enum.PartType.Cylinder
	local expectedY = surface.Position.Y + ((if isVerticalCylinder then surface.Size.X else surface.Size.Y) * 0.5)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { surface }
	local sampleWidth = if isVerticalCylinder then surface.Size.Y else surface.Size.X
	local sampleDepth = surface.Size.Z
	for x = -sampleWidth * 0.48, sampleWidth * 0.48, 4 do
		for z = -sampleDepth * 0.48, sampleDepth * 0.48, 4 do
			-- A cylinder's bounding box has empty corners by design. They are not
			-- floor holes, so only audit points inside its circular footprint.
			if isVerticalCylinder and ((x / (sampleWidth * 0.5)) ^ 2 + (z / (sampleDepth * 0.5)) ^ 2) > 0.92 then
				continue
			end
			samples += 1
			local origin = if isVerticalCylinder
				then Vector3.new(surface.Position.X + x, expectedY + 18, surface.Position.Z + z)
				else surface.CFrame:PointToWorldSpace(Vector3.new(x, 18, z))
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

local bridgeDecks = 0
local bridgeBlockers = {}
local perimeterBarriers = {}
for _, item in world:GetDescendants() do
	if item:IsA("BasePart") and string.find(item.Name, "SafetyBarrier", 1, true) and item.Name ~= "BridgeSafetyBarrier" then
		table.insert(perimeterBarriers, item)
	end
end
for _, item in world:GetDescendants() do
	if item:IsA("BasePart") and item.Name == "CrystalBridgeDeck" then
		bridgeDecks += 1
		-- CanQuery is deliberately false on invisible barriers, so spatial queries
		-- cannot audit them. Sample the playable bridge centreline directly in
		-- every barrier's local space instead.
		for sampleIndex = -5, 5 do
			local corridorPoint = item.CFrame:PointToWorldSpace(Vector3.new(0, 4, (item.Size.Z * 0.45) * (sampleIndex / 5)))
			for _, barrier in perimeterBarriers do
				local localPoint = barrier.CFrame:PointToObjectSpace(corridorPoint)
				local half = barrier.Size * 0.5
				if math.abs(localPoint.X) <= half.X and math.abs(localPoint.Y) <= half.Y and math.abs(localPoint.Z) <= half.Z then
					bridgeBlockers[barrier:GetFullName()] = true
				end
			end
		end
	end
end

local bridgeBlockerCount = 0
for _ in bridgeBlockers do bridgeBlockerCount += 1 end

print(string.format(
	"PRISMORA_COLLISION_AUDIT surfaces=%d samples=%d holes=%d maxDeviation=%.3f visibleCyan=%d bridgeDecks=%d bridgeBlockers=%d",
	#surfaces,
	samples,
	holes,
	maxDeviation,
	#visibleCyan,
	bridgeDecks,
	bridgeBlockerCount
))
if #visibleCyan > 0 then
	warn("PRISMORA_VISIBLE_CYAN " .. table.concat(visibleCyan, " | "))
end
if bridgeBlockerCount > 0 then
	local blockerNames = {}
	for name in bridgeBlockers do table.insert(blockerNames, name) end
	warn("PRISMORA_BRIDGE_BLOCKED " .. table.concat(blockerNames, " | "))
end

-- Gate 1 character probes are opt-in. They deliberately teleport and launch the
-- character, so running them during a normal playtest looks like a gameplay bug.
if workspace:GetAttribute("PrismoraRunCharacterAudit") ~= true then
	print("PRISMORA_CHARACTER_AUDIT skipped=normal_playtest")
	return
end

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
