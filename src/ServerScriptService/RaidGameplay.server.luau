--!strict

-- Complete raid loop, weapons, boss attacks, rewards, and shuttle presentation.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")

local arena = workspace:WaitForChild("BrainrotHeroesRaidArena") :: Model
local geometry = arena:WaitForChild("Architecture")
local effects = arena:WaitForChild("Effects")
local gameplay = arena:WaitForChild("GameplayMarkers")
local boss = arena:WaitForChild("PrismaRex") :: Model
local bossCore = boss:WaitForChild("HeroCore") :: BasePart
local bossShield = boss:WaitForChild("CountdownShield") :: BasePart
local bossDamaged = gameplay:WaitForChild("BossDamaged") :: BindableEvent
local powerRemote = (ReplicatedStorage:WaitForChild("BrainrotHeroesRemotes"):WaitForChild("UseHeroPower")) :: RemoteEvent

local countdownCrystal = effects:WaitForChild("CountdownCrystal") :: BasePart
local hologram = countdownCrystal:WaitForChild("HologramLabel") :: BillboardGui
local hologramFrame = hologram:WaitForChild("Frame") :: Frame
local countdownTitle = hologramFrame:WaitForChild("Title") :: TextLabel
local countdownSubtitle = hologramFrame:WaitForChild("Subtitle") :: TextLabel
local bossNameGui = (boss:WaitForChild("Head"):WaitForChild("BossName")) :: BillboardGui
local bossName = bossNameGui:WaitForChild("TextLabel") :: TextLabel

local COLORS = {
	void = Color3.fromRGB(18, 21, 48),
	stone = Color3.fromRGB(52, 58, 93),
	cyan = Color3.fromRGB(45, 235, 255),
	purple = Color3.fromRGB(170, 67, 255),
	pink = Color3.fromRGB(255, 68, 184),
	gold = Color3.fromRGB(255, 204, 76),
	white = Color3.fromRGB(239, 249, 255),
	green = Color3.fromRGB(105, 255, 145),
}

local COUNTDOWN_SECONDS = 25
local RAID_SECONDS = 100
local REWARD_SECONDS = 12
local BOSS_MAX_HEALTH = 10000

arena:SetAttribute("RaidControllerActive", true)

local function makePart(
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
	object.CanCollide = true
	object.Size = size
	object.CFrame = cframe
	object.Color = color
	object.Material = material
	object.Transparency = transparency or 0
	object.TopSurface = Enum.SurfaceType.Smooth
	object.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		object.Shape = shape
	end
	object.Parent = parent
	return object
end

local function addLight(parent: Instance, color: Color3, brightness: number, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = brightness
	light.Range = range
	light.Shadows = false
	light.Parent = parent
end

local function setDisplay(title: string, subtitle: string, color: Color3)
	countdownTitle.Text = title
	countdownSubtitle.Text = subtitle
	countdownSubtitle.TextColor3 = color
end

local function createRing(position: Vector3, color: Color3, startDiameter: number, endDiameter: number, lifetime: number)
	local ring = makePart(
		effects,
		"Shockwave",
		Vector3.new(0.4, startDiameter, startDiameter),
		CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
		color,
		Enum.Material.Neon,
		0.25,
		Enum.PartType.Cylinder
	)
	ring.CanCollide = false
	TweenService:Create(ring, TweenInfo.new(lifetime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = Vector3.new(0.15, endDiameter, endDiameter),
		Transparency = 1,
	}):Play()
	Debris:AddItem(ring, lifetime + 0.15)
end

local function createBeam(fromPosition: Vector3, toPosition: Vector3, color: Color3, width: number, lifetime: number)
	local distance = (toPosition - fromPosition).Magnitude
	local beam = makePart(
		effects,
		"WeaponBeam",
		Vector3.new(width, width, distance),
		CFrame.lookAt((fromPosition + toPosition) * 0.5, toPosition),
		color,
		Enum.Material.Neon,
		0.04
	)
	beam.CanCollide = false
	TweenService:Create(beam, TweenInfo.new(lifetime), { Transparency = 1, Size = Vector3.new(0.1, 0.1, distance) }):Play()
	Debris:AddItem(beam, lifetime + 0.1)
end

-- Shuttle landing zone.
local shuttleArea = Instance.new("Model")
shuttleArea.Name = "AstroShuttleBay"
shuttleArea.Parent = geometry

local padPosition = Vector3.new(-73, 2.1, 38)
local landingPad = makePart(
	shuttleArea,
	"LandingPad",
	Vector3.new(2.2, 38, 38),
	CFrame.new(padPosition) * CFrame.Angles(0, 0, math.rad(90)),
	COLORS.stone,
	Enum.Material.Metal,
	0,
	Enum.PartType.Cylinder
)

for index = 1, 16 do
	local angle = (index / 16) * math.pi * 2
	local lightPosition = padPosition + Vector3.new(math.cos(angle) * 16.5, 1.5, math.sin(angle) * 16.5)
	local lamp = makePart(
		shuttleArea,
		"PadLight",
		Vector3.new(2, 0.6, 4.5),
		CFrame.new(lightPosition) * CFrame.Angles(0, -angle, 0),
		if index % 2 == 0 then COLORS.cyan else COLORS.gold,
		Enum.Material.Neon,
		0.08
	)
	lamp.CanCollide = false
end

local padLabelPart = makePart(
	shuttleArea,
	"PadSign",
	Vector3.new(10, 5, 1),
	CFrame.new(padPosition + Vector3.new(0, 5, 19)),
	COLORS.void,
	Enum.Material.Metal
)
local padGui = Instance.new("SurfaceGui")
	padGui.Face = Enum.NormalId.Front
	padGui.Parent = padLabelPart
local padText = Instance.new("TextLabel")
	padText.BackgroundTransparency = 1
	padText.Size = UDim2.fromScale(1, 1)
	padText.Font = Enum.Font.GothamBlack
	padText.Text = "ASTRO SHUTTLE\nBAY 01"
	padText.TextColor3 = COLORS.cyan
	padText.TextScaled = true
	padText.Parent = padGui

local shuttle = Instance.new("Model")
shuttle.Name = "NovaShuttle"
shuttle:SetAttribute("DisplayName", "Nova Shuttle")
shuttle.Parent = geometry

local hull = makePart(shuttle, "Hull", Vector3.new(12, 10, 32), CFrame.new(), COLORS.white, Enum.Material.Metal)
shuttle.PrimaryPart = hull
local nose = makePart(shuttle, "Nose", Vector3.new(11.5, 10, 11.5), CFrame.new(0, 0, -17), COLORS.white, Enum.Material.Metal, 0, Enum.PartType.Ball)
nose.CanCollide = false
local cockpit = makePart(shuttle, "Cockpit", Vector3.new(8.5, 4.2, 9), CFrame.new(0, 5.1, -8), COLORS.cyan, Enum.Material.Glass, 0.18)
cockpit.CanCollide = false

for _, side in { -1, 1 } do
	local wing = makePart(
		shuttle,
		if side < 0 then "LeftWing" else "RightWing",
		Vector3.new(16, 1.4, 17),
		CFrame.new(side * 12, -1, 2) * CFrame.Angles(0, math.rad(side * -12), math.rad(side * 5)),
		COLORS.purple,
		Enum.Material.Metal
	)
	wing.CanCollide = false
	local wingTrim = makePart(
		shuttle,
		"WingTrim",
		Vector3.new(12, 0.5, 2),
		wing.CFrame * CFrame.new(0, 1, -7),
		COLORS.pink,
		Enum.Material.Neon,
		0.05
	)
	wingTrim.CanCollide = false

	local engine = makePart(
		shuttle,
		"Engine",
		Vector3.new(5, 5, 9),
		CFrame.new(side * 4, 0, 17),
		COLORS.stone,
		Enum.Material.Metal,
		0,
		Enum.PartType.Cylinder
	)
	engine.CFrame *= CFrame.Angles(math.rad(90), 0, 0)
	engine.CanCollide = false
	local flame = makePart(
		shuttle,
		"EngineFlame",
		Vector3.new(3.5, 3.5, 10),
		CFrame.new(side * 4, 0, 24),
		COLORS.cyan,
		Enum.Material.Neon,
		0.12
	)
	flame.CanCollide = false
	addLight(flame, COLORS.cyan, 2, 24)
end

local topFin = makePart(shuttle, "TopFin", Vector3.new(1.5, 10, 12), CFrame.new(0, 8, 8), COLORS.pink, Enum.Material.Metal)
topFin.CanCollide = false
local landingCFrame = CFrame.lookAt(padPosition + Vector3.new(0, 10, 0), Vector3.new(0, 10, 0))
shuttle:PivotTo(landingCFrame)

local supplyCrate = makePart(
	shuttleArea,
	"SupplyCrate",
	Vector3.new(8, 6, 8),
	CFrame.new(padPosition + Vector3.new(13, 4, 7)),
	COLORS.gold,
	Enum.Material.Metal
)
local supplyPrompt = Instance.new("ProximityPrompt")
supplyPrompt.Name = "GetRaidWeapons"
supplyPrompt.ActionText = "Prendi le armi"
supplyPrompt.ObjectText = "Rifornimenti Nova Shuttle"
supplyPrompt.HoldDuration = 0.4
supplyPrompt.MaxActivationDistance = 12
supplyPrompt.RequiresLineOfSight = false
supplyPrompt.Parent = supplyCrate

local function moveShuttle(startCFrame: CFrame, endCFrame: CFrame, duration: number)
	local startedAt = os.clock()
	while true do
		local alpha = math.clamp((os.clock() - startedAt) / duration, 0, 1)
		local eased = 1 - (1 - alpha) ^ 3
		local arc = math.sin(alpha * math.pi) * 18
		shuttle:PivotTo(startCFrame:Lerp(endCFrame, eased) * CFrame.new(0, arc, 0))
		if alpha >= 1 then
			break
		end
		task.wait()
	end
end

local function landShuttle()
	local startCFrame = landingCFrame * CFrame.new(0, 115, 140) * CFrame.Angles(math.rad(-18), 0, 0)
	shuttle:PivotTo(startCFrame)
	moveShuttle(startCFrame, landingCFrame, 6)
	createRing(padPosition + Vector3.new(0, 1, 0), COLORS.cyan, 8, 48, 1.1)
end

local function launchShuttle()
	local endCFrame = landingCFrame * CFrame.new(0, 130, -160) * CFrame.Angles(math.rad(24), 0, 0)
	moveShuttle(shuttle:GetPivot(), endCFrame, 5)
end

-- Runtime weapon templates. They are fully server-authoritative.
local oldWeapons = ServerStorage:FindFirstChild("BrainrotRaidWeapons")
if oldWeapons then
	oldWeapons:Destroy()
end
local weaponTemplates = Instance.new("Folder")
weaponTemplates.Name = "BrainrotRaidWeapons"
weaponTemplates.Parent = ServerStorage

local WEAPON_VISUAL_SCALE = 0.34

local function toolDecoration(
	handle: BasePart,
	name: string,
	size: Vector3,
	offset: CFrame,
	color: Color3,
	material: Enum.Material,
	shape: Enum.PartType?,
	className: string?
): BasePart
	local decoration = Instance.new(className or "Part") :: BasePart
	decoration.Name = name
	decoration.Size = size * WEAPON_VISUAL_SCALE
	local scaledPosition = offset.Position * WEAPON_VISUAL_SCALE
	local rotationOnly = offset - offset.Position
	decoration.CFrame = handle.CFrame * CFrame.new(scaledPosition) * rotationOnly
	decoration.Color = color
	decoration.Material = material
	if shape and decoration:IsA("Part") then
		decoration.Shape = shape
	end
	decoration.CanCollide = false
	decoration.Massless = true
	decoration.Parent = handle.Parent
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = decoration
	weld.Parent = decoration
	return decoration
end

local function addWeaponLight(part: BasePart, color: Color3, range: number)
	local light = Instance.new("PointLight")
	light.Color = color
	light.Brightness = 1.8
	light.Range = range
	light.Shadows = false
	light.Parent = part
end

local function addRainbowTrail(part: BasePart, top: Vector3, bottom: Vector3)
	local first = Instance.new("Attachment")
	first.Position = top * WEAPON_VISUAL_SCALE
	first.Parent = part
	local second = Instance.new("Attachment")
	second.Position = bottom * WEAPON_VISUAL_SCALE
	second.Parent = part
	local trail = Instance.new("Trail")
	trail.Attachment0 = first
	trail.Attachment1 = second
	trail.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, COLORS.cyan),
		ColorSequenceKeypoint.new(0.48, COLORS.purple),
		ColorSequenceKeypoint.new(1, COLORS.pink),
	})
	trail.LightEmission = 1
	trail.Lifetime = 0.22
	trail.MinLength = 0.08
	trail.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.05),
		NumberSequenceKeypoint.new(1, 1),
	})
	trail.Parent = part
end

local function addWeaponLabel(tool: Tool, rarity: string, color: Color3)
	local handle = tool:FindFirstChild("Handle") :: BasePart
	local gui = Instance.new("BillboardGui")
	gui.Name = "WeaponRarity"
	gui.Size = UDim2.fromOffset(170, 44)
	gui.StudsOffsetWorldSpace = Vector3.new(0, 3.2, 0)
	gui.MaxDistance = 32
	gui.AlwaysOnTop = true
	gui.Enabled = false
	gui.Parent = handle
	local label = Instance.new("TextLabel")
	label.BackgroundColor3 = COLORS.void
	label.BackgroundTransparency = 0.2
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.GothamBlack
	label.Text = string.format("%s\n%s", rarity, string.upper(tool.Name))
	label.TextColor3 = color
	label.TextScaled = true
	label.Parent = gui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = label
end

local function createWeapon(name: string, weaponType: string, rarity: string, color: Color3, damage: number, cooldown: number)
	local tool = Instance.new("Tool")
	tool.Name = name
	tool.CanBeDropped = false
	tool.RequiresHandle = true
	tool:SetAttribute("WeaponType", weaponType)
	tool:SetAttribute("Rarity", rarity)
	tool:SetAttribute("Damage", damage)
	tool:SetAttribute("Cooldown", cooldown)
	tool.ToolTip = string.format("%s • %d danni", rarity, damage)

	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = if weaponType == "Blade" then Vector3.new(0.62, 2.7, 0.62) else Vector3.new(0.62, 1.8, 0.72)
	handle.Color = COLORS.void
	handle.Material = Enum.Material.Metal
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool

	if weaponType == "Blade" then
		local guard = toolDecoration(handle, "PrismGuard", Vector3.new(6.4, 0.7, 1.5), CFrame.new(0, 2.4, 0), COLORS.gold, Enum.Material.Metal)
		toolDecoration(handle, "GuardGemLeft", Vector3.new(1.5, 1.5, 1.5), CFrame.new(-2.7, 2.4, 0), COLORS.cyan, Enum.Material.Neon, Enum.PartType.Ball)
		toolDecoration(handle, "GuardGemRight", Vector3.new(1.5, 1.5, 1.5), CFrame.new(2.7, 2.4, 0), COLORS.pink, Enum.Material.Neon, Enum.PartType.Ball)
		local blade = toolDecoration(handle, "ChromaBlade", Vector3.new(3.4, 10.5, 0.75), CFrame.new(0, 7.7, 0) * CFrame.Angles(0, 0, math.rad(4)), color, Enum.Material.Neon, nil, "WedgePart")
		toolDecoration(handle, "BladeSpine", Vector3.new(0.65, 9.6, 1.15), CFrame.new(-1.45, 7.3, 0), COLORS.purple, Enum.Material.Glass, 0)
		local bladeCore = toolDecoration(handle, "BladeCore", Vector3.new(0.7, 7.5, 1.4), CFrame.new(0.1, 7, 0), COLORS.cyan, Enum.Material.Neon)
		addWeaponLight(bladeCore, COLORS.cyan, 14)
		addRainbowTrail(blade, Vector3.new(0, 5, 0), Vector3.new(0, -5, 0))
		guard.Reflectance = 0.18
		tool.Grip = CFrame.new(0, -2.2, 0) * CFrame.Angles(0, 0, math.rad(-12))
	elseif weaponType == "Rocket" then
		local barrel = toolDecoration(handle, "StarbreakerBarrel", Vector3.new(4.8, 4.8, 10.5), CFrame.new(0, 1.3, -2.4) * CFrame.Angles(math.rad(90), 0, 0), COLORS.stone, Enum.Material.Metal, Enum.PartType.Cylinder)
		toolDecoration(handle, "MuzzleRing", Vector3.new(5.5, 5.5, 1), CFrame.new(0, 1.3, -7.5) * CFrame.Angles(math.rad(90), 0, 0), COLORS.gold, Enum.Material.Neon, Enum.PartType.Cylinder)
		local reactor = toolDecoration(handle, "ChromaReactor", Vector3.new(3.4, 3.4, 3.4), CFrame.new(0, 1.3, 1.3), COLORS.pink, Enum.Material.Neon, Enum.PartType.Ball)
		toolDecoration(handle, "TopRail", Vector3.new(1.3, 1.2, 7), CFrame.new(0, 4, -2), COLORS.cyan, Enum.Material.Neon)
		toolDecoration(handle, "LeftFin", Vector3.new(1.2, 4.5, 5), CFrame.new(-2.7, 1.2, 0) * CFrame.Angles(0, 0, math.rad(18)), COLORS.purple, Enum.Material.Metal, nil, "WedgePart")
		toolDecoration(handle, "RightFin", Vector3.new(1.2, 4.5, 5), CFrame.new(2.7, 1.2, 0) * CFrame.Angles(0, math.rad(180), math.rad(-18)), COLORS.pink, Enum.Material.Metal, nil, "WedgePart")
		addWeaponLight(reactor, COLORS.pink, 16)
		barrel.Reflectance = 0.12
		tool.Grip = CFrame.new(0, -0.5, -1.3) * CFrame.Angles(0, math.rad(90), 0)
	else
		local body = toolDecoration(handle, "NovaBody", Vector3.new(4.6, 3.6, 8), CFrame.new(0, 2, -2.2), COLORS.void, Enum.Material.Metal)
		toolDecoration(handle, "PrismSideLeft", Vector3.new(0.45, 2.7, 6.5), CFrame.new(-2.35, 2.1, -2.3), COLORS.purple, Enum.Material.Neon)
		toolDecoration(handle, "PrismSideRight", Vector3.new(0.45, 2.7, 6.5), CFrame.new(2.35, 2.1, -2.3), COLORS.pink, Enum.Material.Neon)
		local core = toolDecoration(handle, "ChromaCore", Vector3.new(2.6, 2.6, 2.6), CFrame.new(0, 2.1, -1.1), COLORS.cyan, Enum.Material.Neon, Enum.PartType.Ball)
		toolDecoration(handle, "TwinMuzzleLeft", Vector3.new(1.8, 1.8, 4.2), CFrame.new(-1.25, 2.1, -7.1) * CFrame.Angles(math.rad(90), 0, 0), COLORS.cyan, Enum.Material.Neon, Enum.PartType.Cylinder)
		toolDecoration(handle, "TwinMuzzleRight", Vector3.new(1.8, 1.8, 4.2), CFrame.new(1.25, 2.1, -7.1) * CFrame.Angles(math.rad(90), 0, 0), COLORS.pink, Enum.Material.Neon, Enum.PartType.Cylinder)
		toolDecoration(handle, "HoloSight", Vector3.new(0.45, 2.3, 2.5), CFrame.new(0, 4.5, -2.4), COLORS.gold, Enum.Material.Glass)
		toolDecoration(handle, "RearFin", Vector3.new(3.2, 3.5, 2.8), CFrame.new(0, 2.4, 2.1), color, Enum.Material.Metal, nil, "WedgePart")
		addWeaponLight(core, COLORS.cyan, 15)
		body.Reflectance = 0.18
		tool.Grip = CFrame.new(0, -1.2, -1.2) * CFrame.Angles(0, math.rad(90), 0)
	end
	addWeaponLabel(tool, rarity, color)

	tool.Parent = weaponTemplates
	return tool
end

createWeapon("Nova Pulse", "Blaster", "MITICA", COLORS.cyan, 360, 0.65)
createWeapon("Prism Fang", "Blade", "LEGGENDARIA", COLORS.purple, 590, 1.2)
createWeapon("Starbreaker X", "Rocket", "SEGRETA", COLORS.pink, 920, 3.0)

-- A visible vault makes the weapons aspirational before players even equip them.
local vault = Instance.new("Model")
vault.Name = "ChromaWeaponVault"
vault.Parent = geometry
local showcaseColors = { COLORS.cyan, COLORS.purple, COLORS.pink }
for index, template in weaponTemplates:GetChildren() do
	if template:IsA("Tool") then
		local position = padPosition + Vector3.new(25, 1.2, (index - 2) * 13)
		local pedestal = makePart(
			vault,
			"WeaponPedestal",
			Vector3.new(1.4, 8, 8),
			CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90)),
			showcaseColors[index] or COLORS.cyan,
			Enum.Material.Neon,
			0.2,
			Enum.PartType.Cylinder
		)
		pedestal.CanCollide = true
		local displayTool = template:Clone()
		displayTool.Name = "DISPLAY • " .. template.Name
		displayTool.Parent = vault
		local displayHandle = displayTool:FindFirstChild("Handle") :: BasePart
		displayHandle.Anchored = true
		displayHandle.CFrame = CFrame.new(position + Vector3.new(0, 7, 0))
			* CFrame.Angles(math.rad(-12), math.rad(30), math.rad(-18))
		for _, descendant in displayTool:GetDescendants() do
			if descendant:IsA("BasePart") then
				descendant.CanCollide = false
				descendant.CanTouch = false
			end
		end
		local rarityGui = displayHandle:FindFirstChild("WeaponRarity")
		if rarityGui and rarityGui:IsA("BillboardGui") then
			rarityGui.Enabled = true
		end
	end
end

local participants: { [Player]: number } = {}
local weaponCooldowns: { [Tool]: number } = {}
local shearedThresholds: { [number]: boolean } = {}

local function updateBossName()
	local health = boss:GetAttribute("Health") :: number
	local maxHealth = boss:GetAttribute("MaxHealth") :: number
	local percent = math.max(0, math.ceil((health / maxHealth) * 100))
	bossName.Text = string.format("PRISMA REX • %d%%", percent)
end

local function damageBoss(player: Player, amount: number, sourceName: string)
	if arena:GetAttribute("RaidState") ~= "ACTIVE" or boss:GetAttribute("Defeated") then
		powerRemote:FireClient(player, false, "Attendi l'inizio del raid!")
		return false
	end
	local oldHealth = boss:GetAttribute("Health") :: number
	local newHealth = math.max(0, oldHealth - amount)
	boss:SetAttribute("Health", newHealth)
	updateBossName()
	bossDamaged:Fire(player, amount, sourceName)
	powerRemote:FireClient(player, true, string.format("%s  -%d", sourceName, amount))
	if newHealth <= 0 then
		boss:SetAttribute("Defeated", true)
	end
	return true
end

local function bindWeapon(tool: Tool, player: Player)
	local handle = tool:FindFirstChild("Handle")
	local rarityGui = if handle then handle:FindFirstChild("WeaponRarity") else nil
	tool.Equipped:Connect(function()
		if rarityGui and rarityGui:IsA("BillboardGui") then
			rarityGui.Enabled = true
			task.delay(1.6, function()
				if rarityGui.Parent then
					rarityGui.Enabled = false
				end
			end)
		end
	end)
	tool.Activated:Connect(function()
		local now = os.clock()
		local readyAt = weaponCooldowns[tool] or 0
		if now < readyAt then
			return
		end
		weaponCooldowns[tool] = now + (tool:GetAttribute("Cooldown") :: number)

		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local handle = tool:FindFirstChild("Handle")
		local target = boss.PrimaryPart
		if not root or not root:IsA("BasePart") or not handle or not handle:IsA("BasePart") or not target then
			return
		end

		local weaponType = tool:GetAttribute("WeaponType") :: string
		local damage = tool:GetAttribute("Damage") :: number
		local distance = (target.Position - root.Position).Magnitude
		if weaponType == "Blade" then
			if distance > 28 then
				powerRemote:FireClient(player, false, "Avvicinati al boss per usare Prism Fang!")
				return
			end
			createRing(root.Position - Vector3.new(0, 2.5, 0), COLORS.purple, 4, 38, 0.45)
			createBeam(root.Position + Vector3.new(0, 3, 0), bossCore.Position, COLORS.pink, 1.8, 0.3)
			damageBoss(player, damage, "PRISM FANG")
		elseif weaponType == "Rocket" then
			if distance > 150 then
				return
			end
			local rocket = makePart(effects, "ShuttleRocket", Vector3.new(2.8, 2.8, 7), CFrame.lookAt(handle.Position, bossCore.Position), COLORS.pink, Enum.Material.Neon, 0.04)
			rocket.CanCollide = false
			local flight = TweenService:Create(rocket, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { CFrame = CFrame.new(bossCore.Position), Size = Vector3.new(5, 5, 5) })
			flight:Play()
			flight.Completed:Once(function()
				if rocket.Parent then rocket:Destroy() end
				createRing(bossCore.Position, COLORS.pink, 5, 42, 0.65)
				damageBoss(player, damage, "RAZZO")
			end)
		else
			if distance > 135 then
				return
			end
			createBeam(handle.Position, bossCore.Position, COLORS.cyan, 1.2, 0.25)
			damageBoss(player, damage, "BLASTER")
		end
	end)
end

local function giveWeapons(player: Player)
	local backpack = player:FindFirstChildWhichIsA("Backpack")
	if not backpack then
		return
	end
	for _, template in weaponTemplates:GetChildren() do
		if template:IsA("Tool") and not backpack:FindFirstChild(template.Name) and not (player.Character and player.Character:FindFirstChild(template.Name)) then
			local clone = template:Clone()
			clone.Parent = backpack
			bindWeapon(clone, player)
		end
	end
	task.delay(0.25, function()
		local character = player.Character
		local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
		local starterWeapon = backpack:FindFirstChild("Nova Pulse")
		if humanoid and starterWeapon and starterWeapon:IsA("Tool") and not character:FindFirstChildWhichIsA("Tool") then
			humanoid:EquipTool(starterWeapon)
		end
	end)
end

supplyPrompt.Triggered:Connect(giveWeapons)

local function setupPlayer(player: Player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		leaderstats = Instance.new("Folder")
		leaderstats.Name = "leaderstats"
		leaderstats.Parent = player
	end
	if not leaderstats:FindFirstChild("Fragments") then
		local fragments = Instance.new("IntValue")
		fragments.Name = "Fragments"
		fragments.Parent = leaderstats
	end
	if not leaderstats:FindFirstChild("HeroWins") then
		local wins = Instance.new("IntValue")
		wins.Name = "HeroWins"
		wins.Parent = leaderstats
	end
	if player:GetAttribute("ChromaCores") == nil then
		player:SetAttribute("ChromaCores", 0)
	end
	if player:GetAttribute("WeaponCrates") == nil then
		player:SetAttribute("WeaponCrates", 0)
	end
	if player:GetAttribute("RaidCharms") == nil then
		player:SetAttribute("RaidCharms", 0)
	end
	player.CharacterAdded:Connect(function()
		task.wait(0.8)
		giveWeapons(player)
	end)
	if player.Character then
		task.defer(giveWeapons, player)
	end
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end

bossDamaged.Event:Connect(function(player: Player, amount: number)
	participants[player] = (participants[player] or 0) + amount
	local health = boss:GetAttribute("Health") :: number
	local maxHealth = boss:GetAttribute("MaxHealth") :: number
	local ratio = health / maxHealth
	for index, threshold in { 0.75, 0.5, 0.25 } do
		if ratio <= threshold and not shearedThresholds[index] then
			shearedThresholds[index] = true
			local character = player.Character
			local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
			if root and root:IsA("BasePart") then
				local shard = makePart(
					effects,
					"ClaimedChromaShard",
					Vector3.new(2.2, 4.5, 1.2),
					CFrame.new(bossCore.Position) * CFrame.Angles(0, 0, math.rad(28)),
					showcaseColors[index] or COLORS.cyan,
					Enum.Material.Neon,
					0.04
				)
				shard.CanCollide = false
				addLight(shard, shard.Color, 2.2, 20)
				local flight = TweenService:Create(shard, TweenInfo.new(0.85, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
					CFrame = root.CFrame * CFrame.new(0, 3, -2),
					Size = Vector3.new(0.5, 1.2, 0.3),
				})
				flight:Play()
				flight.Completed:Once(function()
					if shard.Parent then shard:Destroy() end
				end)
			end
			local charms = math.min(3, (player:GetAttribute("RaidCharms") or 0) + 1)
			player:SetAttribute("RaidCharms", charms)
			setDisplay("CHROMA STRAPPATO!", string.format("%s • COSTELLAZIONE %d/3", string.upper(player.DisplayName), charms), showcaseColors[index] or COLORS.cyan)
			break
		end
	end
end)

local function bossShockwave()
	setDisplay("ATTACCO DEL BOSS", "SALTA SOPRA L'ONDA!", COLORS.pink)
	createRing(Vector3.new(0, 6.1, 0), COLORS.pink, 10, 175, 1.45)
	task.wait(1.05)
	for _, player in Players:GetPlayers() do
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		local humanoid = if character then character:FindFirstChildWhichIsA("Humanoid") else nil
		if root and root:IsA("BasePart") and humanoid and (root.Position - Vector3.new(0, root.Position.Y, 0)).Magnitude < 88 and root.Position.Y < 9 then
			humanoid:TakeDamage(18)
		end
	end
end

local function chooseWinner(): Player?
	local candidates = {}
	for player, damage in participants do
		if player.Parent == Players and damage > 0 then
			table.insert(candidates, player)
		end
	end
	if #candidates == 0 then
		candidates = Players:GetPlayers()
	end
	if #candidates == 0 then
		return nil
	end
	return candidates[math.random(1, #candidates)]
end

local function awardRaid()
	local winner = chooseWinner()
	for _, player in Players:GetPlayers() do
		local leaderstats = player:FindFirstChild("leaderstats")
		local fragments = if leaderstats then leaderstats:FindFirstChild("Fragments") else nil
		if fragments and fragments:IsA("IntValue") then
			fragments.Value += if player == winner then 5 else 12
		end
		if player == winner and leaderstats then
			local wins = leaderstats:FindFirstChild("HeroWins")
			if wins and wins:IsA("IntValue") then
				wins.Value += 1
			end
		end
		if (participants[player] or 0) > 0 then
			local cores = (player:GetAttribute("ChromaCores") or 0) + 1
			if cores >= 3 then
				cores -= 3
				player:SetAttribute("WeaponCrates", (player:GetAttribute("WeaponCrates") or 0) + 1)
			end
			player:SetAttribute("ChromaCores", cores)
		end
	end
	if winner then
		setDisplay("HERO ASSEGNATO!", string.upper(winner.DisplayName) .. " VINCE PRISMA REX • FRAMMENTI AGLI ALTRI", COLORS.gold)
	else
		setDisplay("RAID COMPLETATO", "NESSUN PARTECIPANTE VALIDO", COLORS.gold)
	end
end

local function resetRaid()
	participants = {}
	shearedThresholds = {}
	for _, player in Players:GetPlayers() do
		player:SetAttribute("RaidCharms", 0)
	end
	-- The raid remains playable alone, but Prisma Rex becomes a true group boss
	-- when a large server joins.
	local scaledMaxHealth = math.max(BOSS_MAX_HEALTH, #Players:GetPlayers() * 6000)
	boss:SetAttribute("MaxHealth", scaledMaxHealth)
	boss:SetAttribute("Health", scaledMaxHealth)
	boss:SetAttribute("Defeated", false)
	bossShield.Transparency = 0.88
	bossCore.Color = COLORS.cyan
	updateBossName()
end

task.spawn(function()
	while arena.Parent do
		resetRaid()
		arena:SetAttribute("RaidState", "COUNTDOWN")
		task.spawn(landShuttle)
		for remaining = COUNTDOWN_SECONDS, 0, -1 do
			arena:SetAttribute("Countdown", remaining)
			setDisplay("MEGA RAID", string.format("SHUTTLE IN ARRIVO • %02d:%02d", math.floor(remaining / 60), remaining % 60), COLORS.cyan)
			task.wait(1)
		end

		arena:SetAttribute("RaidState", "ACTIVE")
		bossShield.Transparency = 1
		setDisplay("RAID ATTIVO", "USA ARMI E POTERI CONTRO PRISMA REX!", COLORS.pink)
		local nextAttackAt = os.clock() + 7
		local defeated = false
		for remaining = RAID_SECONDS, 0, -1 do
			arena:SetAttribute("RaidTime", remaining)
			if boss:GetAttribute("Defeated") or (boss:GetAttribute("Health") :: number) <= 0 then
				defeated = true
				break
			end
			if os.clock() >= nextAttackAt then
				nextAttackAt = os.clock() + 9
				task.spawn(bossShockwave)
			else
				local health = boss:GetAttribute("Health") :: number
				local maxHealth = boss:GetAttribute("MaxHealth") :: number
				setDisplay("RAID ATTIVO", string.format("PRISMA REX %d%% • TEMPO %02d:%02d", math.ceil(health / maxHealth * 100), math.floor(remaining / 60), remaining % 60), COLORS.pink)
			end
			task.wait(1)
		end

		arena:SetAttribute("RaidState", "REWARD")
		bossShield.Transparency = 0.88
		if defeated then
			awardRaid()
		else
			setDisplay("PRISMA REX RESISTE", "POTENZIA LE ARMI E RIPROVA AL PROSSIMO RAID", COLORS.pink)
		end
		task.spawn(launchShuttle)
		task.wait(REWARD_SECONDS)
	end
end)

print("Brainrot Heroes gameplay, weapons, and Nova Shuttle ready")
