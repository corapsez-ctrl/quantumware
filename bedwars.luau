-- One file. Host it on GitHub, then run:
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/YOU/REPO/main/bedwars.luau"))()
-- Right Shift opens and closes the menu.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")
local VirtualInput
pcall(function()
	VirtualInput = game:GetService("VirtualInputManager")
end)

local localPlayer = Players.LocalPlayer
local FLY_SPEED = 70
local KA_RANGE = 18
local SHOOT_RANGE = 220
local NUKER_RANGE = 10

local TEAM_COLORS = {
	red = Color3.fromRGB(255, 75, 75),
	blue = Color3.fromRGB(70, 145, 255),
	green = Color3.fromRGB(80, 220, 100),
	yellow = Color3.fromRGB(255, 220, 70),
	orange = Color3.fromRGB(255, 155, 45),
	pink = Color3.fromRGB(255, 125, 195),
	cyan = Color3.fromRGB(70, 230, 230),
	white = Color3.fromRGB(245, 245, 245),
}

local KIT_ALIASES = {
	["auto cait"] = { "cait", "caitlyn" },
	["auto nyx"] = { "nyx" },
	["auto elder"] = { "elder" },
	["auto silas"] = { "silas" },
	["auto kadia"] = { "kaida", "kadia" },
	["auto raven"] = { "raven" },
	["auto void night"] = { "void" },
	["auto hep"] = { "heph", "hep" },
	["auto adetunde"] = { "adetunde" },
	["auto bounty hunter"] = { "bounty" },
	["auto lucia"] = { "lucia" },
	["auto abbadon"] = { "abaddon", "abbadon" },
	["auto fortuna"] = { "fortuna" },
	["auto davey"] = { "davey" },
	["auto grim"] = { "grim" },
	["auto kalliyah"] = { "kaliyah", "kalliyah" },
	["auto builder"] = { "builder" },
	["auto fish"] = { "fish" },
	["auto krystal"] = { "krystal", "crystal" },
}

local registry = {}
local order = {}
local espFolder = Instance.new("Folder")
espFolder.Name = "QuantumwareEsp"
pcall(function()
	espFolder.Parent = game:GetService("CoreGui")
end)
if espFolder.Parent == nil then
	espFolder.Parent = localPlayer:WaitForChild("PlayerGui")
end

local playerEsp = {}
local bedEsp = {}
local knownBeds = {}
local bedScan = 0
local savedMaterials = {}
local savedDecals = {}
local textureConn
local skinColor = Color3.fromRGB(255, 186, 122)
local flyMover
local flyAttach
local wasJumping = false
local savedWalkSpeed
local shaderEffects = {}

local function register(name, interval, tickFn, onEnable, onDisable)
	registry[name] = {
		name = name,
		enabled = false,
		interval = interval,
		acc = 0,
		tick = tickFn,
		onEnable = onEnable,
		onDisable = onDisable,
	}
	table.insert(order, name)
end

local function enabled(name)
	local mod = registry[name]
	return mod ~= nil and mod.enabled
end

local function character()
	return localPlayer.Character
end

local function rootPart()
	local char = character()
	local root = char and char:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then
		return root
	end
	return nil
end

local function humanoid()
	local char = character()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function teamId(inst)
	local attr = inst:GetAttribute("Team")
	if attr ~= nil then
		return tostring(attr)
	end
	if inst:IsA("Player") then
		if inst.Team then
			return inst.Team.Name
		end
		if inst.TeamColor then
			return inst.TeamColor.Name
		end
	end
	return nil
end

local function sameTeam(inst)
	local mine = teamId(localPlayer)
	local theirs = teamId(inst)
	return mine ~= nil and theirs ~= nil and string.lower(mine) == string.lower(theirs)
end

local function teamColor(inst)
	local id = teamId(inst)
	if id and TEAM_COLORS[string.lower(id)] then
		return TEAM_COLORS[string.lower(id)]
	end
	if inst:IsA("Player") and inst.Team then
		return inst.Team.TeamColor.Color
	end
	return Color3.fromRGB(255, 80, 80)
end

local function kitOf(player)
	local kit = player:GetAttribute("Kit") or player:GetAttribute("EquippedKit") or player:GetAttribute("kit")
	if kit ~= nil and tostring(kit) ~= "" then
		return tostring(kit)
	end
	local char = player.Character
	local value = char and (char:FindFirstChild("Kit") or char:FindFirstChild("EquippedKit"))
	if value and value:IsA("StringValue") then
		return value.Value
	end
	return ""
end

local function kitMatches(name)
	local kit = string.lower(kitOf(localPlayer))
	if kit == "" then
		return false
	end
	if name == "auto kit" then
		return true
	end
	local keys = KIT_ALIASES[name]
	if not keys then
		return false
	end
	for _, key in ipairs(keys) do
		if string.find(kit, key, 1, true) then
			return true
		end
	end
	return false
end

local function click(button)
	button = button or 0
	local ok = pcall(function()
		if button == 0 and type(mouse1click) == "function" then
			mouse1click()
			return
		end
		if button == 1 and type(mouse2click) == "function" then
			mouse2click()
			return
		end
		local pos = UserInputService:GetMouseLocation()
		VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, button, true, game, 0)
		VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, button, false, game, 0)
	end)
	return ok
end

local function aimAt(worldPos, silent)
	local cam = workspace.CurrentCamera
	if not cam then
		return
	end
	local goal = CFrame.lookAt(cam.CFrame.Position, worldPos)
	if silent then
		local old = cam.CFrame
		cam.CFrame = goal
		click(0)
		cam.CFrame = old
	elseif enabled("aim assist") then
		cam.CFrame = cam.CFrame:Lerp(goal, 0.4)
	else
		cam.CFrame = goal
	end
end

local function nearestEnemy(maxDist)
	local mine = rootPart()
	if not mine then
		return nil
	end
	local best, bestRoot, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and not sameTeam(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and root:IsA("BasePart") and hum and hum.Health > 0 then
				local dist = (root.Position - mine.Position).Magnitude
				if dist <= maxDist and (not bestDist or dist < bestDist) then
					best, bestRoot, bestDist = player, root, dist
				end
			end
		end
	end
	return best, bestRoot, bestDist
end

local function aimPoint(targetRoot, dist)
	local pos = targetRoot.Position + Vector3.new(0, 1.5, 0)
	if enabled("projectile aimbot") then
		local speed = 180
		pos += targetRoot.AssemblyLinearVelocity * (dist / speed)
	end
	return pos
end

local function attackNearest(maxDist)
	local _, targetRoot, dist = nearestEnemy(maxDist)
	if not targetRoot then
		return false
	end
	local silent = enabled("silent aim")
	aimAt(aimPoint(targetRoot, dist), silent)
	if not silent then
		click(0)
	end
	return true
end

local function bedParts()
	local found = {}
	local list = {}
	local function add(inst)
		if found[inst] or sameTeam(inst) then
			return
		end
		if inst:GetAttribute("Alive") == false or inst:GetAttribute("Broken") == true then
			return
		end
		found[inst] = true
		table.insert(list, inst)
	end
	for _, tag in ipairs({ "bed", "Bed" }) do
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			add(inst)
		end
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("Model") and string.find(string.lower(inst.Name), "bed", 1, true) then
			add(inst)
		end
	end
	return list
end

local function instancePos(inst)
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	local part = inst:FindFirstChildWhichIsA("BasePart", true)
	return part and part.Position
end

local function nearestEnemyBed()
	local mine = rootPart()
	if not mine then
		return nil
	end
	local best, bestPos, bestDist
	for _, bed in ipairs(knownBeds) do
		if bed.Parent then
			local pos = instancePos(bed)
			if pos then
				local dist = (pos - mine.Position).Magnitude
				if not bestDist or dist < bestDist then
					best, bestPos, bestDist = bed, pos, dist
				end
			end
		end
	end
	return best, bestPos, bestDist
end

local function makeHighlight(adornee, color)
	local highlight = Instance.new("Highlight")
	highlight.Adornee = adornee
	highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	highlight.FillTransparency = 0.55
	highlight.OutlineTransparency = 0
	highlight.FillColor = color
	highlight.OutlineColor = color
	highlight.Parent = espFolder
	return highlight
end

local function makeLabel(adornee)
	local billboard = Instance.new("BillboardGui")
	billboard.AlwaysOnTop = true
	billboard.Size = UDim2.fromOffset(220, 50)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.LightInfluence = 0
	billboard.Adornee = adornee
	billboard.Parent = espFolder
	local text = Instance.new("TextLabel")
	text.Name = "Text"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamBold
	text.TextSize = 14
	text.TextStrokeTransparency = 0.35
	text.Parent = billboard
	return billboard
end

local function setLabel(billboard, message, color)
	local text = billboard:FindFirstChild("Text")
	if text and text:IsA("TextLabel") then
		text.Text = message
		text.TextColor3 = color
	end
end

local function clearMap(map)
	for key, items in pairs(map) do
		if items.highlight then
			items.highlight:Destroy()
		end
		if items.label then
			items.label:Destroy()
		end
		map[key] = nil
	end
end

local function ensureMover()
	local root = rootPart()
	if not root then
		return nil
	end
	if flyMover and flyMover.Parent and flyAttach and flyAttach.Parent then
		return flyMover
	end
	if flyMover then
		flyMover:Destroy()
	end
	if flyAttach then
		flyAttach:Destroy()
	end
	flyAttach = Instance.new("Attachment")
	flyAttach.Name = "QuantumwareFly"
	flyAttach.Parent = root
	flyMover = Instance.new("LinearVelocity")
	flyMover.Attachment0 = flyAttach
	flyMover.MaxForce = math.huge
	flyMover.VectorVelocity = Vector3.zero
	flyMover.RelativeTo = Enum.ActuatorRelativeTo.World
	flyMover.Parent = root
	return flyMover
end

local function stopFly()
	if flyMover then
		flyMover:Destroy()
		flyMover = nil
	end
	if flyAttach then
		flyAttach:Destroy()
		flyAttach = nil
	end
	local hum = humanoid()
	if hum then
		hum.PlatformStand = false
	end
end

local function flyTick()
	if not (enabled("fly") or enabled("infinite fly")) then
		return
	end
	local hum = humanoid()
	local mover = ensureMover()
	local cam = workspace.CurrentCamera
	if not hum or not mover or not cam then
		return
	end
	hum.PlatformStand = true
	local move = Vector3.zero
	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		move += look
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		move -= look
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		move += right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		move -= right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		move += Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		move -= Vector3.yAxis
	end
	if move.Magnitude > 0 then
		move = move.Unit * FLY_SPEED
	end
	mover.VectorVelocity = move
	if enabled("infinite fly") and mover.Parent == nil then
		ensureMover()
	end
end

local function stripPart(inst)
	if inst:IsA("BasePart") and savedMaterials[inst] == nil then
		savedMaterials[inst] = inst.Material
		inst.Material = Enum.Material.SmoothPlastic
		if inst:IsA("MeshPart") then
			pcall(function()
				inst.TextureID = ""
			end)
		end
	elseif (inst:IsA("Decal") or inst:IsA("Texture")) and savedDecals[inst] == nil then
		savedDecals[inst] = inst.Transparency
		inst.Transparency = 1
	elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") or inst:IsA("Smoke") or inst:IsA("Fire") or inst:IsA("Sparkles") then
		inst.Enabled = false
	end
end

local function restoreTextures()
	for inst, material in pairs(savedMaterials) do
		if inst.Parent and inst:IsA("BasePart") then
			inst.Material = material
		end
	end
	for inst, transparency in pairs(savedDecals) do
		if inst.Parent then
			inst.Transparency = transparency
		end
	end
	savedMaterials = {}
	savedDecals = {}
	if textureConn then
		textureConn:Disconnect()
		textureConn = nil
	end
end

local function applySkin()
	local char = character()
	if not char then
		return
	end
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = skinColor
		end
	end
	local body = char:FindFirstChildOfClass("BodyColors")
	if body then
		body.HeadColor3 = skinColor
		body.TorsoColor3 = skinColor
		body.LeftArmColor3 = skinColor
		body.RightArmColor3 = skinColor
		body.LeftLegColor3 = skinColor
		body.RightLegColor3 = skinColor
	end
end

local function firePrompt(prompt)
	pcall(function()
		if type(fireproximityprompt) == "function" then
			fireproximityprompt(prompt, 0)
			return
		end
		prompt:InputHoldBegin()
		task.delay(prompt.HoldDuration, function()
			if prompt.Parent then
				prompt:InputHoldEnd()
			end
		end)
	end)
end

local function nearbyPrompts(needles)
	local root = rootPart()
	if not root then
		return
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then
			local holder = inst.Parent
			local pos = instancePos(holder)
			local label = string.lower(inst.ActionText .. " " .. inst.ObjectText .. " " .. holder.Name)
			local match = #needles == 0
			for _, needle in ipairs(needles) do
				if string.find(label, needle, 1, true) then
					match = true
					break
				end
			end
			if match and pos and (pos - root.Position).Magnitude <= 18 then
				firePrompt(inst)
			end
		end
	end
end

local function placeAround()
	local root = rootPart()
	local cam = workspace.CurrentCamera
	if not root or not cam then
		return
	end
	local old = cam.CFrame
	local spots = {
		root.Position + root.CFrame.LookVector * 4,
		root.Position - root.CFrame.LookVector * 4,
		root.Position + root.CFrame.RightVector * 4,
		root.Position - root.CFrame.RightVector * 4,
		root.Position + Vector3.new(0, -3, 0),
	}
	for _, spot in ipairs(spots) do
		cam.CFrame = CFrame.lookAt(root.Position + Vector3.new(0, 2, 0), spot)
		click(1)
	end
	cam.CFrame = old
end

local function updatePlayers()
	local showKit = enabled("kit esp") or enabled("kit render") or enabled("player esp")
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local mine = rootPart()
		if player == localPlayer or sameTeam(player) or not root or not hum or hum.Health <= 0 or not mine then
			local old = playerEsp[player]
			if old then
				if old.highlight then old.highlight:Destroy() end
				if old.label then old.label:Destroy() end
				playerEsp[player] = nil
			end
		else
			local dist = (root.Position - mine.Position).Magnitude
			local color = if enabled("kit render") and kitOf(player) ~= "" then Color3.fromHSV((#kitOf(player) % 12) / 12, 0.7, 1) else teamColor(player)
			local entry = playerEsp[player]
			if not entry then
				entry = {}
				playerEsp[player] = entry
			end
			if not entry.highlight then
				entry.highlight = makeHighlight(char, color)
			end
			entry.highlight.Adornee = char
			entry.highlight.FillColor = color
			entry.highlight.OutlineColor = color
			local head = char:FindFirstChild("Head")
			local adornee = if head and head:IsA("BasePart") then head else root
			if not entry.label then
				entry.label = makeLabel(adornee)
			end
			entry.label.Adornee = adornee
			local kit = kitOf(player)
			local kitLine = if showKit and kit ~= "" then "\n" .. kit else ""
			setLabel(entry.label, string.format("%s\n%d studs   %d HP%s", player.DisplayName, math.floor(dist + 0.5), math.floor(hum.Health + 0.5), kitLine), color)
		end
	end
end

register("player esp", 0.1, updatePlayers, nil, function()
	if not enabled("kit esp") and not enabled("kit render") then
		clearMap(playerEsp)
	end
end)

register("bed esp", 0.2, function()
	for _, bed in ipairs(knownBeds) do
		local pos = bed.Parent and instancePos(bed)
		local mine = rootPart()
		if not pos or not mine or sameTeam(bed) then
			local old = bedEsp[bed]
			if old then
				if old.highlight then old.highlight:Destroy() end
				if old.label then old.label:Destroy() end
				bedEsp[bed] = nil
			end
		else
			local adornee = if bed:IsA("Model") or bed:IsA("BasePart") then bed else bed:FindFirstChildWhichIsA("BasePart", true)
			if adornee then
				local color = teamColor(bed)
				local entry = bedEsp[bed]
				if not entry then
					entry = {}
					bedEsp[bed] = entry
				end
				if not entry.highlight then
					entry.highlight = makeHighlight(adornee, color)
				end
				entry.highlight.Adornee = adornee
				entry.highlight.FillColor = color
				entry.highlight.OutlineColor = color
				if not entry.label then
					entry.label = makeLabel(adornee)
				end
				entry.label.Adornee = adornee
				setLabel(entry.label, string.format("%s bed\n%d studs", teamId(bed) or "Enemy", math.floor((pos - mine.Position).Magnitude + 0.5)), color)
			end
		end
	end
end, nil, function()
	clearMap(bedEsp)
end)

register("kit esp", 0.1, updatePlayers, nil, function()
	if not enabled("player esp") and not enabled("kit render") then
		clearMap(playerEsp)
	end
end)
register("kit render", 0.1, updatePlayers, nil, function()
	if not enabled("player esp") and not enabled("kit esp") then
		clearMap(playerEsp)
	end
end)

register("skinchanger", 0.4, applySkin, applySkin, function()
	skinColor = Color3.fromRGB(255, 186, 122)
end)

register("fast hits", 1, function() end)

register("fps booster", 2, function()
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	end)
	Lighting.GlobalShadows = false
	Lighting.FogEnd = 100000
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			inst.Enabled = false
		end
	end
end, nil, function()
	pcall(function()
		settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
	end)
	Lighting.GlobalShadows = true
end)

register("long jumps", 0, function()
	local hum = humanoid()
	local root = rootPart()
	if not hum or not root then
		return
	end
	local jumping = hum:GetState() == Enum.HumanoidStateType.Jumping
	if jumping and not wasJumping then
		local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if flat.Magnitude > 0 then
			root.AssemblyLinearVelocity += flat.Unit * 75
		end
	end
	wasJumping = jumping
end)

register("no fall", 0, function()
	local root = rootPart()
	local hum = humanoid()
	if not root or not hum then
		return
	end
	local velocity = root.AssemblyLinearVelocity
	local state = hum:GetState()
	if velocity.Y < -35 and (state == Enum.HumanoidStateType.Freefall or state == Enum.HumanoidStateType.FallingDown) then
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -10, 0))
		if hit then
			root.AssemblyLinearVelocity = Vector3.new(velocity.X, math.max(velocity.Y, -12), velocity.Z)
		end
	end
end)

register("ka", 0.12, function()
	attackNearest(KA_RANGE)
end)

register("nuker", 0.08, function()
	local root = rootPart()
	local char = character()
	if not root or not char then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local parts = workspace:GetPartBoundsInRadius(root.Position, NUKER_RANGE, params)
	local best, bestDist
	for _, part in ipairs(parts) do
		if part.Size.Magnitude < 40 then
			local dist = (part.Position - root.Position).Magnitude
			if not bestDist or dist < bestDist then
				best, bestDist = part, dist
			end
		end
	end
	if best then
		aimAt(best.Position, enabled("silent aim"))
		if not enabled("silent aim") then
			click(0)
		end
	end
end)

register("autoshoot", 0.15, function()
	attackNearest(SHOOT_RANGE)
end)

register("projectile aimbot", 1, function() end)
register("silent aim", 1, function() end)
register("aim assist", 0.03, function()
	local _, targetRoot, dist = nearestEnemy(SHOOT_RANGE)
	if targetRoot then
		aimAt(aimPoint(targetRoot, dist), false)
	end
end)

register("fly", 0, flyTick, nil, function()
	if not enabled("infinite fly") then
		stopFly()
	end
end)
register("infinite fly", 0, flyTick, nil, function()
	if not enabled("fly") then
		stopFly()
	end
end)

register("velocity", 0, function()
	local hum = humanoid()
	local root = rootPart()
	if not hum or not root then
		return
	end
	if not savedWalkSpeed then
		savedWalkSpeed = hum.WalkSpeed
	end
	hum.WalkSpeed = 32
	local velocity = root.AssemblyLinearVelocity
	local flat = Vector3.new(velocity.X, 0, velocity.Z)
	if flat.Magnitude > 2 then
		local sped = flat.Unit * 32
		root.AssemblyLinearVelocity = Vector3.new(sped.X, velocity.Y, sped.Z)
	end
end, nil, function()
	local hum = humanoid()
	if hum and savedWalkSpeed then
		hum.WalkSpeed = savedWalkSpeed
	end
	savedWalkSpeed = nil
end)

register("shaders", 1, function() end, function()
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "QuantumwareColor"
	cc.Saturation = 0.25
	cc.Contrast = 0.12
	cc.TintColor = Color3.fromRGB(255, 230, 210)
	cc.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Name = "QuantumwareBloom"
	bloom.Intensity = 0.45
	bloom.Size = 18
	bloom.Threshold = 0.8
	bloom.Parent = Lighting
	shaderEffects = { cc, bloom }
end, function()
	for _, effect in ipairs(shaderEffects) do
		effect:Destroy()
	end
	shaderEffects = {}
end)

register("desync", 0.2, function()
	local root = rootPart()
	if not root then
		return
	end
	local cf = root.CFrame
	root.CFrame = cf * CFrame.new(0, 0, -8)
	task.defer(function()
		if root.Parent then
			root.CFrame = cf
		end
	end)
end)

register("autoclicker", 0.08, function()
	click(0)
end)

local function kitTick(name, alsoPlace)
	if not kitMatches(name) then
		return
	end
	if not attackNearest(KA_RANGE) and alsoPlace then
		placeAround()
	elseif alsoPlace then
		placeAround()
	end
end

register("auto kit", 0.2, function()
	kitTick("auto kit", false)
end)
for _, kitName in ipairs({
	"auto cait",
	"auto nyx",
	"auto elder",
	"auto silas",
	"auto kadia",
	"auto raven",
	"auto void night",
	"auto hep",
	"auto adetunde",
	"auto bounty hunter",
	"auto lucia",
	"auto abbadon",
	"auto fortuna",
	"auto davey",
	"auto grim",
	"auto kalliyah",
	"auto builder",
	"auto fish",
	"auto krystal",
}) do
	local place = kitName == "auto builder"
	register(kitName, 0.2, function()
		kitTick(kitName, place)
	end)
end

register("auto win", 0.15, function()
	local _, pos = nearestEnemyBed()
	if not pos then
		return
	end
	aimAt(pos, enabled("silent aim"))
	if not enabled("silent aim") then
		click(0)
	end
end)

register("no texture", 1, function() end, function()
	for _, inst in ipairs(workspace:GetDescendants()) do
		stripPart(inst)
	end
	textureConn = workspace.DescendantAdded:Connect(stripPart)
end, restoreTextures)

register("block in", 0.35, placeAround)
register("chest steal", 0.4, function()
	nearbyPrompts({ "chest", "loot", "open" })
end)
register("auto bank", 0.5, function()
	nearbyPrompts({ "bank", "shop", "deposit", "upgrade", "team" })
end)
register("fast place", 0.05, function()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		click(1)
	end
end)

register("anti lasso", 0.15, function()
	local char = character()
	if not char then
		return
	end
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("RopeConstraint") then
			inst.Length = 0
			inst.Visible = false
		elseif inst:IsA("RodConstraint") then
			pcall(function()
				inst.Length = 0
			end)
		end
	end
end)

register("auto lasso", 0.25, function()
	local kit = string.lower(kitOf(localPlayer))
	local tool = character() and character():FindFirstChildOfClass("Tool")
	local toolName = tool and string.lower(tool.Name) or ""
	if string.find(kit, "lasso", 1, true) or string.find(toolName, "lasso", 1, true) then
		attackNearest(40)
	end
end)

register("infinite jumps", 0, function() end)
register("high jump", 0, function()
	local hum = humanoid()
	if not hum then
		return
	end
	hum.UseJumpPower = true
	hum.JumpPower = 95
end, nil, function()
	local hum = humanoid()
	if hum then
		hum.JumpPower = 50
	end
end)

UserInputService.JumpRequest:Connect(function()
	if not enabled("infinite jumps") then
		return
	end
	local hum = humanoid()
	if hum then
		hum:ChangeState(Enum.HumanoidStateType.Jumping)
	end
end)

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.4)
	if enabled("skinchanger") then
		applySkin()
	end
	stopFly()
end)

RunService.Heartbeat:Connect(function(dt)
	bedScan += dt
	if bedScan >= 1 then
		bedScan = 0
		knownBeds = bedParts()
	end
	local fast = enabled("fast hits")
	for _, name in ipairs(order) do
		local mod = registry[name]
		if mod.enabled and mod.tick then
			local interval = mod.interval
			if fast and (name == "ka" or name == "autoclicker" or name == "autoshoot" or name == "nuker") then
				interval = math.min(interval, 0.04)
			end
			mod.acc += dt
			if mod.acc >= interval then
				mod.acc = 0
				pcall(mod.tick)
			end
		end
	end
end)

local function guiParent()
	local ok, hidden = pcall(function()
		return gethui()
	end)
	if ok and typeof(hidden) == "Instance" then
		return hidden
	end
	local coreOk, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if coreOk and core then
		return core
	end
	return localPlayer:WaitForChild("PlayerGui")
end

local gui = Instance.new("ScreenGui")
gui.Name = "Quantumware"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 100000
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = true
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(gui)
	elseif protectgui then
		protectgui(gui)
	end
end)
gui.Parent = guiParent()
print("Quantumware loaded")
pcall(function()
	game:GetService("StarterGui"):SetCore("SendNotification", {
		Title = "Quantumware",
		Text = "Menu is open. Right Shift hides it.",
		Duration = 5,
	})
end)

local frame = Instance.new("Frame")
frame.Size = UDim2.fromOffset(280, 460)
frame.Position = UDim2.new(0, 24, 0.5, -230)
frame.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
frame.BorderSizePixel = 0
frame.Parent = gui
Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -16, 0, 32)
title.Position = UDim2.fromOffset(8, 4)
title.Font = Enum.Font.GothamBold
title.TextSize = 16
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Text = "Quantumware"
title.Parent = frame

local scroll = Instance.new("ScrollingFrame")
scroll.BackgroundTransparency = 1
scroll.Position = UDim2.fromOffset(8, 40)
scroll.Size = UDim2.new(1, -16, 1, -48)
scroll.CanvasSize = UDim2.fromOffset(0, #order * 28)
scroll.ScrollBarThickness = 4
scroll.Parent = frame

local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 4)
list.Parent = scroll

local buttons = {}
local function refresh(name)
	local button = buttons[name]
	if not button then
		return
	end
	local on = registry[name].enabled
	button.BackgroundColor3 = on and Color3.fromRGB(70, 150, 90) or Color3.fromRGB(36, 36, 42)
	button.Text = name .. (on and "  on" or "  off")
end

for _, name in ipairs(order) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(1, -8, 0, 24)
	button.BackgroundColor3 = Color3.fromRGB(36, 36, 42)
	button.BorderSizePixel = 0
	button.Font = Enum.Font.Gotham
	button.TextSize = 13
	button.TextColor3 = Color3.fromRGB(235, 235, 235)
	button.TextXAlignment = Enum.TextXAlignment.Left
	button.Text = "  " .. name .. "  off"
	button.Parent = scroll
	Instance.new("UICorner", button).CornerRadius = UDim.new(0, 4)
	buttons[name] = button
	button.MouseButton1Click:Connect(function()
		local mod = registry[name]
		mod.enabled = not mod.enabled
		if mod.enabled and mod.onEnable then
			pcall(mod.onEnable)
		elseif not mod.enabled and mod.onDisable then
			pcall(mod.onDisable)
		end
		refresh(name)
	end)
	refresh(name)
end

local dragging = false
local dragStart, startPos
title.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = frame.Position
	end
end)
UserInputService.InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)
UserInputService.InputChanged:Connect(function(input)
	if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
		local delta = input.Position - dragStart
		frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.KeyCode ~= Enum.KeyCode.RightShift then
		return
	end
	frame.Visible = not frame.Visible
end)
