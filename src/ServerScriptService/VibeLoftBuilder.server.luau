--!strict

-- Vibe Loft: a bright, social pre-raid penthouse inspired by the approved Grok Build concept.
-- It is deliberately made from lightweight primitives so it remains smooth on phones.

local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local arena = workspace:WaitForChild("BrainrotHeroesRaidArena")
local oldLobby = workspace:FindFirstChild("VibeLoftLobby")
if oldLobby then
	oldLobby:Destroy()
end

local LOFT_ORIGIN = Vector3.new(-250, 0, 28)
local RAID_ENTRY = Vector3.new(0, 8, 67)
local LOFT_SPAWN = LOFT_ORIGIN + Vector3.new(0, 4, 49)

local COLORS = {
	ink = Color3.fromRGB(23, 25, 44),
	panel = Color3.fromRGB(43, 46, 70),
	soft = Color3.fromRGB(224, 229, 242),
	white = Color3.fromRGB(250, 252, 255),
	cyan = Color3.fromRGB(35, 235, 255),
	pink = Color3.fromRGB(255, 62, 176),
	purple = Color3.fromRGB(143, 77, 255),
	gold = Color3.fromRGB(255, 205, 78),
	green = Color3.fromRGB(80, 255, 166),
	water = Color3.fromRGB(56, 201, 255),
}

local lobby = Instance.new("Model")
lobby.Name = "VibeLoftLobby"
lobby:SetAttribute("PartBudget", 420)
lobby:SetAttribute("Purpose", "Social pre-raid lobby")
lobby.Parent = workspace

local architecture = Instance.new("Folder")
architecture.Name = "Architecture"
architecture.Parent = lobby
local zones = Instance.new("Folder")
zones.Name = "Zones"
zones.Parent = lobby
local effects = Instance.new("Folder")
effects.Name = "Effects"
effects.Parent = lobby
local gameplay = Instance.new("Folder")
gameplay.Name = "Gameplay"
gameplay.Parent = lobby

local function part(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material,
	transparency: number?,
	shape: Enum.PartType?
): Part
	local object = Instance.new("Part")
	object.Name = name
	object.Anchored = true
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.Transparency = transparency or 0
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	object.CastShadow = material ~= Enum.Material.Neon and transparency ~= 1
	if shape then
		object.Shape = shape
	end
	object.Parent = parent
	return object
end

local function light(parent: Instance, color: Color3, brightness: number, range: number)
	local point = Instance.new("PointLight")
	point.Color = color
	point.Brightness = brightness
	point.Range = range
	point.Shadows = false
	point.Parent = parent
	return point
end

local function billboard(parent: BasePart, titleText: string, subtitleText: string, accent: Color3, width: number?)
	local gui = Instance.new("BillboardGui")
	gui.Name = "ZoneLabel"
	gui.Size = UDim2.fromOffset(width or 270, 70)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 4.2, 0)
	gui.AlwaysOnTop = false
	gui.MaxDistance = 130
	gui.LightInfluence = 0
	gui.Parent = parent

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = COLORS.ink
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 18)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = accent
	stroke.Thickness = 3
	stroke.Transparency = 0.08
	stroke.Parent = frame

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromScale(0.04, 0.08)
	title.Size = UDim2.fromScale(0.92, 0.48)
	title.Font = Enum.Font.GothamBlack
	title.Text = titleText
	title.TextColor3 = COLORS.white
	title.TextScaled = true
	title.Parent = frame
	local subtitle = Instance.new("TextLabel")
	subtitle.BackgroundTransparency = 1
	subtitle.Position = UDim2.fromScale(0.05, 0.59)
	subtitle.Size = UDim2.fromScale(0.9, 0.23)
	subtitle.Font = Enum.Font.GothamBold
	subtitle.Text = subtitleText
	subtitle.TextColor3 = accent
	subtitle.TextScaled = true
	subtitle.Parent = frame
	return gui
end

local function zoneAnchor(name: string, offset: Vector3, titleText: string, subtitleText: string, accent: Color3)
	local anchor = part(zones, name, Vector3.new(1, 1, 1), CFrame.new(LOFT_ORIGIN + offset), accent, Enum.Material.Neon, 1)
	anchor.CanCollide = false
	anchor.CanQuery = false
	billboard(anchor, titleText, subtitleText, accent)
	return anchor
end

local function sofa(parent: Instance, center: Vector3, color: Color3, yaw: number)
	local cf = CFrame.new(center) * CFrame.Angles(0, math.rad(yaw), 0)
	part(parent, "SofaSeat", Vector3.new(12, 2.1, 4.5), cf, color, Enum.Material.Fabric)
	part(parent, "SofaBack", Vector3.new(12, 4.3, 1.4), cf * CFrame.new(0, 2.7, 1.7), color, Enum.Material.Fabric)
	part(parent, "SofaArm", Vector3.new(1.2, 3.2, 4.8), cf * CFrame.new(-6.1, 1, 0), COLORS.panel, Enum.Material.SmoothPlastic)
	part(parent, "SofaArm", Vector3.new(1.2, 3.2, 4.8), cf * CFrame.new(6.1, 1, 0), COLORS.panel, Enum.Material.SmoothPlastic)
end

-- Bright shell: pale floor and glass keep the neon readable instead of turning the room black.
part(architecture, "LoftFloor", Vector3.new(156, 1.2, 118), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 0, 0)), COLORS.soft, Enum.Material.Marble)
part(architecture, "LeftWall", Vector3.new(2, 30, 118), CFrame.new(LOFT_ORIGIN + Vector3.new(-78, 15, 0)), COLORS.panel, Enum.Material.Concrete)
part(architecture, "RightWall", Vector3.new(2, 30, 118), CFrame.new(LOFT_ORIGIN + Vector3.new(78, 15, 0)), COLORS.panel, Enum.Material.Concrete)
part(architecture, "FrontWallLeft", Vector3.new(60, 30, 2), CFrame.new(LOFT_ORIGIN + Vector3.new(-48, 15, 59)), COLORS.panel, Enum.Material.Concrete)
part(architecture, "FrontWallRight", Vector3.new(60, 30, 2), CFrame.new(LOFT_ORIGIN + Vector3.new(48, 15, 59)), COLORS.panel, Enum.Material.Concrete)
part(architecture, "BackGlass", Vector3.new(154, 28, 1), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 15, -59)), Color3.fromRGB(144, 217, 255), Enum.Material.Glass, 0.58)
part(architecture, "CeilingFrame", Vector3.new(156, 1.2, 5), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 30, 0)), COLORS.panel, Enum.Material.Metal)

for x = -70, 70, 14 do
	part(architecture, "GlassMullion", Vector3.new(0.55, 28, 1.5), CFrame.new(LOFT_ORIGIN + Vector3.new(x, 15, -58.7)), COLORS.cyan, Enum.Material.Neon, 0.14)
end
for x = -68, 68, 17 do
	local rail = part(architecture, "CeilingLight", Vector3.new(11, 0.35, 1), CFrame.new(LOFT_ORIGIN + Vector3.new(x, 29.2, 8)), COLORS.white, Enum.Material.Neon, 0.05)
	light(rail, COLORS.white, 0.7, 22)
end

-- Low-part skyline outside the glass gives the penthouse its screenshot silhouette.
local towerHeights = { 26, 38, 19, 46, 31, 54, 23, 41, 29, 49, 34, 21, 44, 27, 37 }
for index, height in towerHeights do
	local x = -105 + (index - 1) * 15
	local z = -84 - ((index % 3) * 12)
	local tower = part(architecture, "CityTower", Vector3.new(11, height, 10), CFrame.new(LOFT_ORIGIN + Vector3.new(x, height / 2 - 1, z)), Color3.fromRGB(42, 52, 83), Enum.Material.SmoothPlastic)
	local crownColor = if index % 2 == 0 then COLORS.pink else COLORS.cyan
	part(architecture, "TowerCrown", Vector3.new(8, 0.8, 8), tower.CFrame * CFrame.new(0, height / 2 + 1, 0), crownColor, Enum.Material.Neon, 0.12)
end

-- Spawn Hall and a three-step tutorial visible immediately on phone.
local spawnZone = zoneAnchor("SpawnHall", Vector3.new(0, 3, 48), "VIBE LOFT", "SPAWN • SOCIAL • RAID", COLORS.cyan)
part(zones, "SpawnCarpet", Vector3.new(42, 0.35, 18), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 0.8, 47)), Color3.fromRGB(55, 59, 91), Enum.Material.Fabric)
for side = -1, 1, 2 do
	local column = part(zones, "WelcomePillar", Vector3.new(2.2, 19, 2.2), CFrame.new(LOFT_ORIGIN + Vector3.new(side * 20, 10, 49)), if side < 0 then COLORS.pink else COLORS.cyan, Enum.Material.Neon, 0.06)
	light(column, column.Color, 1.1, 26)
end

local tutorialTexts = {
	{ "1", "ARMA PRONTA", COLORS.cyan },
	{ "2", "ENTRA NEL RAID", COLORS.purple },
	{ "3", "TOCCA ATTACCA", COLORS.pink },
}
for index, data in tutorialTexts do
	local x = (index - 2) * 14
	local sign = part(zones, "TutorialStep", Vector3.new(11, 6, 0.8), CFrame.new(LOFT_ORIGIN + Vector3.new(x, 4.6, 35)), data[3] :: Color3, Enum.Material.Neon, 0.08)
	billboard(sign, data[1] :: string, data[2] :: string, data[3] :: Color3, 150)
end

-- 8x8 interactive-looking LED floor: large enough for a group, compact enough for mobile.
zoneAnchor("DanceFloor", Vector3.new(0, 3, 12), "PISTA LED", "BALLA MENTRE ASPETTI", COLORS.pink)
local danceTiles: { Part } = {}
for row = 1, 8 do
	for column = 1, 8 do
		local colorIndex = ((row + column) % 3)
		local color = if colorIndex == 0 then COLORS.cyan elseif colorIndex == 1 then COLORS.purple else COLORS.pink
		local tile = part(
			zones,
			"DanceTile",
			Vector3.new(3.55, 0.42, 3.55),
			CFrame.new(LOFT_ORIGIN + Vector3.new((column - 4.5) * 3.8, 0.95, 12 + (row - 4.5) * 3.8)),
			color,
			Enum.Material.Neon,
			0.12
		)
		table.insert(danceTiles, tile)
	end
end

-- DJ booth anchors the far edge of the dance floor without blocking the raid path.
part(zones, "DJBooth", Vector3.new(22, 4.5, 5), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 3, -7)), COLORS.ink, Enum.Material.Metal)
part(zones, "DJGlow", Vector3.new(20, 1.2, 0.5), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 4.5, -4.5)), COLORS.pink, Enum.Material.Neon)
for side = -1, 1, 2 do
	local speaker = part(zones, "Speaker", Vector3.new(5, 9, 4), CFrame.new(LOFT_ORIGIN + Vector3.new(side * 15, 4.9, -7)), COLORS.ink, Enum.Material.Metal)
	for y = -2, 2, 4 do
		part(zones, "SpeakerCone", Vector3.new(1, 3.2, 3.2), speaker.CFrame * CFrame.new(0, y, -2.05) * CFrame.Angles(0, math.rad(90), 0), COLORS.purple, Enum.Material.Neon, 0.08, Enum.PartType.Cylinder)
	end
end

-- Setup Pro: three monitors, racing chair and ring light.
zoneAnchor("SetupPro", Vector3.new(-51, 3, 16), "SETUP PRO", "CREATOR CORNER", COLORS.cyan)
part(zones, "GamingDesk", Vector3.new(33, 1.2, 8), CFrame.new(LOFT_ORIGIN + Vector3.new(-54, 5, 4)), COLORS.ink, Enum.Material.Metal)
for index = -1, 1 do
	local monitor = part(zones, "RGBMonitor", Vector3.new(10, 6, 0.7), CFrame.new(LOFT_ORIGIN + Vector3.new(-54 + index * 10.5, 9.2, 2.5)) * CFrame.Angles(0, math.rad(index * -10), 0), Color3.fromRGB(11, 18, 36), Enum.Material.Glass)
	part(zones, "MonitorGlow", Vector3.new(8.8, 4.8, 0.15), monitor.CFrame * CFrame.new(0, 0, -0.43), if index == 0 then COLORS.cyan elseif index < 0 then COLORS.purple else COLORS.pink, Enum.Material.Neon, 0.12)
end
sofa(zones, LOFT_ORIGIN + Vector3.new(-54, 1.9, 15), Color3.fromRGB(96, 70, 142), 0)
local ringLight = part(zones, "RingLight", Vector3.new(0.6, 8, 8), CFrame.new(LOFT_ORIGIN + Vector3.new(-72, 9, 12)) * CFrame.Angles(0, math.rad(90), 0), COLORS.white, Enum.Material.Neon, 0.06, Enum.PartType.Cylinder)
ringLight.CanCollide = false
light(ringLight, COLORS.white, 1.2, 20)

-- Snack Wall: bright, playful and readable from the center.
zoneAnchor("SnackWall", Vector3.new(52, 3, 18), "SNACK WALL", "PRENDI ENERGIA", COLORS.gold)
part(zones, "SnackCounter", Vector3.new(35, 4.5, 8), CFrame.new(LOFT_ORIGIN + Vector3.new(55, 2.8, 5)), COLORS.white, Enum.Material.SmoothPlastic)
part(zones, "CounterGlow", Vector3.new(33, 0.45, 0.5), CFrame.new(LOFT_ORIGIN + Vector3.new(55, 4.6, 9.1)), COLORS.gold, Enum.Material.Neon)
local fridge = part(zones, "RGBFridge", Vector3.new(9, 15, 6), CFrame.new(LOFT_ORIGIN + Vector3.new(72, 7.8, 19)), COLORS.panel, Enum.Material.Metal)
part(zones, "FridgeGlass", Vector3.new(7.5, 12.5, 0.35), fridge.CFrame * CFrame.new(0, 0, -3.2), Color3.fromRGB(142, 225, 255), Enum.Material.Glass, 0.35)
for index = 1, 7 do
	part(zones, "SnackBottle", Vector3.new(1.2, 2.8, 1.2), CFrame.new(LOFT_ORIGIN + Vector3.new(40 + index * 4, 6.2, 5)), if index % 2 == 0 then COLORS.pink else COLORS.cyan, Enum.Material.Neon, 0.1, Enum.PartType.Cylinder)
end

-- Cinema Pit: screen stays visible but seats are pushed aside from the critical path.
zoneAnchor("CinemaPit", Vector3.new(-52, 3, -29), "CINEMA PIT", "GUARDA IL RAID LIVE", COLORS.purple)
part(zones, "CinemaRug", Vector3.new(44, 0.3, 31), CFrame.new(LOFT_ORIGIN + Vector3.new(-52, 0.8, -34)), Color3.fromRGB(61, 45, 88), Enum.Material.Fabric)
local screen = part(zones, "RaidScreen", Vector3.new(34, 17, 0.8), CFrame.new(LOFT_ORIGIN + Vector3.new(-52, 11, -55)), Color3.fromRGB(11, 16, 36), Enum.Material.Glass)
part(zones, "ScreenImage", Vector3.new(31.5, 14.5, 0.18), screen.CFrame * CFrame.new(0, 0, -0.5), COLORS.purple, Enum.Material.Neon, 0.35)
billboard(screen, "PRISMA REX LIVE", "RAID TRA POCO", COLORS.pink, 250)
sofa(zones, LOFT_ORIGIN + Vector3.new(-52, 2, -31), Color3.fromRGB(104, 66, 145), 180)
sofa(zones, LOFT_ORIGIN + Vector3.new(-52, 2, -18), Color3.fromRGB(50, 133, 158), 180)

-- Pet Pad: three original hologram pets, made without external assets.
zoneAnchor("PetPad", Vector3.new(51, 3, -21), "PET PAD", "FOTO CON GLI HEROES", COLORS.green)
local petColors = { COLORS.cyan, COLORS.pink, COLORS.gold }
for index, petColor in petColors do
	local x = 39 + (index - 1) * 13
	part(zones, "PetPedestal", Vector3.new(1.2, 9, 9), CFrame.new(LOFT_ORIGIN + Vector3.new(x, 1.3, -28)) * CFrame.Angles(0, 0, math.rad(90)), petColor, Enum.Material.Neon, 0.22, Enum.PartType.Cylinder)
	local body = part(zones, "HoloPetBody", Vector3.new(5, 5, 5), CFrame.new(LOFT_ORIGIN + Vector3.new(x, 5.5, -28)), petColor, Enum.Material.Neon, 0.18, Enum.PartType.Ball)
	part(zones, "HoloPetHead", Vector3.new(4.5, 4.5, 4.5), body.CFrame * CFrame.new(0, 3.5, -1), petColor, Enum.Material.Neon, 0.12, Enum.PartType.Ball)
	part(zones, "PetEar", Vector3.new(1.5, 2.5, 1.5), body.CFrame * CFrame.new(-1.6, 5.5, -1), petColor, Enum.Material.Neon, 0.08)
	part(zones, "PetEar", Vector3.new(1.5, 2.5, 1.5), body.CFrame * CFrame.new(1.6, 5.5, -1), petColor, Enum.Material.Neon, 0.08)
end

-- Hidden Vault: a discovery reward and visible weapon promise, not a dead-end corridor.
zoneAnchor("HiddenVault", Vector3.new(-67, 3, -47), "VAULT SEGRETO", "TROVA IL CORE D'ORO", COLORS.gold)
local vaultDoor = part(zones, "VaultDoor", Vector3.new(16, 20, 2), CFrame.new(LOFT_ORIGIN + Vector3.new(-77, 10.5, -46)), COLORS.ink, Enum.Material.DiamondPlate)
part(zones, "VaultRing", Vector3.new(2.2, 12, 12), vaultDoor.CFrame * CFrame.new(0, 0, -1.2) * CFrame.Angles(0, math.rad(90), 0), COLORS.gold, Enum.Material.Neon, 0.08, Enum.PartType.Cylinder)
local treasure = part(zones, "VaultCore", Vector3.new(5.5, 5.5, 5.5), CFrame.new(LOFT_ORIGIN + Vector3.new(-66, 6, -48)) * CFrame.Angles(math.rad(35), math.rad(45), 0), COLORS.gold, Enum.Material.Neon, 0.05)
light(treasure, COLORS.gold, 1.4, 22)

-- Sky Deck: pool and skyline selfie frame.
zoneAnchor("SkyDeck", Vector3.new(54, 3, -47), "SKY DECK", "POOL • CITY • SELFIE", COLORS.cyan)
part(zones, "PoolShell", Vector3.new(43, 1.4, 22), CFrame.new(LOFT_ORIGIN + Vector3.new(54, 0.65, -47)), COLORS.white, Enum.Material.Marble)
local pool = part(zones, "PoolWater", Vector3.new(39, 0.55, 18), CFrame.new(LOFT_ORIGIN + Vector3.new(54, 1.45, -47)), COLORS.water, Enum.Material.Glass, 0.22)
light(pool, COLORS.cyan, 0.7, 18)
for side = -1, 1, 2 do
	part(zones, "SelfiePost", Vector3.new(1, 12, 1), CFrame.new(LOFT_ORIGIN + Vector3.new(54 + side * 18, 7, -57)), if side < 0 then COLORS.pink else COLORS.cyan, Enum.Material.Neon)
end
part(zones, "SelfieTop", Vector3.new(37, 1, 1), CFrame.new(LOFT_ORIGIN + Vector3.new(54, 13, -57)), COLORS.purple, Enum.Material.Neon)

-- Direct navigation: cyan path from spawn, via the dance floor, into a bright raid elevator.
for index = 1, 12 do
	local alpha = index / 13
	local z = 39 + (-70 * alpha)
	local arrow = part(gameplay, "RaidPathArrow", Vector3.new(4.8, 0.25, 2.2), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 1.1, z)), if index % 2 == 0 then COLORS.cyan else COLORS.purple, Enum.Material.Neon, 0.1)
	arrow.CanCollide = false
end

local portalFrame = part(gameplay, "RaidPortalFrame", Vector3.new(24, 19, 3), CFrame.new(LOFT_ORIGIN + Vector3.new(0, 10, -46)), COLORS.ink, Enum.Material.Metal)
local raidPortal = part(gameplay, "RaidPortal", Vector3.new(18, 15, 1.2), portalFrame.CFrame * CFrame.new(0, 0, -1.8), COLORS.cyan, Enum.Material.Neon, 0.12)
raidPortal.CanCollide = false
light(raidPortal, COLORS.cyan, 2.2, 34)
billboard(raidPortal, "ENTRA NEL RAID", "PRISMA REX • ARMA PRONTA", COLORS.pink, 320)

local prompt = Instance.new("ProximityPrompt")
prompt.Name = "EnterRaidPrompt"
prompt.ActionText = "ENTRA NEL RAID"
prompt.ObjectText = "PRISMA REX"
prompt.KeyboardKeyCode = Enum.KeyCode.E
prompt.GamepadKeyCode = Enum.KeyCode.ButtonX
prompt.HoldDuration = 0
prompt.MaxActivationDistance = 18
prompt.RequiresLineOfSight = false
prompt.Parent = raidPortal

local returnPortal = part(gameplay, "ReturnToLoft", Vector3.new(12, 11, 1.2), CFrame.new(Vector3.new(0, 10, 103)), COLORS.purple, Enum.Material.Neon, 0.18)
returnPortal.CanCollide = false
light(returnPortal, COLORS.purple, 1.5, 24)
billboard(returnPortal, "VIBE LOFT", "TORNA ALLA LOBBY", COLORS.cyan, 220)
local returnPrompt = Instance.new("ProximityPrompt")
returnPrompt.ActionText = "TORNA AL LOFT"
returnPrompt.ObjectText = "VIBE LOFT"
returnPrompt.HoldDuration = 0
returnPrompt.MaxActivationDistance = 14
returnPrompt.RequiresLineOfSight = false
returnPrompt.Parent = returnPortal

local teleportCooldowns: { [Player]: number } = {}
local function teleportPlayer(player: Player, destination: Vector3)
	local now = os.clock()
	if now < (teleportCooldowns[player] or 0) then
		return
	end
	teleportCooldowns[player] = now + 1.5
	local character = player.Character
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if root and root:IsA("BasePart") then
		root.CFrame = CFrame.new(destination)
	end
end

local function playerFromTouch(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	return if character then Players:GetPlayerFromCharacter(character) else nil
end

prompt.Triggered:Connect(function(player)
	teleportPlayer(player, RAID_ENTRY)
end)
raidPortal.Touched:Connect(function(hit)
	local player = playerFromTouch(hit)
	if player then
		teleportPlayer(player, RAID_ENTRY)
	end
end)
returnPrompt.Triggered:Connect(function(player)
	teleportPlayer(player, LOFT_SPAWN)
end)
returnPortal.Touched:Connect(function(hit)
	local player = playerFromTouch(hit)
	if player then
		teleportPlayer(player, LOFT_SPAWN)
	end
end)
Players.PlayerRemoving:Connect(function(player)
	teleportCooldowns[player] = nil
end)

-- Make the loft the real spawn while preserving the original arena checkpoint.
local arenaGameplay = arena:FindFirstChild("GameplayMarkers")
local oldSpawn = if arenaGameplay then arenaGameplay:FindFirstChild("PlayerSpawn") else nil
if oldSpawn and oldSpawn:IsA("SpawnLocation") then
	oldSpawn.Enabled = false
	oldSpawn.CanCollide = false
end
local loftSpawn = Instance.new("SpawnLocation")
loftSpawn.Name = "VibeLoftSpawn"
loftSpawn.Anchored = true
loftSpawn.Neutral = true
loftSpawn.Enabled = true
loftSpawn.Duration = 0
loftSpawn.Size = Vector3.new(12, 1, 12)
loftSpawn.CFrame = CFrame.lookAt(LOFT_SPAWN, LOFT_ORIGIN + Vector3.new(0, 4, 20))
loftSpawn.Material = Enum.Material.SmoothPlastic
loftSpawn.Color = COLORS.cyan
loftSpawn.Transparency = 1
loftSpawn.Parent = gameplay

-- Brighter than the old raid room, but with enough contrast for the chroma lights.
Lighting.ClockTime = 18.35
Lighting.Brightness = 4
Lighting.ExposureCompensation = 0.72
Lighting.Ambient = Color3.fromRGB(154, 151, 178)
Lighting.OutdoorAmbient = Color3.fromRGB(126, 139, 169)
Lighting.ColorShift_Top = Color3.fromRGB(34, 27, 64)
Lighting.FogColor = Color3.fromRGB(76, 81, 126)
Lighting.FogStart = 420
Lighting.FogEnd = 1050

local bloom = Lighting:FindFirstChild("BrainrotArenaBloom")
if bloom and bloom:IsA("BloomEffect") then
	bloom.Intensity = 0.38
	bloom.Size = 20
	bloom.Threshold = 1.25
end
local colorCorrection = Lighting:FindFirstChild("BrainrotArenaColor")
if colorCorrection and colorCorrection:IsA("ColorCorrectionEffect") then
	colorCorrection.Brightness = 0.1
	colorCorrection.Contrast = 0.04
	colorCorrection.Saturation = 0.12
	colorCorrection.TintColor = Color3.fromRGB(255, 247, 255)
end
local atmosphere = Lighting:FindFirstChild("BrainrotArenaAtmosphere")
if atmosphere and atmosphere:IsA("Atmosphere") then
	atmosphere.Density = 0.035
	atmosphere.Haze = 0.22
	atmosphere.Glare = 0.1
	atmosphere.Color = Color3.fromRGB(171, 155, 224)
	atmosphere.Decay = Color3.fromRGB(54, 46, 92)
end

-- Slow shared animation: one loop controls every tile, avoiding 64 individual tweens.
task.spawn(function()
	local palette = { COLORS.cyan, COLORS.purple, COLORS.pink, COLORS.gold }
	local phase = 0
	while lobby.Parent do
		phase += 1
		for index, tile in danceTiles do
			tile.Color = palette[((index + phase - 1) % #palette) + 1]
			tile.Transparency = 0.08 + math.abs(math.sin((index + phase) * 0.43)) * 0.2
		end
		task.wait(0.42)
	end
end)

TweenService:Create(raidPortal, TweenInfo.new(1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	Color = COLORS.pink,
	Transparency = 0.28,
}):Play()
TweenService:Create(treasure, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {
	CFrame = treasure.CFrame * CFrame.Angles(0, math.rad(180), 0),
	Color = COLORS.white,
}):Play()

lobby.PrimaryPart = spawnZone
print("Vibe Loft lobby ready")
