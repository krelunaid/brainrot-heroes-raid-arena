local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

repeat task.wait(0.1) until workspace:GetAttribute("PrismoraReady")

local world = workspace:WaitForChild("PrismoraWorld")
local remote = ReplicatedStorage:WaitForChild("PrismoraEvent")
local spawn = workspace:WaitForChild("PrismoraSpawn")

local crystalFolder = Instance.new("Folder")
crystalFolder.Name = "PrismoraCrystals"
crystalFolder.Parent = workspace

local COLORS = {
	Color3.fromRGB(255, 201, 74),
	Color3.fromRGB(255, 218, 104),
	Color3.fromRGB(255, 190, 58),
}

local function getCrystals(player)
	local stats = player:FindFirstChild("leaderstats")
	return stats and stats:FindFirstChild("Cristalli")
end

local function celebrate(player)
	if player:GetAttribute("PrismoraHero") then
		return
	end
	player:SetAttribute("PrismoraHero", true)
	remote:FireClient(player, "HeroUnlocked")

	local character = player.Character
	if character then
		local highlight = Instance.new("Highlight")
		highlight.Name = "PrismoraHeroAura"
		highlight.FillColor = Color3.fromRGB(107, 255, 234)
		highlight.FillTransparency = 0.55
		highlight.OutlineColor = Color3.fromRGB(255, 118, 222)
		highlight.OutlineTransparency = 0.08
		highlight.Parent = character
	end
end

local function collect(crystal, player)
	if not crystal:GetAttribute("Active") then
		return
	end
	crystal:SetAttribute("Active", false)
	crystal.CanTouch = false

	local crystals = getCrystals(player)
	if crystals then
		crystals.Value += 1
		remote:FireClient(player, "CrystalCollected", crystals.Value)
		if crystals.Value >= 10 then
			celebrate(player)
		end
	end

	TweenService:Create(
		crystal,
		TweenInfo.new(0.28, Enum.EasingStyle.Back, Enum.EasingDirection.In),
		{ Size = Vector3.new(0.1, 0.1, 0.1), Transparency = 1 }
	):Play()

	task.delay(12, function()
		if crystal.Parent then
			crystal.Size = Vector3.new(1.6, 4.2, 1.6)
			crystal.Transparency = 0.08
			crystal.CanTouch = true
			crystal:SetAttribute("Active", true)
		end
	end)
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
rayParams.FilterDescendantsInstances = { world }

local capitalCenter = workspace:GetAttribute("PrismoraCapitalCenter") or spawn.Position
local arenaCenter = workspace:GetAttribute("PrismoraArenaCenter") or (capitalCenter + Vector3.new(0, 0, -330))
local ZONES = {
	capitalCenter + Vector3.new(-18, 0, 34),
	capitalCenter + Vector3.new(18, 0, 34),
	capitalCenter + Vector3.new(-44, 0, -34),
	arenaCenter + Vector3.new(-52, 0, -52),
	arenaCenter + Vector3.new(8, 0, 12),
	arenaCenter + Vector3.new(58, 0, 58),
}

-- Gold always means reward in the new empire. Crystals live in the dense
-- capital ring and inside the expedition arena; none lead to empty islands.
for index = 1, 30 do
	local zone = ZONES[((index - 1) % #ZONES) + 1]
	local localIndex = math.floor((index - 1) / #ZONES)
	local angle = math.rad((localIndex * 61) + (((index - 1) % #ZONES) * 17))
	local radius = 7 + ((localIndex % 3) * 6)
	local zoneCenter = zone
	local probe = zoneCenter + Vector3.new(math.cos(angle) * radius, 110, math.sin(angle) * radius)
	local hit = workspace:Raycast(probe, Vector3.new(0, -150, 0), rayParams)
	local position = hit and (hit.Position + Vector3.new(0, 2.3, 0)) or (zoneCenter + Vector3.new(math.cos(angle) * radius, 2.3, math.sin(angle) * radius))

	local crystal = Instance.new("Part")
	crystal.Name = string.format("Crystal%02d", index)
	crystal.Anchored = true
	crystal.CanCollide = false
	crystal.CanTouch = true
	crystal.CanQuery = false
	crystal.Material = Enum.Material.Neon
	crystal.Color = COLORS[((index - 1) % #COLORS) + 1]
	crystal.Transparency = 0.08
	crystal.Size = Vector3.new(1.6, 4.2, 1.6)
	crystal.CFrame = CFrame.new(position) * CFrame.Angles(0, angle, math.rad(45))
	crystal:SetAttribute("PrismoraBaseCFrame", crystal.CFrame)
	crystal:SetAttribute("PrismoraAnimationPhase", index)
	crystal:SetAttribute("Active", true)
	crystal.Parent = crystalFolder

	if index <= 6 then
		local light = Instance.new("PointLight")
		light.Color = crystal.Color
		light.Brightness = 0.55
		light.Range = 8
		light.Shadows = false
		light.Parent = crystal
	end

	crystal.Touched:Connect(function(hitPart)
		local character = hitPart:FindFirstAncestorOfClass("Model")
		local player = character and Players:GetPlayerFromCharacter(character)
		if player then
			collect(crystal, player)
		end
	end)

end

local function setupPlayer(player)
	local leaderstats = player:FindFirstChild("leaderstats") or Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local crystals = leaderstats:FindFirstChild("Cristalli") or Instance.new("IntValue")
	crystals.Name = "Cristalli"
	crystals.Parent = leaderstats

	local fragments = leaderstats:FindFirstChild("Frammenti") or Instance.new("IntValue")
	fragments.Name = "Frammenti"
	fragments.Parent = leaderstats

	local defeats = leaderstats:FindFirstChild("Sconfitte") or Instance.new("IntValue")
	defeats.Name = "Sconfitte"
	defeats.Parent = leaderstats

	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = 20
		humanoid.JumpHeight = 9
	end)
end

Players.PlayerAdded:Connect(setupPlayer)
for _, player in Players:GetPlayers() do
	setupPlayer(player)
end
