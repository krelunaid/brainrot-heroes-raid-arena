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

local CAPITAL_ASSET_ID = 135905587438926
local CAPITAL_VISUAL_SCALE = 188 / 144
local CAPITAL_PATH_TOP = 1.65 * CAPITAL_VISUAL_SCALE

local WORLD_ORIGIN = CFrame.new(0, 58, 0)
local WORLD_SCALE = 3.2
local FALL_RECOVERY_Y = 24
local WORLD_EDGE_LIMIT = 520

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
	Lighting.Brightness = 2.5
	Lighting.ExposureCompensation = 0.25
	Lighting.ClockTime = 14.2
	Lighting.GeographicLatitude = 20
	Lighting.Ambient = Color3.fromRGB(75, 78, 92)
	Lighting.OutdoorAmbient = Color3.fromRGB(125, 128, 145)
	Lighting.EnvironmentDiffuseScale = 0.6
	Lighting.EnvironmentSpecularScale = 0.3

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
	bloom.Intensity = 0.25
	bloom.Size = 22
	bloom.Threshold = 1.2
	bloom:SetAttribute("PrismoraEffect", true)
	bloom.Parent = Lighting

	local color = Instance.new("ColorCorrectionEffect")
	color.Name = "PrismoraColor"
	color.Brightness = 0.01
	color.Contrast = 0.06
	color.Saturation = 0.07
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

local PALETTE = {
	cream = Color3.fromRGB(255, 246, 229),
	stone = Color3.fromRGB(232, 201, 138),
	darkStone = Color3.fromRGB(201, 154, 91),
	slate = Color3.fromRGB(74, 70, 88),
	gold = Color3.fromRGB(255, 201, 74),
	cyan = Color3.fromRGB(70, 224, 255),
	magenta = Color3.fromRGB(255, 95, 162),
}

local function makeEmpirePart(parent, name, size, cframe, color, material, collidable, transparency, shape)
	local part = Instance.new("Part")
	part.Name = name
	part.Anchored = true
	part.CanCollide = collidable == true
	part.CanTouch = false
	part.CanQuery = collidable == true
	part.CastShadow = material ~= Enum.Material.Neon
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Shape = shape or Enum.PartType.Block
	part.Parent = parent
	return part
end

local function makeVerticalCylinder(parent, name, position, diameter, height, color, material, collidable)
	return makeEmpirePart(
		parent,
		name,
		Vector3.new(height, diameter, diameter),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		material,
		collidable,
		0,
		Enum.PartType.Cylinder
	)
end

local function createInvisibleRoom(parent, center, width, depth, height, prefix)
	local thickness = 8
	for _, wall in {
		{ "North", Vector3.new(width + thickness * 2, height, thickness), Vector3.new(0, height * 0.5, -(depth * 0.5 + thickness * 0.5)) },
		{ "South", Vector3.new(width + thickness * 2, height, thickness), Vector3.new(0, height * 0.5, depth * 0.5 + thickness * 0.5) },
		{ "East", Vector3.new(thickness, height, depth), Vector3.new(width * 0.5 + thickness * 0.5, height * 0.5, 0) },
		{ "West", Vector3.new(thickness, height, depth), Vector3.new(-(width * 0.5 + thickness * 0.5), height * 0.5, 0) },
	} do
		local barrier = makeEmpirePart(parent, prefix .. wall[1] .. "SafetyBarrier", wall[2], CFrame.new(center + wall[3]), PALETTE.cyan, Enum.Material.SmoothPlastic, true, 1)
		barrier.CanQuery = false
	end
	local ceiling = makeEmpirePart(parent, prefix .. "SafetyCeiling", Vector3.new(width + 20, 4, depth + 20), CFrame.new(center + Vector3.new(0, height + 2, 0)), PALETTE.cyan, Enum.Material.SmoothPlastic, true, 1)
	ceiling.CanQuery = false
end

local function createHeroStatue(parent, position, color, powered, yaw)
	local model = Instance.new("Model")
	model.Name = powered and "AwakenedHeroStatue" or "DormantHeroStatue"
	model.Parent = parent
	local baseCFrame = CFrame.new(position) * CFrame.Angles(0, math.rad(yaw or 0), 0)
	local statueColor = powered and color or Color3.fromRGB(107, 100, 120)
	makeEmpirePart(model, "Pedestal", Vector3.new(7.5, 3, 7.5), baseCFrame * CFrame.new(0, 1.5, 0), PALETTE.darkStone, Enum.Material.Slate, false)
	local torso = makeEmpirePart(model, "HeroTorso", Vector3.new(5.5, 7, 3.4), baseCFrame * CFrame.new(0, 7.7, 0), statueColor, Enum.Material.SmoothPlastic, false)
	makeEmpirePart(model, "HeroHead", Vector3.new(3.2, 3.2, 3.2), baseCFrame * CFrame.new(0, 13, 0), statueColor, Enum.Material.SmoothPlastic, false, 0, Enum.PartType.Ball)
	for side = -1, 1, 2 do
		makeEmpirePart(model, "HeroArm", Vector3.new(2.1, 7.2, 2.1), baseCFrame * CFrame.new(side * 4, 7.4, 0) * CFrame.Angles(0, 0, math.rad(side * 12)), statueColor, Enum.Material.SmoothPlastic, false)
		makeEmpirePart(model, "HeroLeg", Vector3.new(2.2, 5.8, 2.4), baseCFrame * CFrame.new(side * 1.65, 3.1, 0), statueColor, Enum.Material.SmoothPlastic, false)
	end
	local crest = makeEmpirePart(model, "HeroCrest", Vector3.new(1.1, 5.8, 1.1), baseCFrame * CFrame.new(0, 16.3, 0) * CFrame.Angles(0, 0, math.rad(45)), statueColor, powered and Enum.Material.Neon or Enum.Material.Slate, false)
	if powered then
		local light = Instance.new("PointLight")
		light.Color = color
		light.Brightness = 1.2
		light.Range = 18
		light.Shadows = false
		light.Parent = torso
	end
	return model
end

local function createPortal(parent, name, position, lookAt, color, destination, titleText)
	local model = Instance.new("Model")
	model.Name = name .. "Portal"
	model.Parent = parent
	local frame = CFrame.lookAt(position, Vector3.new(lookAt.X, position.Y, lookAt.Z))
	for side = -1, 1, 2 do
		makeEmpirePart(model, "PortalPillar", Vector3.new(3.5, 22, 4.5), frame * CFrame.new(side * 9.5, 11, 0), PALETTE.stone, Enum.Material.SmoothPlastic, true)
		makeEmpirePart(model, "PortalRune", Vector3.new(0.5, 15, 4.8), frame * CFrame.new(side * 9.5, 11, -2.35), color, Enum.Material.Neon, false, 0.08)
	end
	makeEmpirePart(model, "PortalCrown", Vector3.new(22.5, 4, 4.8), frame * CFrame.new(0, 22, 0), PALETTE.stone, Enum.Material.SmoothPlastic, true)
	local pane = makeEmpirePart(model, "PortalEnergy", Vector3.new(15.5, 18, 0.8), frame * CFrame.new(0, 10, 0), color, Enum.Material.Glass, false, 0.28)
	pane.CanTouch = destination ~= nil
	local core = makeEmpirePart(model, "PortalCore", Vector3.new(12.5, 15, 0.32), frame * CFrame.new(0, 10, -0.52), color, Enum.Material.Neon, false, 0.42)
	core.CanTouch = false

	local gui = Instance.new("BillboardGui")
	gui.Name = "PortalLabel"
	gui.Size = UDim2.fromOffset(180, 36)
	gui.StudsOffset = Vector3.new(0, 16.5, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 65
	gui.Parent = pane
	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(18, 22, 38)
	label.BackgroundTransparency = 0.1
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBlack
	label.Text = titleText
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextScaled = true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = label

	if destination then
		local debounce = {}
		pane.Touched:Connect(function(hit)
			local character = hit:FindFirstAncestorOfClass("Model")
			local player = character and Players:GetPlayerFromCharacter(character)
			local root = character and character:FindFirstChild("HumanoidRootPart")
			if not player or not root or debounce[player] then return end
			debounce[player] = true
			character:PivotTo(destination)
			root.AssemblyLinearVelocity = Vector3.zero
			root.AssemblyAngularVelocity = Vector3.zero
			player:SetAttribute("PrismoraCheckpoint", destination.Position)
			task.delay(1, function() debounce[player] = nil end)
		end)
	end
	return model
end

local function createLighthouse(parent, center)
	for _, tier in {
		{ 28, 0, 18, PALETTE.darkStone },
		{ 22, 3, 15, PALETTE.stone },
		{ 16, 7, 58, PALETTE.cream },
		{ 22, 60, 6, PALETTE.stone },
	} do
		makeVerticalCylinder(parent, "LighthouseTier", center + Vector3.new(0, tier[2] + tier[3] * 0.5, 0), tier[1], tier[3], tier[4], Enum.Material.SmoothPlastic, tier[2] <= 7)
	end
	makeEmpirePart(parent, "LighthouseCore", Vector3.new(4.2, 52, 4.2), CFrame.new(center + Vector3.new(0, 34, 0)) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.cyan, Enum.Material.Neon, false, 0.04)
	makeEmpirePart(parent, "LighthousePrism", Vector3.new(12, 12, 12), CFrame.new(center + Vector3.new(0, 75, 0)) * CFrame.Angles(math.rad(25), math.rad(45), math.rad(25)), PALETTE.cyan, Enum.Material.Glass, false, 0.16)
end

local function createImperialTree(parent, position, scale)
	scale = scale or 1
	makeEmpirePart(parent, "ImperialTreeTrunk", Vector3.new(2.2, 10, 2.2) * scale, CFrame.new(position + Vector3.new(0, 5 * scale, 0)), Color3.fromRGB(147, 105, 72), Enum.Material.Wood, false)
	for _, offset in {
		Vector3.new(0, 10, 0), Vector3.new(-2.4, 9, 0.5), Vector3.new(2.2, 9.5, -0.4),
	} do
		makeEmpirePart(parent, "ImperialTreeCanopy", Vector3.new(7.5, 7.5, 7.5) * scale, CFrame.new(position + offset * scale), Color3.fromRGB(66, 153, 91), Enum.Material.SmoothPlastic, false, 0, Enum.PartType.Ball)
	end
end

local function createCapital(parent, center)
	local capital = Instance.new("Model")
	capital.Name = "PrismoraCapital"
	capital.Parent = parent
	makeVerticalCylinder(capital, "CapitalVisualFloor", center - Vector3.new(0, 4, 0), 200, 8, PALETTE.cream, Enum.Material.SmoothPlastic, false)
	makeEmpirePart(capital, "CapitalPlayableSurface", Vector3.new(184, 8, 184), CFrame.new(center - Vector3.new(0, CAPITAL_PATH_TOP + 4, 0)), PALETTE.cream, Enum.Material.SmoothPlastic, true, 1)
	-- Collision follows the authored Blender elevations: a low plaza plus four
	-- slightly raised radial avenues. One giant flat collider made players float
	-- whenever they left a raised avenue.
	makeVerticalCylinder(
		capital,
		"CapitalInnerPlayableSurface",
		center + Vector3.new(0, (0.25 - 1.65) * CAPITAL_VISUAL_SCALE, 0),
		116 * CAPITAL_VISUAL_SCALE,
		0.65 * CAPITAL_VISUAL_SCALE,
		PALETTE.cream,
		Enum.Material.SmoothPlastic,
		true
	)
	for _, angle in { 0, math.pi * 0.5, math.pi, math.pi * 1.5 } do
		local px = math.cos(angle) * 35 * CAPITAL_VISUAL_SCALE
		local pz = math.sin(angle) * 35 * CAPITAL_VISUAL_SCALE
		makeEmpirePart(
			capital,
			"CapitalPathPlayableSurface",
			Vector3.new(20 * CAPITAL_VISUAL_SCALE, 1.3 * CAPITAL_VISUAL_SCALE, 60 * CAPITAL_VISUAL_SCALE),
			CFrame.new(center + Vector3.new(px, -(1.3 * CAPITAL_VISUAL_SCALE) * 0.5, pz)) * CFrame.Angles(0, -angle, 0),
			PALETTE.cream,
			Enum.Material.SmoothPlastic,
			true,
			1
		)
	end
	makeVerticalCylinder(capital, "CapitalRockUnderside", center - Vector3.new(0, 15, 0), 194, 22, PALETTE.slate, Enum.Material.Slate, false)
	makeVerticalCylinder(capital, "AwakeningAltarVisual", center + Vector3.new(0, 1, 0), 36, 3, PALETTE.stone, Enum.Material.SmoothPlastic, false)
	makeEmpirePart(capital, "AwakeningAltarPlayableSurface", Vector3.new(28, 3, 28), CFrame.new(center + Vector3.new(0, 1, 0)), PALETTE.stone, Enum.Material.SmoothPlastic, true, 1)
	createLighthouse(capital, center + Vector3.new(0, 2.5, 0))

	-- Two elevated galleries create the hero silhouette from the spawn view.
	for side = -1, 1, 2 do
		local galleryCenter = center + Vector3.new(side * 52, 25, -8)
		makeEmpirePart(capital, "GalleryPlayableSurface", Vector3.new(76, 5, 21), CFrame.new(galleryCenter), PALETTE.stone, Enum.Material.SmoothPlastic, true)
		makeEmpirePart(capital, "GalleryRock", Vector3.new(70, 10, 17), CFrame.new(galleryCenter - Vector3.new(0, 7, 0)), PALETTE.slate, Enum.Material.Slate, false)
		for index = 1, 3 do
			local x = galleryCenter.X + ((index - 2) * 20)
			local powered = side == -1 or index == 2
			local statueColor = index == 1 and PALETTE.cyan or (index == 2 and PALETTE.magenta or PALETTE.gold)
			createHeroStatue(capital, Vector3.new(x, galleryCenter.Y + 2.6, galleryCenter.Z), statueColor, powered, side == -1 and -18 or 18)
		end
	end

	local arenaEntry = center + Vector3.new(0, 4, -330) + Vector3.new(-70, 0, -65)
	createPortal(capital, "Sunreach", center + Vector3.new(0, 0, -72), center, PALETTE.gold, CFrame.lookAt(arenaEntry, arenaEntry + Vector3.new(1, 0, 1)), "SUNREACH • COMBATTI")
	createPortal(capital, "MoonGarden", center + Vector3.new(72, 0, 0), center, PALETTE.magenta, nil, "MOONGARDEN")
	createPortal(capital, "Skyport", center + Vector3.new(0, 0, 82), center, PALETTE.cyan, nil, "SKYPORT")
	createPortal(capital, "HeroArena", center + Vector3.new(-72, 0, 0), center, Color3.fromRGB(176, 118, 255), nil, "HERO ARENA")

	-- Dense, functional-looking props in the otherwise empty radial ring.
	for _, prop in {
		{ Vector3.new(-34, 3, 38), PALETTE.cyan },
		{ Vector3.new(34, 3, 38), PALETTE.gold },
		{ Vector3.new(-40, 3, -38), PALETTE.magenta },
		{ Vector3.new(40, 3, -38), PALETTE.cyan },
	} do
		makeEmpirePart(capital, "ImperialKiosk", Vector3.new(12, 6, 8), CFrame.new(center + prop[1]) * CFrame.Angles(0, math.rad(12), 0), PALETTE.darkStone, Enum.Material.Wood, true)
		makeEmpirePart(capital, "InteractiveMarker", Vector3.new(2.2, 5.2, 2.2), CFrame.new(center + prop[1] + Vector3.new(0, 5.6, 0)) * CFrame.Angles(0, 0, math.rad(45)), prop[2], Enum.Material.Neon, false, 0.08)
	end
	for index = 1, 10 do
		local angle = math.rad(16 + index * 34)
		local radius = index % 2 == 0 and 82 or 76
		createImperialTree(capital, center + Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius), 0.82 + (index % 3) * 0.08)
	end
	createInvisibleRoom(capital, center, 200, 200, 90, "Capital")
	return capital
end

local function loadCapitalVisual(parent, capitalCenter)
	local ok, asset = pcall(function()
		return InsertService:LoadAsset(CAPITAL_ASSET_ID)
	end)
	if not ok or not asset then
		warn(string.format("Prismora capital asset failed to load: %s", tostring(asset)))
		return false
	end

	asset.Name = "PrismoraCapitalBlender"
	configureParts(asset, false)
	asset.Parent = parent
	local _, sourceSize = asset:GetBoundingBox()
	local widest = math.max(sourceSize.X, sourceSize.Z)
	if widest > 0 then
		asset:ScaleTo(188 / widest)
	end
	local visualCFrame, visualSize = asset:GetBoundingBox()
	local tilePart = asset:FindFirstChild("Empire_WarmTile", true)
	-- Roblox rebuilds the joined FBX pivot, so use the validated traversal plane
	-- within WarmTile's imported bounds. The separate colliders above reproduce
	-- the authored height changes rather than flattening the entire capital.
	local floorY = if tilePart and tilePart:IsA("BasePart")
		then (tilePart.Position.Y - tilePart.Size.Y * 0.5) + tilePart.Size.Y * 0.64
		else visualCFrame.Position.Y - visualSize.Y * 0.24
	local horizontalDelta = Vector3.new(capitalCenter.X - visualCFrame.Position.X, 0, capitalCenter.Z - visualCFrame.Position.Z)
	-- floorY is the imported WarmTile reference plane. The authored radial walks
	-- sit CAPITAL_PATH_TOP above the platform datum used by the gameplay world.
	-- Lowering the visual by that exact authored offset makes visible stone and
	-- invisible traversal colliders agree; otherwise avatars appear half buried.
	asset:PivotTo(asset:GetPivot() + horizontalDelta + Vector3.new(0, capitalCenter.Y - floorY - CAPITAL_PATH_TOP, 0))

	local lightCount = 0
	for _, item in asset:GetDescendants() do
		if item:IsA("BasePart") then
			local lowerName = string.lower(item.Name)
			if string.find(lowerName, "cyanenergy", 1, true) or string.find(lowerName, "prismglass", 1, true) then
				item.Material = Enum.Material.Glass
				item.Color = Color3.fromRGB(55, 176, 215)
				item.Transparency = 0.42
				item.Reflectance = 0.04
				item.CastShadow = false
			elseif string.find(lowerName, "magentaenergy", 1, true) then
				item.Material = Enum.Material.Glass
				item.Color = Color3.fromRGB(205, 70, 146)
				item.Transparency = 0.4
				item.Reflectance = 0.04
				item.CastShadow = false
			elseif string.find(lowerName, "purpleenergy", 1, true) then
				item.Material = Enum.Material.Glass
				item.Color = Color3.fromRGB(129, 80, 199)
				item.Transparency = 0.4
				item.Reflectance = 0.04
				item.CastShadow = false
			elseif string.find(lowerName, "goldenergy", 1, true) then
				item.Material = Enum.Material.Glass
				item.Color = Color3.fromRGB(198, 132, 36)
				item.Transparency = 0.58
				item.Reflectance = 0.05
				item.CastShadow = false
			elseif string.find(lowerName, "imperialgold", 1, true) then
				item.Material = Enum.Material.Metal
				item.Color = Color3.fromRGB(238, 160, 53)
			elseif string.find(lowerName, "warmtile", 1, true) then
				item.Material = Enum.Material.Cobblestone
				item.Color = Color3.fromRGB(235, 207, 163)
			elseif string.find(lowerName, "creamstone", 1, true) then
				item.Material = Enum.Material.Limestone
				item.Color = Color3.fromRGB(219, 199, 164)
			elseif string.find(lowerName, "palestone", 1, true) then
				item.Material = Enum.Material.Marble
				item.Color = Color3.fromRGB(157, 169, 190)
			elseif string.find(lowerName, "darkstone", 1, true) then
				item.Material = Enum.Material.Slate
				item.Color = Color3.fromRGB(43, 55, 79)
			elseif string.find(lowerName, "floatingrock", 1, true) then
				item.Material = Enum.Material.Slate
				item.Color = Color3.fromRGB(76, 52, 56)
			elseif string.find(lowerName, "herostone", 1, true) then
				item.Material = Enum.Material.Metal
				item.Color = Color3.fromRGB(74, 91, 126)
			elseif string.find(lowerName, "warmwood", 1, true) then
				item.Material = Enum.Material.Wood
				item.Color = Color3.fromRGB(115, 67, 37)
			elseif string.find(lowerName, "emeraldleaves", 1, true) then
				item.Material = Enum.Material.Grass
				item.Color = Color3.fromRGB(54, 153, 92)
			elseif string.find(lowerName, "deepleaves", 1, true) then
				item.Material = Enum.Material.Grass
				item.Color = Color3.fromRGB(27, 97, 73)
			end
			if item.Material == Enum.Material.Neon and lightCount < 1 then
				lightCount += 1
				local light = Instance.new("PointLight")
				light.Color = item.Color
				light.Brightness = 0.35
				light.Range = 12
				light.Shadows = false
				light.Parent = item
			end
		end
	end

	-- Keep the procedural capital solely as invisible collision, portal triggers
	-- and fall recovery. Blender owns every visible architectural surface.
	local proceduralCapital = parent:FindFirstChild("PrismoraCapital")
	if proceduralCapital then
		for _, item in proceduralCapital:GetDescendants() do
			if item:IsA("BasePart") then
				item.Transparency = 1
				item.CastShadow = false
				local keepCollision = string.find(item.Name, "PlayableSurface", 1, true) ~= nil or string.find(item.Name, "SafetyBarrier", 1, true) ~= nil
				item.CanCollide = keepCollision
			end
		end
	end
	print(string.format("PRISMORA_CAPITAL_ASSET_READY asset=%d size=%.1f,%.1f,%.1f", CAPITAL_ASSET_ID, visualSize.X, visualSize.Y, visualSize.Z))
	return true
end

local function createSunreachArena(parent, center, capitalCenter)
	local arena = Instance.new("Model")
	arena.Name = "SunreachArena"
	arena.Parent = parent
	makeEmpirePart(arena, "ArenaPlayableSurface", Vector3.new(200, 8, 200), CFrame.new(center - Vector3.new(0, 4, 0)), PALETTE.stone, Enum.Material.SmoothPlastic, true)
	makeEmpirePart(arena, "ArenaRockUnderside", Vector3.new(194, 24, 194), CFrame.new(center - Vector3.new(0, 19, 0)), PALETTE.slate, Enum.Material.Slate, false)

	-- The far corner rises toward the boss altar; wide ramps remain easy on mobile.
	makeEmpirePart(arena, "SunreachTerracePlayableSurface", Vector3.new(72, 12, 72), CFrame.new(center + Vector3.new(55, 6, 55)), PALETTE.cream, Enum.Material.SmoothPlastic, true)
	makeEmpirePart(arena, "SunreachRamp", Vector3.new(26, 5, 46), CFrame.new(center + Vector3.new(18, 5.5, 35)) * CFrame.Angles(math.rad(-14), 0, 0), PALETTE.cream, Enum.Material.SmoothPlastic, true)
	makeVerticalCylinder(arena, "BossAltarVisual", center + Vector3.new(76, 14, 76), 38, 5, PALETTE.darkStone, Enum.Material.Slate, true)
	for _, pylon in {
		Vector3.new(32, 14, 58), Vector3.new(58, 14, 32), Vector3.new(58, 14, 58),
	} do
		makeEmpirePart(arena, "SunreachPylon", Vector3.new(4, 13, 4), CFrame.new(center + pylon), PALETTE.darkStone, Enum.Material.Slate, true)
		makeEmpirePart(arena, "PylonCore", Vector3.new(1.6, 8, 1.6), CFrame.new(center + pylon + Vector3.new(0, 2, 0)) * CFrame.Angles(0, 0, math.rad(45)), PALETTE.cyan, Enum.Material.Neon, false, 0.06)
	end
	for index = 1, 14 do
		local angle = (index / 14) * math.pi * 2
		local radius = index % 2 == 0 and 72 or 88
		local rock = makeEmpirePart(arena, "SunreachRuin", Vector3.new(5 + index % 4, 7 + index % 8, 5 + index % 3), CFrame.new(center + Vector3.new(math.cos(angle) * radius, 3, math.sin(angle) * radius)) * CFrame.Angles(0, angle + 0.2, math.rad((index % 3) - 1) * 0.08), index % 3 == 0 and PALETTE.darkStone or PALETTE.stone, Enum.Material.Slate, true)
		rock.CastShadow = index % 2 == 0
	end

	local returnPosition = capitalCenter + Vector3.new(0, 4, 32)
	createPortal(arena, "ReturnCapital", center + Vector3.new(-72, 0, -72), center, PALETTE.cyan, CFrame.lookAt(returnPosition, capitalCenter), "TORNA ALLA CAPITALE")
	createInvisibleRoom(arena, center, 200, 200, 60, "Arena")
	return arena
end

local function createEmpirePrototype(world)
	local centralIsland = world:FindFirstChild("PrismoraIsland")
	local capitalCenter = centralIsland and centralIsland:IsA("Model") and (select(1, centralIsland:GetBoundingBox())).Position or WORLD_ORIGIN.Position
	if centralIsland and centralIsland:IsA("Model") then
		local _, boundsSize = centralIsland:GetBoundingBox()
		capitalCenter = Vector3.new(capitalCenter.X, capitalCenter.Y + (boundsSize.Y * 0.5), capitalCenter.Z)
	else
		capitalCenter = WORLD_ORIGIN.Position + Vector3.new(0, 4, 0)
	end
	-- The original castle/cottage clusters were authored for the small island and
	-- blocked the deliberate spawn composition. Keep the island underside, but
	-- replace those overlapping props with the new lighthouse, portals and trees.
	for _, visualName in { "PrismoraCastle", "PrismoraCottage", "PrismoraVegetation", "PrismoraDecorations" } do
		local visual = world:FindFirstChild(visualName)
		if visual then visual:Destroy() end
	end
	local arenaCenter = capitalCenter + Vector3.new(0, 0, -330)
	createCapital(world, capitalCenter)
	local capitalLoaded = loadCapitalVisual(world, capitalCenter)
	if capitalLoaded and centralIsland then
		centralIsland:Destroy()
	end
	createSunreachArena(world, arenaCenter, capitalCenter)
	workspace:SetAttribute("PrismoraSpawnPoint", capitalCenter + Vector3.new(0, 4, 50))
	workspace:SetAttribute("PrismoraSpawnLookAt", capitalCenter + Vector3.new(0, 18, -24))
	workspace:SetAttribute("PrismoraCapitalCenter", capitalCenter)
	workspace:SetAttribute("PrismoraArenaCenter", arenaCenter)
	workspace:SetAttribute("PrismoraCombatCenter", arenaCenter + Vector3.new(0, 2, 0))
	workspace:SetAttribute("PrismoraCombatHalfSizeX", 88)
	workspace:SetAttribute("PrismoraCombatHalfSizeZ", 88)
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
	createEmpirePrototype(world)
else
	world:ScaleTo(WORLD_SCALE)
	world:PivotTo(WORLD_ORIGIN)
	createEmpirePrototype(world)
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
local lookAt = workspace:GetAttribute("PrismoraSpawnLookAt") or (spawnPosition + Vector3.new(0, 0, -20))
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
	if not string.find(name, "PlayableSurface", 1, true) then
		return nil
	end
	return result.Position
end

local function recoveryCFrame(player)
	local checkpoint = player:GetAttribute("PrismoraCheckpoint")
	if typeof(checkpoint) == "Vector3" then
		return CFrame.new(checkpoint + Vector3.new(0, 3, 0))
	end
	if lastSafeCFrame[player] then
		return lastSafeCFrame[player]
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
workspace:SetAttribute("PrismoraWorldSpan", 700)
workspace:SetAttribute("PrismoraReady", true)
remote:FireAllClients("WorldReady", loadedCount)

print(string.format("PRISMORA_READY assets=%d spawn=%s", loadedCount, tostring(spawnPosition)))
