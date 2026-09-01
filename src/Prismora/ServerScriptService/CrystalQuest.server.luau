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
	Color3.fromRGB(108, 250, 255),
	Color3.fromRGB(255, 112, 220),
	Color3.fromRGB(176, 118, 255),
	Color3.fromRGB(255, 207, 102),
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

local center = spawn.Position
local ZONES = {
	Vector3.new(0, 0, 0),
	Vector3.new(155, 0, 4),
	Vector3.new(-150, 0, -8),
	Vector3.new(4, 0, -132),
	Vector3.new(12, 0, 145),
}

-- Crystals now lead players through every district instead of clustering next
-- to the spawn. There are enough nearby for a quick first reward, while a full
-- Hero awakening requires real exploration of the larger world.
for index = 1, 30 do
	local zone = ZONES[((index - 1) % #ZONES) + 1]
	local localIndex = math.floor((index - 1) / #ZONES)
	local angle = math.rad((localIndex * 61) + (((index - 1) % #ZONES) * 17))
	local radius = 16 + ((localIndex % 3) * 9)
	local zoneCenter = center + zone
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

	local light = Instance.new("PointLight")
	light.Color = crystal.Color
	light.Brightness = 0.65
	light.Range = 12
	light.Parent = crystal

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
