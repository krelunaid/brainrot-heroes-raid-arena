local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local questRemote = ReplicatedStorage:WaitForChild("PrismoraEvent")
local combatRemote = ReplicatedStorage:WaitForChild("PrismoraCombat")

local old = playerGui:FindFirstChild("PrismoraUI")
if old then old:Destroy() end

local screen = Instance.new("ScreenGui")
screen.Name = "PrismoraUI"
screen.IgnoreGuiInset = false
screen.ResetOnSpawn = false
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.Parent = playerGui

local function round(parent, radius)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius)
	corner.Parent = parent
end

local function stroke(parent, color, transparency, thickness)
	local outline = Instance.new("UIStroke")
	outline.Color = color
	outline.Transparency = transparency
	outline.Thickness = thickness
	outline.Parent = parent
end

local header = Instance.new("Frame")
header.Name = "Header"
header.AnchorPoint = Vector2.new(0.5, 0)
header.Position = UDim2.fromScale(0.5, 0.026)
header.Size = UDim2.fromOffset(410, 88)
header.BackgroundColor3 = Color3.fromRGB(15, 20, 36)
header.BackgroundTransparency = 0.08
header.Parent = screen
round(header, 22)
stroke(header, Color3.fromRGB(70, 224, 255), 0.32, 2)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Position = UDim2.fromOffset(22, 10)
title.Size = UDim2.new(1, -44, 0, 34)
title.Font = Enum.Font.GothamBlack
title.Text = "PRISMORA: HERO RUSH"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = header

local objective = Instance.new("TextLabel")
objective.BackgroundTransparency = 1
objective.Position = UDim2.fromOffset(22, 48)
objective.Size = UDim2.new(1, -44, 0, 24)
objective.Font = Enum.Font.GothamMedium
objective.Text = "Prendi la Raggialama e attacca gli Spenti"
objective.TextColor3 = Color3.fromRGB(127, 232, 196)
objective.TextScaled = true
objective.TextXAlignment = Enum.TextXAlignment.Left
objective.Parent = header

local heroMeter = Instance.new("Frame")
heroMeter.Name = "HeroMeter"
heroMeter.AnchorPoint = Vector2.new(0.5, 0)
heroMeter.Position = UDim2.fromScale(0.5, 0.122)
heroMeter.Size = UDim2.fromOffset(330, 28)
heroMeter.BackgroundColor3 = Color3.fromRGB(38, 42, 58)
heroMeter.BackgroundTransparency = 0.08
heroMeter.ClipsDescendants = true
heroMeter.Parent = screen
round(heroMeter, 14)
stroke(heroMeter, Color3.fromRGB(255, 201, 74), 0.35, 1.5)

local heroFill = Instance.new("Frame")
heroFill.Name = "Fill"
heroFill.Size = UDim2.fromScale(0, 1)
heroFill.BackgroundColor3 = Color3.fromRGB(255, 201, 74)
heroFill.BorderSizePixel = 0
heroFill.Parent = heroMeter

local heroText = Instance.new("TextLabel")
heroText.Size = UDim2.fromScale(1, 1)
heroText.BackgroundTransparency = 1
heroText.Font = Enum.Font.GothamBlack
heroText.Text = "CARICA SOLARIS  0%"
heroText.TextColor3 = Color3.new(1, 1, 1)
heroText.TextScaled = true
heroText.ZIndex = 2
heroText.Parent = heroMeter

local statusToast = Instance.new("TextLabel")
statusToast.Name = "StatusToast"
statusToast.AnchorPoint = Vector2.new(0.5, 0.5)
statusToast.Position = UDim2.fromScale(0.5, 0.67)
statusToast.Size = UDim2.fromOffset(430, 58)
statusToast.BackgroundColor3 = Color3.fromRGB(16, 20, 35)
statusToast.BackgroundTransparency = 1
statusToast.Font = Enum.Font.GothamBlack
statusToast.Text = ""
statusToast.TextColor3 = Color3.new(1, 1, 1)
statusToast.TextScaled = true
statusToast.TextTransparency = 1
statusToast.ZIndex = 10
statusToast.Parent = screen
round(statusToast, 18)

local function showToast(text, color)
	statusToast.Text = text
	statusToast.TextColor3 = color or Color3.new(1, 1, 1)
	statusToast.BackgroundTransparency = 0.12
	statusToast.TextTransparency = 0
	statusToast.Size = UDim2.fromOffset(390, 50)
	TweenService:Create(statusToast, TweenInfo.new(0.16, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(460, 62) }):Play()
	task.delay(1.25, function()
		if statusToast.Parent then
			TweenService:Create(statusToast, TweenInfo.new(0.3), {
				BackgroundTransparency = 1,
				TextTransparency = 1,
			}):Play()
		end
	end)
end

local function makeActionButton(name, text, color, size, position, anchor)
	local button = Instance.new("TextButton")
	button.Name = name
	button.AnchorPoint = anchor or Vector2.new(1, 1)
	button.Position = position
	button.Size = UDim2.fromOffset(size, size)
	button.BackgroundColor3 = color
	button.BackgroundTransparency = 0.06
	button.AutoButtonColor = false
	button.Font = Enum.Font.GothamBlack
	button.Text = text
	button.TextColor3 = Color3.new(1, 1, 1)
	button.TextScaled = true
	button.ZIndex = 5
	button.Parent = screen
	round(button, math.floor(size * 0.34))
	stroke(button, Color3.new(1, 1, 1), 0.42, 2)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.06), { Size = UDim2.fromOffset(size * 0.92, size * 0.92) }):Play()
	end)
	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(size, size) }):Play()
	end)
	return button
end

local touch = UserInputService.TouchEnabled
local attack = makeActionButton(
	"Attack",
	touch and "ATTACCA" or "LMB",
	Color3.fromRGB(255, 95, 162),
	touch and 96 or 70,
	UDim2.new(1, -28, 1, touch and -136 or -35),
	Vector2.new(1, 1)
)
local skill = makeActionButton(
	"Skill",
	touch and "POTERE" or "Q",
	Color3.fromRGB(255, 201, 74),
	touch and 76 or 58,
	UDim2.new(1, touch and -142 or -110, 1, touch and -150 or -40),
	Vector2.new(1, 1)
)
local dash = makeActionButton(
	"Dash",
	touch and "DASH" or "SHIFT",
	Color3.fromRGB(70, 224, 255),
	touch and 76 or 62,
	UDim2.new(0, touch and 28 or 20, 1, touch and -190 or -30),
	Vector2.new(0, 1)
)
local hero = makeActionButton(
	"Hero",
	touch and "HERO" or "E HERO",
	Color3.fromRGB(115, 97, 76),
	touch and 86 or 72,
	UDim2.new(1, -38, 1, touch and -255 or -125),
	Vector2.new(1, 1)
)
hero.Active = false
hero.BackgroundTransparency = 0.4

local cooldowns = { Attack = 0, Skill = 0, Dash = 0 }
local heroReady = false
local baseLabels = {
	Attack = touch and "ATTACCA" or "LMB",
	Skill = touch and "POTERE" or "Q",
	Dash = touch and "DASH" or "SHIFT",
}

local function startCooldown(button, key, duration)
	cooldowns[key] = os.clock() + duration
	button.Active = false
	task.spawn(function()
		while button.Parent and cooldowns[key] > os.clock() do
			button.Text = string.format("%.1f", cooldowns[key] - os.clock())
			button.BackgroundTransparency = 0.38
			task.wait(0.08)
		end
		if button.Parent then
			button.Text = baseLabels[key]
			button.BackgroundTransparency = 0.06
			button.Active = true
		end
	end)
end

local function aimAssist(maxDistance, minDot)
	if not touch then return end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local folder = workspace:FindFirstChild("PrismoraEnemies")
	if not root or not folder then return end

	local bestRoot, bestScore
	for _, enemy in folder:GetChildren() do
		local enemyRoot = enemy:IsA("Model") and enemy.PrimaryPart
		if enemyRoot and not enemy:GetAttribute("Dead") then
			local flat = Vector3.new(enemyRoot.Position.X, root.Position.Y, enemyRoot.Position.Z) - root.Position
			local distance = flat.Magnitude
			if distance > 0 and distance <= maxDistance then
				local dot = root.CFrame.LookVector:Dot(flat.Unit)
				if dot >= minDot then
					local score = distance - (dot * 8)
					if not bestScore or score < bestScore then
						bestRoot, bestScore = enemyRoot, score
					end
				end
			end
		end
	end
	if bestRoot then
		root.CFrame = CFrame.lookAt(root.Position, Vector3.new(bestRoot.Position.X, root.Position.Y, bestRoot.Position.Z))
	end
end

local function requestAttack()
	if cooldowns.Attack > os.clock() then return end
	aimAssist(30, 0.34)
	startCooldown(attack, "Attack", 0.38)
	combatRemote:FireServer("Attack")
end

local function requestSkill()
	if cooldowns.Skill > os.clock() then return end
	aimAssist(38, 0.25)
	startCooldown(skill, "Skill", 7)
	combatRemote:FireServer("Skill")
end

local function requestDash()
	if cooldowns.Dash > os.clock() then return end
	startCooldown(dash, "Dash", 1.2)
	combatRemote:FireServer("Dash")
end

local function requestHero()
	if not heroReady then return end
	heroReady = false
	hero.Active = false
	hero.BackgroundColor3 = Color3.fromRGB(115, 97, 76)
	hero.BackgroundTransparency = 0.4
	combatRemote:FireServer("SummonHero")
end

attack.Activated:Connect(requestAttack)
skill.Activated:Connect(requestSkill)
dash.Activated:Connect(requestDash)
hero.Activated:Connect(requestHero)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		requestAttack()
	elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.ButtonX then
		requestSkill()
	elseif input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.ButtonB then
		requestDash()
	elseif input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonY then
		requestHero()
	end
end)

local function pulseHeader(color)
	local original = header.BackgroundColor3
	header.BackgroundColor3 = color
	TweenService:Create(header, TweenInfo.new(0.3), { BackgroundColor3 = original }):Play()
end

combatRemote.OnClientEvent:Connect(function(action, value, extra)
	if action == "WeaponEquipped" then
		objective.Text = touch and "Premi ATTACCA: sconfiggi 3 Spenti" or "Clic sinistro: sconfiggi 3 Spenti"
		showToast("RAGGIALAMA ALBA EQUIPAGGIATA", Color3.fromRGB(255, 201, 74))
	elseif action == "AttackFeedback" then
		if extra and extra > 0 then
			showToast(value == 3 and "COMBO! COLPO SPEZZAGUARDIA" or "COLPITO!", Color3.fromRGB(255, 233, 184))
			pulseHeader(Color3.fromRGB(113, 82, 48))
		end
	elseif action == "SkillFeedback" then
		showToast("RIFRAZIONE!", Color3.fromRGB(255, 95, 162))
	elseif action == "DashFeedback" then
		pulseHeader(Color3.fromRGB(38, 104, 122))
	elseif action == "DamageReceived" then
		showToast(string.format("-%d  SCHIVA!", value), Color3.fromRGB(255, 122, 47))
		pulseHeader(Color3.fromRGB(130, 55, 35))
	elseif action == "ArmorBlocked" then
		showToast("CORAZZA! DASH E COLPISCI DA DIETRO", Color3.fromRGB(255, 122, 47))
	elseif action == "BossTelegraph" then
		showToast("ONDA ARANCIONE • SALTA!", Color3.fromRGB(255, 122, 47))
	elseif action == "Reward" then
		showToast(string.format("+%d FRAMMENTI • %s SCONFITTO", value, string.upper(extra or "SPENTO")), Color3.fromRGB(127, 232, 196))
	elseif action == "HeroCharge" then
		local charge = math.clamp(value or 0, 0, 100)
		TweenService:Create(heroFill, TweenInfo.new(0.18, Enum.EasingStyle.Quint), { Size = UDim2.fromScale(charge / 100, 1) }):Play()
		heroText.Text = string.format("CARICA SOLARIS  %d%%", math.floor(charge))
	elseif action == "HeroReady" then
		heroReady = true
		hero.Active = true
		hero.BackgroundColor3 = Color3.fromRGB(255, 201, 74)
		hero.BackgroundTransparency = 0.02
		heroText.Text = touch and "SOLARIS PRONTO • PREMI HERO" or "SOLARIS PRONTO • PREMI E"
		showToast("SOLARIS È PRONTO!", Color3.fromRGB(255, 201, 74))
	elseif action == "HeroSummoned" then
		title.Text = "SOLARIS SCATENATO"
		objective.Text = string.upper(value or "UN HERO") .. " HA RISVEGLIATO SOLARIS"
		showToast("RISVEGLIO COLOSSALE!", Color3.fromRGB(255, 240, 184))
		task.delay(8, function()
			if title.Parent then title.Text = "PRISMORA: HERO RUSH" end
		end)
	elseif action == "RunModifier" then
		showToast("MODIFICATORE • " .. string.upper(value or "SCONOSCIUTO"), Color3.fromRGB(176, 118, 255))
	elseif action == "RunPhase" then
		title.Text = "INCURSIONE PRISMORA"
		objective.Text = value or "COMBATTI"
		if extra and extra ~= "NESSUNO" then
			showToast(string.upper(extra), Color3.fromRGB(176, 118, 255))
		end
	elseif action == "RunComplete" then
		title.Text = "INCURSIONE COMPLETATA"
		objective.Text = "RICOMPENSA OTTENUTA • NUOVA RUN TRA 8s"
		showToast("VITTORIA! TUTTI RICEVONO FRAMMENTI", Color3.fromRGB(127, 232, 196))
	end
end)

questRemote.OnClientEvent:Connect(function(action, value)
	if action == "CrystalCollected" then
		pulseHeader(Color3.fromRGB(87, 80, 133))
	elseif action == "HeroUnlocked" then
		title.Text = "HERO RISVEGLIATO"
		objective.Text = "Ora affronta il Monolite e conquista frammenti"
		showToast("RISVEGLIO PRISMATICO!", Color3.fromRGB(255, 95, 162))
	end
end)

task.spawn(function()
	local stats = player:WaitForChild("leaderstats", 20)
	local defeats = stats and stats:WaitForChild("Sconfitte", 10)
	local fragments = stats and stats:WaitForChild("Frammenti", 10)
	if defeats then
		local function updateMission()
			if defeats.Value < 3 then
				objective.Text = string.format("Sconfiggi gli Spenti  •  %d/3", defeats.Value)
			elseif defeats.Value < 5 then
				objective.Text = "Usa POTERE e DASH contro il Guscione"
			else
				objective.Text = string.format("Affronta il MONOLITE  •  %d frammenti", fragments and fragments.Value or 0)
			end
		end
		updateMission()
		defeats:GetPropertyChangedSignal("Value"):Connect(updateMission)
		if fragments then fragments:GetPropertyChangedSignal("Value"):Connect(updateMission) end
	end
end)

task.delay(0.8, function()
	showToast(touch and "MUOVITI • ATTACCA • DASH" or "WASD • LMB ATTACCA • Q POTERE • SHIFT DASH", Color3.fromRGB(70, 224, 255))
end)
