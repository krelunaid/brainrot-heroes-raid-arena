local InsertService = game:GetService("InsertService")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ASSETS = {
	{ name = "Island", id = 89621275204493, collidable = false },
	{ name = "Castle", id = 129541222713048, collidable = false },
	{ name = "Cottage", id = 78727486552489, collidable = false },
	{ name = "Vegetation", id = 90302038650932, collidable = false },
	{ name = "Decorations", id = 123657820780419, collidable = false },
}

local WORLD_ORIGIN = CFrame.new(0, 58, 0)
local WORLD_SCALE = 3.2
local FALL_RECOVERY_Y = 24
local WORLD_EDGE_LIMIT = 390

-- The original Blender island becomes the central castle district. Four cloned
-- landmasses turn it into an explorable archipelago without making the castle,
-- trees and cottage comically large compared with the player.
local DISTRICTS = {
	{ name = "Sunreach", displayName = "REGNO SOLARE", purpose = "FORGIA E BOSS", offset = Vector3.new(155, -3, 4), scale = 1.22, rotation = 14, color = Color3.fromRGB(255, 199, 92) },
	{ name = "MoonGarden", displayName = "GIARDINO LUNARE", purpose = "EROI E MISTERI", offset = Vector3.new(-150, -4, -8), scale = 1.18, rotation = -18, color = Color3.fromRGB(184, 119, 255) },
	{ name = "Skyport", displayName = "PORTO CELESTE", purpose = "SHUTTLE E CORSE", offset = Vector3.new(4, -5, -132), scale = 1.10, rotation = 176, color = Color3.fromRGB(95, 224, 255) },
	{ name = "HeroArena", displayName = "ARENA DEGLI EROI", purpose = "ONDATE E RAID", offset = Vector3.new(12, -3, 145), scale = 1.30, rotation = -8, color = Color3.fromRGB(255, 103, 190) },
}

local function addPostProcessing()
	for _, child in Lighting:GetChildren() do
		if child:GetAttribute("PrismoraEffect") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "PrismoraAtmosphere"
	Lighting.Brightness = 1.8
	Lighting.ExposureCompensation = -0.34
	Lighting.ClockTime = 16.15
	Lighting.Ambient = Color3.fromRGB(82, 84, 105)
	Lighting.OutdoorAmbient = Color3.fromRGB(128, 142, 166)
	Lighting.EnvironmentDiffuseScale = 0.38
	Lighting.EnvironmentSpecularScale = 0.58

	atmosphere.Density = 0.18
	atmosphere.Offset = 0.12
	atmosphere.Color = Color3.fromRGB(210, 226, 247)
	atmosphere.Decay = Color3.fromRGB(137, 153, 190)
	atmosphere.Glare = 0.04
	atmosphere.Haze = 0.72
	atmosphere:SetAttribute("PrismoraEffect", true)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PrismoraBloom"
	bloom.Intensity = 0.24
	bloom.Size = 18
	bloom.Threshold = 1.72
	bloom:SetAttribute("PrismoraEffect", true)
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "PrismoraColor"
	color.Brightness = -0.035
	color.Contrast = 0.13
	color.Saturation = 0.07
	color.TintColor = Color3.fromRGB(250, 249, 255)
	color:SetAttribute("PrismoraEffect", true)
	color.Parent = Lighting

end

local function configureParts(container, canCollide)
	for _, item in container:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = canCollide
			item.CanTouch = false
			-- Imported meshes are visual only. Gameplay always uses thick Roblox
			-- primitives so mesh collision fidelity can never swallow a player.
			item.CanQuery = canCollide
			item.CastShadow = true
		end
	end
end

local function addFallbackIsland(world)
	local base = Instance.new("Part")
	base.Name = "FallbackIsland"
	base.Anchored = true
	base.Size = Vector3.new(430, 8, 350)
	base.CFrame = WORLD_ORIGIN
	base.Material = Enum.Material.Grass
	base.Color = Color3.fromRGB(88, 128, 62)
	base.Parent = world

	local rock = Instance.new("Part")
	rock.Name = "FallbackRock"
	rock.Anchored = true
	rock.Size = Vector3.new(410, 22, 330)
	rock.CFrame = WORLD_ORIGIN * CFrame.new(0, -14, 0)
	rock.Material = Enum.Material.Slate
	rock.Color = Color3.fromRGB(87, 57, 46)
	rock.Parent = world
end

local function createCheckpoint(parent, position, accentColor, name)
	local checkpoint = Instance.new("Part")
	checkpoint.Name = name .. "Checkpoint"
	checkpoint.Anchored = true
	checkpoint.CanCollide = false
	checkpoint.CanTouch = true
	checkpoint.Material = Enum.Material.Neon
	checkpoint.Color = accentColor
	-- Technical checkpoint trigger: never expose collision/debug geometry to players.
	checkpoint.Transparency = 1
	checkpoint.Size = Vector3.new(1.4, 4, 1.4)
	checkpoint.CFrame = CFrame.new(position + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(45))
	checkpoint.Parent = parent

	checkpoint.Touched:Connect(function(hit)
		local character = hit:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			player:SetAttribute("PrismoraCheckpoint", position + Vector3.new(0, 4, 0))
		end
	end)
end

local function createWalkSurface(parent, island, name, accentColor)
	local boundsCFrame, boundsSize = island:GetBoundingBox()
	local topY = boundsCFrame.Position.Y + (boundsSize.Y * 0.5)
	local sizeX = math.clamp(boundsSize.X * 0.9, 86, 176)
	local sizeZ = math.clamp(boundsSize.Z * 0.9, 80, 164)
	local center = Vector3.new(boundsCFrame.Position.X, topY - 1.25, boundsCFrame.Position.Z)

	local surface = Instance.new("Part")
	surface.Name = name .. "PlayableSurface"
	surface.Anchored = true
	surface.CanCollide = true
	surface.CanTouch = false
	surface.Transparency = 1
	surface.Size = Vector3.new(sizeX, 4, sizeZ)
	surface.CFrame = CFrame.new(center)
	surface.Parent = parent

	local surfaceTop = center.Y + (surface.Size.Y * 0.5)
	local playableCenter = Vector3.new(center.X, surfaceTop, center.Z)
	createCheckpoint(parent, playableCenter + Vector3.new(0, 1, 0), accentColor, name)
	return { center = playableCenter, size = Vector2.new(sizeX, sizeZ), topY = surfaceTop }
end

local function createBridge(parent, fromData, toData, accentColor)
	local flatDelta = Vector3.new(toData.center.X - fromData.center.X, 0, toData.center.Z - fromData.center.Z)
	local direction = flatDelta.Unit
	local fromRadius = math.min(fromData.size.X, fromData.size.Y) * 0.36
	local toRadius = math.min(toData.size.X, toData.size.Y) * 0.36
	-- The deck top sits only half a stud above each island surface. The old
	-- three-stud lip looked like a bridge but stopped a Humanoid at the landing.
	local startPoint = fromData.center + (direction * fromRadius) + Vector3.new(0, -1.2, 0)
	local endPoint = toData.center - (direction * toRadius) + Vector3.new(0, -1.2, 0)
	local length = (endPoint - startPoint).Magnitude
	local segmentCount = math.max(2, math.ceil(length / 36))

	for index = 1, segmentCount do
		local alpha0 = (index - 1) / segmentCount
		local alpha1 = index / segmentCount
		local a = startPoint:Lerp(endPoint, alpha0)
		local b = startPoint:Lerp(endPoint, alpha1)
		local midpoint = (a + b) * 0.5
		local segmentLength = (b - a).Magnitude + 1.2
		local bridgeCFrame = CFrame.lookAt(midpoint, b)

		local deck = Instance.new("Part")
		deck.Name = "CrystalBridgeDeck"
		deck.Anchored = true
		deck.CanCollide = true
		deck.Material = Enum.Material.Cobblestone
		deck.Color = Color3.fromRGB(232, 205, 164)
		deck.Size = Vector3.new(24, 3.5, segmentLength)
		deck.CFrame = bridgeCFrame
		deck.Parent = parent

		for side = -1, 1, 2 do
			local rail = Instance.new("Part")
			rail.Name = "BridgeGlowRail"
			rail.Anchored = true
			rail.CanCollide = false
			rail.Material = Enum.Material.Neon
			rail.Color = accentColor
			-- A thin edge light marks the route without looking like a solid cyan wall.
			rail.Transparency = 0.58
			rail.Size = Vector3.new(0.28, 0.42, segmentLength)
			rail.CFrame = bridgeCFrame * CFrame.new(side * 11.35, 1.82, 0)
			rail.Parent = parent

			local barrier = Instance.new("Part")
			barrier.Name = "BridgeSafetyBarrier"
			barrier.Anchored = true
			barrier.CanCollide = true
			barrier.Transparency = 1
			barrier.Size = Vector3.new(1.5, 18, segmentLength)
			barrier.CFrame = bridgeCFrame * CFrame.new(side * 11.7, 9.5, 0)
			barrier.Parent = parent
		end
	end

	for _, endpoint in { startPoint, endPoint } do
		local landing = Instance.new("Part")
		landing.Name = "BridgeLanding"
		landing.Anchored = true
		landing.CanCollide = true
		landing.Material = Enum.Material.Cobblestone
		landing.Color = Color3.fromRGB(232, 205, 164)
		landing.Size = Vector3.new(28, 3.5, 24)
		landing.CFrame = CFrame.new(endpoint)
		landing.Parent = parent
	end
end

local function sideToward(fromPosition, toPosition)
	local delta = toPosition - fromPosition
	if math.abs(delta.X) > math.abs(delta.Z) then
		return delta.X >= 0 and "East" or "West"
	end
	return delta.Z >= 0 and "South" or "North"
end

local function createSafetyPerimeter(parent, data, openSides, accentColor)
	local gap = 30
	-- High enough to stop a full dash/knockback arc, not only a walking player.
	local height = 22
	local function addSection(name, size, position)
		local barrier = Instance.new("Part")
		barrier.Name = name .. "SafetyBarrier"
		barrier.Anchored = true
		barrier.CanCollide = true
		barrier.CanTouch = false
		barrier.CanQuery = false
		barrier.Material = Enum.Material.Glass
		barrier.Color = accentColor
		barrier.Transparency = 1
		barrier.Size = size
		barrier.CFrame = CFrame.new(position)
		barrier.Parent = parent

		local rail = Instance.new("Part")
		rail.Name = name .. "SafetyGlow"
		rail.Anchored = true
		rail.CanCollide = false
		rail.CanTouch = false
		rail.CanQuery = false
		rail.Material = Enum.Material.Neon
		rail.Color = accentColor
		rail.Transparency = 1
		rail.Size = Vector3.new(size.X, 0.32, size.Z)
		rail.CFrame = CFrame.new(position + Vector3.new(0, (height * 0.5) - 0.18, 0))
		rail.Parent = parent
	end

	for _, side in {
		{ name = "North", length = data.size.X, edge = Vector3.new(0, 0, -data.size.Y * 0.5), alongX = true },
		{ name = "South", length = data.size.X, edge = Vector3.new(0, 0, data.size.Y * 0.5), alongX = true },
		{ name = "East", length = data.size.Y, edge = Vector3.new(data.size.X * 0.5, 0, 0), alongX = false },
		{ name = "West", length = data.size.Y, edge = Vector3.new(-data.size.X * 0.5, 0, 0), alongX = false },
	} do
		local sectionLength = side.length
		local centers = { 0 }
		if openSides[side.name] then
			sectionLength = math.max(4, (side.length - gap) * 0.5)
			local offset = (gap * 0.5) + (sectionLength * 0.5)
			centers = { -offset, offset }
		end
		for index, centerOffset in centers do
			local lateral = side.alongX and Vector3.new(centerOffset, 0, 0) or Vector3.new(0, 0, centerOffset)
			local size = side.alongX and Vector3.new(sectionLength, height, 1.5) or Vector3.new(1.5, height, sectionLength)
			local position = data.center + side.edge + lateral + Vector3.new(0, height * 0.5, 0)
			addSection(side.name .. index, size, position)
		end
	end
end

local function createDistrictBeacon(parent, district, position)
	local beacon = Instance.new("Part")
	beacon.Name = district.name .. "Beacon"
	beacon.Anchored = true
	beacon.CanCollide = false
	beacon.Material = Enum.Material.Neon
	beacon.Color = district.color
	beacon.Size = Vector3.new(4, 18, 4)
	beacon.CFrame = CFrame.new(position + Vector3.new(0, 16, 0)) * CFrame.Angles(0, 0, math.rad(45))
	beacon.Parent = parent

	local light = Instance.new("PointLight")
	light.Color = district.color
	light.Brightness = 0.85
	light.Range = 19
	light.Parent = beacon

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DistrictLabel"
	billboard.Size = UDim2.fromOffset(150, 34)
	billboard.StudsOffset = Vector3.new(0, 13, 0)
	billboard.AlwaysOnTop = false
	billboard.MaxDistance = 52
	billboard.Parent = beacon

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(19, 24, 44)
	label.BackgroundTransparency = 0.16
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = district.displayName or string.upper(district.name)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = label
end

local function createRealmGate(parent, capitalData, districtData, district)
	local delta = Vector3.new(districtData.center.X - capitalData.center.X, 0, districtData.center.Z - capitalData.center.Z)
	local direction = delta.Unit
	local gatePosition = capitalData.center + direction * (math.min(capitalData.size.X, capitalData.size.Y) * 0.35)
	local gateCFrame = CFrame.lookAt(gatePosition, gatePosition + direction)

	for side = -1, 1, 2 do
		local pillar = Instance.new("Part")
		pillar.Name = district.name .. "GatePillar"
		pillar.Anchored = true
		pillar.CanCollide = true
		pillar.Material = Enum.Material.Marble
		pillar.Color = Color3.fromRGB(218, 221, 235)
		pillar.Size = Vector3.new(2.6, 13, 2.6)
		pillar.CFrame = gateCFrame * CFrame.new(side * 10.2, 6.5, 0)
		pillar.Parent = parent

		local rune = Instance.new("Part")
		rune.Name = district.name .. "GateRune"
		rune.Anchored = true
		rune.CanCollide = false
		rune.Material = Enum.Material.Neon
		rune.Color = district.color
		rune.Transparency = 0.22
		rune.Size = Vector3.new(0.32, 9.2, 2.85)
		rune.CFrame = gateCFrame * CFrame.new(side * 10.2, 6.6, -1.34)
		rune.Parent = parent
	end

	local crown = Instance.new("Part")
	crown.Name = district.name .. "GateCrown"
	crown.Anchored = true
	crown.CanCollide = false
	crown.Material = Enum.Material.Marble
	crown.Color = Color3.fromRGB(218, 221, 235)
	crown.Size = Vector3.new(23, 2.4, 2.8)
	crown.CFrame = gateCFrame * CFrame.new(0, 12.2, 0)
	crown.Parent = parent

	local sign = Instance.new("BillboardGui")
	sign.Name = district.name .. "RealmSign"
	sign.AlwaysOnTop = false
	sign.MaxDistance = 46
	sign.Size = UDim2.fromOffset(220, 50)
	sign.StudsOffset = Vector3.new(0, 3.5, 0)
	sign.Parent = crown

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(14, 18, 34)
	label.BackgroundTransparency = 0.08
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = string.format("%s\n%s", district.displayName, district.purpose)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = sign
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = label
end

local function createCapitalIdentity(parent, capitalData)
	local anchor = Instance.new("Part")
	anchor.Name = "PrismoraCapitalIdentity"
	anchor.Anchored = true
	anchor.CanCollide = false
	anchor.CanQuery = false
	anchor.Transparency = 1
	anchor.Size = Vector3.one
	anchor.CFrame = CFrame.new(capitalData.center + Vector3.new(0, 12, 18))
	anchor.Parent = parent

	local title = Instance.new("BillboardGui")
	title.Name = "CapitalTitle"
	title.AlwaysOnTop = false
	title.MaxDistance = 62
	title.Size = UDim2.fromOffset(270, 58)
	title.Parent = anchor
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(12, 17, 34)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = "CAPITALE PRISMORA\nIL CUORE DELL'IMPERO"
	label.TextColor3 = Color3.fromRGB(235, 255, 252)
	label.TextScaled = true
	label.Parent = title
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = label
end

local function createArchipelago(world)
	local centralIsland = world:FindFirstChild("PrismoraIsland")
	if not centralIsland or not centralIsland:IsA("Model") then
		return
	end

	local basePivot = centralIsland:GetPivot()
	local districtFolder = Instance.new("Folder")
	districtFolder.Name = "PrismoraDistricts"
	districtFolder.Parent = world

	local centralData = createWalkSurface(world, centralIsland, "PrismaHub", Color3.fromRGB(118, 255, 235))
	createCapitalIdentity(world, centralData)
	workspace:SetAttribute("PrismoraSpawnPoint", centralData.center + Vector3.new(0, 3, 24))
	workspace:SetAttribute("PrismoraCombatCenter", centralData.center + Vector3.new(0, 2, -28))
	workspace:SetAttribute("PrismoraCombatHalfSizeX", math.max(32, (centralData.size.X * 0.5) - 8))
	workspace:SetAttribute("PrismoraCombatHalfSizeZ", math.max(32, (centralData.size.Y * 0.5) - 8))

	local centralOpenings = {}
	local districtPerimeters = {}
	for _, district in DISTRICTS do
		local island = centralIsland:Clone()
		island.Name = district.name .. "Island"
		island:ScaleTo(island:GetScale() * district.scale)
		local destination = basePivot.Position + district.offset
		island:PivotTo(CFrame.new(destination) * CFrame.Angles(0, math.rad(district.rotation), 0))
		island.Parent = districtFolder

		local districtData = createWalkSurface(districtFolder, island, district.name, district.color)
		createBridge(districtFolder, centralData, districtData, district.color)
		createRealmGate(districtFolder, centralData, districtData, district)
		centralOpenings[sideToward(centralData.center, districtData.center)] = true
		table.insert(districtPerimeters, {
			data = districtData,
			openings = { [sideToward(districtData.center, centralData.center)] = true },
			color = district.color,
		})
		createDistrictBeacon(districtFolder, district, districtData.center + Vector3.new(0, 2, 0))
		workspace:SetAttribute("Prismora" .. district.name .. "Center", districtData.center + Vector3.new(0, 2, 0))
	end
	-- Keep the outside edges safe while leaving every real bridge entrance open.
	-- Closing the whole perimeter made the visible bridge impossible to enter.
	createSafetyPerimeter(world, centralData, centralOpenings, Color3.fromRGB(118, 255, 235))
	for _, perimeter in districtPerimeters do
		createSafetyPerimeter(districtFolder, perimeter.data, perimeter.openings, perimeter.color)
	end
end

addPostProcessing()

local oldWorld = workspace:FindFirstChild("PrismoraWorld")
if oldWorld then
	oldWorld:Destroy()
end

local world = Instance.new("Model")
world.Name = "PrismoraWorld"
world.Parent = workspace

local loadedCount = 0
for _, asset in ASSETS do
	local ok, result = pcall(function()
		return InsertService:LoadAsset(asset.id)
	end)

	if ok and result then
		result.Name = "Prismora" .. asset.name
		configureParts(result, asset.collidable)
		result.Parent = world
		loadedCount += 1
	else
		warn(string.format("Prismora asset %s failed to load: %s", asset.name, tostring(result)))
	end
end

if loadedCount == 0 then
	addFallbackIsland(world)
else
	world:ScaleTo(WORLD_SCALE)
	world:PivotTo(WORLD_ORIGIN)
	createArchipelago(world)
end

-- Start on the wide south bridge instead of raycasting against the imported
-- island mesh. Its collision hull can report a point inside the floating rock.
-- This fixed point is open, safe, and immediately shows the larger world.
local spawnPosition = workspace:GetAttribute("PrismoraSpawnPoint") or Vector3.new(0, 70, 0)
local fallRecoveryHeight = math.max(FALL_RECOVERY_Y, spawnPosition.Y - 22)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "PrismoraSpawn"
spawn.Anchored = true
spawn.CanCollide = false
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = Color3.fromRGB(118, 255, 235)
spawn.Transparency = 1
spawn.Size = Vector3.new(8, 1, 8)
local lookAt = workspace:GetAttribute("PrismoraCombatCenter") or (spawnPosition + Vector3.new(0, 0, -20))
spawn.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(lookAt.X, spawnPosition.Y, lookAt.Z))
spawn.Parent = workspace

local glow = Instance.new("PointLight")
glow.Color = spawn.Color
glow.Brightness = 0
glow.Range = 0
glow.Parent = spawn

-- Touched events can be skipped when a fast character tunnels through a thin
-- part. Polling also recovers a player before Roblox destroys the character.
local lastSafeCFrame = {}
local unsupportedSince = {}
local recoveryRayParams = RaycastParams.new()
recoveryRayParams.FilterType = Enum.RaycastFilterType.Include
recoveryRayParams.FilterDescendantsInstances = { world }

local function safeGroundBelow(root)
	local result = workspace:Raycast(root.Position + Vector3.new(0, 2, 0), Vector3.new(0, -40, 0), recoveryRayParams)
	if not result then
		return nil
	end
	local name = result.Instance.Name
	if not string.find(name, "PlayableSurface", 1, true)
		and name ~= "CrystalBridgeDeck"
		and name ~= "BridgeLanding" then
		return nil
	end
	return result.Position
end

local function recoveryCFrame(player)
	if lastSafeCFrame[player] then
		return lastSafeCFrame[player]
	end
	local checkpoint = player:GetAttribute("PrismoraCheckpoint")
	if typeof(checkpoint) == "Vector3" then
		return CFrame.new(checkpoint + Vector3.new(0, 3, 0))
	end
	return CFrame.new(spawnPosition + Vector3.new(0, 3, 0))
end

Players.PlayerRemoving:Connect(function(player)
	lastSafeCFrame[player] = nil
	unsupportedSince[player] = nil
end)

task.spawn(function()
	while world.Parent do
		for _, player in Players:GetPlayers() do
			local character = player.Character
			local humanoid = character and character:FindFirstChildOfClass("Humanoid")
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if humanoid and root and humanoid.Health > 0 then
				local position = root.Position
				local outside = math.abs(position.X) > WORLD_EDGE_LIMIT or math.abs(position.Z) > WORLD_EDGE_LIMIT
				if position.Y < fallRecoveryHeight or outside then
					character:PivotTo(recoveryCFrame(player))
					root.AssemblyLinearVelocity = Vector3.zero
					root.AssemblyAngularVelocity = Vector3.zero
					humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
					unsupportedSince[player] = nil
				elseif humanoid.FloorMaterial ~= Enum.Material.Air and math.abs(root.AssemblyLinearVelocity.Y) < 12 then
					local groundPosition = safeGroundBelow(root)
					local look = root.CFrame.LookVector
					local flatLook = Vector3.new(look.X, 0, look.Z)
					if flatLook.Magnitude < 0.1 then flatLook = Vector3.new(0, 0, -1) end
					if groundPosition then
						local safePosition = groundPosition + Vector3.new(0, 4, 0)
						lastSafeCFrame[player] = CFrame.lookAt(safePosition, safePosition + flatLook.Unit)
					end
					unsupportedSince[player] = nil
				elseif humanoid.FloorMaterial == Enum.Material.Air then
					if safeGroundBelow(root) then
						unsupportedSince[player] = nil
					else
						unsupportedSince[player] = unsupportedSince[player] or os.clock()
					end
					if unsupportedSince[player] and os.clock() - unsupportedSince[player] >= 0.65 then
						character:PivotTo(recoveryCFrame(player))
						root.AssemblyLinearVelocity = Vector3.zero
						root.AssemblyAngularVelocity = Vector3.zero
						humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
						unsupportedSince[player] = nil
					end
				else
					unsupportedSince[player] = nil
				end
			end
		end
		task.wait(0.2)
	end
end)

local remote = ReplicatedStorage:FindFirstChild("PrismoraEvent") or Instance.new("RemoteEvent")
remote.Name = "PrismoraEvent"
remote.Parent = ReplicatedStorage

workspace:SetAttribute("PrismoraLoadedAssets", loadedCount)
workspace:SetAttribute("PrismoraWorldSpan", 450)
workspace:SetAttribute("PrismoraReady", true)
remote:FireAllClients("WorldReady", loadedCount)

print(string.format("PRISMORA_READY assets=%d spawn=%s", loadedCount, tostring(spawnPosition)))
