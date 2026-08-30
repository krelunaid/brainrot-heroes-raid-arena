--!strict

local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ProximityPromptService = game:GetService("ProximityPromptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local arena = workspace:WaitForChild("BrainrotHeroesRaidArena")
local remotes = ReplicatedStorage:WaitForChild("BrainrotHeroesRemotes")
local useHeroPower = remotes:WaitForChild("UseHeroPower") :: RemoteEvent

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "BrainrotHeroesArenaHUD"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.DisplayOrder = 10
screenGui.Parent = playerGui

local status = Instance.new("Frame")
status.Name = "RaidStatus"
status.AnchorPoint = Vector2.new(0.5, 0)
status.Position = UDim2.fromScale(0.5, 0.025)
status.Size = UDim2.fromOffset(440, 64)
status.BackgroundColor3 = Color3.fromRGB(8, 9, 24)
status.BackgroundTransparency = 0.16
status.BorderSizePixel = 0
status.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = status

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(45, 235, 255)
stroke.Thickness = 2
stroke.Transparency = 0.18
stroke.Parent = status

local gradient = Instance.new("UIGradient")
gradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(45, 235, 255)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 204, 76)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 67, 255)),
})
gradient.Parent = stroke

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromScale(0.04, 0.09)
title.Size = UDim2.fromScale(0.92, 0.44)
title.Font = Enum.Font.GothamBlack
title.Text = "BRAINROT HEROES • RAID HUB"
title.TextColor3 = Color3.fromRGB(244, 249, 255)
title.TextScaled = true
title.Parent = status

local subtitle = Instance.new("TextLabel")
subtitle.BackgroundTransparency = 1
subtitle.Position = UDim2.fromScale(0.04, 0.57)
subtitle.Size = UDim2.fromScale(0.92, 0.23)
subtitle.Font = Enum.Font.GothamBold
subtitle.Text = "Esplora, potenzia i tuoi Heroes e preparati all'evento"
subtitle.TextColor3 = Color3.fromRGB(255, 204, 76)
subtitle.TextScaled = true
subtitle.Parent = status

local function formatTime(seconds: number): string
	return string.format("%02d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function refreshRaidStatus()
	local state = arena:GetAttribute("RaidState") or "COUNTDOWN"
	if state == "ACTIVE" then
		title.Text = "PRISMA REX • RAID ATTIVO"
		subtitle.Text = string.format("TEMPO %s  •  USA ARMI E POTERI", formatTime(arena:GetAttribute("RaidTime") or 0))
		subtitle.TextColor3 = Color3.fromRGB(255, 68, 184)
	elseif state == "REWARD" then
		title.Text = "RICOMPENSE DEL RAID"
		subtitle.Text = "1 HERO COMPLETO • FRAMMENTI PER GLI ALTRI"
		subtitle.TextColor3 = Color3.fromRGB(105, 255, 145)
	else
		title.Text = "NOVA SHUTTLE IN ARRIVO"
		subtitle.Text = string.format("MEGA RAID TRA %s  •  RITIRA LE ARMI", formatTime(arena:GetAttribute("Countdown") or 0))
		subtitle.TextColor3 = Color3.fromRGB(255, 204, 76)
	end
end

for _, attribute in { "RaidState", "Countdown", "RaidTime" } do
	arena:GetAttributeChangedSignal(attribute):Connect(refreshRaidStatus)
end
refreshRaidStatus()

TweenService:Create(status, TweenInfo.new(0.7, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
	Position = UDim2.fromScale(0.5, 0.018),
}):Play()

task.spawn(function()
	while screenGui.Parent do
		TweenService:Create(gradient, TweenInfo.new(4, Enum.EasingStyle.Linear), { Rotation = gradient.Rotation + 180 }):Play()
		task.wait(4)
	end
end)

local arsenal = Instance.new("Frame")
arsenal.Name = "ChromaArsenal"
arsenal.AnchorPoint = Vector2.new(1, 0.5)
arsenal.Position = UDim2.fromScale(0.985, 0.58)
arsenal.Size = UDim2.fromOffset(300, 224)
arsenal.BackgroundColor3 = Color3.fromRGB(8, 9, 24)
arsenal.BackgroundTransparency = 0.1
arsenal.BorderSizePixel = 0
arsenal.Parent = screenGui

local arsenalCorner = Instance.new("UICorner")
arsenalCorner.CornerRadius = UDim.new(0, 18)
arsenalCorner.Parent = arsenal
local arsenalStroke = Instance.new("UIStroke")
arsenalStroke.Color = Color3.fromRGB(170, 67, 255)
arsenalStroke.Thickness = 2
arsenalStroke.Transparency = 0.18
arsenalStroke.Parent = arsenal

local arsenalTitle = Instance.new("TextLabel")
arsenalTitle.BackgroundTransparency = 1
arsenalTitle.Position = UDim2.fromOffset(16, 10)
arsenalTitle.Size = UDim2.new(1, -32, 0, 34)
arsenalTitle.Font = Enum.Font.GothamBlack
arsenalTitle.Text = "ARSENALE CHROMA • 3/3"
arsenalTitle.TextColor3 = Color3.fromRGB(244, 249, 255)
arsenalTitle.TextSize = 20
arsenalTitle.TextXAlignment = Enum.TextXAlignment.Left
arsenalTitle.Parent = arsenal

local weapons = {
	{ name = "NOVA PULSE", rarity = "MITICA", color = Color3.fromRGB(45, 235, 255) },
	{ name = "PRISM FANG", rarity = "LEGGENDARIA", color = Color3.fromRGB(170, 67, 255) },
	{ name = "STARBREAKER X", rarity = "SEGRETA", color = Color3.fromRGB(255, 68, 184) },
}

for index, weapon in weapons do
	local row = Instance.new("Frame")
	row.Position = UDim2.fromOffset(14, 47 + (index - 1) * 48)
	row.Size = UDim2.new(1, -28, 0, 40)
	row.BackgroundColor3 = weapon.color
	row.BackgroundTransparency = 0.78
	row.BorderSizePixel = 0
	row.Parent = arsenal
	local rowCorner = Instance.new("UICorner")
	rowCorner.CornerRadius = UDim.new(0, 11)
	rowCorner.Parent = row
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(12, 4)
	name.Size = UDim2.new(0.62, 0, 1, -8)
	name.Font = Enum.Font.GothamBlack
	name.Text = weapon.name
	name.TextColor3 = Color3.fromRGB(245, 249, 255)
	name.TextSize = 17
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.Parent = row
	local rarity = Instance.new("TextLabel")
	rarity.BackgroundTransparency = 1
	rarity.AnchorPoint = Vector2.new(1, 0)
	rarity.Position = UDim2.new(1, -10, 0, 4)
	rarity.Size = UDim2.new(0.38, -4, 1, -8)
	rarity.Font = Enum.Font.GothamBlack
	rarity.Text = weapon.rarity
	rarity.TextColor3 = weapon.color
	rarity.TextSize = 14
	rarity.TextXAlignment = Enum.TextXAlignment.Right
	rarity.Parent = row
end

local crateProgress = Instance.new("TextLabel")
crateProgress.BackgroundTransparency = 1
crateProgress.Position = UDim2.fromOffset(16, 194)
crateProgress.Size = UDim2.new(1, -32, 0, 22)
crateProgress.Font = Enum.Font.GothamBold
crateProgress.TextColor3 = Color3.fromRGB(255, 204, 76)
crateProgress.TextSize = 15
crateProgress.TextXAlignment = Enum.TextXAlignment.Left
crateProgress.Parent = arsenal

local function refreshCrateProgress()
	crateProgress.Text = string.format(
		"CASSA CHROMA  %d/3 CORE  •  CASSE %d",
		player:GetAttribute("ChromaCores") or 0,
		player:GetAttribute("WeaponCrates") or 0
	)
end
player:GetAttributeChangedSignal("ChromaCores"):Connect(refreshCrateProgress)
player:GetAttributeChangedSignal("WeaponCrates"):Connect(refreshCrateProgress)
refreshCrateProgress()

local function refreshArsenalVisibility()
	arsenal.Visible = arena:GetAttribute("RaidState") == "REWARD"
end
arena:GetAttributeChangedSignal("RaidState"):Connect(refreshArsenalVisibility)
refreshArsenalVisibility()

local combatHint = Instance.new("TextLabel")
combatHint.Name = "CombatHint"
combatHint.AnchorPoint = Vector2.new(0.5, 1)
combatHint.Position = UDim2.fromScale(0.5, 0.91)
combatHint.Size = UDim2.fromOffset(610, 48)
combatHint.BackgroundColor3 = Color3.fromRGB(8, 9, 24)
combatHint.BackgroundTransparency = 0.08
combatHint.BorderSizePixel = 0
combatHint.Font = Enum.Font.GothamBlack
combatHint.TextColor3 = Color3.fromRGB(255, 204, 76)
combatHint.TextSize = 19
combatHint.Parent = screenGui
local combatCorner = Instance.new("UICorner")
combatCorner.CornerRadius = UDim.new(0, 16)
combatCorner.Parent = combatHint
local combatStroke = Instance.new("UIStroke")
combatStroke.Color = Color3.fromRGB(45, 235, 255)
combatStroke.Thickness = 2
combatStroke.Transparency = 0.2
combatStroke.Parent = combatHint

local playerInLoft = false

local function refreshCombatHint()
	local state = arena:GetAttribute("RaidState")
	if playerInLoft then
		combatHint.Text = "SEGUI LE FRECCE  •  ENTRA NEL PORTALE RAID"
		combatHint.TextColor3 = Color3.fromRGB(45, 235, 255)
	elseif state == "ACTIVE" then
		if UserInputService.TouchEnabled then
			combatHint.Text = "SEGUI LE FRECCE  •  TOCCA ATTACCA"
		elseif UserInputService.GamepadEnabled then
			combatHint.Text = "SEGUI LE FRECCE  •  PREMI RT PER ATTACCARE"
		else
			combatHint.Text = "SEGUI LE FRECCE  •  CLIC PER ATTACCARE"
		end
		combatHint.TextColor3 = Color3.fromRGB(105, 255, 145)
	elseif state == "REWARD" then
		combatHint.Text = "RAID FINITO  •  GUARDA COSA HAI OTTENUTO"
		combatHint.TextColor3 = Color3.fromRGB(255, 204, 76)
	else
		combatHint.Text = "SEGUI LE FRECCE  •  L'ARMA È GIÀ PRONTA"
		combatHint.TextColor3 = Color3.fromRGB(255, 204, 76)
	end
end
arena:GetAttributeChangedSignal("RaidState"):Connect(refreshCombatHint)
refreshCombatHint()

local bossTarget = arena:WaitForChild("PrismaRex"):WaitForChild("HeroCore") :: BasePart
local shuttleTarget = arena:WaitForChild("Architecture"):WaitForChild("AstroShuttleBay"):WaitForChild("SupplyCrate") :: BasePart
local loft = workspace:WaitForChild("VibeLoftLobby", 12)
local raidPortalTarget: BasePart? = nil
if loft then
	local loftGameplay = loft:FindFirstChild("Gameplay")
	local candidate = if loftGameplay then loftGameplay:FindFirstChild("RaidPortal") else nil
	if candidate and candidate:IsA("BasePart") then
		raidPortalTarget = candidate
	end
end

local targetGui = Instance.new("BillboardGui")
targetGui.Name = "WorldObjective"
targetGui.Size = UDim2.fromOffset(230, 54)
targetGui.StudsOffsetWorldSpace = Vector3.new(0, 2.5, 0)
targetGui.AlwaysOnTop = true
targetGui.MaxDistance = 180
targetGui.Parent = screenGui
local targetLabel = Instance.new("TextLabel")
targetLabel.BackgroundColor3 = Color3.fromRGB(8, 9, 24)
targetLabel.BackgroundTransparency = 0.08
targetLabel.Size = UDim2.fromScale(1, 1)
targetLabel.Font = Enum.Font.GothamBlack
targetLabel.Text = "AVVICINATI"
targetLabel.TextColor3 = Color3.fromRGB(45, 235, 255)
targetLabel.TextScaled = true
targetLabel.Parent = targetGui
local targetCorner = Instance.new("UICorner")
targetCorner.CornerRadius = UDim.new(0, 18)
targetCorner.Parent = targetLabel
local targetStroke = Instance.new("UIStroke")
targetStroke.Color = Color3.fromRGB(255, 204, 76)
targetStroke.Thickness = 3
targetStroke.Parent = targetLabel

local guideFolder = Instance.new("Folder")
guideFolder.Name = "LocalRaidGuides"
guideFolder.Parent = workspace
local guideParts = {}
for index = 1, 7 do
	local pair = {}
	for side = -1, 1, 2 do
		local marker = Instance.new("Part")
		marker.Name = "ObjectiveChevron"
		marker.Anchored = true
		marker.CanCollide = false
		marker.CanQuery = false
		marker.CanTouch = false
		marker.Material = Enum.Material.Neon
		marker.Color = if index % 2 == 0 then Color3.fromRGB(170, 67, 255) else Color3.fromRGB(45, 235, 255)
		marker.Size = Vector3.new(0.45, 0.13, 3.2)
		marker.Transparency = 0.18
		marker.Parent = guideFolder
		pair[if side < 0 then 1 else 2] = marker
	end
	table.insert(guideParts, pair)
end

local function raidAttack(_actionName: string, inputState: Enum.UserInputState)
	if inputState ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	local character = player.Character
	local equipped = if character then character:FindFirstChildWhichIsA("Tool") else nil
	if equipped then
		equipped:Activate()
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("BrainrotRaidAttack", raidAttack, false, Enum.KeyCode.ButtonR2)
ContextActionService:SetTitle("BrainrotRaidAttack", "ATTACCA")
ContextActionService:SetPosition("BrainrotRaidAttack", UDim2.fromScale(0.82, 0.72))

local touchAttackButton: TextButton? = nil
if UserInputService.TouchEnabled then
	local button = Instance.new("TextButton")
	button.Name = "MobileAttackButton"
	button.AnchorPoint = Vector2.new(1, 1)
	button.Position = UDim2.fromScale(0.94, 0.82)
	button.Size = UDim2.fromOffset(160, 64)
	button.BackgroundColor3 = Color3.fromRGB(255, 62, 176)
	button.BackgroundTransparency = 0.06
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBlack
	button.Text = "⚡  ATTACCA"
	button.TextColor3 = Color3.fromRGB(255, 255, 255)
	button.TextScaled = true
	button.Visible = false
	button.Parent = screenGui
	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0.5, 0)
	buttonCorner.Parent = button
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(255, 205, 78)
	buttonStroke.Thickness = 5
	buttonStroke.Parent = button
	button.Activated:Connect(function()
		raidAttack("BrainrotRaidAttack", Enum.UserInputState.Begin)
		button.Size = UDim2.fromOffset(150, 58)
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(160, 64) }):Play()
	end)
	touchAttackButton = button
end

task.spawn(function()
	while screenGui.Parent do
		local state = arena:GetAttribute("RaidState")
		local character = player.Character
		local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
		if root and root:IsA("BasePart") then
			local isOutsideRaid = (Vector3.new(root.Position.X, 0, root.Position.Z) - Vector3.new(0, 0, 0)).Magnitude > 155
			local newPlayerInLoft = isOutsideRaid and raidPortalTarget ~= nil
			if playerInLoft ~= newPlayerInLoft then
				playerInLoft = newPlayerInLoft
				refreshCombatHint()
			end
			if touchAttackButton then
				local hasWeapon = character ~= nil and character:FindFirstChildWhichIsA("Tool") ~= nil
				touchAttackButton.Visible = state == "ACTIVE" and not playerInLoft and hasWeapon
			end
			local target = if playerInLoft and raidPortalTarget then raidPortalTarget elseif state == "COUNTDOWN" then shuttleTarget else bossTarget
			targetGui.Adornee = target
			local flatTarget = Vector3.new(target.Position.X, 5.9, target.Position.Z)
			local flatRoot = Vector3.new(root.Position.X, 5.9, root.Position.Z)
			local distance = (flatTarget - flatRoot).Magnitude
			local showPath = state ~= "REWARD" and distance > 18
			for index, pair in guideParts do
				local alpha = 0.12 + index * 0.095
				local center = flatRoot:Lerp(flatTarget, alpha)
				local facing = CFrame.lookAt(center, flatTarget)
				for sideIndex, marker in pair do
					local side = if sideIndex == 1 then -1 else 1
					marker.CFrame = facing * CFrame.new(side * 0.72, 0, 0) * CFrame.Angles(0, math.rad(side * 28), 0)
					marker.Transparency = if showPath then 0.14 + math.abs(math.sin(os.clock() * 3 + index)) * 0.25 else 1
				end
			end
			if playerInLoft then
				targetLabel.Text = "ENTRA NEL RAID"
				targetLabel.TextColor3 = Color3.fromRGB(45, 235, 255)
			elseif state == "COUNTDOWN" then
				targetLabel.Text = "VAI ALLO SHUTTLE"
				targetLabel.TextColor3 = Color3.fromRGB(45, 235, 255)
			elseif state == "ACTIVE" then
				local charms = player:GetAttribute("RaidCharms") or 0
				targetLabel.Text = if distance > 45 then "AVVICINATI" else string.format("ATTACCA  •  CHROMA %d/3", charms)
				targetLabel.TextColor3 = Color3.fromRGB(255, 68, 184)
			else
				targetLabel.Text = "RICOMPENSA"
				targetLabel.TextColor3 = Color3.fromRGB(255, 204, 76)
			end
		end
		task.wait(0.08)
	end
end)

local heroCard = Instance.new("Frame")
heroCard.Name = "HeroCard"
heroCard.AnchorPoint = Vector2.new(0.5, 0.5)
heroCard.Position = UDim2.fromScale(0.5, 0.53)
heroCard.Size = UDim2.fromOffset(470, 330)
heroCard.BackgroundColor3 = Color3.fromRGB(12, 14, 34)
heroCard.BackgroundTransparency = 0.06
heroCard.BorderSizePixel = 0
heroCard.Visible = false
heroCard.Parent = screenGui

local heroCardCorner = Instance.new("UICorner")
heroCardCorner.CornerRadius = UDim.new(0, 26)
heroCardCorner.Parent = heroCard

local heroCardStroke = Instance.new("UIStroke")
heroCardStroke.Name = "AccentStroke"
heroCardStroke.Color = Color3.fromRGB(170, 67, 255)
heroCardStroke.Thickness = 4
heroCardStroke.Transparency = 0.08
heroCardStroke.Parent = heroCard

local cardGradient = Instance.new("UIGradient")
cardGradient.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(22, 25, 59)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(38, 17, 67)),
})
cardGradient.Rotation = 25
cardGradient.Parent = heroCard

local cardIcon = Instance.new("TextLabel")
cardIcon.BackgroundTransparency = 1
cardIcon.Position = UDim2.fromOffset(24, 25)
cardIcon.Size = UDim2.fromOffset(82, 82)
cardIcon.Font = Enum.Font.GothamBlack
cardIcon.Text = "★"
cardIcon.TextColor3 = Color3.fromRGB(255, 204, 76)
cardIcon.TextScaled = true
cardIcon.Parent = heroCard

local cardTitle = Instance.new("TextLabel")
cardTitle.Name = "HeroName"
cardTitle.BackgroundTransparency = 1
cardTitle.Position = UDim2.fromOffset(118, 28)
cardTitle.Size = UDim2.fromOffset(300, 48)
cardTitle.Font = Enum.Font.GothamBlack
cardTitle.Text = "HERO"
cardTitle.TextColor3 = Color3.fromRGB(244, 249, 255)
cardTitle.TextScaled = true
cardTitle.TextXAlignment = Enum.TextXAlignment.Left
cardTitle.Parent = heroCard

local rarityLabel = Instance.new("TextLabel")
rarityLabel.Name = "Rarity"
rarityLabel.BackgroundTransparency = 1
rarityLabel.Position = UDim2.fromOffset(120, 79)
rarityLabel.Size = UDim2.fromOffset(240, 28)
rarityLabel.Font = Enum.Font.GothamBold
rarityLabel.Text = "RARITÀ"
rarityLabel.TextColor3 = Color3.fromRGB(255, 204, 76)
rarityLabel.TextSize = 22
rarityLabel.TextXAlignment = Enum.TextXAlignment.Left
rarityLabel.Parent = heroCard

local divider = Instance.new("Frame")
divider.BackgroundColor3 = Color3.fromRGB(45, 235, 255)
divider.BackgroundTransparency = 0.15
divider.BorderSizePixel = 0
divider.Position = UDim2.fromOffset(25, 120)
divider.Size = UDim2.new(1, -50, 0, 3)
divider.Parent = heroCard

local powerLabel = Instance.new("TextLabel")
powerLabel.Name = "Power"
powerLabel.BackgroundTransparency = 1
powerLabel.Position = UDim2.fromOffset(28, 138)
powerLabel.Size = UDim2.new(1, -56, 0, 38)
powerLabel.Font = Enum.Font.GothamBlack
powerLabel.Text = "POTERE:"
powerLabel.TextColor3 = Color3.fromRGB(45, 235, 255)
powerLabel.TextSize = 24
powerLabel.TextXAlignment = Enum.TextXAlignment.Left
powerLabel.Parent = heroCard

local descriptionLabel = Instance.new("TextLabel")
descriptionLabel.Name = "Description"
descriptionLabel.BackgroundTransparency = 1
descriptionLabel.Position = UDim2.fromOffset(28, 180)
descriptionLabel.Size = UDim2.new(1, -56, 0, 64)
descriptionLabel.Font = Enum.Font.GothamMedium
descriptionLabel.Text = "Descrizione dell'Hero"
descriptionLabel.TextColor3 = Color3.fromRGB(224, 232, 250)
descriptionLabel.TextSize = 19
descriptionLabel.TextWrapped = true
descriptionLabel.TextXAlignment = Enum.TextXAlignment.Left
descriptionLabel.TextYAlignment = Enum.TextYAlignment.Top
descriptionLabel.Parent = heroCard

local usePowerButton = Instance.new("TextButton")
usePowerButton.Name = "UsePower"
usePowerButton.AnchorPoint = Vector2.new(0.5, 1)
usePowerButton.Position = UDim2.new(0.5, 0, 1, -20)
usePowerButton.Size = UDim2.fromOffset(250, 48)
usePowerButton.BackgroundColor3 = Color3.fromRGB(45, 235, 255)
usePowerButton.BorderSizePixel = 0
usePowerButton.Font = Enum.Font.GothamBlack
usePowerButton.Text = "USA POTERE"
usePowerButton.TextColor3 = Color3.fromRGB(8, 9, 24)
usePowerButton.TextSize = 22
usePowerButton.Parent = heroCard

local usePowerCorner = Instance.new("UICorner")
usePowerCorner.CornerRadius = UDim.new(0, 15)
usePowerCorner.Parent = usePowerButton

local closeButton = Instance.new("TextButton")
closeButton.Name = "Close"
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -16, 0, 14)
closeButton.Size = UDim2.fromOffset(42, 42)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 75, 150)
closeButton.BackgroundTransparency = 0.12
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBlack
closeButton.Text = "×"
closeButton.TextColor3 = Color3.new(1, 1, 1)
closeButton.TextSize = 30
closeButton.Parent = heroCard

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(1, 0)
closeCorner.Parent = closeButton

local cardScale = Instance.new("UIScale")
cardScale.Scale = 1
cardScale.Parent = heroCard

local selectedSlot: number? = nil

local function hideHeroCard()
	if not heroCard.Visible then
		return
	end
	local tween = TweenService:Create(cardScale, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Scale = 0.82 })
	tween:Play()
	tween.Completed:Wait()
	heroCard.Visible = false
end

local function showHeroCard(prompt: ProximityPrompt)
	local accent = if prompt:GetAttribute("Accent") == "Cyan"
		then Color3.fromRGB(45, 235, 255)
		else Color3.fromRGB(170, 67, 255)
	cardTitle.Text = tostring(prompt:GetAttribute("HeroName") or "Hero sconosciuto")
	rarityLabel.Text = "RARITÀ • " .. tostring(prompt:GetAttribute("Rarity") or "?")
	powerLabel.Text = "POTERE • " .. tostring(prompt:GetAttribute("Power") or "Segreto")
	descriptionLabel.Text = tostring(prompt:GetAttribute("Description") or "Questo Hero è ancora avvolto nel mistero.")
	selectedSlot = prompt:GetAttribute("SlotIndex") :: number?
	heroCardStroke.Color = accent
	divider.BackgroundColor3 = accent
	powerLabel.TextColor3 = accent
	usePowerButton.BackgroundColor3 = accent
	usePowerButton.Text = "USA POTERE"
	cardScale.Scale = 0.72
	heroCard.Visible = true
	TweenService:Create(cardScale, TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end

closeButton.Activated:Connect(hideHeroCard)

usePowerButton.Activated:Connect(function()
	if selectedSlot then
		useHeroPower:FireServer(selectedSlot)
		usePowerButton.Text = "ATTIVAZIONE..."
	end
end)

useHeroPower.OnClientEvent:Connect(function(success: boolean, message: string)
	usePowerButton.Text = message
	usePowerButton.BackgroundColor3 = if success then Color3.fromRGB(115, 255, 145) else Color3.fromRGB(255, 105, 130)
	combatHint.Text = message
	combatHint.TextColor3 = if success then Color3.fromRGB(105, 255, 145) else Color3.fromRGB(255, 105, 130)
	task.delay(2.4, function()
		if heroCard.Visible then
			usePowerButton.Text = "USA POTERE"
			usePowerButton.BackgroundColor3 = heroCardStroke.Color
		end
		refreshCombatHint()
	end)
end)

ProximityPromptService.PromptTriggered:Connect(function(prompt: ProximityPrompt, triggeringPlayer: Player)
	if prompt.Name == "InspectHero" and (triggeringPlayer == nil or triggeringPlayer == player) then
		showHeroCard(prompt)
	end
end)
