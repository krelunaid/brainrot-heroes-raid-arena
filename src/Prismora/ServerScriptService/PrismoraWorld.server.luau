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

-- The original Blender island becomes the central castle district. Four cloned
-- landmasses turn it into an explorable archipelago without making the castle,
-- trees and cottage comically large compared with the player.
local DISTRICTS = {
	{ name = "Sunreach", offset = Vector3.new(155, -3, 4), scale = 1.22, rotation = 14, color = Color3.fromRGB(255, 199, 92) },
	{ name = "MoonGarden", offset = Vector3.new(-150, -4, -8), scale = 1.18, rotation = -18, color = Color3.fromRGB(184, 119, 255) },
	{ name = "Skyport", offset = Vector3.new(4, -5, -132), scale = 1.10, rotation = 176, color = Color3.fromRGB(95, 224, 255) },
	{ name = "HeroArena", offset = Vector3.new(12, -3, 145), scale = 1.30, rotation = -8, color = Color3.fromRGB(255, 103, 190) },
}

local function addPostProcessing()
	for _, child in Lighting:GetChildren() do
		if child:GetAttribute("PrismoraEffect") then
			child:Destroy()
		end
	end

	local atmosphere = Instance.new("Atmosphere")
	atmosphere.Name = "PrismoraAtmosphere"
	atmosphere.Density = 0.28
	atmosphere.Offset = 0.22
	atmosphere.Color = Color3.fromRGB(200, 225, 255)
	atmosphere.Decay = Color3.fromRGB(120, 145, 190)
	atmosphere.Glare = 0.15
	atmosphere.Haze = 1.8
	atmosphere:SetAttribute("PrismoraEffect", true)
	atmosphere.Parent = Lighting

	local bloom = Instance.new("BloomEffect")
	bloom.Name = "PrismoraBloom"
	bloom.Intensity = 0.7
	bloom.Size = 22
	bloom.Threshold = 1.05
	bloom:SetAttribute("PrismoraEffect", true)
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "PrismoraColor"
	color.Brightness = 0.01
	color.Contrast = 0.06
	color.Saturation = 0.12
	color.TintColor = Color3.fromRGB(255, 252, 246)
	color:SetAttribute("PrismoraEffect", true)
	color.Parent = Lighting

end

local function configureParts(container, canCollide)
	for _, item in container:GetDescendants() do
		if item:IsA("BasePart") then
			item.Anchored = true
			item.CanCollide = canCollide
			item.CanTouch = false
			item.CanQuery = true
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
	checkpoint.Transparency = 0.38
	checkpoint.Size = Vector3.new(3, 8, 3)
	checkpoint.CFrame = CFrame.new(position + Vector3.new(0, 4, 0)) * CFrame.Angles(0, 0, math.rad(45))
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
	local sizeX = math.clamp(boundsSize.X * 0.68, 72, 128)
	local sizeZ = math.clamp(boundsSize.Z * 0.68, 64, 118)
	local center = Vector3.new(boundsCFrame.Position.X, topY + 0.45, boundsCFrame.Position.Z)

	local surface = Instance.new("Part")
	surface.Name = name .. "PlayableSurface"
	surface.Anchored = true
	surface.CanCollide = true
	surface.CanTouch = false
	surface.Transparency = 1
	surface.Size = Vector3.new(sizeX, 1, sizeZ)
	surface.CFrame = CFrame.new(center)
	surface.Parent = parent

	createCheckpoint(parent, center + Vector3.new(0, 1, 0), accentColor, name)
	return { center = center, size = Vector2.new(sizeX, sizeZ), topY = center.Y }
end

local function createBridge(parent, fromData, toData, accentColor)
	local flatDelta = Vector3.new(toData.center.X - fromData.center.X, 0, toData.center.Z - fromData.center.Z)
	local direction = flatDelta.Unit
	local fromRadius = math.min(fromData.size.X, fromData.size.Y) * 0.36
	local toRadius = math.min(toData.size.X, toData.size.Y) * 0.36
	local startPoint = fromData.center + (direction * fromRadius) + Vector3.new(0, 1.3, 0)
	local endPoint = toData.center - (direction * toRadius) + Vector3.new(0, 1.3, 0)
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
		deck.Size = Vector3.new(24, 2.2, segmentLength)
		deck.CFrame = bridgeCFrame
		deck.Parent = parent

		for side = -1, 1, 2 do
			local rail = Instance.new("Part")
			rail.Name = "BridgeGlowRail"
			rail.Anchored = true
			rail.CanCollide = false
			rail.Material = Enum.Material.Neon
			rail.Color = accentColor
			rail.Transparency = 0.12
			rail.Size = Vector3.new(0.55, 1.25, segmentLength)
			rail.CFrame = bridgeCFrame * CFrame.new(side * 11.1, 2.0, 0)
			rail.Parent = parent

			local barrier = Instance.new("Part")
			barrier.Name = "BridgeSafetyBarrier"
			barrier.Anchored = true
			barrier.CanCollide = true
			barrier.Transparency = 1
			barrier.Size = Vector3.new(1, 9, segmentLength)
			barrier.CFrame = bridgeCFrame * CFrame.new(side * 11.7, 5.0, 0)
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
		landing.Size = Vector3.new(28, 2.2, 24)
		landing.CFrame = CFrame.new(endpoint)
		landing.Parent = parent
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
	light.Brightness = 2.2
	light.Range = 34
	light.Parent = beacon

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DistrictLabel"
	billboard.Size = UDim2.fromOffset(250, 54)
	billboard.StudsOffset = Vector3.new(0, 13, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 260
	billboard.Parent = beacon

	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = Color3.fromRGB(19, 24, 44)
	label.BackgroundTransparency = 0.16
	label.BorderSizePixel = 0
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = string.upper(district.name)
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
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
	workspace:SetAttribute("PrismoraSpawnPoint", centralData.center + Vector3.new(0, 3, 0))
	workspace:SetAttribute("PrismoraCombatCenter", centralData.center + Vector3.new(0, 2, -20))

	for _, district in DISTRICTS do
		local island = centralIsland:Clone()
		island.Name = district.name .. "Island"
		island:ScaleTo(island:GetScale() * district.scale)
		local destination = basePivot.Position + district.offset
		island:PivotTo(CFrame.new(destination) * CFrame.Angles(0, math.rad(district.rotation), 0))
		island.Parent = districtFolder

		local districtData = createWalkSurface(districtFolder, island, district.name, district.color)
		createBridge(districtFolder, centralData, districtData, district.color)
		createDistrictBeacon(districtFolder, district, districtData.center + Vector3.new(0, 2, 0))
		workspace:SetAttribute("Prismora" .. district.name .. "Center", districtData.center + Vector3.new(0, 2, 0))
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

local rescue = Instance.new("Part")
rescue.Name = "PrismoraRescueField"
rescue.Anchored = true
rescue.CanCollide = false
rescue.CanTouch = true
rescue.Transparency = 1
rescue.Size = Vector3.new(720, 3, 650)
rescue.CFrame = CFrame.new(0, 8, 0)
rescue.Parent = world

local rescueDebounce = {}
rescue.Touched:Connect(function(hit)
	local character = hit:FindFirstAncestorOfClass("Model")
	local player = character and Players:GetPlayerFromCharacter(character)
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not player or not root or rescueDebounce[player] then
		return
	end
	rescueDebounce[player] = true
	local checkpoint = player:GetAttribute("PrismoraCheckpoint") or workspace:GetAttribute("PrismoraSpawnPoint")
	root.AssemblyLinearVelocity = Vector3.zero
	root.CFrame = CFrame.new(checkpoint + Vector3.new(0, 3, 0))
	task.delay(1, function()
		rescueDebounce[player] = nil
	end)
end)

-- Start on the wide south bridge instead of raycasting against the imported
-- island mesh. Its collision hull can report a point inside the floating rock.
-- This fixed point is open, safe, and immediately shows the larger world.
local spawnPosition = workspace:GetAttribute("PrismoraSpawnPoint") or Vector3.new(0, 70, 0)

local spawn = Instance.new("SpawnLocation")
spawn.Name = "PrismoraSpawn"
spawn.Anchored = true
spawn.CanCollide = true
spawn.Neutral = true
spawn.Material = Enum.Material.Neon
spawn.Color = Color3.fromRGB(118, 255, 235)
spawn.Transparency = 0.28
spawn.Size = Vector3.new(8, 1, 8)
local lookAt = workspace:GetAttribute("PrismoraCombatCenter") or (spawnPosition + Vector3.new(0, 0, -20))
spawn.CFrame = CFrame.lookAt(spawnPosition, Vector3.new(lookAt.X, spawnPosition.Y, lookAt.Z))
spawn.Parent = workspace

local glow = Instance.new("PointLight")
glow.Color = spawn.Color
glow.Brightness = 1.4
glow.Range = 18
glow.Parent = spawn

local remote = ReplicatedStorage:FindFirstChild("PrismoraEvent") or Instance.new("RemoteEvent")
remote.Name = "PrismoraEvent"
remote.Parent = ReplicatedStorage

workspace:SetAttribute("PrismoraLoadedAssets", loadedCount)
workspace:SetAttribute("PrismoraWorldSpan", 450)
workspace:SetAttribute("PrismoraReady", true)
remote:FireAllClients("WorldReady", loadedCount)

print(string.format("PRISMORA_READY assets=%d spawn=%s", loadedCount, tostring(spawnPosition)))
