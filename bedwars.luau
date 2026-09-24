-- Quantumware
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/corapsez-ctrl/quantumware/main/bedwars.luau"))()
-- Right Shift opens and closes the menu.

local cloneref = cloneref or function(obj)
	return obj
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local Lighting = cloneref(game:GetService("Lighting"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local HttpService = cloneref(game:GetService("HttpService"))
local TweenService = cloneref(game:GetService("TweenService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local VirtualInput
pcall(function()
	VirtualInput = cloneref(game:GetService("VirtualInputManager"))
end)

local localPlayer = Players.LocalPlayer
local camera = workspace.CurrentCamera

local Theme = {
	Bg = Color3.fromRGB(12, 12, 14),
	Panel = Color3.fromRGB(18, 18, 21),
	Row = Color3.fromRGB(22, 22, 26),
	RowHover = Color3.fromRGB(32, 32, 38),
	RowOn = Color3.fromRGB(36, 36, 42),
	Stroke = Color3.fromRGB(40, 40, 46),
	Text = Color3.fromRGB(232, 232, 236),
	Dim = Color3.fromRGB(150, 150, 158),
	Accent = Color3.fromRGB(255, 255, 255),
	Green = Color3.fromRGB(88, 190, 110),
}

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
	if coreOk then
		return core
	end
	return localPlayer:WaitForChild("PlayerGui")
end

local function protect(gui)
	pcall(function()
		if syn and syn.protect_gui then
			syn.protect_gui(gui)
		elseif protectgui then
			protectgui(gui)
		end
	end)
end

local function corner(parent, radius)
	local obj = Instance.new("UICorner")
	obj.CornerRadius = UDim.new(0, radius or 4)
	obj.Parent = parent
	return obj
end

local function pad(parent, l, t, r, b)
	local obj = Instance.new("UIPadding")
	obj.PaddingLeft = UDim.new(0, l or 8)
	obj.PaddingTop = UDim.new(0, t or 6)
	obj.PaddingRight = UDim.new(0, r or 8)
	obj.PaddingBottom = UDim.new(0, b or 6)
	obj.Parent = parent
	return obj
end

local function stroke(parent, color)
	local obj = Instance.new("UIStroke")
	obj.Color = color or Theme.Stroke
	obj.Thickness = 1
	obj.Transparency = 0.35
	obj.Parent = parent
	return obj
end

local function drag(handle, window)
	local held, origin, start
	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			held = true
			origin = input.Position
			start = window.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			held = false
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if held and input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - origin
			window.Position = UDim2.new(start.X.Scale, start.X.Offset + d.X, start.Y.Scale, start.Y.Offset + d.Y)
		end
	end)
end

local Connections = {}
local function track(conn)
	table.insert(Connections, conn)
	return conn
end

local function disconnectAll(list)
	for _, conn in ipairs(list) do
		pcall(function()
			if typeof(conn) == "RBXScriptConnection" then
				conn:Disconnect()
			elseif typeof(conn) == "Instance" then
				conn:Destroy()
			end
		end)
	end
	table.clear(list)
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Quantumware",
			Text = text,
			Duration = 4,
		})
	end)
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
end

local function humanoid()
	local char = character()
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function teamId(inst)
	if not inst then
		return
	end
	for _, key in ipairs({ "Team", "team", "TeamId" }) do
		local attr = inst:GetAttribute(key)
		if attr ~= nil then
			return string.lower(tostring(attr))
		end
	end
	if inst:IsA("Player") then
		if inst.Team then
			return string.lower(inst.Team.Name)
		end
		if inst.TeamColor then
			return string.lower(inst.TeamColor.Name)
		end
	end
end

local function sameTeam(inst)
	local a, b = teamId(localPlayer), teamId(inst)
	return a ~= nil and b ~= nil and a == b
end

local TEAM_COLORS = {
	red = Color3.fromRGB(255, 82, 82),
	blue = Color3.fromRGB(70, 150, 255),
	green = Color3.fromRGB(80, 220, 110),
	yellow = Color3.fromRGB(255, 220, 70),
	orange = Color3.fromRGB(255, 155, 45),
	pink = Color3.fromRGB(255, 125, 195),
	cyan = Color3.fromRGB(70, 230, 230),
	white = Color3.fromRGB(245, 245, 245),
	purple = Color3.fromRGB(170, 110, 255),
}

local function teamColor(inst)
	local id = teamId(inst)
	if id and TEAM_COLORS[id] then
		return TEAM_COLORS[id]
	end
	if inst and inst:IsA("Player") and inst.Team then
		return inst.Team.TeamColor.Color
	end
	return Color3.fromRGB(255, 80, 80)
end

local function kitOf(player)
	for _, key in ipairs({ "Kit", "EquippedKit", "kit", "SelectedKit" }) do
		local attr = player:GetAttribute(key)
		if attr ~= nil and tostring(attr) ~= "" then
			return tostring(attr)
		end
	end
	local char = player.Character
	if char then
		local value = char:FindFirstChild("Kit") or char:FindFirstChild("EquippedKit")
		if value and value:IsA("ValueBase") then
			return tostring(value.Value)
		end
	end
	return ""
end

local function click(button)
	button = button or 0
	pcall(function()
		if button == 0 and type(mouse1click) == "function" then
			mouse1click()
			return
		end
		if button == 1 and type(mouse2click) == "function" then
			mouse2click()
			return
		end
		if VirtualInput then
			local pos = UserInputService:GetMouseLocation()
			VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, button, true, game, 0)
			VirtualInput:SendMouseButtonEvent(pos.X, pos.Y, button, false, game, 0)
		end
	end)
end

local function lookAt(world)
	if camera then
		camera.CFrame = CFrame.lookAt(camera.CFrame.Position, world)
	end
end

local BW = {
	ok = false,
	controllers = {},
	client = nil,
	store = nil,
	attackRemote = nil,
}

local function safeRequire(inst)
	if not inst then
		return
	end
	local ok, result = pcall(require, inst)
	if ok then
		return result
	end
end

local function findChild(root, names)
	if not root then
		return
	end
	for _, name in ipairs(names) do
		local child = root:FindFirstChild(name)
		if child then
			return child
		end
	end
end

local function resolveBedwars()
	local knit
	local paths = {
		function()
			return ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src.Knit.KnitClient
		end,
		function()
			return ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src.KnitClient
		end,
		function()
			return ReplicatedStorage.rbxts_include.node_modules.knit.src.KnitClient
		end,
	}
	for _, get in ipairs(paths) do
		local ok, inst = pcall(get)
		if ok and inst then
			knit = safeRequire(inst)
			if knit then
				break
			end
		end
	end

	if type(getloadedmodules) == "function" and not knit then
		pcall(function()
			for _, module in ipairs(getloadedmodules()) do
				if string.find(string.lower(module.Name), "knitclient") then
					knit = safeRequire(module)
					if knit then
						break
					end
				end
			end
		end)
	end

	if knit then
		local controllers = knit.Controllers or (type(knit.GetController) == "function" and {})
		if type(debug) == "table" and debug.getupvalue and type(knit.GetController) == "function" then
			pcall(function()
				controllers = debug.getupvalue(knit.GetController, 1) or controllers
			end)
		end
		BW.controllers = controllers or {}
	end

	pcall(function()
		BW.client = require(ReplicatedStorage.TS.remotes).default.Client
	end)
	pcall(function()
		BW.store = require(localPlayer.PlayerScripts.TS.ui.store).ClientStore
	end)
	pcall(function()
		local sword = BW.controllers.SwordController
		if sword and sword.sendServerRequest and type(debug) == "table" and debug.getconstants then
			for _, value in ipairs(debug.getconstants(sword.sendServerRequest)) do
				if type(value) == "string" and string.find(value, "attack", 1, true) then
					BW.attackRemote = value
					break
				end
			end
		end
	end)

	BW.ok = next(BW.controllers) ~= nil or BW.client ~= nil
end

pcall(resolveBedwars)

local function controller(name)
	return BW.controllers[name]
end

local function storeHand()
	local ok, state = pcall(function()
		return BW.store:getState()
	end)
	if ok and state then
		return state.Inventory and state.Inventory.observedInventory and state.Inventory.observedInventory.inventory and state.Inventory.observedInventory.inventory.hand
			or state.hand
	end
end

local function swordInHand()
	local char = character()
	if char then
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then
			local name = string.lower(tool.Name)
			if string.find(name, "sword", 1, true) or string.find(name, "scythe", 1, true) or string.find(name, "dagger", 1, true) then
				return tool
			end
		end
	end
	local hand = storeHand()
	if type(hand) == "table" and hand.tool then
		return hand.tool
	end
	return char and char:FindFirstChildOfClass("Tool")
end

local function nearestEnemy(maxDist)
	local mine = rootPart()
	if not mine then
		return
	end
	local best, bestRoot, bestDist
	for _, player in ipairs(Players:GetPlayers()) do
		if player ~= localPlayer and not sameTeam(player) then
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			if root and hum and hum.Health > 0 then
				local dist = (root.Position - mine.Position).Magnitude
				if dist <= maxDist and (not bestDist or dist < bestDist) then
					best, bestRoot, bestDist = player, root, dist
				end
			end
		end
	end
	return best, bestRoot, bestDist
end

local function canSee(part)
	local origin = camera and camera.CFrame.Position or (rootPart() and rootPart().Position)
	if not origin then
		return true
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character() }
	local hit = workspace:Raycast(origin, part.Position - origin, params)
	return not hit or hit.Instance:IsDescendantOf(part.Parent)
end

local function sendAttack(target, targetRoot)
	local sword = controller("SwordController")
	if sword then
		if type(sword.swingSwordAtMouse) == "function" then
			pcall(function()
				sword:swingSwordAtMouse()
			end)
		end
		if BW.client and BW.attackRemote then
			pcall(function()
				BW.client:Get(BW.attackRemote):SendToServer({
					weapon = swordInHand(),
					entityInstance = target.Character,
					validate = {
						raycast = {
							cameraPosition = camera.CFrame.Position,
							cursorDirection = (targetRoot.Position - camera.CFrame.Position).Unit,
						},
					},
					chargedAttack = { chargeTime = 0 },
				})
			end)
			return true
		end
		if type(sword.attackEntity) == "function" then
			pcall(function()
				sword:attackEntity({
					getInstance = function()
						return target.Character
					end,
				})
			end)
			return true
		end
	end
	lookAt(targetRoot.Position + Vector3.new(0, 1.4, 0))
	click(0)
	return true
end

local function breakAt(position)
	local breaker = controller("BlockBreakController")
	if breaker and breaker.blockBreaker and type(breaker.blockBreaker.hitBlock) == "function" then
		pcall(function()
			breaker.blockBreaker:hitBlock()
		end)
		return
	end
	pcall(function()
		ContextActionService:CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end)
	lookAt(position)
	click(0)
end

local function firePrompt(prompt)
	pcall(function()
		if type(fireproximityprompt) == "function" then
			fireproximityprompt(prompt)
			return
		end
		prompt:InputHoldBegin()
		task.delay(prompt.HoldDuration or 0, function()
			if prompt.Parent then
				prompt:InputHoldEnd()
			end
		end)
	end)
end

local function nearbyPrompts(needles, range)
	local root = rootPart()
	if not root then
		return
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then
			local holder = inst.Parent
			local part = holder and (holder:IsA("BasePart") and holder or holder:FindFirstChildWhichIsA("BasePart", true))
			if part and (part.Position - root.Position).Magnitude <= (range or 14) then
				local label = string.lower(inst.ActionText .. " " .. inst.ObjectText .. " " .. holder.Name)
				for _, needle in ipairs(needles) do
					if string.find(label, needle, 1, true) then
						firePrompt(inst)
						break
					end
				end
			end
		end
	end
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

local function collectBeds()
	local seen, list = {}, {}
	local function add(inst)
		if seen[inst] or sameTeam(inst) then
			return
		end
		if inst:GetAttribute("Alive") == false or inst:GetAttribute("Broken") == true then
			return
		end
		seen[inst] = true
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

local beds = {}
local bedClock = 0

local KIT_MAP = {
	AutoCait = { "cait", "caitlyn" },
	AutoNyx = { "nyx" },
	AutoElder = { "elder" },
	AutoSilas = { "silas" },
	AutoKadia = { "kaida", "kadia" },
	AutoRaven = { "raven" },
	AutoVoidNight = { "void" },
	AutoHep = { "heph", "hep" },
	AutoAdetunde = { "adetunde" },
	AutoBountyHunter = { "bounty" },
	AutoLucia = { "lucia" },
	AutoAbbadon = { "abaddon", "abbadon" },
	AutoFortuna = { "fortuna" },
	AutoDavey = { "davey" },
	AutoGrim = { "grim" },
	AutoKalliyah = { "kaliyah", "kalliyah" },
	AutoBuilder = { "builder" },
	AutoFish = { "fish" },
	AutoKrystal = { "krystal", "crystal" },
}

local function kitMatches(keys)
	local kit = string.lower(kitOf(localPlayer))
	if kit == "" then
		return false
	end
	for _, key in ipairs(keys) do
		if string.find(kit, key, 1, true) then
			return true
		end
	end
	return false
end

local function useKitAbility()
	local kit = controller("KitController") or controller("AbilityController")
	if kit then
		for _, name in ipairs({ "useAbility", "activateAbility", "useKitAbility" }) do
			if type(kit[name]) == "function" then
				pcall(function()
					kit[name](kit)
				end)
				return true
			end
		end
	end
	if BW.client then
		for _, remote in ipairs({ "use-ability", "kit-ability", "ability" }) do
			pcall(function()
				BW.client:Get(remote):SendToServer({})
			end)
		end
	end
	return false
end

local Modules = {}
local Categories = {}
local HudOrder = {}
local Settings = {}

local function option(mod, name, kind, default, extra)
	mod.options[name] = {
		name = name,
		kind = kind,
		value = default,
		min = extra and extra.min or 0,
		max = extra and extra.max or 100,
		step = extra and extra.step or 1,
	}
	return mod.options[name]
end

local function getOption(mod, name)
	return mod.options[name] and mod.options[name].value
end

local function createModule(category, name, tooltip, defaultOptions, onToggle, onTick)
	local mod = {
		name = name,
		tooltip = tooltip,
		category = category,
		enabled = false,
		options = {},
		conns = {},
		onToggle = onToggle,
		onTick = onTick,
		interval = 0.05,
		acc = 0,
	}
	if defaultOptions then
		defaultOptions(mod)
	end
	Modules[name] = mod
	table.insert(Categories[category].modules, mod)
	return mod
end

local function setEnabled(mod, state)
	if mod.enabled == state then
		return
	end
	mod.enabled = state
	if not state then
		disconnectAll(mod.conns)
	end
	if mod.onToggle then
		pcall(mod.onToggle, state, mod)
	end
	if mod.refresh then
		mod.refresh()
	end
	if refreshHud then
		refreshHud()
	end
end

local function addCat(name)
	Categories[name] = { name = name, modules = {} }
end

addCat("Combat")
addCat("Blatant")
addCat("Render")
addCat("Utility")
addCat("World")
addCat("Inventory")
addCat("Kits")

local espFolder = Instance.new("Folder")
espFolder.Name = "QWEsp"
local playerEsp, bedEsp = {}, {}

local function makeHighlight(adornee, color)
	local h = Instance.new("Highlight")
	h.Adornee = adornee
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.FillTransparency = 0.62
	h.OutlineTransparency = 0
	h.FillColor = color
	h.OutlineColor = color
	h.Parent = espFolder
	return h
end

local function makeLabel(adornee)
	local gui = Instance.new("BillboardGui")
	gui.AlwaysOnTop = true
	gui.Size = UDim2.fromOffset(180, 42)
	gui.StudsOffset = Vector3.new(0, 2.8, 0)
	gui.Adornee = adornee
	gui.Parent = espFolder
	local text = Instance.new("TextLabel")
	text.Name = "T"
	text.BackgroundTransparency = 1
	text.Size = UDim2.fromScale(1, 1)
	text.Font = Enum.Font.GothamMedium
	text.TextSize = 13
	text.TextStrokeTransparency = 0.4
	text.TextColor3 = Theme.Text
	text.Parent = gui
	return gui
end

local function clearEsp(map)
	for key, item in pairs(map) do
		if item.hl then
			item.hl:Destroy()
		end
		if item.lb then
			item.lb:Destroy()
		end
		map[key] = nil
	end
end

local function updatePlayerEsp(showKit)
	local mine = rootPart()
	for _, player in ipairs(Players:GetPlayers()) do
		local char = player.Character
		local root = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		local keep = player ~= localPlayer and not sameTeam(player) and root and hum and hum.Health > 0 and mine
		if not keep then
			if playerEsp[player] then
				if playerEsp[player].hl then
					playerEsp[player].hl:Destroy()
				end
				if playerEsp[player].lb then
					playerEsp[player].lb:Destroy()
				end
				playerEsp[player] = nil
			end
		else
			local color = teamColor(player)
			local kit = kitOf(player)
			if showKit and kit ~= "" then
				color = Color3.fromHSV((#kit % 10) / 10, 0.55, 1)
			end
			local entry = playerEsp[player] or {}
			playerEsp[player] = entry
			if not entry.hl then
				entry.hl = makeHighlight(char, color)
			end
			entry.hl.Adornee = char
			entry.hl.FillColor = color
			entry.hl.OutlineColor = color
			local head = char:FindFirstChild("Head")
			if not entry.lb then
				entry.lb = makeLabel(head or root)
			end
			entry.lb.Adornee = head or root
			local text = entry.lb:FindFirstChild("T")
			if text then
				local dist = math.floor((root.Position - mine.Position).Magnitude + 0.5)
				local extra = (showKit and kit ~= "") and ("\n" .. kit) or ""
				text.Text = string.format("%s  %dHP\n%dst%s", player.DisplayName, math.floor(hum.Health + 0.5), dist, extra)
				text.TextColor3 = color
			end
		end
	end
end

local flyMover, flyAttach
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

local function fly(speed)
	local root = rootPart()
	local hum = humanoid()
	if not root or not hum or not camera then
		return
	end
	if not flyMover or not flyMover.Parent then
		if flyMover then
			flyMover:Destroy()
		end
		if flyAttach then
			flyAttach:Destroy()
		end
		flyAttach = Instance.new("Attachment")
		flyAttach.Parent = root
		flyMover = Instance.new("LinearVelocity")
		flyMover.Attachment0 = flyAttach
		flyMover.MaxForce = math.huge
		flyMover.RelativeTo = Enum.ActuatorRelativeTo.World
		flyMover.Parent = root
	end
	hum.PlatformStand = true
	local move = Vector3.zero
	local look, right = camera.CFrame.LookVector, camera.CFrame.RightVector
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		move = move + look
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		move = move - look
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		move = move + right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		move = move - right
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		move = move + Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		move = move - Vector3.yAxis
	end
	flyMover.VectorVelocity = move.Magnitude > 0 and move.Unit * speed or Vector3.zero
end

local shaderFx = {}
local texSaved = {}
local texConn
local sprintOld
local jumpWas = false
local savedSpeed

createModule("Combat", "AimAssist", "Smoothly aims at the closest enemy", function(m)
	option(m, "Range", "slider", 18, { min = 6, max = 40, step = 1 })
	option(m, "Smooth", "slider", 35, { min = 10, max = 100, step = 5 })
end, nil, function(mod)
	local _, root = nearestEnemy(getOption(mod, "Range"))
	if root and camera then
		local alpha = getOption(mod, "Smooth") / 100
		local goal = CFrame.lookAt(camera.CFrame.Position, root.Position + Vector3.new(0, 1.4, 0))
		camera.CFrame = camera.CFrame:Lerp(goal, alpha)
	end
end)

createModule("Combat", "SilentAim", "Redirects swings toward the nearest enemy", function(m)
	option(m, "Range", "slider", 20, { min = 8, max = 40, step = 1 })
end)

createModule("Combat", "AutoClicker", "Clicks while you hold attack", function(m)
	option(m, "CPS", "slider", 12, { min = 4, max = 20, step = 1 })
end, nil, function(mod)
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		click(0)
	end
end).interval = 0.08

createModule("Combat", "ProjectileAimbot", "Leads bow and fireball shots", function(m)
	option(m, "Range", "slider", 180, { min = 40, max = 300, step = 10 })
end, nil, function(mod)
	local _, root, dist = nearestEnemy(getOption(mod, "Range"))
	if root then
		local lead = root.AssemblyLinearVelocity * (dist / 180)
		lookAt(root.Position + Vector3.new(0, 1.5, 0) + lead)
	end
end)

createModule("Combat", "Velocity", "Cuts incoming knockback", nil, function(on)
	if on then
		table.insert(Modules.Velocity.conns, RunService.Heartbeat:Connect(function()
			local root = rootPart()
			if root then
				local v = root.AssemblyLinearVelocity
				if Vector3.new(v.X, 0, v.Z).Magnitude > 28 then
					root.AssemblyLinearVelocity = Vector3.new(v.X * 0.25, v.Y, v.Z * 0.25)
				end
			end
		end))
	end
end)

createModule("Combat", "Sprint", "Keeps sprint held", nil, function(on)
	local sprint = controller("SprintController")
	if sprint and type(sprint.startSprinting) == "function" then
		if on then
			pcall(function()
				sprint:startSprinting()
			end)
		end
	end
end, function()
	local sprint = controller("SprintController")
	if sprint and type(sprint.startSprinting) == "function" then
		pcall(function()
			sprint:startSprinting()
		end)
	else
		local hum = humanoid()
		if hum then
			hum.WalkSpeed = math.max(hum.WalkSpeed, 23)
		end
	end
end)

createModule("Blatant", "Killaura", "Attacks nearby enemies automatically", function(m)
	option(m, "Range", "slider", 18, { min = 8, max = 22, step = 1 })
	option(m, "Walls", "toggle", false)
end, nil, function(mod)
	local target, root, dist = nearestEnemy(getOption(mod, "Range"))
	if not target then
		return
	end
	if getOption(mod, "Walls") and not canSee(root) then
		return
	end
	if Modules.SilentAim.enabled then
		lookAt(root.Position + Vector3.new(0, 1.4, 0))
	end
	sendAttack(target, root)
end).interval = 0.08

createModule("Blatant", "FastHits", "Shortens aura delay", nil)

createModule("Blatant", "Fly", "WASD fly, Space up, Ctrl down", function(m)
	option(m, "Speed", "slider", 70, { min = 20, max = 140, step = 5 })
end, function(on)
	if not on then
		stopFly()
	end
end, function(mod)
	fly(getOption(mod, "Speed"))
end).interval = 0

createModule("Blatant", "InfiniteFly", "Keeps fly active if the mover is stripped", function(m)
	option(m, "Speed", "slider", 70, { min = 20, max = 140, step = 5 })
end, function(on)
	if not on and not Modules.Fly.enabled then
		stopFly()
	end
end, function(mod)
	fly(getOption(mod, "Speed"))
end).interval = 0

createModule("Blatant", "LongJumps", "Adds forward boost on jump", nil, nil, function()
	local hum, root = humanoid(), rootPart()
	if not hum or not root then
		return
	end
	local jumping = hum:GetState() == Enum.HumanoidStateType.Jumping
	if jumping and not jumpWas then
		local flat = Vector3.new(root.CFrame.LookVector.X, 0, root.CFrame.LookVector.Z)
		if flat.Magnitude > 0 then
			root.AssemblyLinearVelocity = root.AssemblyLinearVelocity + flat.Unit * 72
		end
	end
	jumpWas = jumping
end).interval = 0

createModule("Blatant", "HighJump", "Raises jump power", function(m)
	option(m, "Power", "slider", 90, { min = 50, max = 140, step = 5 })
end, function(on, mod)
	local hum = humanoid()
	if hum then
		hum.UseJumpPower = true
		hum.JumpPower = on and getOption(mod, "Power") or 50
	end
end)

createModule("Blatant", "InfiniteJumps", "Jump in the air", nil, function(on)
	if on then
		table.insert(Modules.InfiniteJumps.conns, UserInputService.JumpRequest:Connect(function()
			local hum = humanoid()
			if hum then
				hum:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end))
	end
end)

createModule("Blatant", "NoFall", "Cancels hard landings", nil, nil, function()
	local root, hum = rootPart(), humanoid()
	if not root or not hum then
		return
	end
	local v = root.AssemblyLinearVelocity
	if v.Y < -40 then
		local hit = workspace:Raycast(root.Position, Vector3.new(0, -12, 0))
		if hit then
			root.AssemblyLinearVelocity = Vector3.new(v.X, math.max(v.Y, -8), v.Z)
		end
	end
	pcall(function()
		local fall = controller("FallDamageController")
		if fall then
			fall.lastOnGround = os.clock()
		end
	end)
end).interval = 0

createModule("Blatant", "Speed", "Raises walk speed", function(m)
	option(m, "Speed", "slider", 23, { min = 16, max = 32, step = 1 })
end, function(on)
	if not on then
		local hum = humanoid()
		if hum and savedSpeed then
			hum.WalkSpeed = savedSpeed
		end
	end
end, function(mod)
	local hum = humanoid()
	if hum then
		if not savedSpeed then
			savedSpeed = hum.WalkSpeed
		end
		hum.WalkSpeed = getOption(mod, "Speed")
	end
end)

createModule("Blatant", "Desync", "Offsets you for a frame", nil, nil, function()
	local root = rootPart()
	if not root then
		return
	end
	local cf = root.CFrame
	root.CFrame = cf * CFrame.new(0, 0, -7)
	task.defer(function()
		if root.Parent then
			root.CFrame = cf
		end
	end)
end).interval = 0.2

createModule("Render", "ESP", "Outlines enemies through walls", nil, function(on)
	if not on and not Modules.KitESP.enabled then
		clearEsp(playerEsp)
	end
end, function()
	updatePlayerEsp(Modules.KitESP.enabled or Modules.KitRender.enabled)
end).interval = 0.08

createModule("Render", "BedESP", "Marks enemy beds", nil, function(on)
	if not on then
		clearEsp(bedEsp)
	end
end, function()
	local mine = rootPart()
	for _, bed in ipairs(beds) do
		local pos = bed.Parent and instancePos(bed)
		if not pos or not mine then
			if bedEsp[bed] then
				if bedEsp[bed].hl then
					bedEsp[bed].hl:Destroy()
				end
				if bedEsp[bed].lb then
					bedEsp[bed].lb:Destroy()
				end
				bedEsp[bed] = nil
			end
		else
			local adornee = bed:IsA("Model") and bed or bed:FindFirstChildWhichIsA("BasePart", true)
			local color = teamColor(bed)
			local entry = bedEsp[bed] or {}
			bedEsp[bed] = entry
			if adornee then
				if not entry.hl then
					entry.hl = makeHighlight(adornee, color)
				end
				entry.hl.Adornee = adornee
				if not entry.lb then
					entry.lb = makeLabel(adornee)
				end
				entry.lb.Adornee = adornee
				local text = entry.lb:FindFirstChild("T")
				if text then
					text.Text = string.format("%s bed\n%dst", teamId(bed) or "enemy", math.floor((pos - mine.Position).Magnitude + 0.5))
					text.TextColor3 = color
				end
			end
		end
	end
end).interval = 0.15

createModule("Render", "KitESP", "Shows equipped kits on ESP", nil, function(on)
	if not on and not Modules.ESP.enabled then
		clearEsp(playerEsp)
	end
end, function()
	updatePlayerEsp(true)
end).interval = 0.1

createModule("Render", "KitRender", "Colors players by kit", nil, function()
	updatePlayerEsp(true)
end)

createModule("Render", "SkinChanger", "Recolors your character", nil, nil, function()
	local char = character()
	if not char then
		return
	end
	local color = Color3.fromRGB(255, 186, 122)
	for _, part in ipairs(char:GetChildren()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Color = color
		end
	end
end).interval = 0.4

createModule("Render", "FPSBooster", "Drops lighting and particles", nil, function(on)
	pcall(function()
		settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
	end)
	Lighting.GlobalShadows = not on
	if not on then
		Lighting.FogEnd = 100000
	end
end, function()
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
			inst.Enabled = false
		end
	end
end).interval = 2

createModule("Render", "Shaders", "Warm color grade", nil, function(on)
	if on then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = 0.18
		cc.Contrast = 0.1
		cc.TintColor = Color3.fromRGB(255, 228, 210)
		cc.Parent = Lighting
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity = 0.35
		bloom.Size = 16
		bloom.Threshold = 0.85
		bloom.Parent = Lighting
		shaderFx = { cc, bloom }
	else
		for _, fx in ipairs(shaderFx) do
			fx:Destroy()
		end
		shaderFx = {}
	end
end)

createModule("Render", "NoTexture", "Flattens world materials", nil, function(on)
	if on then
		local function strip(inst)
			if inst:IsA("BasePart") and not texSaved[inst] then
				texSaved[inst] = inst.Material
				inst.Material = Enum.Material.SmoothPlastic
			elseif (inst:IsA("Decal") or inst:IsA("Texture")) and not texSaved[inst] then
				texSaved[inst] = inst.Transparency
				inst.Transparency = 1
			end
		end
		for _, inst in ipairs(workspace:GetDescendants()) do
			strip(inst)
		end
		texConn = workspace.DescendantAdded:Connect(strip)
		table.insert(Modules.NoTexture.conns, texConn)
	else
		for inst, value in pairs(texSaved) do
			if inst.Parent then
				if inst:IsA("BasePart") then
					inst.Material = value
				else
					inst.Transparency = value
				end
			end
		end
		texSaved = {}
	end
end)

createModule("Render", "TargetInfo", "Shows the current aura target", nil)

createModule("Utility", "AutoWin", "Aims at the nearest enemy bed", nil, nil, function()
	local mine = rootPart()
	if not mine then
		return
	end
	local best, bestPos
	for _, bed in ipairs(beds) do
		local pos = instancePos(bed)
		if pos and (not best or (pos - mine.Position).Magnitude < (bestPos - mine.Position).Magnitude) then
			best, bestPos = bed, pos
		end
	end
	if bestPos then
		lookAt(bestPos)
		breakAt(bestPos)
	end
end).interval = 0.12

createModule("Utility", "AntiLasso", "Breaks lasso constraints on you", nil, nil, function()
	local char = character()
	if not char then
		return
	end
	for _, inst in ipairs(char:GetDescendants()) do
		if inst:IsA("Constraint") then
			pcall(function()
				inst.Enabled = false
			end)
		end
	end
end)

createModule("Utility", "AutoLasso", "Uses lasso on the closest enemy", nil, nil, function()
	local kit = string.lower(kitOf(localPlayer))
	local tool = character() and character():FindFirstChildOfClass("Tool")
	local name = tool and string.lower(tool.Name) or ""
	if string.find(kit, "lasso", 1, true) or string.find(name, "lasso", 1, true) then
		local target, root = nearestEnemy(40)
		if target then
			sendAttack(target, root)
		end
	end
end)

createModule("Utility", "AutoKit", "Uses your kit ability in fights", nil, nil, function()
	if nearestEnemy(20) then
		useKitAbility()
	end
end).interval = 0.25

createModule("Utility", "ChestSteal", "Opens nearby chests", nil, nil, function()
	nearbyPrompts({ "chest", "loot", "open" }, 12)
end).interval = 0.35

createModule("Utility", "FastPlace", "Repeats place while holding right click", nil, nil, function()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		click(1)
	end
end).interval = 0.05

createModule("World", "Nuker", "Breaks the closest block", function(m)
	option(m, "Range", "slider", 8, { min = 4, max = 12, step = 1 })
end, nil, function(mod)
	local root = rootPart()
	local char = character()
	if not root or not char then
		return
	end
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { char }
	local parts = workspace:GetPartBoundsInRadius(root.Position, getOption(mod, "Range"), params)
	local best, bestDist
	for _, part in ipairs(parts) do
		if part.Size.Magnitude < 28 then
			local dist = (part.Position - root.Position).Magnitude
			if not bestDist or dist < bestDist then
				best, bestDist = part, dist
			end
		end
	end
	if best then
		breakAt(best.Position)
	end
end).interval = 0.08

createModule("World", "BlockIn", "Places blocks around you", nil, nil, function()
	local root = rootPart()
	if not root or not camera then
		return
	end
	local old = camera.CFrame
	for _, offset in ipairs({
		root.CFrame.LookVector * 3,
		-root.CFrame.LookVector * 3,
		root.CFrame.RightVector * 3,
		-root.CFrame.RightVector * 3,
		Vector3.new(0, -3, 0),
	}) do
		lookAt(root.Position + offset)
		click(1)
	end
	camera.CFrame = old
end).interval = 0.35

createModule("Inventory", "AutoBank", "Uses nearby bank and shop prompts", nil, nil, function()
	nearbyPrompts({ "bank", "shop", "upgrade", "deposit", "team" }, 16)
end).interval = 0.45

createModule("Kits", "AutoCait", "Cait kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoCait) then
		local t, r = nearestEnemy(20)
		if t then
			sendAttack(t, r)
			useKitAbility()
		end
	end
end)
createModule("Kits", "AutoNyx", "Nyx kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoNyx) then
		local t, r = nearestEnemy(20)
		if t then
			sendAttack(t, r)
			useKitAbility()
		end
	end
end)
createModule("Kits", "AutoElder", "Elder kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoElder) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoSilas", "Silas kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoSilas) then
		local t, r = nearestEnemy(22)
		if t then
			sendAttack(t, r)
			useKitAbility()
		end
	end
end)
createModule("Kits", "AutoKadia", "Kadia kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoKadia) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoRaven", "Raven kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoRaven) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoVoidNight", "Void Night kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoVoidNight) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoHep", "Hep kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoHep) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoAdetunde", "Adetunde kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoAdetunde) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoBountyHunter", "Bounty Hunter kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoBountyHunter) then
		local t, r = nearestEnemy(24)
		if t then
			sendAttack(t, r)
			useKitAbility()
		end
	end
end)
createModule("Kits", "AutoLucia", "Lucia kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoLucia) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoAbbadon", "Abbadon kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoAbbadon) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoFortuna", "Fortuna kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoFortuna) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoDavey", "Davey kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoDavey) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoGrim", "Grim kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoGrim) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoKalliyah", "Kalliyah kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoKalliyah) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoBuilder", "Places while Builder is equipped", nil, nil, function()
	if kitMatches(KIT_MAP.AutoBuilder) then
		Modules.BlockIn.onTick(Modules.BlockIn)
	end
end)
createModule("Kits", "AutoFish", "Fish kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoFish) then
		useKitAbility()
	end
end)
createModule("Kits", "AutoKrystal", "Krystal kit assist", nil, nil, function()
	if kitMatches(KIT_MAP.AutoKrystal) then
		useKitAbility()
	end
end)

local screen = Instance.new("ScreenGui")
screen.Name = "Quantumware"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screen.DisplayOrder = 999999
protect(screen)
screen.Parent = guiParent()
espFolder.Parent = screen

local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.BackgroundTransparency = 1
menu.Size = UDim2.fromScale(1, 1)
menu.Parent = screen

local top = Instance.new("Frame")
top.Size = UDim2.new(1, -48, 0, 36)
top.Position = UDim2.fromOffset(24, 14)
top.BackgroundColor3 = Theme.Bg
top.BackgroundTransparency = 0.08
top.Parent = menu
corner(top, 6)
stroke(top)

local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Size = UDim2.new(0, 180, 1, 0)
brand.Position = UDim2.fromOffset(14, 0)
brand.Font = Enum.Font.GothamBold
brand.TextSize = 15
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.TextColor3 = Theme.Text
brand.Text = "Quantumware"
brand.Parent = top

local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 260, 0, 24)
search.Position = UDim2.new(0.5, -130, 0.5, -12)
search.BackgroundColor3 = Theme.Row
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.PlaceholderText = "Search modules"
search.PlaceholderColor3 = Theme.Dim
search.TextColor3 = Theme.Text
search.Text = ""
search.ClearTextOnFocus = false
search.Parent = top
corner(search, 4)
stroke(search)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(0, 220, 1, 0)
hint.Position = UDim2.new(1, -230, 0, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextColor3 = Theme.Dim
hint.Text = "Right Shift  ·  drag windows"
hint.Parent = top

local windows = Instance.new("Frame")
windows.BackgroundTransparency = 1
windows.Position = UDim2.fromOffset(24, 64)
windows.Size = UDim2.new(1, -48, 1, -80)
windows.Parent = menu

local arraylist = Instance.new("Frame")
arraylist.Name = "Arraylist"
arraylist.BackgroundTransparency = 1
arraylist.AnchorPoint = Vector2.new(1, 0)
arraylist.Position = UDim2.new(1, -16, 0, 18)
arraylist.Size = UDim2.fromOffset(220, 400)
arraylist.Parent = screen
local arrayLayout = Instance.new("UIListLayout")
arrayLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
arrayLayout.SortOrder = Enum.SortOrder.LayoutOrder
arrayLayout.Padding = UDim.new(0, 2)
arrayLayout.Parent = arraylist

local targetHud = Instance.new("Frame")
targetHud.Size = UDim2.fromOffset(220, 58)
targetHud.Position = UDim2.new(0.5, -110, 1, -80)
targetHud.BackgroundColor3 = Theme.Bg
targetHud.BackgroundTransparency = 0.08
targetHud.Visible = false
targetHud.Parent = screen
corner(targetHud, 6)
stroke(targetHud)
local targetTitle = Instance.new("TextLabel")
targetTitle.BackgroundTransparency = 1
targetTitle.Size = UDim2.new(1, -16, 0, 20)
targetTitle.Position = UDim2.fromOffset(10, 6)
targetTitle.Font = Enum.Font.GothamMedium
targetTitle.TextSize = 13
targetTitle.TextXAlignment = Enum.TextXAlignment.Left
targetTitle.TextColor3 = Theme.Dim
targetTitle.Text = "Target"
targetTitle.Parent = targetHud
local targetName = Instance.new("TextLabel")
targetName.BackgroundTransparency = 1
targetName.Size = UDim2.new(1, -16, 0, 22)
targetName.Position = UDim2.fromOffset(10, 26)
targetName.Font = Enum.Font.GothamBold
targetName.TextSize = 16
targetName.TextXAlignment = Enum.TextXAlignment.Left
targetName.TextColor3 = Theme.Text
targetName.Text = "None"
targetName.Parent = targetHud

function refreshHud()
	for _, child in ipairs(arraylist:GetChildren()) do
		if child:IsA("TextLabel") then
			child:Destroy()
		end
	end
	local names = {}
	for name, mod in pairs(Modules) do
		if mod.enabled then
			table.insert(names, name)
		end
	end
	table.sort(names, function(a, b)
		return #a > #b
	end)
	for i, name in ipairs(names) do
		local label = Instance.new("TextLabel")
		label.BackgroundColor3 = Theme.Bg
		label.BackgroundTransparency = 0.15
		label.Size = UDim2.fromOffset(12 + #name * 7, 20)
		label.Font = Enum.Font.GothamMedium
		label.TextSize = 13
		label.TextColor3 = Theme.Text
		label.Text = name
		label.LayoutOrder = i
		label.Parent = arraylist
		corner(label, 3)
	end
end

local function matchesSearch(mod, query)
	if query == "" then
		return true
	end
	return string.find(string.lower(mod.name), query, 1, true) ~= nil
end

local function buildWindow(category, x)
	local data = Categories[category]
	local window = Instance.new("Frame")
	window.Name = category
	window.Size = UDim2.fromOffset(176, 36)
	window.Position = UDim2.fromOffset(x, 0)
	window.BackgroundColor3 = Theme.Bg
	window.BackgroundTransparency = 0.04
	window.Parent = windows
	corner(window, 6)
	stroke(window)

	local header = Instance.new("TextButton")
	header.AutoButtonColor = false
	header.Size = UDim2.new(1, 0, 0, 32)
	header.BackgroundTransparency = 1
	header.Font = Enum.Font.GothamMedium
	header.TextSize = 13
	header.TextXAlignment = Enum.TextXAlignment.Left
	header.TextColor3 = Theme.Text
	header.Text = "   " .. category
	header.Parent = window
	drag(header, window)

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(0, 32)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = window
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = list
	pad(list, 6, 0, 6, 8)

	window.AutomaticSize = Enum.AutomaticSize.Y

	local rows = {}
	for i, mod in ipairs(data.modules) do
		local row = Instance.new("Frame")
		row.Name = mod.name
		row.BackgroundColor3 = Theme.Row
		row.Size = UDim2.new(1, 0, 0, 26)
		row.LayoutOrder = i
		row.Parent = list
		corner(row, 4)

		local toggle = Instance.new("TextButton")
		toggle.AutoButtonColor = false
		toggle.BackgroundTransparency = 1
		toggle.Size = UDim2.new(1, -22, 1, 0)
		toggle.Font = Enum.Font.Gotham
		toggle.TextSize = 12
		toggle.TextXAlignment = Enum.TextXAlignment.Left
		toggle.TextColor3 = Theme.Dim
		toggle.Text = "  " .. mod.name
		toggle.Parent = row

		local more = Instance.new("TextButton")
		more.AutoButtonColor = false
		more.BackgroundTransparency = 1
		more.Size = UDim2.fromOffset(22, 26)
		more.Position = UDim2.new(1, -22, 0, 0)
		more.Font = Enum.Font.GothamBold
		more.TextSize = 12
		more.TextColor3 = Theme.Dim
		more.Text = next(mod.options) and ":" or ""
		more.Parent = row

		local extra = Instance.new("Frame")
		extra.BackgroundColor3 = Theme.Panel
		extra.Size = UDim2.new(1, 0, 0, 0)
		extra.AutomaticSize = Enum.AutomaticSize.Y
		extra.Visible = false
		extra.LayoutOrder = i
		extra.Parent = list
		local extraList = Instance.new("UIListLayout")
		extraList.Padding = UDim.new(0, 4)
		extraList.Parent = extra
		pad(extra, 8, 4, 8, 6)

		for optName, opt in pairs(mod.options) do
			if opt.kind == "toggle" then
				local btn = Instance.new("TextButton")
				btn.Size = UDim2.new(1, 0, 0, 20)
				btn.BackgroundColor3 = Theme.Row
				btn.Font = Enum.Font.Gotham
				btn.TextSize = 11
				btn.TextColor3 = Theme.Text
				btn.Text = optName .. "  " .. (opt.value and "On" or "Off")
				btn.Parent = extra
				corner(btn, 3)
				btn.MouseButton1Click:Connect(function()
					opt.value = not opt.value
					btn.Text = optName .. "  " .. (opt.value and "On" or "Off")
				end)
			else
				local hold = Instance.new("Frame")
				hold.BackgroundTransparency = 1
				hold.Size = UDim2.new(1, 0, 0, 34)
				hold.Parent = extra
				local label = Instance.new("TextLabel")
				label.BackgroundTransparency = 1
				label.Size = UDim2.new(1, 0, 0, 14)
				label.Font = Enum.Font.Gotham
				label.TextSize = 11
				label.TextXAlignment = Enum.TextXAlignment.Left
				label.TextColor3 = Theme.Dim
				label.Text = optName .. "  " .. tostring(opt.value)
				label.Parent = hold
				local bar = Instance.new("TextButton")
				bar.AutoButtonColor = false
				bar.Size = UDim2.new(1, 0, 0, 8)
				bar.Position = UDim2.fromOffset(0, 18)
				bar.BackgroundColor3 = Theme.Row
				bar.Text = ""
				bar.Parent = hold
				corner(bar, 3)
				local fill = Instance.new("Frame")
				fill.BackgroundColor3 = Theme.Accent
				fill.Size = UDim2.new((opt.value - opt.min) / math.max(opt.max - opt.min, 1), 0, 1, 0)
				fill.Parent = bar
				corner(fill, 3)
				local function apply(x)
					local alpha = math.clamp(x / math.max(bar.AbsoluteSize.X, 1), 0, 1)
					local raw = opt.min + (opt.max - opt.min) * alpha
					opt.value = math.floor(raw / opt.step + 0.5) * opt.step
					fill.Size = UDim2.new((opt.value - opt.min) / math.max(opt.max - opt.min, 1), 0, 1, 0)
					label.Text = optName .. "  " .. tostring(opt.value)
				end
				bar.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						apply(input.Position.X - bar.AbsolutePosition.X)
					end
				end)
			end
		end

		local function paint()
			row.BackgroundColor3 = mod.enabled and Theme.RowOn or Theme.Row
			toggle.TextColor3 = mod.enabled and Theme.Text or Theme.Dim
		end
		mod.refresh = paint
		paint()

		toggle.MouseButton1Click:Connect(function()
			setEnabled(mod, not mod.enabled)
		end)
		more.MouseButton1Click:Connect(function()
			if next(mod.options) then
				extra.Visible = not extra.Visible
			end
		end)
		rows[mod.name] = row
	end

	return function(query)
		for _, mod in ipairs(data.modules) do
			local row = list:FindFirstChild(mod.name)
			if row then
				row.Visible = matchesSearch(mod, query)
			end
		end
	end
end

local filters = {}
local x = 0
for _, name in ipairs({ "Combat", "Blatant", "Render", "Utility", "World", "Inventory", "Kits" }) do
	table.insert(filters, buildWindow(name, x))
	x = x + 188
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	local query = string.lower(search.Text)
	for _, filter in ipairs(filters) do
		filter(query)
	end
end)

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.RightShift then
		menu.Visible = not menu.Visible
	end
end)

track(RunService.Heartbeat:Connect(function(dt)
	bedClock = bedClock + dt
	if bedClock >= 1 then
		bedClock = 0
		beds = collectBeds()
	end
	local fast = Modules.FastHits.enabled
	for _, mod in pairs(Modules) do
		if mod.enabled and mod.onTick then
			local interval = mod.interval
			if fast and (mod.name == "Killaura" or mod.name == "AutoClicker" or mod.name == "Nuker") then
				interval = math.min(interval, 0.04)
			end
			mod.acc = mod.acc + dt
			if interval == 0 or mod.acc >= interval then
				mod.acc = 0
				pcall(mod.onTick, mod)
			end
		end
	end
	if Modules.TargetInfo.enabled then
		local target = nearestEnemy(26)
		targetHud.Visible = target ~= nil
		if target then
			targetName.Text = target.DisplayName
		end
	else
		targetHud.Visible = false
	end
end))

localPlayer.CharacterAdded:Connect(function()
	task.wait(0.3)
	stopFly()
end)

refreshHud()
notify(BW.ok and "Hooks found. Right Shift toggles the menu." or "Generic mode. Right Shift toggles the menu.")
print("[Quantumware] loaded  hooks=" .. tostring(BW.ok))
