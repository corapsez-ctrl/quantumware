-- Quantumware
-- loadstring(game:HttpGet("https://raw.githubusercontent.com/corapsez-ctrl/quantumware/main/bedwars.luau"))()
-- Right Shift toggles the menu.

local cloneref = cloneref or function(v)
	return v
end

local Players = cloneref(game:GetService("Players"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local CollectionService = cloneref(game:GetService("CollectionService"))
local Lighting = cloneref(game:GetService("Lighting"))
local ReplicatedStorage = cloneref(game:GetService("ReplicatedStorage"))
local ContextActionService = cloneref(game:GetService("ContextActionService"))
local StarterGui = cloneref(game:GetService("StarterGui"))
local TweenService = cloneref(game:GetService("TweenService"))
local VirtualInput
pcall(function()
	VirtualInput = cloneref(game:GetService("VirtualInputManager"))
end)

local lp = Players.LocalPlayer
local cam = workspace.CurrentCamera
local dbg = (type(debug) == "table" and debug) or {}

local function parentGui()
	local ok, hui = pcall(function()
		return gethui()
	end)
	if ok and typeof(hui) == "Instance" then
		return hui
	end
	local ok2, core = pcall(function()
		return game:GetService("CoreGui")
	end)
	if ok2 then
		return core
	end
	return lp:WaitForChild("PlayerGui")
end

local function notify(text)
	pcall(function()
		StarterGui:SetCore("SendNotification", {
			Title = "Quantumware",
			Text = text,
			Duration = 5,
		})
	end)
	print("[Quantumware] " .. text)
end

local function click(btn)
	btn = btn or 0
	pcall(function()
		if btn == 0 and mouse1click then
			mouse1click()
		elseif btn == 1 and mouse2click then
			mouse2click()
		elseif VirtualInput then
			local p = UserInputService:GetMouseLocation()
			VirtualInput:SendMouseButtonEvent(p.X, p.Y, btn, true, game, 0)
			VirtualInput:SendMouseButtonEvent(p.X, p.Y, btn, false, game, 0)
		end
	end)
end

local function char()
	return lp.Character
end

local function root()
	local c = char()
	return c and (c:FindFirstChild("HumanoidRootPart") or c.PrimaryPart)
end

local function hum()
	local c = char()
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function teamOf(player)
	if player then
		local t = player:GetAttribute("Team")
		if t ~= nil then
			return tostring(t)
		end
		if player.Team then
			return player.Team.Name
		end
	end
end

local function enemy(player)
	return player and player ~= lp and teamOf(player) ~= teamOf(lp)
end

local TEAM_COLORS = {
	Red = Color3.fromRGB(255, 88, 88),
	Blue = Color3.fromRGB(80, 160, 255),
	Green = Color3.fromRGB(90, 220, 120),
	Yellow = Color3.fromRGB(255, 220, 80),
	Orange = Color3.fromRGB(255, 160, 60),
	Pink = Color3.fromRGB(255, 130, 200),
	Cyan = Color3.fromRGB(70, 230, 230),
	White = Color3.fromRGB(240, 240, 245),
	Purple = Color3.fromRGB(170, 120, 255),
}

local function colorOf(player)
	local t = teamOf(player)
	return (t and TEAM_COLORS[t]) or Color3.fromRGB(255, 90, 90)
end

local function kitOf(player)
	for _, k in ipairs({ "Kit", "EquippedKit", "kit", "SelectedKit" }) do
		local v = player:GetAttribute(k)
		if v and tostring(v) ~= "" then
			return tostring(v)
		end
	end
	return ""
end

local BW = {
	ready = false,
	knit = nil,
	client = nil,
	store = nil,
	sword = nil,
	attack = nil,
	sprint = nil,
	breaker = nil,
	knockback = nil,
	query = nil,
	itemMeta = nil,
}

local function dumpRemote(fn)
	if type(dbg.getconstants) ~= "function" then
		return
	end
	local ok, consts = pcall(dbg.getconstants, fn)
	if not ok or type(consts) ~= "table" then
		return
	end
	for i, v in ipairs(consts) do
		if v == "Client" then
			return consts[i + 1]
		end
	end
	for _, v in ipairs(consts) do
		if type(v) == "string" and (string.find(v, "Sword", 1, true) or string.find(v, "attack", 1, true) or string.find(v, "swing", 1, true)) then
			return v
		end
	end
end

local function hookKnit()
	local started = os.clock()
	while os.clock() - started < 20 do
		local knit
		pcall(function()
			local setup = require(lp.PlayerScripts.TS.knit).setup
			if type(dbg.getupvalue) == "function" then
				knit = dbg.getupvalue(setup, 9)
			end
		end)
		if not knit then
			pcall(function()
				knit = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"].knit.src.Knit.KnitClient)
			end)
		end
		if knit then
			pcall(function()
				if type(dbg.getupvalue) == "function" and knit.Start and not dbg.getupvalue(knit.Start, 1) then
					repeat
						task.wait()
					until dbg.getupvalue(knit.Start, 1) or os.clock() - started > 20
				end
			end)
			BW.knit = knit
			BW.sword = knit.Controllers and knit.Controllers.SwordController
			BW.sprint = knit.Controllers and knit.Controllers.SprintController
			BW.breaker = knit.Controllers and knit.Controllers.BlockBreakController
			pcall(function()
				BW.client = require(ReplicatedStorage.TS.remotes).default.Client
			end)
			pcall(function()
				BW.store = require(lp.PlayerScripts.TS.ui.store).ClientStore
			end)
			pcall(function()
				BW.knockback = require(ReplicatedStorage.TS.damage["knockback-util"]).KnockbackUtil
			end)
			pcall(function()
				BW.query = require(ReplicatedStorage.rbxts_include.node_modules["@easy-games"]["game-core"].out).GameQueryUtil
			end)
			if BW.sword and BW.sword.sendServerRequest then
				BW.attack = dumpRemote(BW.sword.sendServerRequest)
			end
			BW.ready = BW.sword ~= nil or BW.client ~= nil
			return BW.ready
		end
		task.wait(0.25)
	end
	return false
end

task.spawn(function()
	local ok = hookKnit()
	notify(ok and "Bedwars hooks ready" or "Hooks missing — still running fallbacks")
end)

local function handTool()
	if BW.sword and type(BW.sword.getHandItem) == "function" then
		local ok, item = pcall(function()
			return BW.sword:getHandItem()
		end)
		if ok and item then
			return item.tool or item
		end
	end
	if BW.store then
		local ok, state = pcall(function()
			return BW.store:getState()
		end)
		if ok and state and state.Inventory and state.Inventory.observedInventory then
			local hand = state.Inventory.observedInventory.inventory.hand
			if hand then
				return hand.tool
			end
		end
	end
	local c = char()
	return c and c:FindFirstChildOfClass("Tool")
end

local function healthOf(model)
	if not model then
		return 0
	end
	local h = model:GetAttribute("Health")
	if type(h) == "number" then
		return h
	end
	local human = model:FindFirstChildOfClass("Humanoid")
	return human and human.Health or 0
end

local function nearest(range)
	local me = root()
	if not me then
		return
	end
	local best, bestRoot, bestDist
	local tagged = {}
	pcall(function()
		tagged = CollectionService:GetTagged("inventory-entity")
	end)
	if #tagged == 0 then
		for _, p in ipairs(Players:GetPlayers()) do
			if p.Character then
				table.insert(tagged, p.Character)
			end
		end
	end
	for _, model in ipairs(tagged) do
		local plr = Players:GetPlayerFromCharacter(model)
		local r = model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart
		if plr and enemy(plr) and r and healthOf(model) > 0 then
			local d = (r.Position - me.Position).Magnitude
			if d <= range and (not bestDist or d < bestDist) then
				best, bestRoot, bestDist = plr, r, d
			end
		end
	end
	return best, bestRoot, bestDist
end

local function look(world)
	if cam then
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, world)
	end
end

local function sendAttack(target, targetRoot)
	local me = root()
	if not me or not target or not targetRoot then
		return false
	end
	local sent = false
	if BW.client and BW.attack then
		local delta = targetRoot.Position - me.Position
		local swingDelta = 0.2
		pcall(function()
			swingDelta = workspace:GetServerTimeNow() - (BW.sword.lastSwingServerTime or 0)
		end)
		local ok = pcall(function()
			BW.client:Get(BW.attack):SendToServer({
				weapon = handTool(),
				chargedAttack = { chargeRatio = 1 },
				lastSwingServerTimeDelta = swingDelta,
				entityInstance = target.Character,
				validate = {
					raycast = {
						cameraPosition = { value = cam.CFrame.Position },
						cursorDirection = { value = CFrame.lookAt(cam.CFrame.Position, targetRoot.Position).LookVector },
					},
					targetPosition = { value = targetRoot.Position },
					selfPosition = {
						value = me.Position + CFrame.lookAt(me.Position, targetRoot.Position).LookVector * math.max(delta.Magnitude - 14.399, 0),
					},
				},
			})
		end)
		sent = ok
	end
	if BW.sword then
		pcall(function()
			if BW.sword.playSwordEffect then
				BW.sword:playSwordEffect()
			end
			if BW.sword.swingSwordAtMouse then
				BW.sword:swingSwordAtMouse()
			end
		end)
	end
	if not sent then
		look(targetRoot.Position + Vector3.new(0, 1.4, 0))
		click(0)
	end
	return true
end

local function breakAt(pos)
	if BW.breaker and BW.breaker.blockBreaker then
		pcall(function()
			BW.breaker.blockBreaker:hitBlock()
		end)
	end
	pcall(function()
		ContextActionService:CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end)
	look(pos)
	click(0)
end

local function beds()
	local list, seen = {}, {}
	local function add(inst)
		if seen[inst] or not inst.Parent then
			return
		end
		if inst:GetAttribute("Team") and tostring(inst:GetAttribute("Team")) == tostring(teamOf(lp)) then
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
	return list
end

local function posOf(inst)
	if inst:IsA("Model") then
		return inst:GetPivot().Position
	end
	if inst:IsA("BasePart") then
		return inst.Position
	end
	local p = inst:FindFirstChildWhichIsA("BasePart", true)
	return p and p.Position
end

local function firePrompt(prompt)
	pcall(function()
		if fireproximityprompt then
			fireproximityprompt(prompt)
		else
			prompt:InputHoldBegin()
			task.delay(prompt.HoldDuration or 0, function()
				if prompt.Parent then
					prompt:InputHoldEnd()
				end
			end)
		end
	end)
end

local function prompts(needles, range)
	local me = root()
	if not me then
		return
	end
	for _, inst in ipairs(workspace:GetDescendants()) do
		if inst:IsA("ProximityPrompt") then
			local part = inst.Parent and (inst.Parent:IsA("BasePart") and inst.Parent or inst.Parent:FindFirstChildWhichIsA("BasePart", true))
			if part and (part.Position - me.Position).Magnitude <= range then
				local s = string.lower(inst.ActionText .. inst.ObjectText .. inst.Parent.Name)
				for _, n in ipairs(needles) do
					if string.find(s, n, 1, true) then
						firePrompt(inst)
						break
					end
				end
			end
		end
	end
end

local flyVel, flyAtt
local function stopFly()
	if flyVel then
		flyVel:Destroy()
		flyVel = nil
	end
	if flyAtt then
		flyAtt:Destroy()
		flyAtt = nil
	end
	local h = hum()
	if h then
		h.PlatformStand = false
	end
end

local function fly(speed)
	local r, h = root(), hum()
	if not r or not h or not cam then
		return
	end
	if not flyVel or not flyVel.Parent then
		flyAtt = Instance.new("Attachment")
		flyAtt.Parent = r
		flyVel = Instance.new("LinearVelocity")
		flyVel.Attachment0 = flyAtt
		flyVel.MaxForce = math.huge
		flyVel.RelativeTo = Enum.ActuatorRelativeTo.World
		flyVel.Parent = r
	end
	h.PlatformStand = true
	local m = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		m = m + cam.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		m = m - cam.CFrame.LookVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		m = m + cam.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		m = m - cam.CFrame.RightVector
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		m = m + Vector3.yAxis
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		m = m - Vector3.yAxis
	end
	local v = m.Magnitude > 0 and m.Unit * speed or Vector3.zero
	flyVel.VectorVelocity = v
	r.AssemblyLinearVelocity = v
end

local Modules, Cats = {}, {}
local function cat(n)
	Cats[n] = { name = n, modules = {} }
end
cat("Combat")
cat("Blatant")
cat("Render")
cat("Utility")
cat("World")
cat("Inventory")
cat("Kits")

local function opt(mod, name, kind, value, extra)
	mod.options[name] = {
		name = name,
		kind = kind,
		value = value,
		min = extra and extra.min or 0,
		max = extra and extra.max or 100,
		step = extra and extra.step or 1,
	}
end

local function get(mod, name)
	return mod.options[name] and mod.options[name].value
end

local refreshHud
local function setOn(mod, state)
	if mod.enabled == state then
		return
	end
	mod.enabled = state
	if not state then
		for _, c in ipairs(mod.conns) do
			pcall(function()
				if typeof(c) == "RBXScriptConnection" then
					c:Disconnect()
				elseif typeof(c) == "Instance" then
					c:Destroy()
				end
			end)
		end
		table.clear(mod.conns)
	end
	if mod.toggle then
		pcall(mod.toggle, state, mod)
	end
	if mod.paint then
		mod.paint()
	end
	if refreshHud then
		refreshHud()
	end
end

local function add(category, name, tip, setup, toggle, tick, interval)
	local mod = {
		name = name,
		tip = tip,
		enabled = false,
		options = {},
		conns = {},
		toggle = toggle,
		tick = tick,
		interval = interval or 0.06,
		acc = 0,
	}
	if setup then
		setup(mod)
	end
	Modules[name] = mod
	table.insert(Cats[category].modules, mod)
	return mod
end

local espFolder = Instance.new("Folder")
espFolder.Name = "QWWorld"
espFolder.Parent = workspace
local pEsp, bEsp = {}, {}

local function hl(adornee, color)
	local h = Instance.new("Highlight")
	h.Adornee = adornee
	h.FillTransparency = 0.65
	h.OutlineTransparency = 0
	h.FillColor = color
	h.OutlineColor = color
	h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
	h.Parent = adornee
	return h
end

local function bill(adornee)
	local g = Instance.new("BillboardGui")
	g.AlwaysOnTop = true
	g.Size = UDim2.fromOffset(170, 40)
	g.StudsOffset = Vector3.new(0, 2.7, 0)
	g.Adornee = adornee
	g.Parent = adornee
	local t = Instance.new("TextLabel")
	t.Name = "T"
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.GothamMedium
	t.TextSize = 13
	t.TextStrokeTransparency = 0.35
	t.Parent = g
	return g
end

local function wipe(map)
	for k, v in pairs(map) do
		if v.h then
			v.h:Destroy()
		end
		if v.b then
			v.b:Destroy()
		end
		map[k] = nil
	end
end

local function drawPlayers(showKit)
	local me = root()
	for _, plr in ipairs(Players:GetPlayers()) do
		local model = plr.Character
		local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		local keep = enemy(plr) and r and healthOf(model) > 0 and me
		if not keep then
			if pEsp[plr] then
				if pEsp[plr].h then
					pEsp[plr].h:Destroy()
				end
				if pEsp[plr].b then
					pEsp[plr].b:Destroy()
				end
				pEsp[plr] = nil
			end
		else
			local col = colorOf(plr)
			local kit = kitOf(plr)
			if showKit and kit ~= "" then
				col = Color3.fromHSV((#kit % 9) / 9, 0.5, 1)
			end
			local e = pEsp[plr] or {}
			pEsp[plr] = e
			if not e.h or e.h.Parent == nil then
				e.h = hl(model, col)
			end
			e.h.Adornee = model
			e.h.FillColor, e.h.OutlineColor = col, col
			local head = model:FindFirstChild("Head") or r
			if not e.b or e.b.Parent == nil then
				e.b = bill(head)
			end
			e.b.Adornee = head
			local t = e.b:FindFirstChild("T")
			if t then
				t.TextColor3 = col
				t.Text = string.format("%s  %dHP\n%dst%s", plr.DisplayName, math.floor(healthOf(model) + 0.5), math.floor((r.Position - me.Position).Magnitude + 0.5), (showKit and kit ~= "" and ("  " .. kit) or ""))
			end
		end
	end
end

local shader, tex, texConn, jumpWas, savedSpeed

add("Combat", "AimAssist", "Smoothes aim onto the nearest enemy", function(m)
	opt(m, "Range", "slider", 20, { min = 8, max = 30, step = 1 })
	opt(m, "Smooth", "slider", 40, { min = 10, max = 100, step = 5 })
end, nil, function(m)
	local _, r = nearest(get(m, "Range"))
	if r and cam then
		cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, r.Position + Vector3.new(0, 1.4, 0)), get(m, "Smooth") / 100)
	end
end, 0.03)

add("Combat", "SilentAim", "Feeds aura the closest target", function(m)
	opt(m, "Range", "slider", 20, { min = 8, max = 22, step = 1 })
end)

add("Combat", "AutoClicker", "Clicks while you hold M1", function(m)
	opt(m, "CPS", "slider", 12, { min = 4, max = 20, step = 1 })
end, nil, function()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
		if BW.sword and BW.sword.swingSwordAtMouse then
			pcall(function()
				BW.sword:swingSwordAtMouse()
			end)
		else
			click(0)
		end
	end
end, 0.08)

add("Combat", "ProjectileAimbot", "Leads projectiles", function(m)
	opt(m, "Range", "slider", 180, { min = 40, max = 280, step = 10 })
end, nil, function(m)
	local _, r, d = nearest(get(m, "Range"))
	if r then
		look(r.Position + Vector3.new(0, 1.5, 0) + r.AssemblyLinearVelocity * (d / 170))
	end
end)

add("Combat", "Velocity", "Cuts knockback", nil, function(on)
	if on and BW.knockback and BW.knockback.applyKnockback then
		local old = BW.knockback.applyKnockback
		BW.knockback.applyKnockback = function(rootp, mass, dir, kb, ...)
			kb = kb or {}
			kb.horizontal = (kb.horizontal or 1) * 0.15
			kb.vertical = (kb.vertical or 1) * 0.4
			return old(rootp, mass, dir, kb, ...)
		end
		table.insert(Modules.Velocity.conns, {
			Disconnect = function()
				BW.knockback.applyKnockback = old
			end,
		})
	elseif on then
		table.insert(Modules.Velocity.conns, RunService.Heartbeat:Connect(function()
			local r = root()
			if r then
				local v = r.AssemblyLinearVelocity
				if Vector3.new(v.X, 0, v.Z).Magnitude > 26 then
					r.AssemblyLinearVelocity = Vector3.new(v.X * 0.2, v.Y, v.Z * 0.2)
				end
			end
		end))
	end
end)

add("Combat", "Sprint", "Holds sprint", nil, nil, function()
	if BW.sprint and BW.sprint.startSprinting then
		pcall(function()
			BW.sprint:startSprinting()
		end)
	else
		local h = hum()
		if h then
			h.WalkSpeed = math.max(h.WalkSpeed, 23)
		end
	end
end, 0.2)

add("Blatant", "Killaura", "Hits nearby enemies", function(m)
	opt(m, "Range", "slider", 18, { min = 8, max = 22, step = 1 })
end, nil, function(m)
	local t, r = nearest(get(m, "Range"))
	if t then
		sendAttack(t, r)
	end
end, 0.09)

add("Blatant", "FastHits", "Shortens aura delay")

add("Blatant", "Fly", "WASD fly", function(m)
	opt(m, "Speed", "slider", 68, { min = 24, max = 140, step = 4 })
end, function(on)
	if not on then
		stopFly()
	end
end, function(m)
	fly(get(m, "Speed"))
end, 0)

add("Blatant", "InfiniteFly", "Keeps fly alive", function(m)
	opt(m, "Speed", "slider", 68, { min = 24, max = 140, step = 4 })
end, function(on)
	if not on and not Modules.Fly.enabled then
		stopFly()
	end
end, function(m)
	fly(get(m, "Speed"))
end, 0)

add("Blatant", "LongJumps", "Boosts jump distance", nil, nil, function()
	local h, r = hum(), root()
	if not h or not r then
		return
	end
	local j = h:GetState() == Enum.HumanoidStateType.Jumping
	if j and not jumpWas then
		local f = Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		if f.Magnitude > 0 then
			r.AssemblyLinearVelocity = r.AssemblyLinearVelocity + f.Unit * 74
		end
	end
	jumpWas = j
end, 0)

add("Blatant", "HighJump", "Raises jump power", function(m)
	opt(m, "Power", "slider", 92, { min = 50, max = 140, step = 4 })
end, function(on, m)
	local h = hum()
	if h then
		h.UseJumpPower = true
		h.JumpPower = on and get(m, "Power") or 50
	end
end)

add("Blatant", "InfiniteJumps", "Air jump", nil, function(on)
	if on then
		table.insert(Modules.InfiniteJumps.conns, UserInputService.JumpRequest:Connect(function()
			local h = hum()
			if h then
				h:ChangeState(Enum.HumanoidStateType.Jumping)
			end
		end))
	end
end)

add("Blatant", "NoFall", "Stops fall damage", nil, nil, function()
	local r, h = root(), hum()
	if r and h and r.AssemblyLinearVelocity.Y < -42 then
		local hit = workspace:Raycast(r.Position, Vector3.new(0, -14, 0))
		if hit then
			r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, -6, r.AssemblyLinearVelocity.Z)
		end
	end
	pcall(function()
		local fall = BW.knit and BW.knit.Controllers and BW.knit.Controllers.FallDamageController
		if fall then
			fall.lastOnGround = os.clock()
		end
	end)
end, 0)

add("Blatant", "Speed", "Walk faster", function(m)
	opt(m, "Speed", "slider", 23, { min = 16, max = 30, step = 1 })
end, function(on)
	if not on and hum() and savedSpeed then
		hum().WalkSpeed = savedSpeed
	end
end, function(m)
	local h = hum()
	if h then
		savedSpeed = savedSpeed or h.WalkSpeed
		h.WalkSpeed = get(m, "Speed")
	end
end)

add("Blatant", "Desync", "Short position desync", nil, nil, function()
	local r = root()
	if not r then
		return
	end
	local cf = r.CFrame
	r.CFrame = cf * CFrame.new(0, 0, -6)
	task.defer(function()
		if r.Parent then
			r.CFrame = cf
		end
	end)
end, 0.2)

add("Render", "ESP", "Enemy outlines", nil, function(on)
	if not on and not (Modules.KitESP and Modules.KitESP.enabled) then
		wipe(pEsp)
	end
end, function()
	drawPlayers(Modules.KitESP.enabled or Modules.KitRender.enabled)
end, 0.08)

add("Render", "BedESP", "Enemy beds", nil, function(on)
	if not on then
		wipe(bEsp)
	end
end, function()
	local me = root()
	for _, bed in ipairs(beds()) do
		local p = posOf(bed)
		if p and me then
			local e = bEsp[bed] or {}
			bEsp[bed] = e
			if not e.h then
				e.h = hl(bed, Color3.fromRGB(255, 90, 90))
			end
			if not e.b then
				e.b = bill(bed)
			end
			local t = e.b:FindFirstChild("T")
			if t then
				t.TextColor3 = Color3.fromRGB(255, 120, 120)
				t.Text = string.format("%s bed\n%dst", tostring(bed:GetAttribute("Team") or "enemy"), math.floor((p - me.Position).Magnitude + 0.5))
			end
		end
	end
end, 0.2)

add("Render", "KitESP", "Shows kits on ESP", nil, nil, function()
	drawPlayers(true)
end, 0.1)

add("Render", "KitRender", "Colors by kit")
add("Render", "SkinChanger", "Recolors you", nil, nil, function()
	local c = char()
	if not c then
		return
	end
	for _, p in ipairs(c:GetChildren()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			p.Color = Color3.fromRGB(255, 186, 122)
		end
	end
end, 0.5)

add("Render", "FPSBooster", "Lowers quality", nil, function(on)
	pcall(function()
		settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
	end)
	Lighting.GlobalShadows = not on
end)

add("Render", "Shaders", "Warm grade", nil, function(on)
	if on then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Saturation = 0.16
		cc.Contrast = 0.08
		cc.TintColor = Color3.fromRGB(255, 228, 214)
		cc.Parent = Lighting
		shader = { cc }
	else
		for _, f in ipairs(shader or {}) do
			f:Destroy()
		end
		shader = {}
	end
end)

add("Render", "NoTexture", "Flattens materials", nil, function(on)
	if on then
		tex = {}
		local function strip(i)
			if i:IsA("BasePart") and not tex[i] then
				tex[i] = i.Material
				i.Material = Enum.Material.SmoothPlastic
			end
		end
		for _, i in ipairs(workspace:GetDescendants()) do
			strip(i)
		end
		texConn = workspace.DescendantAdded:Connect(strip)
		table.insert(Modules.NoTexture.conns, texConn)
	else
		for i, m in pairs(tex or {}) do
			if i.Parent and i:IsA("BasePart") then
				i.Material = m
			end
		end
	end
end)

add("Render", "TargetInfo", "Shows current target")

add("Utility", "AutoWin", "Breaks the closest bed", nil, nil, function()
	local me = root()
	if not me then
		return
	end
	local best, bestP
	for _, bed in ipairs(beds()) do
		local p = posOf(bed)
		if p and (not best or (p - me.Position).Magnitude < (bestP - me.Position).Magnitude) then
			best, bestP = bed, p
		end
	end
	if bestP then
		breakAt(bestP)
	end
end, 0.12)

add("Utility", "AntiLasso", "Clears lasso constraints", nil, nil, function()
	local c = char()
	if not c then
		return
	end
	for _, i in ipairs(c:GetDescendants()) do
		if i:IsA("Constraint") then
			pcall(function()
				i.Enabled = false
			end)
		end
	end
end, 0.15)

add("Utility", "AutoLasso", "Uses lasso on enemies", nil, nil, function()
	local k = string.lower(kitOf(lp))
	if string.find(k, "lasso", 1, true) then
		local t, r = nearest(36)
		if t then
			sendAttack(t, r)
		end
	end
end)

add("Utility", "AutoKit", "Fires kit abilities", nil, nil, function()
	if nearest(22) then
		local kit = BW.knit and BW.knit.Controllers and (BW.knit.Controllers.AbilityController or BW.knit.Controllers.KitAbilityController)
		if kit then
			for _, n in ipairs({ "useAbility", "activateAbility" }) do
				if kit[n] then
					pcall(function()
						kit[n](kit)
					end)
				end
			end
		end
	end
end, 0.25)

add("Utility", "ChestSteal", "Opens nearby chests", nil, nil, function()
	prompts({ "chest", "loot", "open" }, 12)
end, 0.3)

add("Utility", "FastPlace", "Spam place", nil, nil, function()
	if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
		click(1)
	end
end, 0.05)

add("World", "Nuker", "Breaks close blocks", function(m)
	opt(m, "Range", "slider", 8, { min = 4, max = 12, step = 1 })
end, nil, function(m)
	local r, c = root(), char()
	if not r or not c then
		return
	end
	local params = OverlapParams.new()
	params.FilterDescendantsInstances = { c }
	params.FilterType = Enum.RaycastFilterType.Exclude
	local best, d
	for _, p in ipairs(workspace:GetPartBoundsInRadius(r.Position, get(m, "Range"), params)) do
		if p.Size.Magnitude < 26 then
			local nd = (p.Position - r.Position).Magnitude
			if not d or nd < d then
				best, d = p, nd
			end
		end
	end
	if best then
		breakAt(best.Position)
	end
end, 0.08)

add("World", "BlockIn", "Places around you", nil, nil, function()
	local r = root()
	if not r or not cam then
		return
	end
	local old = cam.CFrame
	for _, o in ipairs({ r.CFrame.LookVector * 3, -r.CFrame.LookVector * 3, r.CFrame.RightVector * 3, -r.CFrame.RightVector * 3, Vector3.new(0, -3, 0) }) do
		look(r.Position + o)
		click(1)
	end
	cam.CFrame = old
end, 0.35)

add("Inventory", "AutoBank", "Uses shop / bank prompts", nil, nil, function()
	prompts({ "bank", "shop", "upgrade", "deposit" }, 16)
end, 0.4)

local KIT = {
	AutoCait = { "cait" },
	AutoNyx = { "nyx" },
	AutoElder = { "elder" },
	AutoSilas = { "silas" },
	AutoKadia = { "kadia", "kaida" },
	AutoRaven = { "raven" },
	AutoVoidNight = { "void" },
	AutoHep = { "hep", "heph" },
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
	AutoKrystal = { "krystal" },
}

local function kitOn(keys)
	local k = string.lower(kitOf(lp))
	for _, s in ipairs(keys) do
		if string.find(k, s, 1, true) then
			return true
		end
	end
end

for name, keys in pairs(KIT) do
	add("Kits", name, name .. " assist", nil, nil, function()
		if kitOn(keys) then
			local t, r = nearest(22)
			if t then
				sendAttack(t, r)
			end
			if name == "AutoBuilder" and Modules.BlockIn.tick then
				Modules.BlockIn.tick(Modules.BlockIn)
			end
		end
	end, 0.2)
end

local function glass(inst)
	pcall(function()
		local b = Instance.new("UIBlur")
		b.Size = 18
		b.Parent = inst
	end)
	pcall(function()
		local g = Instance.new("UIGradient")
		g.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(210, 214, 230))
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.15),
			NumberSequenceKeypoint.new(1, 0.45),
		})
		g.Rotation = 90
		g.Parent = inst
	end)
end

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 10)
	c.Parent = p
end

local function stroke(p, a)
	local s = Instance.new("UIStroke")
	s.Color = Color3.fromRGB(255, 255, 255)
	s.Transparency = a or 0.78
	s.Thickness = 1
	s.Parent = p
end

local screen = Instance.new("ScreenGui")
screen.Name = "Quantumware"
screen.ResetOnSpawn = false
screen.IgnoreGuiInset = true
screen.DisplayOrder = 1e6
screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
pcall(function()
	if syn and syn.protect_gui then
		syn.protect_gui(screen)
	end
end)
screen.Parent = parentGui()

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(8, 10, 16)
overlay.BackgroundTransparency = 0.35
overlay.Parent = screen
glass(overlay)

local worldBlur = Instance.new("BlurEffect")
worldBlur.Size = 18
worldBlur.Parent = Lighting

local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.Size = UDim2.fromScale(1, 1)
menu.Parent = overlay

local bar = Instance.new("Frame")
bar.Size = UDim2.new(0, 720, 0, 48)
bar.Position = UDim2.new(0.5, -360, 0, 18)
bar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
bar.BackgroundTransparency = 0.28
bar.Parent = menu
corner(bar, 14)
stroke(bar, 0.72)
glass(bar)

local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Size = UDim2.new(0, 180, 1, 0)
brand.Position = UDim2.fromOffset(18, 0)
brand.Font = Enum.Font.GothamBold
brand.TextSize = 16
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.TextColor3 = Color3.fromRGB(245, 246, 255)
brand.Text = "Quantumware"
brand.Parent = bar

local search = Instance.new("TextBox")
search.Size = UDim2.new(0, 280, 0, 28)
search.Position = UDim2.new(0.5, -140, 0.5, -14)
search.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
search.BackgroundTransparency = 0.88
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.PlaceholderText = "Search"
search.PlaceholderColor3 = Color3.fromRGB(180, 184, 200)
search.TextColor3 = Color3.fromRGB(240, 242, 255)
search.Text = ""
search.ClearTextOnFocus = false
search.Parent = bar
corner(search, 10)
stroke(search, 0.8)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.new(0, 200, 1, 0)
hint.Position = UDim2.new(1, -214, 0, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextColor3 = Color3.fromRGB(190, 194, 210)
hint.Text = "Right Shift"
hint.Parent = bar

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(0, 160, 0, 20)
status.Position = UDim2.fromOffset(18, 72)
status.Font = Enum.Font.GothamMedium
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = Color3.fromRGB(170, 210, 255)
status.Text = "connecting to bedwars..."
status.Parent = menu

local array = Instance.new("Frame")
array.BackgroundTransparency = 1
array.AnchorPoint = Vector2.new(1, 0)
array.Position = UDim2.new(1, -16, 0, 16)
array.Size = UDim2.fromOffset(220, 400)
array.Parent = screen
local al = Instance.new("UIListLayout")
al.HorizontalAlignment = Enum.HorizontalAlignment.Right
al.Padding = UDim.new(0, 3)
al.Parent = array

local targetHud = Instance.new("Frame")
targetHud.Size = UDim2.fromOffset(230, 62)
targetHud.Position = UDim2.new(0.5, -115, 1, -86)
targetHud.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
targetHud.BackgroundTransparency = 0.25
targetHud.Visible = false
targetHud.Parent = screen
corner(targetHud, 12)
stroke(targetHud, 0.75)
glass(targetHud)
local tt = Instance.new("TextLabel")
tt.BackgroundTransparency = 1
tt.Size = UDim2.new(1, -18, 0, 18)
tt.Position = UDim2.fromOffset(12, 8)
tt.Font = Enum.Font.Gotham
tt.TextSize = 12
tt.TextXAlignment = Enum.TextXAlignment.Left
tt.TextColor3 = Color3.fromRGB(180, 184, 200)
tt.Text = "Target"
tt.Parent = targetHud
local tn = Instance.new("TextLabel")
tn.BackgroundTransparency = 1
tn.Size = UDim2.new(1, -18, 0, 24)
tn.Position = UDim2.fromOffset(12, 28)
tn.Font = Enum.Font.GothamBold
tn.TextSize = 16
tn.TextXAlignment = Enum.TextXAlignment.Left
tn.TextColor3 = Color3.fromRGB(245, 246, 255)
tn.Text = "None"
tn.Parent = targetHud

function refreshHud()
	for _, c in ipairs(array:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local names = {}
	for n, m in pairs(Modules) do
		if m.enabled then
			table.insert(names, n)
		end
	end
	table.sort(names, function(a, b)
		return #a > #b
	end)
	for i, n in ipairs(names) do
		local l = Instance.new("TextLabel")
		l.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
		l.BackgroundTransparency = 0.28
		l.Size = UDim2.fromOffset(18 + #n * 7, 22)
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 13
		l.TextColor3 = Color3.fromRGB(240, 242, 255)
		l.Text = n
		l.LayoutOrder = i
		l.Parent = array
		corner(l, 6)
		stroke(l, 0.82)
	end
end

local function drag(handle, win)
	local held, o, s
	handle.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			held, o, s = true, i.Position, win.Position
		end
	end)
	UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 then
			held = false
		end
	end)
	UserInputService.InputChanged:Connect(function(i)
		if held and i.UserInputType == Enum.UserInputType.MouseMovement then
			local d = i.Position - o
			win.Position = UDim2.new(s.X.Scale, s.X.Offset + d.X, s.Y.Scale, s.Y.Offset + d.Y)
		end
	end)
end

local filters = {}
local function window(name, x)
	local data = Cats[name]
	local win = Instance.new("Frame")
	win.Size = UDim2.fromOffset(188, 40)
	win.Position = UDim2.fromOffset(x, 104)
	win.AutomaticSize = Enum.AutomaticSize.Y
	win.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	win.BackgroundTransparency = 0.22
	win.Parent = menu
	corner(win, 14)
	stroke(win, 0.74)
	glass(win)

	local head = Instance.new("TextButton")
	head.AutoButtonColor = false
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 38)
	head.Font = Enum.Font.GothamMedium
	head.TextSize = 14
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.TextColor3 = Color3.fromRGB(236, 238, 250)
	head.Text = "   " .. name
	head.Parent = win
	drag(head, win)

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Position = UDim2.fromOffset(0, 36)
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = win
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 4)
	lay.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 10)
	pad.Parent = list

	for i, mod in ipairs(data.modules) do
		local row = Instance.new("Frame")
		row.Name = mod.name
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BackgroundTransparency = 0.9
		row.Size = UDim2.new(1, 0, 0, 28)
		row.LayoutOrder = i
		row.Parent = list
		corner(row, 8)

		local btn = Instance.new("TextButton")
		btn.AutoButtonColor = false
		btn.BackgroundTransparency = 1
		btn.Size = UDim2.new(1, -22, 1, 0)
		btn.Font = Enum.Font.Gotham
		btn.TextSize = 13
		btn.TextXAlignment = Enum.TextXAlignment.Left
		btn.Text = "  " .. mod.name
		btn.Parent = row

		local more = Instance.new("TextButton")
		more.AutoButtonColor = false
		more.BackgroundTransparency = 1
		more.Size = UDim2.fromOffset(22, 28)
		more.Position = UDim2.new(1, -22, 0, 0)
		more.Font = Enum.Font.GothamBold
		more.TextSize = 12
		more.TextColor3 = Color3.fromRGB(190, 194, 210)
		more.Text = next(mod.options) and ":" or ""
		more.Parent = row

		local extra = Instance.new("Frame")
		extra.BackgroundTransparency = 1
		extra.AutomaticSize = Enum.AutomaticSize.Y
		extra.Size = UDim2.new(1, 0, 0, 0)
		extra.Visible = false
		extra.LayoutOrder = i
		extra.Parent = list
		local el = Instance.new("UIListLayout")
		el.Padding = UDim.new(0, 4)
		el.Parent = extra

		for _, o in pairs(mod.options) do
			if o.kind == "toggle" then
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1, 0, 0, 22)
				b.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				b.BackgroundTransparency = 0.9
				b.Font = Enum.Font.Gotham
				b.TextSize = 12
				b.TextColor3 = Color3.fromRGB(230, 232, 245)
				b.Text = o.name .. "  " .. (o.value and "On" or "Off")
				b.Parent = extra
				corner(b, 6)
				b.MouseButton1Click:Connect(function()
					o.value = not o.value
					b.Text = o.name .. "  " .. (o.value and "On" or "Off")
				end)
			else
				local hold = Instance.new("Frame")
				hold.BackgroundTransparency = 1
				hold.Size = UDim2.new(1, 0, 0, 32)
				hold.Parent = extra
				local lab = Instance.new("TextLabel")
				lab.BackgroundTransparency = 1
				lab.Size = UDim2.new(1, 0, 0, 14)
				lab.Font = Enum.Font.Gotham
				lab.TextSize = 11
				lab.TextXAlignment = Enum.TextXAlignment.Left
				lab.TextColor3 = Color3.fromRGB(190, 194, 210)
				lab.Text = o.name .. "  " .. tostring(o.value)
				lab.Parent = hold
				local bar2 = Instance.new("TextButton")
				bar2.AutoButtonColor = false
				bar2.Text = ""
				bar2.Size = UDim2.new(1, 0, 0, 8)
				bar2.Position = UDim2.fromOffset(0, 18)
				bar2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
				bar2.BackgroundTransparency = 0.85
				bar2.Parent = hold
				corner(bar2, 4)
				local fill = Instance.new("Frame")
				fill.BackgroundColor3 = Color3.fromRGB(230, 234, 255)
				fill.Size = UDim2.new((o.value - o.min) / math.max(o.max - o.min, 1), 0, 1, 0)
				fill.Parent = bar2
				corner(fill, 4)
				bar2.InputBegan:Connect(function(input)
					if input.UserInputType == Enum.UserInputType.MouseButton1 then
						local a = math.clamp((input.Position.X - bar2.AbsolutePosition.X) / math.max(bar2.AbsoluteSize.X, 1), 0, 1)
						o.value = math.floor((o.min + (o.max - o.min) * a) / o.step + 0.5) * o.step
						fill.Size = UDim2.new((o.value - o.min) / math.max(o.max - o.min, 1), 0, 1, 0)
						lab.Text = o.name .. "  " .. tostring(o.value)
					end
				end)
			end
		end

		mod.paint = function()
			row.BackgroundTransparency = mod.enabled and 0.78 or 0.9
			btn.TextColor3 = mod.enabled and Color3.fromRGB(255, 255, 255) or Color3.fromRGB(168, 172, 190)
		end
		mod.paint()
		btn.MouseButton1Click:Connect(function()
			setOn(mod, not mod.enabled)
		end)
		more.MouseButton1Click:Connect(function()
			if next(mod.options) then
				extra.Visible = not extra.Visible
			end
		end)
	end

	return function(q)
		for _, mod in ipairs(data.modules) do
			local row = list:FindFirstChild(mod.name)
			if row then
				row.Visible = q == "" or string.find(string.lower(mod.name), q, 1, true) ~= nil
			end
		end
	end
end

local x = 22
for _, n in ipairs({ "Combat", "Blatant", "Render", "Utility", "World", "Inventory", "Kits" }) do
	table.insert(filters, window(n, x))
	x = x + 200
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(search.Text)
	for _, f in ipairs(filters) do
		f(q)
	end
end)

UserInputService.InputBegan:Connect(function(i, g)
	if g then
		return
	end
	if i.KeyCode == Enum.KeyCode.RightShift then
		local show = not overlay.Visible
		overlay.Visible = show
		worldBlur.Enabled = show
	end
end)

RunService.Heartbeat:Connect(function(dt)
	status.Text = BW.ready and "hooks live" or "waiting for bedwars..."
	status.TextColor3 = BW.ready and Color3.fromRGB(120, 230, 160) or Color3.fromRGB(170, 210, 255)
	local fast = Modules.FastHits.enabled
	for _, m in pairs(Modules) do
		if m.enabled and m.tick then
			local iv = m.interval
			if fast and m.name == "Killaura" then
				iv = 0.04
			end
			m.acc = m.acc + dt
			if iv == 0 or m.acc >= iv then
				m.acc = 0
				pcall(m.tick, m)
			end
		end
	end
	if Modules.TargetInfo.enabled then
		local t = nearest(24)
		targetHud.Visible = t ~= nil
		if t then
			tn.Text = t.DisplayName
		end
	else
		targetHud.Visible = false
	end
end)

lp.CharacterAdded:Connect(function()
	task.wait(0.25)
	stopFly()
end)

refreshHud()
notify("Glass UI loaded. Right Shift toggles it. Wait for hooks live.")
