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

local hookRankRemotes

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
			BW.placer = knit.Controllers and knit.Controllers.BlockPlacementController
			BW.emote = knit.Controllers and (knit.Controllers.EmoteController or knit.Controllers.EmotesController)
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
			pcall(function()
				local getItemMeta = require(ReplicatedStorage.TS.item["item-meta"]).getItemMeta
				if type(dbg.getupvalue) == "function" then
					BW.itemMeta = dbg.getupvalue(getItemMeta, 1)
				end
			end)
			task.defer(function()
				pcall(hookFall)
			end)
			if BW.sword and BW.sword.sendServerRequest then
				BW.attack = dumpRemote(BW.sword.sendServerRequest)
			end
			if BW.breaker then
				for _, fn in pairs(BW.breaker) do
					if type(fn) == "function" then
						local name = dumpRemote(fn)
						if name and not BW.breakRemote then
							BW.breakRemote = name
						end
					end
				end
				if BW.breaker.blockBreaker then
					for _, fn in pairs(BW.breaker.blockBreaker) do
						if type(fn) == "function" and not BW.breakRemote then
							BW.breakRemote = dumpRemote(fn)
						end
					end
				end
			end
			BW.ready = BW.sword ~= nil or BW.client ~= nil
			pcall(function()
				if BW.sword and type(hookSwing) == "function" then
					hookSwing()
				end
			end)
			if hookRankRemotes then
				pcall(hookRankRemotes)
			end
			return BW.ready
		end
		task.wait(0.25)
	end
	return false
end

task.spawn(function()
	local ok = hookKnit()
	notify(ok and "Bedwars hooks ready" or "Hooks missing - still running fallbacks")
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

local function inventory()
	if not BW.store then
		return
	end
	local ok, state = pcall(function()
		return BW.store:getState()
	end)
	if ok and state and state.Inventory and state.Inventory.observedInventory then
		return state.Inventory.observedInventory.inventory
	end
end

local function metaOf(itemType)
	if BW.itemMeta and itemType then
		return BW.itemMeta[itemType]
	end
end

local function isSword(item)
	if not item then
		return false
	end
	local meta = metaOf(item.itemType)
	if meta and meta.sword then
		return true
	end
	local n = string.lower(tostring(item.itemType or "") .. tostring(item.tool and item.tool.Name or ""))
	return string.find(n, "sword", 1, true) or string.find(n, "scythe", 1, true) or string.find(n, "dagger", 1, true) or string.find(n, "spear", 1, true)
end

local function equipSlot(slot)
	if not BW.store or slot == nil then
		return
	end
	pcall(function()
		BW.store:dispatch({
			type = "InventorySelectHotbarSlot",
			slot = slot,
		})
	end)
end

local function equipSword()
	local inv = inventory()
	if inv and inv.items then
		if isSword(inv.hand) then
			return inv.hand.tool
		end
		for slot, item in pairs(inv.items) do
			if isSword(item) then
				equipSlot(slot)
				return item.tool
			end
		end
	end
	return handTool()
end

local function equipBreaker(kind)
	local inv = inventory()
	if not inv or not inv.items then
		return
	end
	local bestSlot, best = nil, 0
	for slot, item in pairs(inv.items) do
		local meta = metaOf(item.itemType)
		local dmg = meta and meta.breakBlock and (meta.breakBlock[kind] or 0) or 0
		if dmg > best then
			bestSlot, best = slot, dmg
		end
	end
	if bestSlot then
		equipSlot(bestSlot)
	end
end

local oldCanSee
local function setWalls(on)
	if not BW.sword or type(BW.sword.canSee) ~= "function" then
		return
	end
	if on and not oldCanSee then
		oldCanSee = BW.sword.canSee
		BW.sword.canSee = function()
			return true
		end
	elseif not on and oldCanSee then
		BW.sword.canSee = oldCanSee
		oldCanSee = nil
	end
end

local function setMissBypass(on)
	if not BW.sword or type(BW.sword.attackEntity) ~= "function" then
		return
	end
	pcall(function()
		dbg.setconstant(BW.sword.attackEntity, 58, on and "damage" or "multiHitCheckDurationSec")
	end)
end

local function lineOfSight(targetRoot)
	local me = root()
	if not me or not cam or not targetRoot then
		return false
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local ignore = { char() }
	if targetRoot.Parent then
		table.insert(ignore, targetRoot.Parent)
	end
	params.FilterDescendantsInstances = ignore
	local delta = targetRoot.Position - cam.CFrame.Position
	return workspace:Raycast(cam.CFrame.Position, delta, params) == nil
end

local function inFov(targetRoot, degrees)
	if not cam or not targetRoot then
		return false
	end
	local delta = targetRoot.Position - cam.CFrame.Position
	if delta.Magnitude < 0.1 then
		return true
	end
	return cam.CFrame.LookVector:Dot(delta.Unit) >= math.cos(math.rad((degrees or 80) / 2))
end

local function pick(range, o)
	o = o or {}
	local me = root()
	if not me then
		return
	end
	local best, bestRoot, bestScore, bestDist
	for _, plr in ipairs(Players:GetPlayers()) do
		local model = plr.Character
		local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		local hp = model and healthOf(model) or 0
		if plr ~= lp and r and hp > 0 and (o.teams or enemy(plr)) then
			local d = (r.Position - me.Position).Magnitude
			local ok = d <= range
			if ok and o.fov and o.fov < 360 then
				ok = inFov(r, o.fov)
			end
			if ok and o.visible then
				ok = lineOfSight(r)
			end
			if ok then
				local score = o.sort == "Health" and hp or o.sort == "Angle" and cam and -cam.CFrame.LookVector:Dot((r.Position - cam.CFrame.Position).Unit) or d
				if not bestScore or score < bestScore then
					best, bestRoot, bestScore, bestDist = plr, r, score, d
				end
			end
		end
	end
	return best, bestRoot, bestDist
end

local attackRemote
local function sendAttack(target, targetRoot, mode, cfg)
	cfg = cfg or {}
	local me = root()
	if not me or not target or not target.Character or not targetRoot then
		return false
	end
	local weapon
	if cfg.switch == false then
		weapon = handTool()
	else
		weapon = equipSword() or handTool()
	end
	mode = mode or "walls"
	local aim = CFrame.lookAt(me.Position, targetRoot.Position)
	local delta = targetRoot.Position - me.Position
	local selfPos = me.Position + aim.LookVector * math.max(delta.Magnitude - 14.2, 0)
	local camPos = cam and cam.CFrame.Position or me.Position
	if mode == "walls" then
		camPos = targetRoot.Position - aim.LookVector * 2.5
	end
	local cursor = mode == "walls" and aim.LookVector or CFrame.lookAt(camPos, targetRoot.Position).LookVector
	if BW.sword then
		pcall(function()
			BW.sword.lastSwingServerTime = workspace:GetServerTimeNow() - 0.45
		end)
		if cfg.swing and type(BW.sword.playSwordEffect) == "function" then
			pcall(BW.sword.playSwordEffect, BW.sword)
		end
	end
	local payload = {
		weapon = weapon,
		chargedAttack = { chargeRatio = 0 },
		lastSwingServerTimeDelta = 0.45,
		entityInstance = target.Character,
		validate = {
			raycast = {
				cameraPosition = { value = camPos },
				cursorDirection = { value = cursor },
			},
			targetPosition = { value = targetRoot.Position },
			selfPosition = { value = selfPos },
		},
	}
	local sent = false
	if BW.client and BW.attack then
		if not attackRemote then
			pcall(function()
				attackRemote = BW.client:Get(BW.attack)
			end)
		end
		if attackRemote then
			sent = pcall(function()
				attackRemote:SendToServer(payload)
			end)
		end
	end
	if not sent and BW.sword and type(BW.sword.sendServerRequest) == "function" then
		sent = pcall(function()
			BW.sword:sendServerRequest(payload)
		end)
	end
	if not sent and BW.sword and type(BW.sword.attackEntity) == "function" then
		sent = pcall(function()
			BW.sword:attackEntity({
				getInstance = function()
					return target.Character
				end,
			})
		end)
	end
	return sent
end

local function snap3(pos)
	return Vector3.new(math.round(pos.X / 3) * 3, math.round(pos.Y / 3) * 3, math.round(pos.Z / 3) * 3)
end

local function breakKind(part)
	local n = string.lower(part.Name .. tostring(part:GetAttribute("BlockType") or part:GetAttribute("blockType") or ""))
	if string.find(n, "wool", 1, true) or string.find(n, "bed", 1, true) then
		return "wool"
	end
	if string.find(n, "wood", 1, true) or string.find(n, "log", 1, true) then
		return "wood"
	end
	return "stone"
end

local breakFn
local function mineBlock(part)
	if not part or not part:IsA("BasePart") then
		return
	end
	equipBreaker(breakKind(part))
	local blockPosition = snap3(part.Position)
	local breaker = BW.breaker and BW.breaker.blockBreaker
	if breaker then
		breaker.breakCooldown = 0
		breaker.cooldown = 0
		breaker.lastBreakTime = 0
		breaker.lastHitTime = 0
		breaker.nextBreakTime = 0
		if not breakFn then
			for name, fn in pairs(breaker) do
				local lower = string.lower(tostring(name))
				if type(fn) == "function" and (lower == "hitblock" or lower == "breakblock" or lower == "damageblock" or string.find(lower, "hit", 1, true)) then
					breakFn = fn
					break
				end
			end
		end
		if breakFn then
			pcall(breakFn, breaker, { blockPosition = blockPosition }, part.Position, Vector3.yAxis)
			pcall(breakFn, breaker, part)
			return
		end
	end
	pcall(function()
		ContextActionService:CallFunction("block-break", Enum.UserInputState.Begin, newproxy(true))
	end)
end

local function collectRemotes(fn, into, seen)
	if type(fn) ~= "function" or type(dbg.getconstants) ~= "function" or seen[fn] then
		return
	end
	seen[fn] = true
	local ok, consts = pcall(dbg.getconstants, fn)
	if ok and type(consts) == "table" then
		for i, v in ipairs(consts) do
			if v == "Client" and type(consts[i + 1]) == "string" then
				into[consts[i + 1]] = true
			end
		end
	end
	if type(dbg.getprotos) == "function" then
		local ok2, protos = pcall(dbg.getprotos, fn)
		if ok2 and type(protos) == "table" then
			for _, p in pairs(protos) do
				collectRemotes(p, into, seen)
			end
		end
	end
end

function hookFall()
	if BW.fallHooked or not (BW.client and BW.knit and BW.knit.Controllers) then
		return
	end
	local fall = BW.knit.Controllers.FallDamageController
	if not fall then
		return
	end
	BW.fallHooked = true
	local names, seen = {}, {}
	for _, fn in pairs(fall) do
		collectRemotes(fn, names, seen)
	end
	for name in pairs(names) do
		pcall(function()
			local remote = BW.client:Get(name)
			if remote and type(remote.SendToServer) == "function" then
				local old = remote.SendToServer
				remote.SendToServer = function(self, ...)
					if BW.nofall then
						return
					end
					return old(self, ...)
				end
			end
		end)
	end
	if not BW.namecall and type(hookmetamethod) == "function" and type(getnamecallmethod) == "function" then
		BW.namecall = true
		local old
		old = hookmetamethod(game, "__namecall", function(self, ...)
			if BW.nofall then
				local method = getnamecallmethod()
				if method == "FireServer" or method == "fireServer" then
					local ok, n = pcall(function()
						return self.Name
					end)
					if ok and type(n) == "string" and string.find(string.lower(n), "fall", 1, true) then
						return
					end
				end
			end
			return old(self, ...)
		end)
	end
end

local function clearFall()
	local fall = BW.knit and BW.knit.Controllers and BW.knit.Controllers.FallDamageController
	if not fall then
		return
	end
	local nowTick, nowClock = tick(), os.clock()
	local nowServer = workspace:GetServerTimeNow()
	for key, value in pairs(fall) do
		if type(value) == "number" then
			local name = string.lower(tostring(key))
			if string.find(name, "ground", 1, true) or string.find(name, "fall", 1, true) or string.find(name, "land", 1, true) or string.find(name, "time", 1, true) then
				if value > 1e8 then
					fall[key] = nowTick
				elseif value > 1e5 then
					fall[key] = nowServer
				else
					fall[key] = nowClock
				end
			end
		end
	end
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
	if #list == 0 and os.clock() % 2 < 0.2 then
		local map = workspace:FindFirstChild("Map")
		if map then
			for _, inst in ipairs(map:GetChildren()) do
				if string.find(string.lower(inst.Name), "bed", 1, true) then
					add(inst)
				end
			end
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

local promptCache, promptAt = {}, 0
local function prompts(needles, range)
	local me = root()
	if not me then
		return
	end
	if os.clock() - promptAt > 1.5 then
		promptAt = os.clock()
		promptCache = {}
		for _, inst in ipairs(workspace:GetDescendants()) do
			if inst:IsA("ProximityPrompt") then
				table.insert(promptCache, inst)
			end
		end
	end
	for _, inst in ipairs(promptCache) do
		if inst.Parent then
			local part = inst.Parent:IsA("BasePart") and inst.Parent or inst.Parent:FindFirstChildWhichIsA("BasePart")
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
cat("World")
cat("Larping")

local function opt(mod, name, kind, value, extra)
	mod.options[name] = {
		name = name,
		kind = kind,
		value = value,
		min = extra and extra.min or 0,
		max = extra and extra.max or 100,
		step = extra and extra.step or 1,
		list = extra and extra.list,
		suffix = extra and extra.suffix or "",
		order = #mod.order + 1,
	}
	table.insert(mod.order, name)
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
				elseif type(c) == "table" and c.Disconnect then
					c.Disconnect()
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
		order = {},
		conns = {},
		toggle = toggle,
		tick = tick,
		interval = interval or 0.06,
		acc = 0,
	}
	if setup then
		setup(mod)
	end
	opt(mod, "Bind", "bind", nil)
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

local shader, tex, jumpWas, savedSpeed, swingOrig
local menuOpen = false
local M1 = Enum.UserInputType.MouseButton1
local M2 = Enum.UserInputType.MouseButton2

local function held(btn)
	return UserInputService:IsMouseButtonPressed(btn) and not UserInputService:GetFocusedTextBox() and not menuOpen
end

local function handKind()
	local inv = inventory()
	local hand = inv and inv.hand
	if not hand then
		return ""
	end
	local meta = metaOf(hand.itemType)
	if isSword(hand) then
		return "sword"
	end
	if meta and meta.block then
		return "block"
	end
	local n = string.lower(tostring(hand.itemType or ""))
	for _, k in ipairs({ "bow", "crossbow", "fireball", "snowball", "arrow", "tnt" }) do
		if string.find(n, k, 1, true) then
			return "projectile"
		end
	end
	return n
end

local function equipBlock()
	local inv = inventory()
	if not inv or not inv.items then
		return false
	end
	local handMeta = inv.hand and metaOf(inv.hand.itemType)
	if handMeta and handMeta.block then
		return true
	end
	for slot, item in pairs(inv.items) do
		local meta = metaOf(item.itemType)
		if meta and meta.block then
			equipSlot(slot)
			return true
		end
	end
	return false
end

local function blockPlacer()
	return BW.placer and BW.placer.blockPlacer
end

local function placeGrid(grid)
	local placer = blockPlacer()
	if not placer or not grid then
		return false
	end
	return pcall(placer.placeBlock, placer, grid)
end

local function mouseGrid()
	local placer = blockPlacer()
	if not placer then
		return
	end
	local ok, info = pcall(function()
		return placer.clientManager:getBlockSelector():getMouseInfo(0)
	end)
	if ok and info and info.placementPosition == info.placementPosition then
		return info.placementPosition
	end
end

local function refreshBypass()
	local on = false
	for _, n in ipairs({ "Killaura", "Reach", "SilentAim", "Silent Aura" }) do
		if Modules[n] and Modules[n].enabled then
			on = true
		end
	end
	setMissBypass(on)
end

local function onSwing()
	local me = root()
	if not me then
		return
	end
	local sa = Modules.SilentAim
	if sa and sa.enabled then
		local walls = get(sa, "Walls")
		local t, r = pick(get(sa, "Range"), { fov = get(sa, "FOV"), visible = not walls, sort = get(sa, "Priority") })
		if t then
			sendAttack(t, r, walls and "walls" or "silent", { switch = false })
			return
		end
	end
	local rc = Modules.Reach
	if rc and rc.enabled then
		local range = get(rc, "Range")
		local mouse = lp:GetMouse()
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char() }
		local hit = workspace:Raycast(mouse.UnitRay.Origin, mouse.UnitRay.Direction * (range + 14), params)
		local model = hit and hit.Instance and hit.Instance:FindFirstAncestorOfClass("Model")
		local plr = model and Players:GetPlayerFromCharacter(model)
		local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		if plr and enemy(plr) and r then
			local d = (r.Position - me.Position).Magnitude
			local moving = me.AssemblyLinearVelocity.Magnitude > 3
			if d > 13 and d <= range and (moving or not get(rc, "Only moving")) then
				sendAttack(plr, r, "reach", { switch = false })
			end
		end
	end
end

local function hookSwing()
	if not BW.sword or type(BW.sword.swingSwordAtMouse) ~= "function" then
		return
	end
	if not swingOrig then
		swingOrig = BW.sword.swingSwordAtMouse
	end
	BW.sword.swingSwordAtMouse = function(...)
		local result = swingOrig(...)
		onSwing()
		return result
	end
end

local function flyStep(speed, vspeed)
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
	local look = cam.CFrame.LookVector
	local right = cam.CFrame.RightVector
	local flat = Vector3.new(look.X, 0, look.Z)
	local side = Vector3.new(right.X, 0, right.Z)
	local m = Vector3.zero
	if UserInputService:IsKeyDown(Enum.KeyCode.W) then
		m += flat
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.S) then
		m -= flat
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.D) then
		m += side
	end
	if UserInputService:IsKeyDown(Enum.KeyCode.A) then
		m -= side
	end
	local v = m.Magnitude > 0 and m.Unit * speed or Vector3.zero
	local y = 0
	if UserInputService:IsKeyDown(Enum.KeyCode.Space) then
		y = vspeed
	elseif UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
		y = -vspeed
	end
	flyVel.VectorVelocity = Vector3.new(v.X, y, v.Z)
end

local function mineWith(part, autoTool)
	if autoTool then
		mineBlock(part)
	else
		local saved = equipBreaker
		equipBreaker = function() end
		mineBlock(part)
		equipBreaker = saved
	end
end

local function breakBedStep(range, defenseFirst, autoTool)
	local r = root()
	if not r then
		return
	end
	local bedPart, bedPos, bedDist
	for _, bed in ipairs(beds()) do
		local p = posOf(bed)
		if p then
			local d = (p - r.Position).Magnitude
			if d <= range and (not bedDist or d < bedDist) then
				bedPart = bed:IsA("BasePart") and bed or bed:FindFirstChildWhichIsA("BasePart", true)
				bedPos, bedDist = p, d
			end
		end
	end
	if not bedPart then
		return
	end
	if defenseFirst then
		local bedModel = bedPart:FindFirstAncestorWhichIsA("Model")
		if bedModel and not string.find(string.lower(bedModel.Name), "bed", 1, true) then
			bedModel = nil
		end
		local params = OverlapParams.new()
		params.FilterType = Enum.RaycastFilterType.Exclude
		params.FilterDescendantsInstances = { char(), bedModel or bedPart }
		local guard, guardDist
		for _, p in ipairs(workspace:GetPartBoundsInRadius(bedPos, 9, params)) do
			local s = p.Size
			local owner = p:FindFirstAncestorOfClass("Model")
			local isChar = owner and owner:FindFirstChildOfClass("Humanoid")
			if not isChar and p.CanCollide and s.X <= 4 and s.Y <= 4 and s.Z <= 4 then
				local d = (p.Position - r.Position).Magnitude
				if d <= range and (not guardDist or d < guardDist) then
					guard, guardDist = p, d
				end
			end
		end
		if guard then
			mineWith(guard, autoTool)
			return
		end
	end
	mineWith(bedPart, autoTool)
end

local function drawESP()
	local esp, kitEsp, kitRender = Modules.ESP, Modules.KitESP, Modules.KitRender
	local me = root()
	local on = (esp and esp.enabled) or (kitEsp and kitEsp.enabled) or (kitRender and kitRender.enabled)
	local range = esp.enabled and get(esp, "Range") or 400
	local teams = esp.enabled and get(esp, "Teammates")
	for _, plr in ipairs(Players:GetPlayers()) do
		local model = plr.Character
		local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
		local e = pEsp[plr]
		local keep = on and me and plr ~= lp and r and healthOf(model) > 0 and (teams or enemy(plr)) and (r.Position - me.Position).Magnitude <= range
		if not keep then
			if e then
				if e.h then
					e.h:Destroy()
				end
				if e.b then
					e.b:Destroy()
				end
				pEsp[plr] = nil
			end
		else
			local col = colorOf(plr)
			local kit = kitOf(plr)
			if kitRender and kitRender.enabled and kit ~= "" then
				col = Color3.fromHSV(((#kit * 37) % 360) / 360, get(kitRender, "Saturation") / 100, 1)
			end
			e = e or {}
			pEsp[plr] = e
			if not e.h or not e.h.Parent then
				e.h = hl(model, col)
			end
			e.h.Adornee = model
			e.h.FillColor, e.h.OutlineColor = col, col
			e.h.FillTransparency = esp and esp.enabled and (1 - get(esp, "Fill") / 100) or 0.85
			e.h.Enabled = (esp and esp.enabled) or (kitRender and kitRender.enabled) or true
			local head = model:FindFirstChild("Head") or r
			if not e.b or not e.b.Parent then
				e.b = bill(head)
			end
			e.b.Adornee = head
			local lines, info = {}, {}
			if not esp or not esp.enabled or get(esp, "Names") then
				table.insert(lines, plr.DisplayName)
			end
			if esp and esp.enabled and get(esp, "Health") then
				table.insert(info, math.floor(healthOf(model) + 0.5) .. "hp")
			end
			if esp and esp.enabled and get(esp, "Distance") then
				table.insert(info, math.floor((r.Position - me.Position).Magnitude + 0.5) .. "m")
			end
			if #info > 0 then
				table.insert(lines, table.concat(info, "  "))
			end
			if kitEsp and kitEsp.enabled and kit ~= "" then
				table.insert(lines, get(kitEsp, "Uppercase") and string.upper(kit) or kit)
			end
			local t = e.b:FindFirstChild("T")
			if t then
				t.TextColor3 = col
				t.Text = table.concat(lines, "\n")
				t.TextSize = esp and esp.enabled and get(esp, "Text size") or 13
			end
		end
	end
end

local function noM1Gate(m)
	return get(m, "Click only") and not held(M1)
end

add("Combat", "AimAssist", "Smoothly pulls your aim onto enemies", function(m)
	opt(m, "Range", "slider", 18, { min = 6, max = 30, suffix = " st" })
	opt(m, "Smooth", "slider", 12, { min = 2, max = 60, suffix = "%" })
	opt(m, "FOV", "slider", 90, { min = 20, max = 360, step = 10, suffix = "\u{B0}" })
	opt(m, "Click only", "toggle", true)
	opt(m, "Sword only", "toggle", true)
	opt(m, "Through walls", "toggle", false)
end, nil, function(m)
	if noM1Gate(m) or (get(m, "Sword only") and handKind() ~= "sword") then
		return
	end
	local _, r = pick(get(m, "Range"), { fov = get(m, "FOV"), visible = not get(m, "Through walls"), sort = "Angle" })
	if r and cam then
		local goal = CFrame.lookAt(cam.CFrame.Position, r.Position + Vector3.new(0, 1.2, 0))
		cam.CFrame = cam.CFrame:Lerp(goal, get(m, "Smooth") / 100)
	end
end, 0)

add("Combat", "SilentAim", "Your own swings hit the best enemy in FOV", function(m)
	opt(m, "Range", "slider", 16, { min = 8, max = 22, suffix = " st" })
	opt(m, "FOV", "slider", 120, { min = 20, max = 360, step = 10, suffix = "\u{B0}" })
	opt(m, "Priority", "list", "Angle", { list = { "Angle", "Distance", "Health" } })
	opt(m, "Walls", "toggle", false)
end, function(on)
	refreshBypass()
	if on then
		hookSwing()
	end
end, function()
	if not swingOrig then
		hookSwing()
	end
end, 1)

add("Combat", "Reach", "Extends swings you aim yourself, no walls", function(m)
	opt(m, "Range", "slider", 18, { min = 14, max = 22, suffix = " st" })
	opt(m, "Only moving", "toggle", false)
end, function(on)
	refreshBypass()
	if on then
		hookSwing()
	end
end, function()
	if not swingOrig then
		hookSwing()
	end
end, 1)

add("Combat", "Silent Aura", "Closet aura: visible targets in FOV, slower hits", function(m)
	opt(m, "Range", "slider", 15, { min = 8, max = 20, suffix = " st" })
	opt(m, "FOV", "slider", 80, { min = 20, max = 360, step = 10, suffix = "\u{B0}" })
	opt(m, "Delay", "slider", 160, { min = 60, max = 500, step = 10, suffix = "ms" })
	opt(m, "Priority", "list", "Distance", { list = { "Distance", "Health", "Angle" } })
	opt(m, "Auto switch", "toggle", false)
	opt(m, "Swing", "toggle", true)
	opt(m, "Click only", "toggle", false)
end, refreshBypass, function(m)
	if noM1Gate(m) then
		return
	end
	local t, r = pick(get(m, "Range"), { fov = get(m, "FOV"), visible = true, sort = get(m, "Priority") })
	if t then
		sendAttack(t, r, "silent", { switch = get(m, "Auto switch"), swing = get(m, "Swing") })
	end
end, function(m)
	return get(m, "Delay") / 1000
end)

add("Combat", "AutoClicker", "Swings or places blocks while you hold M1", function(m)
	opt(m, "CPS", "slider", 12, { min = 4, max = 20 })
	opt(m, "Place blocks", "toggle", true)
	opt(m, "Randomize", "toggle", true)
end, nil, function(m)
	if not held(M1) then
		return
	end
	if handKind() == "block" then
		if get(m, "Place blocks") then
			task.spawn(placeGrid, mouseGrid())
		end
	elseif BW.sword and BW.sword.swingSwordAtMouse then
		pcall(BW.sword.swingSwordAtMouse, BW.sword)
	else
		click(0)
	end
end, function(m)
	local base = 1 / get(m, "CPS")
	return get(m, "Randomize") and base * (0.85 + math.random() * 0.3) or base
end)

add("Combat", "Sprint", "Always sprints", nil, nil, function()
	if BW.sprint and BW.sprint.startSprinting then
		pcall(BW.sprint.startSprinting, BW.sprint)
	end
end, 0.25)

add("Blatant", "Killaura", "Hits everyone around you, through walls, with reach", function(m)
	opt(m, "Range", "slider", 22, { min = 8, max = 22, suffix = " st" })
	opt(m, "Delay", "slider", 80, { min = 20, max = 400, step = 10, suffix = "ms" })
	opt(m, "FOV", "slider", 360, { min = 30, max = 360, step = 10, suffix = "\u{B0}" })
	opt(m, "Priority", "list", "Distance", { list = { "Distance", "Health", "Angle" } })
	opt(m, "Walls", "toggle", true)
	opt(m, "Multi target", "toggle", false)
	opt(m, "Auto switch", "toggle", true)
	opt(m, "Swing", "toggle", true)
end, function(on, m)
	setWalls(on and get(m, "Walls"))
	refreshBypass()
	if on then
		hookSwing()
	end
end, function(m)
	local walls = get(m, "Walls")
	local cfg = { switch = get(m, "Auto switch"), swing = get(m, "Swing") }
	local mode = walls and "walls" or "silent"
	if get(m, "Multi target") then
		local me = root()
		for _, plr in ipairs(Players:GetPlayers()) do
			local model = plr.Character
			local r = model and (model:FindFirstChild("HumanoidRootPart") or model.PrimaryPart)
			if me and r and enemy(plr) and healthOf(model) > 0 and (r.Position - me.Position).Magnitude <= get(m, "Range") and inFov(r, get(m, "FOV")) and (walls or lineOfSight(r)) then
				sendAttack(plr, r, mode, cfg)
			end
		end
	else
		local t, r = pick(get(m, "Range"), { fov = get(m, "FOV"), visible = not walls, sort = get(m, "Priority") })
		if t then
			sendAttack(t, r, mode, cfg)
		end
	end
end, function(m)
	local d = get(m, "Delay")
	local fh = Modules.FastHits
	if fh and fh.enabled then
		d = math.min(d, get(fh, "Delay"))
	end
	return d / 1000
end)

add("Blatant", "FastHits", "Overrides Killaura delay with a faster one", function(m)
	opt(m, "Delay", "slider", 35, { min = 10, max = 100, step = 5, suffix = "ms" })
end)

add("Blatant", "Fly", "WASD fly, Space up, Shift down", function(m)
	opt(m, "Speed", "slider", 60, { min = 20, max = 140, step = 2 })
	opt(m, "Vertical", "slider", 45, { min = 10, max = 120, step = 5 })
end, function(on)
	if not on then
		stopFly()
	end
end, function(m)
	flyStep(get(m, "Speed"), get(m, "Vertical"))
end, 0)

add("Blatant", "InfiniteJumps", "Jump again in mid air", function(m)
	opt(m, "Boost", "slider", 50, { min = 30, max = 120, step = 5 })
end, function(on, m)
	if on then
		table.insert(m.conns, UserInputService.JumpRequest:Connect(function()
			local r = root()
			if r and not menuOpen then
				r.AssemblyLinearVelocity = Vector3.new(r.AssemblyLinearVelocity.X, get(m, "Boost"), r.AssemblyLinearVelocity.Z)
			end
		end))
	end
end)

add("Blatant", "NoFall", "Cancels fall damage, fall speed stays normal", function(m)
	opt(m, "Reset timer", "toggle", true)
end, function(on)
	BW.nofall = on
	if on then
		pcall(hookFall)
	end
end, function(m)
	if not BW.fallHooked then
		pcall(hookFall)
	end
	if get(m, "Reset timer") then
		clearFall()
	end
end, 0)

add("Blatant", "Speed", "Walk faster", function(m)
	opt(m, "Speed", "slider", 23, { min = 16, max = 40 })
	opt(m, "Mode", "list", "Velocity", { list = { "Velocity", "WalkSpeed" } })
end, function(on)
	local h = hum()
	if not on and h and savedSpeed then
		h.WalkSpeed = savedSpeed
		savedSpeed = nil
	end
end, function(m)
	local h, r = hum(), root()
	if not h or not r then
		return
	end
	if get(m, "Mode") == "WalkSpeed" then
		savedSpeed = savedSpeed or h.WalkSpeed
		h.WalkSpeed = get(m, "Speed")
	elseif h.MoveDirection.Magnitude > 0 then
		local v = h.MoveDirection.Unit * get(m, "Speed")
		r.AssemblyLinearVelocity = Vector3.new(v.X, r.AssemblyLinearVelocity.Y, v.Z)
	end
end, 0)

add("Render", "ESP", "Outlines and tags enemies", function(m)
	opt(m, "Range", "slider", 300, { min = 50, max = 1000, step = 50, suffix = " st" })
	opt(m, "Fill", "slider", 35, { min = 0, max = 100, step = 5, suffix = "%" })
	opt(m, "Text size", "slider", 13, { min = 9, max = 20 })
	opt(m, "Names", "toggle", true)
	opt(m, "Health", "toggle", true)
	opt(m, "Distance", "toggle", true)
	opt(m, "Teammates", "toggle", false)
end, function()
	drawESP()
end, drawESP, 0.08)

add("Render", "BedESP", "Highlights enemy beds", function(m)
	opt(m, "Range", "slider", 600, { min = 50, max = 1500, step = 50, suffix = " st" })
	opt(m, "Distance", "toggle", true)
	opt(m, "Team color", "toggle", true)
end, function(on)
	if not on then
		wipe(bEsp)
	end
end, function(m)
	local me = root()
	local seen = {}
	for _, bed in ipairs(beds()) do
		local p = posOf(bed)
		if p and me and (p - me.Position).Magnitude <= get(m, "Range") then
			seen[bed] = true
			local team = bed:GetAttribute("Team")
			local col = (get(m, "Team color") and team and TEAM_COLORS[tostring(team)]) or Color3.fromRGB(255, 90, 90)
			local e = bEsp[bed] or {}
			bEsp[bed] = e
			if not e.h or not e.h.Parent then
				e.h = hl(bed, col)
			end
			e.h.FillColor, e.h.OutlineColor = col, col
			if not e.b or not e.b.Parent then
				e.b = bill(bed)
			end
			local t = e.b:FindFirstChild("T")
			if t then
				t.TextColor3 = col
				t.Text = tostring(team or "Enemy") .. " bed" .. (get(m, "Distance") and ("\n" .. math.floor((p - me.Position).Magnitude + 0.5) .. "m") or "")
			end
		end
	end
	for bed, e in pairs(bEsp) do
		if not seen[bed] then
			if e.h then
				e.h:Destroy()
			end
			if e.b then
				e.b:Destroy()
			end
			bEsp[bed] = nil
		end
	end
end, 0.25)

add("Render", "KitESP", "Adds each player's kit to their tag", function(m)
	opt(m, "Uppercase", "toggle", false)
end, function()
	drawESP()
end, drawESP, 0.15)

add("Render", "TargetInfo", "Shows your closest target", function(m)
	opt(m, "Range", "slider", 24, { min = 8, max = 60, suffix = " st" })
end)

local RANK_LIST = {
	"Bronze 1", "Bronze 2", "Bronze 3", "Bronze 4",
	"Silver 1", "Silver 2", "Silver 3", "Silver 4",
	"Gold 1", "Gold 2", "Gold 3", "Gold 4",
	"Platinum 1", "Platinum 2", "Platinum 3", "Platinum 4",
	"Diamond 1", "Diamond 2", "Diamond 3",
	"Emerald 1", "Emerald 2", "Emerald 3", "Emerald 4",
	"Nightmare",
}

local RANK_COLOR = {
	Bronze = Color3.fromRGB(176, 112, 64),
	Silver = Color3.fromRGB(198, 206, 214),
	Gold = Color3.fromRGB(255, 190, 60),
	Platinum = Color3.fromRGB(55, 230, 220),
	Diamond = Color3.fromRGB(70, 150, 255),
	Emerald = Color3.fromRGB(50, 210, 130),
	Nightmare = Color3.fromRGB(186, 92, 255),
}

local RANK_IMAGE = {
	Bronze = "rbxassetid://7904293227",
	Silver = "rbxassetid://7904292748",
	Gold = "rbxassetid://7904293006",
	Platinum = "rbxassetid://7904292835",
	Diamond = "rbxassetid://7904293114",
	Emerald = "rbxassetid://12599231807",
	Nightmare = "rbxassetid://107117112416767",
}

local function tierOf(rank)
	return (string.match(tostring(rank or ""), "^(%a+)") or "Platinum")
end

local function asExecutor()
	if type(setthreadidentity) == "function" then
		pcall(setthreadidentity, 8)
	elseif type(syn) == "table" and type(syn.set_thread_identity) == "function" then
		pcall(syn.set_thread_identity, 8)
	end
end

local rankMeta
local function loadRankMeta()
	if rankMeta then
		return rankMeta
	end
	pcall(function()
		rankMeta = require(ReplicatedStorage.TS.rank["rank-meta"]).RankMeta
	end)
	if type(rankMeta) == "table" then
		for _, div in pairs(rankMeta) do
			if type(div) == "table" and type(div.name) == "string" and type(div.image) == "string" then
				RANK_IMAGE[tierOf(div.name)] = div.image
			end
		end
	end
	return rankMeta
end

local function imageForRank(rank)
	loadRankMeta()
	local want = string.lower(tostring(rank or ""))
	if type(rankMeta) == "table" then
		for _, div in pairs(rankMeta) do
			if type(div) == "table" and type(div.name) == "string" and string.lower(div.name) == want and type(div.image) == "string" then
				return div.image
			end
		end
	end
	return RANK_IMAGE[tierOf(rank)]
end

local function isRankImage(image)
	local id = string.match(tostring(image or ""), "%d+")
	if not id then
		return false
	end
	loadRankMeta()
	for _, asset in pairs(RANK_IMAGE) do
		if string.find(asset, id, 1, true) then
			return true
		end
	end
	if type(rankMeta) == "table" then
		for _, div in pairs(rankMeta) do
			if type(div) == "table" and type(div.image) == "string" and string.find(div.image, id, 1, true) then
				return true
			end
		end
	end
	return false
end

local function rankColor(rank)
	loadRankMeta()
	local want = string.lower(tostring(rank or ""))
	if type(rankMeta) == "table" then
		for _, div in pairs(rankMeta) do
			if type(div) == "table" and type(div.name) == "string" and string.lower(div.name) == want then
				for _, key in ipairs({ "color", "progressColor", "barColor", "backgroundColor" }) do
					if typeof(div[key]) == "Color3" then
						return div[key]
					end
				end
			end
		end
	end
	return RANK_COLOR[tierOf(rank)] or RANK_COLOR.Platinum
end

local function rpParts(m)
	local rank = tostring(get(m, "Rank") or "Nightmare")
	if tierOf(rank) == "Nightmare" then
		local raw = math.clamp(math.floor(tonumber(get(m, "Nightmare RP")) or 0), 0, 1000)
		return rank, raw, 1000, string.format("%d RP", raw)
	end
	local shown = math.clamp(math.floor(tonumber(get(m, "RP")) or 0), 0, 100)
	return rank, shown, 100, string.format("%d RP / 100", shown)
end

local function plainText(text)
	text = string.gsub(tostring(text or ""), "<.->", "")
	text = string.gsub(text, "\n", " ")
	return string.match(text, "^%s*(.-)%s*$") or text
end

local function isRpLine(text)
	local plain = plainText(text)
	if plain == "" or #plain > 32 then
		return false
	end
	local lower = string.lower(plain)
	if string.find(lower, "leaderboard", 1, true) or not string.find(lower, "rp", 1, true) then
		return false
	end
	return string.find(plain, "%d") ~= nil
end

local nmTrack, nmEffect, nmFollow, nmAsset, nmLooked, nmMissing, nmKey, nmSent
local function stopNm()
	if nmFollow then
		pcall(function()
			RunService:UnbindFromRenderStep("QW_NMFollow")
		end)
		nmFollow = false
	end
	local h = hum()
	if h then
		for _, track in ipairs(h:GetPlayingAnimationTracks()) do
			if track == nmTrack or string.find(string.lower(tostring(track.Name)), "nightmare", 1, true) then
				pcall(function()
					track:Stop(0.05)
				end)
			end
		end
	end
	if nmTrack then
		pcall(function()
			nmTrack:Stop(0.05)
			nmTrack:Destroy()
		end)
		nmTrack = nil
	end
	if nmEffect then
		nmEffect:Destroy()
		nmEffect = nil
	end
	local c = char()
	if c and c:GetAttribute("PlayingEmote") ~= nil then
		pcall(function()
			c:SetAttribute("PlayingEmote", nil)
		end)
	end
	local ctrl = BW.emote or (BW.knit and BW.knit.Controllers and (BW.knit.Controllers.EmoteController or BW.knit.Controllers.EmotesController))
	local maid = ctrl and ctrl.emoteAudioMaids and ctrl.emoteAudioMaids[lp.UserId]
	if maid and maid.DoCleaning then
		pcall(function()
			maid:DoCleaning()
		end)
	end
end

local function nightmareEmote()
	local emoteMeta = require(ReplicatedStorage.TS.locker.emote["emote-meta"]).EmoteMeta
	local emoteType = require(ReplicatedStorage.TS.locker.emote["emote-type"]).EmoteType
	if emoteType and emoteType.NIGHTMARE and emoteMeta[emoteType.NIGHTMARE] then
		return emoteType.NIGHTMARE, emoteMeta[emoteType.NIGHTMARE]
	end
	for key, meta in pairs(emoteMeta) do
		if key ~= (emoteType and emoteType.NONE) and type(meta) == "table" and type(meta.name) == "string" and string.lower(meta.name) == "nightmare" then
			return key, meta
		end
	end
end

local function findNmAsset()
	if nmLooked then
		return nmAsset
	end
	nmLooked = true
	local best
	for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
		local lname = string.lower(obj.Name)
		if string.find(lname, "nightmare", 1, true) and (obj:IsA("Model") or obj:IsA("Folder")) and obj:FindFirstChildWhichIsA("BasePart", true) then
			best = obj
			if obj.Name == "NightmareEmote" or obj.Name == "Nightmare_1" then
				break
			end
		end
	end
	nmAsset = best
	return best
end

local function attachAura(model, r)
	nmEffect = model:Clone()
	nmEffect.Name = "QW_Nightmare"
	for _, p in ipairs(nmEffect:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Anchored = true
		elseif p:IsA("ParticleEmitter") or p:IsA("Beam") or p:IsA("Trail") then
			p.Enabled = true
		end
	end
	nmEffect.Parent = workspace
	pcall(function()
		nmEffect:PivotTo(r.CFrame * CFrame.new(0, -2, 0))
	end)
	local outer, middle = nmEffect:FindFirstChild("Outer", true), nmEffect:FindFirstChild("Middle", true)
	if outer and outer:IsA("BasePart") then
		TweenService:Create(outer, TweenInfo.new(1.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = outer.Orientation + Vector3.new(0, 360, 0),
		}):Play()
	end
	if middle and middle:IsA("BasePart") then
		TweenService:Create(middle, TweenInfo.new(12.5, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, -1), {
			Orientation = middle.Orientation + Vector3.new(0, -360, 0),
		}):Play()
	end
	nmFollow = true
	RunService:BindToRenderStep("QW_NMFollow", Enum.RenderPriority.Last.Value, function()
		local rootPart = root()
		if nmEffect and rootPart then
			pcall(function()
				nmEffect:PivotTo(rootPart.CFrame * CFrame.new(0, -2, 0))
			end)
		end
	end)
end

local function sendEmote(key)
	if nmSent or not BW.client or not key then
		return
	end
	local ctrl = BW.emote
	local remoteName
	if ctrl and type(dbg.getconstants) == "function" then
		for _, fn in pairs(ctrl) do
			if type(fn) == "function" then
				local ok, consts = pcall(dbg.getconstants, fn)
				if ok and type(consts) == "table" then
					for i, value in ipairs(consts) do
						if value == "Client" and type(consts[i + 1]) == "string" and string.find(string.lower(consts[i + 1]), "emote", 1, true) then
							remoteName = consts[i + 1]
							break
						end
					end
				end
			end
			if remoteName then
				break
			end
		end
	end
	if not remoteName then
		return
	end
	local ok, remote = pcall(function()
		return BW.client:Get(remoteName)
	end)
	if ok and remote and remote.SendToServer then
		nmSent = true
		pcall(function()
			remote:SendToServer({ emote = key })
		end)
	end
end

local function playNm()
	local c, h = char(), hum()
	if not c or not h then
		return
	end
	if nmTrack and nmTrack.IsPlaying and c:GetAttribute("PlayingEmote") ~= nil then
		return
	end
	local key, meta
	local ok, errKey, errMeta = pcall(nightmareEmote)
	if ok then
		key, meta = errKey, errMeta
	end
	if not meta or key == nil then
		if not nmMissing then
			nmMissing = true
			notify("Nightmare emote is not in this place's emote list")
		end
		return
	end
	stopNm()
	nmKey = key
	c = char()
	h = hum()
	if not c or not h then
		return
	end
	local ctrl = BW.emote or (BW.knit and BW.knit.Controllers and (BW.knit.Controllers.EmoteController or BW.knit.Controllers.EmotesController))
	BW.emote = ctrl
	c:SetAttribute("PlayingEmote", key)
	local playSounds = ctrl and (ctrl.createEmoteBeginAudioPlayers or ctrl.playEmoteBeginSounds)
	if playSounds then
		pcall(playSounds, ctrl, key, lp)
	end
	sendEmote(key)
	local animation = meta.animation
	if not animation and meta.emoteDisplayType then
		pcall(function()
			local display = require(ReplicatedStorage.TS.locker.emote["emote-display-meta"]).EmoteDisplayMeta[meta.emoteDisplayType]
			animation = display and display.animation
		end)
	end
	if animation and animation.type then
		local played = pcall(function()
			local animUtil = require(ReplicatedStorage.TS.animation["animation-util"]).GameAnimationUtil
			nmTrack = h:LoadAnimation(animUtil:getAnimation(animation.type))
			nmTrack.Looped = true
			nmTrack.Priority = Enum.AnimationPriority.Action
			nmTrack:Play(0.15, 1, animation.speed or 1)
		end)
		if not played then
			nmTrack = nil
		end
	end
	task.delay(0.4, function()
		local mod = Modules["Fake NM Emote"]
		if not mod or not mod.enabled or nmEffect then
			return
		end
		local body = char()
		local r = root()
		if not body or not r then
			return
		end
		if body:FindFirstChild("Outer", true) or body:FindFirstChild("NightmareEmote", true) or workspace:FindFirstChild("NightmareEmote") then
			return
		end
		local okAsset, asset = pcall(findNmAsset)
		if okAsset and asset then
			attachAura(asset, r)
		end
	end)
end

local oldUsername, oldDisplay
local statSwapped, statWatch, barSaved = {}, {}, {}
local statWriting
local realNames = {}
local shownName = ""

local function gamePlayerClass()
	local ok, util = pcall(function()
		return require(ReplicatedStorage.TS.player["player-util"]).GamePlayerUtil
	end)
	if not ok or type(util) ~= "table" or type(util.getGamePlayer) ~= "function" then
		return
	end
	local gp = util.getGamePlayer(lp)
	local mt = gp and getmetatable(gp)
	local class = mt and mt.__index
	if type(class) == "table" and type(class.getUsername) == "function" and type(class.getDisplayName) == "function" then
		return class
	end
end

local function commaNum(n)
	local s = tostring(math.floor(tonumber(n) or 0))
	local k
	repeat
		s, k = string.gsub(s, "^(-?%d+)(%d%d%d)", "%1,%2")
	until k == 0
	return s
end

local function statText(text, m)
	if type(text) ~= "string" or text == "" or #text > 90 then
		return text
	end
	local name = tostring(get(m, "Name") or "")
	local rank, _, _, rpLine = rpParts(m)
	local lb = tonumber((tostring(get(m, "Leaderboard") or "1"):gsub(",", ""))) or 1
	if name ~= "" then
		for _, old in ipairs(realNames) do
			if old ~= "" and old ~= name then
				local a, b = string.find(text, old, 1, true)
				if a then
					text = string.sub(text, 1, a - 1) .. name .. string.sub(text, b + 1)
				end
			end
		end
		if shownName ~= "" and shownName ~= name then
			local a, b = string.find(text, shownName, 1, true)
			if a then
				text = string.sub(text, 1, a - 1) .. name .. string.sub(text, b + 1)
			end
		end
	end
	if string.find(text, "Leaderboard Rank", 1, true) then
		return "Leaderboard Rank: " .. commaNum(lb)
	end
	if isRpLine(text) then
		return rpLine
	end
	local trimmed = string.match(text, "^%s*(.-)%s*$") or text
	if #trimmed <= 18 then
		for _, word in ipairs({ "Nightmare", "Emerald", "Diamond", "Platinum", "Gold", "Silver", "Bronze" }) do
			if string.find(trimmed, word, 1, true) then
				return rank
			end
		end
	end
	return text
end

local mineAnswer = setmetatable({}, { __mode = "k" })

local function nameList()
	local names, seen = {}, {}
	local function push(n)
		if type(n) == "string" and n ~= "" and not seen[n] then
			seen[n] = true
			table.insert(names, n)
		end
	end
	for _, n in ipairs(realNames) do
		push(n)
	end
	push(shownName)
	local mod = Modules["Fake Stats"]
	if mod then
		push(tostring(get(mod, "Name") or ""))
	end
	return names
end

local function textHasName(text, names)
	if type(text) ~= "string" then
		return false
	end
	for _, n in ipairs(names) do
		if string.find(text, n, 1, true) then
			return true
		end
	end
	return false
end

local function cardIsMine(obj)
	local names = nameList()
	local node = obj
	for _ = 1, 8 do
		node = node and node.Parent
		if not node or node:IsA("ScreenGui") or node.Name == "Quantumware" then
			return false
		end
		local cached = mineAnswer[node]
		if cached == true then
			return true
		end
		if cached == nil then
			local count, hit = 0, false
			local cap = (node:IsA("SurfaceGui") or node:IsA("BillboardGui")) and 900 or 280
			for _, ch in ipairs(node:GetDescendants()) do
				count += 1
				if count > cap then
					break
				end
				if (ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("TextBox")) and textHasName(ch.Text, names) then
					hit = true
					break
				end
			end
			if hit or count <= cap then
				mineAnswer[node] = hit
			end
			if hit then
				return true
			end
		end
		if node:IsA("SurfaceGui") or node:IsA("BillboardGui") then
			return false
		end
	end
	return false
end

local function rememberBar(frame)
	if barSaved[frame] == nil then
		local grad = frame:FindFirstChildOfClass("UIGradient")
		barSaved[frame] = {
			Color = frame:IsA("ImageLabel") and frame.ImageColor3 or frame.BackgroundColor3,
			Size = frame.Size,
			Gradient = grad and grad.Color or nil,
		}
	end
end

local function paintFill(frame, ratio, color)
	if not frame or not frame.Parent then
		return
	end
	rememberBar(frame)
	local yScale, yOffset = frame.Size.Y.Scale, frame.Size.Y.Offset
	frame.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, yScale, yOffset)
	if frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
		frame.ImageColor3 = color
	else
		frame.BackgroundColor3 = color
		frame.BackgroundTransparency = 0
	end
	local grad = frame:FindFirstChildOfClass("UIGradient")
	if grad then
		grad.Color = ColorSequence.new(color, color)
	end
end

local function reapplyBars(m)
	local rank, shown, maxRp = rpParts(m)
	local color = rankColor(rank)
	local ratio = maxRp > 0 and (shown / maxRp) or 0
	for frame in pairs(barSaved) do
		if typeof(frame) == "Instance" and frame.Parent then
			paintFill(frame, ratio, color)
		end
	end
end

local function styleRankBlock(anchor, m)
	if not anchor or not anchor.Parent then
		return
	end
	local _, shown, maxRp, rpLine = rpParts(m)
	local color = rankColor(get(m, "Rank"))
	local ratio = maxRp > 0 and (shown / maxRp) or 0
	local node = anchor.Parent
	local block = node
	for _ = 1, 6 do
		if not node or node:IsA("ScreenGui") or node:IsA("SurfaceGui") or node:IsA("BillboardGui") then
			break
		end
		local count, hasRp = 0, false
		for _, ch in ipairs(node:GetDescendants()) do
			count += 1
			if count > 140 then
				break
			end
			if (ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("TextBox")) and isRpLine(ch.Text) then
				hasRp = true
			end
		end
		if hasRp and count <= 140 then
			block = node
			break
		end
		node = node.Parent
	end
	if not block then
		return
	end
	for _, ch in ipairs(block:GetDescendants()) do
		if (ch:IsA("TextLabel") or ch:IsA("TextButton") or ch:IsA("TextBox")) and isRpLine(ch.Text) and ch.Text ~= rpLine then
			if statSwapped[ch] == nil then
				statSwapped[ch] = ch.Text
			end
			statWriting = ch
			ch.Text = rpLine
			statWriting = nil
		end
	end
	local function besideRp(frame)
		local parent = frame.Parent
		local grand = parent and parent.Parent
		for _, scope in ipairs({ parent, grand }) do
			if scope then
				for _, other in ipairs(scope:GetDescendants()) do
					if (other:IsA("TextLabel") or other:IsA("TextButton") or other:IsA("TextBox")) and isRpLine(other.Text) then
						return true
					end
				end
			end
		end
		return false
	end
	for _, ch in ipairs(block:GetDescendants()) do
		if (ch:IsA("Frame") or ch:IsA("ImageLabel")) and besideRp(ch) then
			local size = ch.AbsoluteSize
			local parent = ch.Parent
			if size.Y >= 3 and size.Y <= 18 and size.X >= 16 and parent and parent:IsA("GuiObject") then
				local psize = parent.AbsoluteSize
				local colorSum = ch.BackgroundColor3.R + ch.BackgroundColor3.G + ch.BackgroundColor3.B
				local parentSum = parent.BackgroundColor3.R + parent.BackgroundColor3.G + parent.BackgroundColor3.B
				local brighter = colorSum > parentSum + 0.2
				local shorter = size.X < psize.X - 4
				if psize.Y >= 3 and psize.Y <= 22 and psize.X >= 40 and (brighter or shorter) then
					paintFill(ch, ratio, color)
				end
			end
		end
	end
end

local function paintStatObject(obj, m)
	if statWriting == obj or not obj or not obj.Parent or obj:FindFirstAncestor("Quantumware") then
		return
	end
	local isImage = obj:IsA("ImageLabel") or obj:IsA("ImageButton")
	local isText = obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox")
	if not isImage and not isText then
		return
	end
	asExecutor()
	if isImage then
		if isRankImage(obj.Image) and cardIsMine(obj) then
			local nextImage = imageForRank(get(m, "Rank"))
			if nextImage and obj.Image ~= nextImage then
				if statSwapped[obj] == nil then
					statSwapped[obj] = obj.Image
				end
				statWriting = obj
				obj.Image = nextImage
				statWriting = nil
			end
		end
		return
	end
	local nextText = statText(obj.Text, m)
	local rank = tostring(get(m, "Rank") or "")
	local rankish = nextText == rank or string.find(nextText, "Leaderboard Rank", 1, true) or isRpLine(nextText)
	if nextText ~= obj.Text and rankish and not cardIsMine(obj) then
		return
	end
	if rankish and (nextText == rank or string.find(obj.Text, "Leaderboard Rank", 1, true) or string.find(nextText, "Leaderboard Rank", 1, true)) then
		styleRankBlock(obj, m)
	end
	if nextText ~= obj.Text then
		if statSwapped[obj] == nil then
			statSwapped[obj] = obj.Text
		end
		statWriting = obj
		obj.Text = nextText
		statWriting = nil
		if not statWatch[obj] then
			statWatch[obj] = obj:GetPropertyChangedSignal("Text"):Connect(function()
				local mod = Modules["Fake Stats"]
				if mod and mod.enabled and statWriting ~= obj then
					paintStatObject(obj, mod)
				end
			end)
		end
	end
end

local function scanStatRoot(root, m, worldBoards)
	if not root or not (Modules["Fake Stats"] and Modules["Fake Stats"].enabled) then
		return
	end
	asExecutor()
	local clock = os.clock()
	local list = worldBoards and {} or root:GetDescendants()
	if worldBoards then
		for _, obj in ipairs(root:GetDescendants()) do
			if obj:IsA("SurfaceGui") or obj:IsA("BillboardGui") then
				table.insert(list, obj)
			end
			if os.clock() - clock > 0.003 then
				task.wait()
				clock = os.clock()
				if not (Modules["Fake Stats"] and Modules["Fake Stats"].enabled) then
					return
				end
			end
		end
		local boards = list
		list = {}
		for _, gui in ipairs(boards) do
			table.insert(list, gui)
			for _, obj in ipairs(gui:GetDescendants()) do
				table.insert(list, obj)
			end
		end
	end
	table.clear(mineAnswer)
	for _, obj in ipairs(list) do
		paintStatObject(obj, m)
		if os.clock() - clock > 0.003 then
			task.wait()
			clock = os.clock()
			asExecutor()
			if not (Modules["Fake Stats"] and Modules["Fake Stats"].enabled) then
				return
			end
		end
	end
end

local function hookGamePlayer()
	local class = gamePlayerClass()
	if not class or oldUsername then
		return
	end
	oldUsername, oldDisplay = class.getUsername, class.getDisplayName
	local function playerOf(self)
		if type(self) ~= "table" or type(self.getPlayer) ~= "function" then
			return
		end
		local ok, player = pcall(self.getPlayer, self)
		if ok then
			return player
		end
	end
	class.getUsername = function(self, ...)
		local mod = Modules["Fake Stats"]
		if mod and mod.enabled and playerOf(self) == lp then
			return tostring(get(mod, "Name") or shownName)
		end
		return oldUsername(self, ...)
	end
	class.getDisplayName = function(self, ...)
		local mod = Modules["Fake Stats"]
		if mod and mod.enabled and playerOf(self) == lp then
			return tostring(get(mod, "Name") or shownName)
		end
		return oldDisplay(self, ...)
	end
end

local function unhookGamePlayer()
	local class = gamePlayerClass()
	if class and oldUsername then
		class.getUsername = oldUsername
		class.getDisplayName = oldDisplay
	end
	oldUsername, oldDisplay = nil, nil
end

local RANK_REMOTE = {
	FetchRanks = true,
	RequestProfileData = true,
}

local function divisionIdFor(rankName)
	loadRankMeta()
	local want = string.lower(tostring(rankName or ""))
	if type(rankMeta) ~= "table" then
		return
	end
	for key, div in pairs(rankMeta) do
		if type(div) == "table" and type(div.name) == "string" and string.lower(div.name) == want then
			return key
		end
	end
end

local SKIP_PROFILE = {
	matchHistory = true,
	players = true,
	matches = true,
	queues = true,
	favoriteKitData = true,
}

local function patchProfile(value, force, depth, rankName, rp, lb, fakeName, divId)
	if depth > 5 or type(value) ~= "table" or value.andThen or value.expect or value.await then
		return
	end
	local uid = value.userId or value.playerId or value.user_id
	if uid ~= nil and uid ~= lp and tonumber(uid) ~= lp.UserId then
		return
	end
	local mine = force or uid == lp or tonumber(uid) == lp.UserId
	for key, field in pairs(value) do
		if type(key) ~= "number" and not SKIP_PROFILE[key] then
		local lk = string.lower(tostring(key))
		if type(field) == "table" then
			patchProfile(field, mine, depth + 1, rankName, rp, lb, fakeName, divId)
		elseif mine then
			if divId ~= nil and (lk == "rankdivision" or lk == "division" or lk == "rankeddivision" or lk == "currentdivision") then
				value[key] = divId
			elseif type(field) == "string" and (lk == "rankname" or lk == "divisionname") then
				value[key] = rankName
			elseif type(field) == "string" and (lk == "displayname" or lk == "username" or lk == "name") then
				if fakeName ~= "" and (field == lp.Name or field == lp.DisplayName or field == shownName or field == realNames[1] or field == realNames[2]) then
					value[key] = fakeName
				end
			elseif type(field) == "number" and (lk == "rp" or lk == "rankpoints" or lk == "rankedrp" or lk == "currentrp" or lk == "rpindivision") then
				value[key] = rp
			elseif type(field) == "number" and (lk == "leaderboardrank" or lk == "leaderboardposition" or lk == "leaderboardplacement" or lk == "rankposition") then
				value[key] = lb
			end
		end
		end
	end
	if type(value[1]) == "table" then
		for _, entry in ipairs(value) do
			patchProfile(entry, force, depth + 1, rankName, rp, lb, fakeName, divId)
		end
	end
end

local function rewriteRankResult(value, requested)
	local mod = Modules["Fake Stats"]
	if not mod or not mod.enabled or type(value) ~= "table" or value.andThen then
		return
	end
	local rankName, rp = rpParts(mod)
	local lb = tonumber((tostring(get(mod, "Leaderboard") or "1"):gsub(",", ""))) or 1
	local fakeName = tostring(get(mod, "Name") or "")
	patchProfile(value, requested, 0, rankName, rp, lb, fakeName, divisionIdFor(rankName))
end

local function wrapRankCall(fn, remote)
	return function(_, ...)
		local requested = false
		for i = 1, select("#", ...) do
			local arg = select(i, ...)
			if arg == lp or arg == lp.UserId or tostring(arg) == tostring(lp.UserId) then
				requested = true
			elseif type(arg) == "table" and (arg[1] == lp.UserId or arg[1] == lp or arg.userId == lp.UserId or arg.player == lp) then
				requested = true
			end
		end
		local packed = table.pack(fn(remote, ...))
		for i = 1, packed.n do
			local item = packed[i]
			if type(item) == "table" and not item.__qwRanks then
				if type(item.andThen) == "function" and not item.__qwThen then
					local oldThen = item.andThen
					item.andThen = function(promise, callback, ...)
						return oldThen(promise, function(result, ...)
							rewriteRankResult(result, requested)
							if type(callback) == "function" then
								return callback(result, ...)
							end
						end, ...)
					end
					item.__qwThen = true
				end
				if type(item.expect) == "function" and not item.__qwExpect then
					local oldExpect = item.expect
					item.expect = function(promise, ...)
						local result = oldExpect(promise, ...)
						rewriteRankResult(result, requested)
						return result
					end
					item.__qwExpect = true
				end
				if type(item.await) == "function" and not item.__qwAwait then
					local oldAwait = item.await
					item.await = function(promise, ...)
						local result = oldAwait(promise, ...)
						rewriteRankResult(result, requested)
						return result
					end
					item.__qwAwait = true
				end
				if not item.andThen and not item.expect and not item.await then
					rewriteRankResult(item, requested)
				end
			end
		end
		return table.unpack(packed, 1, packed.n)
	end
end

local ranksHooked = false
function hookRankRemotes()
	if ranksHooked then
		return
	end
	local client = BW.client
	if type(client) ~= "table" or type(client.Get) ~= "function" then
		return
	end
	local original = client.Get
	local originalThrow = client.GetOrThrow
	local wrappedRemotes = setmetatable({}, { __mode = "k" })
	local function wrapRemote(id, remote)
		if type(remote) ~= "table" or not RANK_REMOTE[tostring(id)] then
			return remote
		end
		if wrappedRemotes[remote] then
			return wrappedRemotes[remote]
		end
		local cache = {}
		local proxy = setmetatable(cache, {
			__index = function(_, key)
				local value = remote[key]
				if type(value) == "function" and (key == "CallServer" or key == "CallServerAsync" or key == "InvokeServer" or key == "Fire") then
					local wrapped = wrapRankCall(value, remote)
					cache[key] = wrapped
					return wrapped
				end
				if type(value) == "function" then
					local wrapped = function(_, ...)
						return value(remote, ...)
					end
					cache[key] = wrapped
					return wrapped
				end
				cache[key] = value
				return value
			end,
		})
		wrappedRemotes[remote] = proxy
		return proxy
	end
	client.Get = function(self, id, ...)
		return wrapRemote(id, original(self, id, ...))
	end
	if type(originalThrow) == "function" then
		client.GetOrThrow = function(self, id, ...)
			return wrapRemote(id, originalThrow(self, id, ...))
		end
	end
	ranksHooked = true
end
task.defer(function()
	pcall(hookRankRemotes)
end)

local textHooked = false
local function hookTextWrites()
	if textHooked or type(hookmetamethod) ~= "function" then
		return
	end
	local old
	local wrap = type(newcclosure) == "function" and newcclosure or function(fn)
		return fn
	end
	old = hookmetamethod(game, "__newindex", wrap(function(obj, key, value)
		local mod = Modules["Fake Stats"]
		if not mod or not mod.enabled or statWriting == obj or typeof(obj) ~= "Instance" or type(value) ~= "string" then
			return old(obj, key, value)
		end
		local isText = key == "Text" and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
		local isImage = key == "Image" and (obj:IsA("ImageLabel") or obj:IsA("ImageButton"))
		if not isText and not isImage then
			return old(obj, key, value)
		end
		if obj:FindFirstAncestor("Quantumware") then
			return old(obj, key, value)
		end
		local replacement = value
		local ok, changed = pcall(function()
			if isText then
				local nextText = statText(value, mod)
				if nextText == value then
					return value
				end
				local rank = tostring(get(mod, "Rank") or "")
				local rankish = nextText == rank or string.find(nextText, "Leaderboard Rank", 1, true) ~= nil or isRpLine(nextText)
				if rankish and not cardIsMine(obj) then
					return value
				end
				if statSwapped[obj] == nil then
					statSwapped[obj] = obj.Text
				end
				return nextText
			end
			if isRankImage(value) and cardIsMine(obj) then
				local nextImage = imageForRank(get(mod, "Rank"))
				if nextImage and nextImage ~= value then
					if statSwapped[obj] == nil then
						statSwapped[obj] = obj.Image
					end
					return nextImage
				end
			end
			return value
		end)
		if ok and type(changed) == "string" then
			replacement = changed
		end
		statWriting = obj
		local result = old(obj, key, replacement)
		statWriting = nil
		return result
	end))
	textHooked = old ~= nil
end

add("Larping", "Fake NM Emote", "Plays the Nightmare emote. Walking or jumping turns it off", nil, function(on)
	if on then
		nmMissing = false
		nmSent = false
		playNm()
	else
		nmKey = nil
		nmSent = false
		stopNm()
	end
end, function()
	local mod = Modules["Fake NM Emote"]
	if not mod or not mod.enabled then
		return
	end
	local h = hum()
	local moving = false
	if h and (h.MoveDirection.Magnitude > 0.05 or h.Jump) then
		moving = true
	end
	if not moving then
		for _, key in ipairs({ Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D, Enum.KeyCode.Space }) do
			if UserInputService:IsKeyDown(key) then
				moving = true
				break
			end
		end
	end
	if moving then
		stopNm()
		setOn(mod, false)
	end
end, 0.05)

add("Larping", "Fake Stats", "Name, rank, and leaderboard. Division RP is 0-100. Nightmare RP is 0-1000", function(m)
	opt(m, "Name", "text", "corapses")
	opt(m, "Rank", "list", "Nightmare", { list = RANK_LIST })
	opt(m, "RP", "slider", 20, { min = 0, max = 100, suffix = " RP" })
	opt(m, "Nightmare RP", "slider", 477, { min = 0, max = 1000, suffix = " RP" })
	opt(m, "Leaderboard", "text", "1")
end, function(on, m)
	if on then
		realNames = {}
		shownName = ""
		if lp.Name ~= "" then
			table.insert(realNames, lp.Name)
		end
		if lp.DisplayName ~= "" and lp.DisplayName ~= lp.Name then
			table.insert(realNames, lp.DisplayName)
		end
		hookGamePlayer()
		pcall(hookRankRemotes)
		pcall(hookTextWrites)
		pcall(function()
			RunService:UnbindFromRenderStep("QW_RankBar")
		end)
		RunService:BindToRenderStep("QW_RankBar", Enum.RenderPriority.Last.Value, function()
			if m.enabled then
				reapplyBars(m)
			end
		end)
		shownName = tostring(get(m, "Name") or "")
		local function watch(root, guisOnly)
			if not root then
				return
			end
			table.insert(m.conns, root.DescendantAdded:Connect(function(obj)
				if m.enabled then
					task.defer(paintStatObject, obj, m)
				end
			end))
			task.spawn(scanStatRoot, root, m, guisOnly)
		end
		watch(lp:FindFirstChildOfClass("PlayerGui"), false)
		pcall(function()
			watch(game:GetService("CoreGui"), false)
		end)
		pcall(function()
			if type(gethui) == "function" then
				watch(gethui(), false)
			end
		end)
		watch(lp.Character, false)
		task.spawn(scanStatRoot, workspace, m, true)
		table.insert(m.conns, workspace.DescendantAdded:Connect(function(obj)
			if not m.enabled then
				return
			end
			if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") or obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
				if obj:FindFirstAncestorWhichIsA("SurfaceGui") or obj:FindFirstAncestorWhichIsA("BillboardGui") then
					task.defer(paintStatObject, obj, m)
				end
			end
		end))
		task.delay(1.2, function()
			if not m.enabled then
				return
			end
			local pg = lp:FindFirstChildOfClass("PlayerGui")
			if pg then
				scanStatRoot(pg, m, false)
			end
			scanStatRoot(workspace, m, true)
		end)
		table.insert(m.conns, lp.CharacterAdded:Connect(function(character)
			if m.enabled then
				task.delay(0.4, function()
					if m.enabled then
						scanStatRoot(character, m, false)
					end
				end)
			end
		end))
	else
		unhookGamePlayer()
		asExecutor()
		for _, conn in pairs(statWatch) do
			pcall(function()
				conn:Disconnect()
			end)
		end
		table.clear(statWatch)
		for obj, old in pairs(statSwapped) do
			if typeof(obj) == "Instance" and obj.Parent then
				statWriting = obj
				if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
					obj.Image = old
				elseif obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
					obj.Text = old
				end
			end
		end
		statWriting = nil
		table.clear(statSwapped)
		for frame, saved in pairs(barSaved) do
			if typeof(frame) == "Instance" and frame.Parent and type(saved) == "table" then
				frame.Size = saved.Size
				if frame:IsA("ImageLabel") or frame:IsA("ImageButton") then
					frame.ImageColor3 = saved.Color
				else
					frame.BackgroundColor3 = saved.Color
				end
				local grad = frame:FindFirstChildOfClass("UIGradient")
				if grad and saved.Gradient then
					grad.Color = saved.Gradient
				end
			end
		end
		table.clear(barSaved)
		pcall(function()
			RunService:UnbindFromRenderStep("QW_RankBar")
		end)
		shownName = ""
		pcall(function()
			lp.DisplayName = realNames[2] or realNames[1] or lp.Name
		end)
	end
end, function(m)
	pcall(hookRankRemotes)
	local name = tostring(get(m, "Name") or "")
	if name ~= "" then
		pcall(function()
			lp.DisplayName = name
		end)
		local h = hum()
		if h then
			pcall(function()
				h.DisplayName = name
			end)
		end
	end
	shownName = name
	for obj in pairs(statWatch) do
		if typeof(obj) == "Instance" and obj.Parent then
			paintStatObject(obj, m)
		end
	end
	reapplyBars(m)
end, 0.2)

local signFolder, signFollow, signLabels
local function stopSign()
	if signFollow then
		pcall(function()
			RunService:UnbindFromRenderStep("QW_Sign")
		end)
		signFollow = false
	end
	if signFolder then
		signFolder:Destroy()
		signFolder = nil
	end
	signLabels = nil
end

local function makeDisc(parent, name, diameter, color, transparency)
	local part = Instance.new("Part")
	part.Name = name
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(0.35, diameter, diameter)
	part.Color = color
	part.Material = Enum.Material.Neon
	part.Transparency = transparency
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Parent = parent
	return part
end

local function startSign(m)
	stopSign()
	local r = root()
	if not r then
		return
	end
	signFolder = Instance.new("Folder")
	signFolder.Name = "QW_Sign"
	signFolder.Parent = workspace
	local outer = makeDisc(signFolder, "Outer", 18, Color3.fromRGB(0, 0, 0), 0.05)
	local middle = makeDisc(signFolder, "Middle", 11, Color3.fromRGB(12, 12, 14), 0.15)
	local inner = makeDisc(signFolder, "Inner", 5, Color3.fromRGB(0, 0, 0), 0.05)
	local slice = Instance.new("Part")
	slice.Name = "Slice"
	slice.Size = Vector3.new(7, 0.4, 1.4)
	slice.Color = Color3.fromRGB(245, 245, 245)
	slice.Material = Enum.Material.Neon
	slice.Anchored = true
	slice.CanCollide = false
	slice.CanQuery = false
	slice.CanTouch = false
	slice.CastShadow = false
	slice.Parent = signFolder
	local board = Instance.new("Part")
	board.Name = "Sign"
	board.Size = Vector3.new(72, 28, 0.4)
	board.Transparency = 1
	board.Anchored = true
	board.CanCollide = false
	board.CanQuery = false
	board.CanTouch = false
	board.CastShadow = false
	board.Parent = signFolder
	signLabels = {}
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local gui = Instance.new("SurfaceGui")
		gui.Face = face
		gui.LightInfluence = 0
		gui.Brightness = 2
		gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		gui.PixelsPerStud = 18
		gui.Parent = board
		local text = Instance.new("TextLabel")
		text.BackgroundTransparency = 1
		text.Size = UDim2.fromScale(1, 1)
		text.Font = Enum.Font.GothamBlack
		text.TextScaled = true
		text.TextColor3 = Color3.new(1, 1, 1)
		text.Text = tostring(get(m, "Text") or "HI")
		text.Parent = gui
		local stroke = Instance.new("UIStroke")
		stroke.Thickness = 8
		stroke.Color = Color3.new(0, 0, 0)
		stroke.Parent = text
		table.insert(signLabels, text)
	end
	local spin = 0
	signFollow = true
	RunService:BindToRenderStep("QW_Sign", Enum.RenderPriority.Last.Value, function(dt)
		local rootPart = root()
		local mod = Modules["Black Aura"]
		if not rootPart or not signFolder or not mod or not mod.enabled then
			return
		end
		local word = tostring(get(mod, "Text") or "HI")
		if signLabels then
			for _, text in ipairs(signLabels) do
				if text.Text ~= word then
					text.Text = word
				end
			end
		end
		local height = tonumber(get(mod, "Height")) or 200
		spin += (dt or 0.016) * 2.4
		local base = rootPart.CFrame * CFrame.new(0, -2.6, 0)
		local flat = CFrame.Angles(0, 0, math.rad(90))
		outer.CFrame = base * CFrame.Angles(0, spin, 0) * flat
		middle.CFrame = base * CFrame.Angles(0, -spin * 0.65, 0) * flat
		inner.CFrame = base * CFrame.Angles(0, spin * 1.4, 0) * flat
		slice.CFrame = base * CFrame.Angles(0, spin, 0) * CFrame.new(4.2, 0.25, 0)
		local pos = rootPart.Position + Vector3.new(0, height, 0)
		local look = cam and cam.CFrame.Position or (pos + Vector3.new(0, 0, -1))
		board.CFrame = CFrame.lookAt(pos, Vector3.new(look.X, pos.Y, look.Z))
	end)
end

add("Larping", "Black Aura", "Black spinning aura at your feet and a giant sign above you", function(m)
	opt(m, "Text", "text", "HI")
	opt(m, "Height", "slider", 200, { min = 40, max = 300, suffix = " st" })
end, function(on, m)
	if on then
		startSign(m)
	else
		stopSign()
	end
end, function(m)
	if m.enabled and not signFolder then
		startSign(m)
	end
end, 0.5)

add("World", "Nuker", "Fast-breaks bed defense, then the bed", function(m)
	opt(m, "Range", "slider", 30, { min = 10, max = 40, suffix = " st" })
	opt(m, "Delay", "slider", 80, { min = 40, max = 300, step = 10, suffix = "ms" })
	opt(m, "Defense first", "toggle", true)
	opt(m, "Auto tool", "toggle", true)
end, nil, function(m)
	breakBedStep(get(m, "Range"), get(m, "Defense first"), get(m, "Auto tool"))
end, function(m)
	return get(m, "Delay") / 1000
end)

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
local attached = false
pcall(function()
	screen.Parent = parentGui()
	attached = screen.Parent ~= nil
end)
if not attached then
	pcall(function()
		screen.Parent = lp:WaitForChild("PlayerGui")
	end)
end

local overlay = Instance.new("Frame")
overlay.Size = UDim2.fromScale(1, 1)
overlay.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
overlay.BackgroundTransparency = 0.55
overlay.Visible = true
overlay.Parent = screen

local worldBlur = Instance.new("BlurEffect")
worldBlur.Size = 10
worldBlur.Enabled = true
pcall(function()
	worldBlur.Parent = Lighting
end)

local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.Size = UDim2.fromScale(1, 1)
menu.Parent = overlay

local COL_W, COL_GAP = 176, 12
local COLS = { "Combat", "Blatant", "Render", "World", "Larping" }
local boardW = #COLS * COL_W + (#COLS - 1) * COL_GAP

local bar = Instance.new("Frame")
bar.Size = UDim2.fromOffset(boardW, 42)
bar.Position = UDim2.new(0.5, -boardW / 2, 0, 16)
bar.BackgroundColor3 = Color3.fromRGB(16, 18, 26)
bar.BackgroundTransparency = 0.22
bar.Parent = menu
corner(bar, 12)
stroke(bar, 0.7)
glass(bar)

local brand = Instance.new("TextLabel")
brand.BackgroundTransparency = 1
brand.Size = UDim2.new(0, 150, 1, 0)
brand.Position = UDim2.fromOffset(14, 0)
brand.Font = Enum.Font.GothamBold
brand.TextSize = 15
brand.TextXAlignment = Enum.TextXAlignment.Left
brand.TextColor3 = Color3.fromRGB(245, 246, 255)
brand.Text = "Quantumware"
brand.Parent = bar

local search = Instance.new("TextBox")
search.Size = UDim2.fromOffset(240, 26)
search.Position = UDim2.new(0.5, -120, 0.5, -13)
search.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
search.BackgroundTransparency = 0.9
search.Font = Enum.Font.Gotham
search.TextSize = 13
search.PlaceholderText = "Search modules"
search.PlaceholderColor3 = Color3.fromRGB(160, 166, 186)
search.TextColor3 = Color3.fromRGB(240, 242, 255)
search.Text = ""
search.ClearTextOnFocus = false
search.Parent = bar
corner(search, 8)
stroke(search, 0.82)

local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.Size = UDim2.fromOffset(120, 42)
hint.Position = UDim2.new(1, -134, 0, 0)
hint.Font = Enum.Font.Gotham
hint.TextSize = 12
hint.TextXAlignment = Enum.TextXAlignment.Right
hint.TextColor3 = Color3.fromRGB(168, 174, 194)
hint.Text = "Right Shift"
hint.Parent = bar

local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.fromOffset(90, 42)
status.Position = UDim2.new(1, -230, 0, 0)
status.Font = Enum.Font.GothamMedium
status.TextSize = 12
status.TextXAlignment = Enum.TextXAlignment.Right
status.TextColor3 = Color3.fromRGB(170, 210, 255)
status.Text = "waiting"
status.Parent = bar

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
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromOffset(210, 16)
		l.Font = Enum.Font.GothamMedium
		l.TextSize = 13
		l.TextXAlignment = Enum.TextXAlignment.Right
		l.TextColor3 = Color3.fromRGB(236, 238, 250)
		l.Text = n
		l.LayoutOrder = i
		l.Parent = array
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
local binding

local TXT = Color3.fromRGB(236, 238, 250)
local DIM = Color3.fromRGB(156, 162, 182)
local ACCENT = Color3.fromRGB(150, 168, 255)

local function label(parent, text, size, color, align)
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.TextSize = size or 12
	l.TextColor3 = color or TXT
	l.TextXAlignment = align or Enum.TextXAlignment.Left
	l.Text = text
	l.Parent = parent
	return l
end

local panel = Instance.new("Frame")
panel.Size = UDim2.fromOffset(236, 60)
panel.AutomaticSize = Enum.AutomaticSize.Y
panel.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
panel.BackgroundTransparency = 0.06
panel.Visible = false
panel.ZIndex = 20
panel.Parent = menu
corner(panel, 12)
stroke(panel, 0.6)
local panelPad = Instance.new("UIPadding")
panelPad.PaddingTop = UDim.new(0, 10)
panelPad.PaddingBottom = UDim.new(0, 12)
panelPad.PaddingLeft = UDim.new(0, 12)
panelPad.PaddingRight = UDim.new(0, 12)
panelPad.Parent = panel
local panelList = Instance.new("UIListLayout")
panelList.Padding = UDim.new(0, 8)
panelList.SortOrder = Enum.SortOrder.LayoutOrder
panelList.Parent = panel
local panelMod

local function fmt(o)
	local v = o.value
	if type(v) == "number" and o.step < 1 then
		v = string.format("%.2f", v)
	end
	return tostring(v) .. o.suffix
end

local function sliderRow(o, order)
	local hold = Instance.new("Frame")
	hold.BackgroundTransparency = 1
	hold.Size = UDim2.new(1, 0, 0, 30)
	hold.LayoutOrder = order
	hold.Parent = panel
	local name = label(hold, o.name, 12, TXT)
	name.Size = UDim2.new(1, 0, 0, 14)
	local val = label(hold, fmt(o), 12, DIM, Enum.TextXAlignment.Right)
	val.Size = UDim2.new(1, 0, 0, 14)
	local track = Instance.new("TextButton")
	track.AutoButtonColor = false
	track.Text = ""
	track.Size = UDim2.new(1, 0, 0, 6)
	track.Position = UDim2.fromOffset(0, 21)
	track.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	track.BackgroundTransparency = 0.86
	track.Parent = hold
	corner(track, 3)
	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ACCENT
	fill.BorderSizePixel = 0
	fill.Parent = track
	corner(fill, 3)
	local function paint()
		fill.Size = UDim2.new(math.clamp((o.value - o.min) / math.max(o.max - o.min, 1e-3), 0, 1), 0, 1, 0)
		val.Text = fmt(o)
	end
	local function set(x)
		local a = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
		local v = o.min + (o.max - o.min) * a
		o.value = math.clamp(math.floor(v / o.step + 0.5) * o.step, o.min, o.max)
		paint()
	end
	local dragging = false
	track.InputBegan:Connect(function(i)
		if i.UserInputType == M1 then
			dragging = true
			set(i.Position.X)
		end
	end)
	table.insert(panelMod.uiConns, UserInputService.InputChanged:Connect(function(i)
		if dragging and i.UserInputType == Enum.UserInputType.MouseMovement then
			set(i.Position.X)
		end
	end))
	table.insert(panelMod.uiConns, UserInputService.InputEnded:Connect(function(i)
		if i.UserInputType == M1 then
			dragging = false
		end
	end))
	paint()
end

local function pillRow(o, order)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Text = ""
	b.Size = UDim2.new(1, 0, 0, 18)
	b.LayoutOrder = order
	b.Parent = panel
	local name = label(b, o.name, 12, TXT)
	name.Size = UDim2.new(1, -40, 1, 0)
	local pill = Instance.new("Frame")
	pill.Size = UDim2.fromOffset(28, 14)
	pill.Position = UDim2.new(1, -28, 0.5, -7)
	pill.Parent = b
	corner(pill, 8)
	local knob = Instance.new("Frame")
	knob.Size = UDim2.fromOffset(10, 10)
	knob.BackgroundColor3 = Color3.fromRGB(240, 242, 252)
	knob.Parent = pill
	corner(knob, 8)
	local function paint()
		pill.BackgroundColor3 = o.value and ACCENT or Color3.fromRGB(255, 255, 255)
		pill.BackgroundTransparency = o.value and 0.1 or 0.8
		knob.Position = o.value and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
	end
	b.MouseButton1Click:Connect(function()
		o.value = not o.value
		paint()
	end)
	paint()
end

local function choiceRow(o, order, isBind)
	local b = Instance.new("TextButton")
	b.AutoButtonColor = false
	b.BackgroundTransparency = 1
	b.Text = ""
	b.Size = UDim2.new(1, 0, 0, 22)
	b.LayoutOrder = order
	b.Parent = panel
	local name = label(b, o.name, 12, TXT)
	name.Size = UDim2.new(0.5, 0, 1, 0)
	local chip = Instance.new("TextLabel")
	chip.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	chip.BackgroundTransparency = 0.9
	chip.Font = Enum.Font.GothamMedium
	chip.TextSize = 12
	chip.TextColor3 = TXT
	chip.AutomaticSize = Enum.AutomaticSize.X
	chip.Size = UDim2.fromOffset(0, 20)
	chip.AnchorPoint = Vector2.new(1, 0.5)
	chip.Position = UDim2.new(1, 0, 0.5, 0)
	chip.Parent = b
	corner(chip, 6)
	local chipPad = Instance.new("UIPadding")
	chipPad.PaddingLeft = UDim.new(0, 8)
	chipPad.PaddingRight = UDim.new(0, 8)
	chipPad.Parent = chip
	local function paint()
		if isBind then
			chip.Text = binding == o and "press a key" or (o.value and o.value.Name or "None")
		else
			chip.Text = tostring(o.value)
		end
	end
	o.paint = paint
	local function step(dir)
		if isBind then
			binding = o
		else
			local idx = table.find(o.list, o.value) or 1
			o.value = o.list[(idx - 1 + dir) % #o.list + 1]
		end
		paint()
	end
	b.MouseButton1Click:Connect(function()
		step(1)
	end)
	b.MouseButton2Click:Connect(function()
		if isBind then
			o.value = nil
			binding = nil
			paint()
		else
			step(-1)
		end
	end)
	paint()
end

local function textRow(o, order)
	local hold = Instance.new("Frame")
	hold.BackgroundTransparency = 1
	hold.Size = UDim2.new(1, 0, 0, 44)
	hold.LayoutOrder = order
	hold.Parent = panel
	local name = label(hold, o.name, 12, TXT)
	name.Size = UDim2.new(1, 0, 0, 14)
	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, 0, 0, 24)
	box.Position = UDim2.fromOffset(0, 18)
	box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	box.BackgroundTransparency = 0.9
	box.Font = Enum.Font.Gotham
	box.TextSize = 12
	box.TextColor3 = TXT
	box.PlaceholderColor3 = DIM
	box.PlaceholderText = o.name
	box.Text = tostring(o.value or "")
	box.ClearTextOnFocus = false
	box.Parent = hold
	corner(box, 6)
	box.FocusLost:Connect(function()
		o.value = box.Text
	end)
end

local function closePanel()
	if panelMod then
		for _, c in ipairs(panelMod.uiConns or {}) do
			c:Disconnect()
		end
		panelMod.uiConns = {}
	end
	binding = nil
	panelMod = nil
	panel.Visible = false
end

local function openPanel(mod, anchor)
	if panelMod == mod then
		closePanel()
		return
	end
	closePanel()
	panelMod = mod
	mod.uiConns = {}
	for _, c in ipairs(panel:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	local head = Instance.new("Frame")
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 34)
	head.LayoutOrder = 0
	head.Parent = panel
	local title = label(head, mod.name, 14, Color3.fromRGB(255, 255, 255))
	title.Font = Enum.Font.GothamBold
	title.Size = UDim2.new(1, -24, 0, 16)
	local tip = label(head, mod.tip or "", 11, DIM)
	tip.Size = UDim2.new(1, -4, 0, 14)
	tip.Position = UDim2.fromOffset(0, 18)
	tip.TextTruncate = Enum.TextTruncate.AtEnd
	local x = Instance.new("TextButton")
	x.AutoButtonColor = false
	x.BackgroundTransparency = 1
	x.Size = UDim2.fromOffset(18, 16)
	x.Position = UDim2.new(1, -18, 0, 0)
	x.Font = Enum.Font.GothamBold
	x.TextSize = 13
	x.TextColor3 = DIM
	x.Text = "x"
	x.Parent = head
	x.MouseButton1Click:Connect(closePanel)
	local line = Instance.new("Frame")
	line.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	line.BackgroundTransparency = 0.9
	line.BorderSizePixel = 0
	line.Size = UDim2.new(1, 0, 0, 1)
	line.LayoutOrder = 1
	line.Parent = panel
	for i, key in ipairs(mod.order) do
		local o = mod.options[key]
		local order = i + 1
		if o.kind == "slider" then
			sliderRow(o, order)
		elseif o.kind == "toggle" then
			pillRow(o, order)
		elseif o.kind == "list" then
			choiceRow(o, order, false)
		elseif o.kind == "bind" then
			choiceRow(o, order, true)
		elseif o.kind == "text" then
			textRow(o, order)
		end
	end
	local view = cam and cam.ViewportSize or Vector2.new(1920, 1080)
	local px = anchor.AbsolutePosition.X + anchor.AbsoluteSize.X + 10
	if px + 236 > view.X - 8 then
		px = anchor.AbsolutePosition.X - 246
	end
	local py = math.clamp(anchor.AbsolutePosition.Y - 8, 8, view.Y - 320)
	panel.Position = UDim2.fromOffset(px, py)
	panel.Visible = true
end

local function window(name, x)
	local data = Cats[name]
	local win = Instance.new("Frame")
	win.Size = UDim2.fromOffset(COL_W, 420)
	win.Position = UDim2.new(0.5, x, 0, 68)
	win.BackgroundColor3 = Color3.fromRGB(14, 16, 24)
	win.BackgroundTransparency = 0.18
	win.Parent = menu
	corner(win, 12)
	stroke(win, 0.72)
	glass(win)

	local head = Instance.new("TextButton")
	head.AutoButtonColor = false
	head.BackgroundTransparency = 1
	head.Size = UDim2.new(1, 0, 0, 34)
	head.Font = Enum.Font.GothamMedium
	head.TextSize = 13
	head.TextXAlignment = Enum.TextXAlignment.Left
	head.TextColor3 = TXT
	head.Text = "  " .. string.upper(name)
	head.Parent = win
	drag(head, win)

	local scroll = Instance.new("ScrollingFrame")
	scroll.BackgroundTransparency = 1
	scroll.BorderSizePixel = 0
	scroll.Position = UDim2.fromOffset(0, 34)
	scroll.Size = UDim2.new(1, 0, 1, -34)
	scroll.ScrollBarThickness = 3
	scroll.ScrollBarImageColor3 = Color3.fromRGB(200, 206, 230)
	scroll.CanvasSize = UDim2.new()
	scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
	scroll.Parent = win

	local list = Instance.new("Frame")
	list.BackgroundTransparency = 1
	list.Size = UDim2.new(1, 0, 0, 0)
	list.AutomaticSize = Enum.AutomaticSize.Y
	list.Parent = scroll
	local lay = Instance.new("UIListLayout")
	lay.Padding = UDim.new(0, 2)
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Parent = list
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 6)
	pad.PaddingRight = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = list

	for i, mod in ipairs(data.modules) do
		local row = Instance.new("TextButton")
		row.Name = mod.name
		row.AutoButtonColor = false
		row.Text = ""
		row.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		row.BackgroundTransparency = 1
		row.Size = UDim2.new(1, 0, 0, 26)
		row.LayoutOrder = i
		row.Parent = list
		corner(row, 6)

		local txt = label(row, mod.name, 13, DIM)
		txt.Size = UDim2.new(1, -44, 1, 0)
		txt.Position = UDim2.fromOffset(6, 0)

		local pill = Instance.new("Frame")
		pill.Size = UDim2.fromOffset(28, 14)
		pill.Position = UDim2.new(1, -30, 0.5, -7)
		pill.Parent = row
		corner(pill, 8)
		local knob = Instance.new("Frame")
		knob.Size = UDim2.fromOffset(10, 10)
		knob.BackgroundColor3 = Color3.fromRGB(240, 242, 252)
		knob.Parent = pill
		corner(knob, 8)

		mod.paint = function()
			txt.TextColor3 = mod.enabled and Color3.fromRGB(255, 255, 255) or DIM
			pill.BackgroundColor3 = mod.enabled and ACCENT or Color3.fromRGB(255, 255, 255)
			pill.BackgroundTransparency = mod.enabled and 0.1 or 0.8
			knob.Position = mod.enabled and UDim2.new(1, -12, 0.5, -5) or UDim2.new(0, 2, 0.5, -5)
		end
		mod.paint()

		row.MouseEnter:Connect(function()
			row.BackgroundTransparency = 0.93
			hint.Text = "Right-click for settings"
		end)
		row.MouseLeave:Connect(function()
			row.BackgroundTransparency = 1
			hint.Text = "Right Shift"
		end)
		row.MouseButton1Click:Connect(function()
			setOn(mod, not mod.enabled)
		end)
		row.MouseButton2Click:Connect(function()
			openPanel(mod, row)
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

local x = -boardW / 2
for _, n in ipairs(COLS) do
	table.insert(filters, window(n, x))
	x = x + COL_W + COL_GAP
end

search:GetPropertyChangedSignal("Text"):Connect(function()
	local q = string.lower(search.Text)
	for _, f in ipairs(filters) do
		f(q)
	end
end)

menuOpen = overlay.Visible

UserInputService.InputBegan:Connect(function(i, g)
	if i.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
	if i.KeyCode == Enum.KeyCode.RightShift then
		local show = not overlay.Visible
		overlay.Visible = show
		pcall(function()
			worldBlur.Enabled = show
		end)
		menuOpen = show
		if not show then
			closePanel()
		end
		return
	end
	if binding then
		local o = binding
		binding = nil
		if i.KeyCode == Enum.KeyCode.Escape or i.KeyCode == Enum.KeyCode.Backspace then
			o.value = nil
		elseif i.KeyCode ~= Enum.KeyCode.RightShift then
			o.value = i.KeyCode
		end
		if o.paint then
			o.paint()
		end
		return
	end
	if g then
		return
	end
	for _, m in pairs(Modules) do
		local b = m.options.Bind
		if b and b.value == i.KeyCode then
			setOn(m, not m.enabled)
		end
	end
end)

local function intervalOf(m)
	if type(m.interval) == "function" then
		local ok, v = pcall(m.interval, m)
		return ok and tonumber(v) or 0.1
	end
	return m.interval
end

RunService.Heartbeat:Connect(function(dt)
	status.Text = BW.ready and "live" or "waiting"
	status.TextColor3 = BW.ready and Color3.fromRGB(120, 230, 160) or Color3.fromRGB(170, 210, 255)
	for _, m in pairs(Modules) do
		if m.enabled and m.tick then
			m.iv = m.iv or intervalOf(m)
			m.acc += dt
			if m.iv <= 0 or m.acc >= m.iv then
				m.acc = 0
				m.iv = nil
				local ok, err = pcall(m.tick, m)
				if not ok and not m.warned then
					m.warned = true
					warn("[Quantumware] " .. m.name .. ": " .. tostring(err))
				end
			end
		end
	end
	local ti = Modules.TargetInfo
	if ti and ti.enabled then
		local t, r = pick(get(ti, "Range"))
		targetHud.Visible = t ~= nil
		if t and r then
			tn.Text = string.format("%s   %dhp", t.DisplayName, math.floor(healthOf(r.Parent) + 0.5))
		end
	else
		targetHud.Visible = false
	end
end)

lp.CharacterAdded:Connect(function()
	task.wait(0.25)
	stopFly()
	savedSpeed = nil
end)

refreshHud()
notify("Loaded. Right Shift opens the menu, right-click a module for settings.")
