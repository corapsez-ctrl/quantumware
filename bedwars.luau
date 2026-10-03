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
			BW.placer = knit.Controllers and knit.Controllers.BlockPlacementController
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

local function sendAttack(target, targetRoot, mode, cfg)
	cfg = cfg or {}
	local me = root()
	if not me or not target or not target.Character or not targetRoot then
		return false
	end
	if not (BW.client and BW.attack) then
		return false
	end
	local weapon
	if cfg.switch == false then
		local inv = inventory()
		weapon = inv and isSword(inv.hand) and inv.hand.tool
	else
		weapon = equipSword()
	end
	if typeof(weapon) ~= "Instance" then
		return false
	end
	if cfg.swing and BW.sword then
		pcall(function()
			BW.sword:playSwordEffect(metaOf(weapon.Name), false)
		end)
	end
	mode = mode or "walls"
	local aim = CFrame.lookAt(me.Position, targetRoot.Position)
	local delta = targetRoot.Position - me.Position
	local selfPos = me.Position + aim.LookVector * math.max(delta.Magnitude - 14.2, 0)
	local camPos = mode == "walls" and (targetRoot.Position - aim.LookVector * 2.5) or cam.CFrame.Position
	local cursor = mode == "walls" and aim.LookVector or CFrame.lookAt(cam.CFrame.Position, targetRoot.Position).LookVector
	if BW.sword then
		pcall(function()
			BW.sword.lastSwingServerTime = workspace:GetServerTimeNow() - 0.45
		end)
	end
	return pcall(function()
		BW.client:Get(BW.attack):SendToServer({
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
		})
	end)
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

local function mineBlock(part)
	if not part or not part:IsA("BasePart") then
		return
	end
	equipBreaker(breakKind(part))
	local blockPosition = snap3(part.Position)
	local ref = { blockPosition = blockPosition }
	local payload = {
		blockRef = ref,
		blockPosition = blockPosition,
		hitPosition = part.Position,
		hitNormal = Vector3.yAxis,
	}
	local breaker = BW.breaker and BW.breaker.blockBreaker
	if breaker then
		breaker.breakCooldown = 0
		breaker.cooldown = 0
		breaker.lastBreakTime = 0
		breaker.lastHitTime = 0
		breaker.nextBreakTime = 0
		for name, fn in pairs(breaker) do
			local lower = string.lower(tostring(name))
			if type(fn) == "function" and (string.find(lower, "break", 1, true) or string.find(lower, "hit", 1, true) or string.find(lower, "damage", 1, true)) then
				pcall(fn, breaker, ref, part.Position, Vector3.yAxis)
				pcall(fn, breaker, part, part.Position, Vector3.yAxis)
			end
		end
	end
	if BW.client then
		local names = { BW.breakRemote, "DamageBlock", "BlockDamage" }
		for i = 1, 3 do
			for _, name in ipairs(names) do
				if type(name) == "string" and name ~= "" then
					pcall(function()
						local remote = BW.client:Get(name)
						if remote and remote.SendToServer then
							remote:SendToServer(payload)
						end
					end)
				end
			end
		end
	end
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
	if #list == 0 then
		local map = workspace:FindFirstChild("Map") or workspace
		for _, inst in ipairs(map:GetDescendants()) do
			if string.find(string.lower(inst.Name), "bed", 1, true) and (inst:IsA("Model") or inst:IsA("BasePart")) then
				add(inst)
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
	if swingOrig or not BW.sword or type(BW.sword.swingSwordAtMouse) ~= "function" then
		return
	end
	swingOrig = BW.sword.swingSwordAtMouse
	BW.sword.swingSwordAtMouse = function(...)
		local result = swingOrig(...)
		task.spawn(onSwing)
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
	local on = esp.enabled or kitEsp.enabled or kitRender.enabled
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
			if kitRender.enabled and kit ~= "" then
				col = Color3.fromHSV(((#kit * 37) % 360) / 360, get(kitRender, "Saturation") / 100, 1)
			end
			e = e or {}
			pEsp[plr] = e
			if not e.h or not e.h.Parent then
				e.h = hl(model, col)
			end
			e.h.Adornee = model
			e.h.FillColor, e.h.OutlineColor = col, col
			e.h.FillTransparency = esp.enabled and (1 - get(esp, "Fill") / 100) or 0.85
			e.h.Enabled = esp.enabled or kitRender.enabled
			local head = model:FindFirstChild("Head") or r
			if not e.b or not e.b.Parent then
				e.b = bill(head)
			end
			e.b.Adornee = head
			local lines, info = {}, {}
			if not esp.enabled or get(esp, "Names") then
				table.insert(lines, plr.DisplayName)
			end
			if esp.enabled and get(esp, "Health") then
				table.insert(info, math.floor(healthOf(model) + 0.5) .. "hp")
			end
			if esp.enabled and get(esp, "Distance") then
				table.insert(info, math.floor((r.Position - me.Position).Magnitude + 0.5) .. "m")
			end
			if #info > 0 then
				table.insert(lines, table.concat(info, "  "))
			end
			if kitEsp.enabled and kit ~= "" then
				table.insert(lines, get(kitEsp, "Uppercase") and string.upper(kit) or kit)
			end
			local t = e.b:FindFirstChild("T")
			if t then
				t.TextColor3 = col
				t.Text = table.concat(lines, "\n")
				t.TextSize = esp.enabled and get(esp, "Text size") or 13
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
end, refreshBypass, hookSwing, 0.5)

add("Combat", "Reach", "Extends swings you aim yourself, no walls", function(m)
	opt(m, "Range", "slider", 18, { min = 14, max = 22, suffix = " st" })
	opt(m, "Only moving", "toggle", false)
end, refreshBypass, hookSwing, 0.5)

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

add("Combat", "ProjectileAimbot", "Aims bows and throwables with lead while charging", function(m)
	opt(m, "Range", "slider", 120, { min = 30, max = 250, step = 10, suffix = " st" })
	opt(m, "Speed", "slider", 170, { min = 60, max = 400, step = 10 })
	opt(m, "FOV", "slider", 120, { min = 20, max = 360, step = 10, suffix = "\u{B0}" })
	opt(m, "Drop comp", "toggle", true)
end, nil, function(m)
	if handKind() ~= "projectile" or not (held(M1) or held(M2)) then
		return
	end
	local _, r, d = pick(get(m, "Range"), { fov = get(m, "FOV"), visible = true, sort = "Angle" })
	if r and cam then
		local t = d / get(m, "Speed")
		local aim = r.Position + r.AssemblyLinearVelocity * t
		if get(m, "Drop comp") then
			aim += Vector3.new(0, 0.5 * workspace.Gravity * t * t * 0.3, 0)
		end
		look(aim)
	end
end, 0)

add("Combat", "Velocity", "Cuts knockback you take", function(m)
	opt(m, "Horizontal", "slider", 0, { min = 0, max = 100, step = 5, suffix = "%" })
	opt(m, "Vertical", "slider", 0, { min = 0, max = 100, step = 5, suffix = "%" })
	opt(m, "Chance", "slider", 100, { min = 0, max = 100, step = 5, suffix = "%" })
end, nil, function(m)
	if m.hooked or not (BW.knockback and BW.knockback.applyKnockback) then
		return
	end
	local old = BW.knockback.applyKnockback
	BW.knockback.applyKnockback = function(rootp, mass, dir, kb, ...)
		if math.random(1, 100) > get(m, "Chance") then
			return old(rootp, mass, dir, kb, ...)
		end
		local h, v = get(m, "Horizontal") / 100, get(m, "Vertical") / 100
		if h == 0 and v == 0 then
			return
		end
		kb = kb or {}
		kb.horizontal = (kb.horizontal or 1) * h
		kb.vertical = (kb.vertical or 1) * v
		return old(rootp, mass, dir, kb, ...)
	end
	m.hooked = true
	table.insert(m.conns, {
		Disconnect = function()
			BW.knockback.applyKnockback = old
			m.hooked = false
		end,
	})
end, 0.5)

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
end, function(m)
	local walls = get(m, "Walls")
	setWalls(walls)
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
	if not on and not Modules.InfiniteFly.enabled then
		stopFly()
	end
end, function(m)
	flyStep(get(m, "Speed"), get(m, "Vertical"))
end, 0)

add("Blatant", "InfiniteFly", "Fly that dips every few seconds to reset air time", function(m)
	opt(m, "Speed", "slider", 60, { min = 20, max = 140, step = 2 })
	opt(m, "Vertical", "slider", 45, { min = 10, max = 120, step = 5 })
	opt(m, "Dip every", "slider", 2, { min = 1, max = 6, suffix = "s" })
end, function(on, m)
	m.t = 0
	if not on and not Modules.Fly.enabled then
		stopFly()
	end
end, function(m)
	m.t = (m.t or 0) + 1 / 60
	flyStep(get(m, "Speed"), get(m, "Vertical"))
	if m.t >= get(m, "Dip every") then
		m.t = 0
		if flyVel then
			flyVel.VectorVelocity = Vector3.new(flyVel.VectorVelocity.X, -60, flyVel.VectorVelocity.Z)
		end
	end
end, 0)

add("Blatant", "LongJumps", "Launches you forward when you jump", function(m)
	opt(m, "Boost", "slider", 60, { min = 20, max = 140, step = 5 })
	opt(m, "Height", "slider", 10, { min = 0, max = 60, step = 5 })
end, nil, function(m)
	local h, r = hum(), root()
	if not h or not r then
		return
	end
	local j = h:GetState() == Enum.HumanoidStateType.Jumping
	if j and not jumpWas then
		local dir = h.MoveDirection.Magnitude > 0 and h.MoveDirection or Vector3.new(r.CFrame.LookVector.X, 0, r.CFrame.LookVector.Z)
		if dir.Magnitude > 0 then
			r.AssemblyLinearVelocity += dir.Unit * get(m, "Boost") + Vector3.new(0, get(m, "Height"), 0)
		end
	end
	jumpWas = j
end, 0)

add("Blatant", "HighJump", "Raises jump power", function(m)
	opt(m, "Power", "slider", 80, { min = 50, max = 160, step = 5 })
end, function(on)
	local h = hum()
	if h and not on then
		h.UseJumpPower = true
		h.JumpPower = 50
	end
end, function(m)
	local h = hum()
	if h then
		h.UseJumpPower = true
		h.JumpPower = get(m, "Power")
	end
end, 0.25)

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

add("Blatant", "Desync", "Jitters your server position forward", function(m)
	opt(m, "Distance", "slider", 6, { min = 2, max = 12, suffix = " st" })
	opt(m, "Delay", "slider", 200, { min = 50, max = 1000, step = 50, suffix = "ms" })
end, nil, function(m)
	local r = root()
	if not r then
		return
	end
	local cf = r.CFrame
	r.CFrame = cf * CFrame.new(0, 0, -get(m, "Distance"))
	task.defer(function()
		if r.Parent then
			r.CFrame = cf
		end
	end)
end, function(m)
	return get(m, "Delay") / 1000
end)

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

add("Render", "KitRender", "Colors ESP by kit", function(m)
	opt(m, "Saturation", "slider", 55, { min = 10, max = 100, step = 5, suffix = "%" })
end, function()
	drawESP()
end, drawESP, 0.15)

add("Render", "SkinChanger", "Recolors your character (client side)", function(m)
	opt(m, "Hue", "slider", 28, { min = 0, max = 360, step = 4, suffix = "\u{B0}" })
	opt(m, "Material", "list", "Keep", { list = { "Keep", "Neon", "ForceField", "SmoothPlastic", "Glass" } })
end, function(on, m)
	if not on then
		for p, saved in pairs(m.saved or {}) do
			if p.Parent then
				p.Color, p.Material = saved[1], saved[2]
			end
		end
		m.saved = {}
	end
end, function(m)
	local c = char()
	if not c then
		return
	end
	m.saved = m.saved or {}
	local col = Color3.fromHSV(get(m, "Hue") / 360, 0.55, 1)
	local mat = get(m, "Material")
	for _, p in ipairs(c:GetDescendants()) do
		if p:IsA("BasePart") and p.Name ~= "HumanoidRootPart" then
			m.saved[p] = m.saved[p] or { p.Color, p.Material }
			p.Color = col
			if mat ~= "Keep" then
				p.Material = Enum.Material[mat]
			end
		end
	end
end, 0.5)

add("Render", "FPSBooster", "Lowers quality for more frames", function(m)
	opt(m, "Shadows off", "toggle", true)
	opt(m, "Particles off", "toggle", true)
end, function(on, m)
	pcall(function()
		settings().Rendering.QualityLevel = on and Enum.QualityLevel.Level01 or Enum.QualityLevel.Automatic
	end)
	Lighting.GlobalShadows = not (on and get(m, "Shadows off"))
	if on and get(m, "Particles off") then
		m.fx = {}
		for _, i in ipairs(workspace:GetDescendants()) do
			if (i:IsA("ParticleEmitter") or i:IsA("Trail") or i:IsA("Smoke") or i:IsA("Fire")) and i.Enabled then
				m.fx[i] = true
				i.Enabled = false
			end
		end
	elseif not on then
		for i in pairs(m.fx or {}) do
			if i.Parent then
				i.Enabled = true
			end
		end
		m.fx = {}
	end
end)

add("Render", "Shaders", "Color grading and bloom", function(m)
	opt(m, "Saturation", "slider", 15, { min = -50, max = 80, step = 5 })
	opt(m, "Contrast", "slider", 8, { min = -20, max = 50, step = 2 })
	opt(m, "Warmth", "slider", 30, { min = 0, max = 100, step = 5, suffix = "%" })
	opt(m, "Bloom", "toggle", true)
end, function(on)
	for _, f in ipairs(shader or {}) do
		f:Destroy()
	end
	shader = {}
	if on then
		local cc = Instance.new("ColorCorrectionEffect")
		cc.Parent = Lighting
		local bloom = Instance.new("BloomEffect")
		bloom.Intensity, bloom.Size, bloom.Threshold = 0.6, 24, 1.6
		bloom.Parent = Lighting
		shader = { cc, bloom }
	end
end, function(m)
	local cc, bloom = shader and shader[1], shader and shader[2]
	if cc then
		cc.Saturation = get(m, "Saturation") / 100
		cc.Contrast = get(m, "Contrast") / 100
		local w = get(m, "Warmth") / 100
		cc.TintColor = Color3.new(1, 1 - w * 0.12, 1 - w * 0.2)
	end
	if bloom then
		bloom.Enabled = get(m, "Bloom")
	end
end, 0.2)

add("Render", "NoTexture", "Flattens every material", nil, function(on, m)
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
		table.insert(m.conns, workspace.DescendantAdded:Connect(strip))
	else
		for i, mat in pairs(tex or {}) do
			if i.Parent then
				i.Material = mat
			end
		end
		tex = {}
	end
end)

add("Render", "TargetInfo", "Shows your closest target", function(m)
	opt(m, "Range", "slider", 24, { min = 8, max = 60, suffix = " st" })
end)

add("Utility", "AutoWin", "Walks the bed break: defense first, then the bed", function(m)
	opt(m, "Range", "slider", 30, { min = 10, max = 40, suffix = " st" })
	opt(m, "Auto tool", "toggle", true)
end, nil, function(m)
	breakBedStep(get(m, "Range"), true, get(m, "Auto tool"))
end, 0.06)

add("Utility", "AntiLasso", "Breaks lasso pulls on you", nil, nil, function()
	local c = char()
	if not c then
		return
	end
	for _, i in ipairs(c:GetDescendants()) do
		if i:IsA("Constraint") and not i:IsA("Motor6D") and i ~= flyVel then
			pcall(function()
				i.Enabled = false
			end)
		end
	end
end, 0.1)

add("Utility", "AutoLasso", "Swings at enemies while you have a lasso kit", function(m)
	opt(m, "Range", "slider", 30, { min = 10, max = 40, suffix = " st" })
end, nil, function(m)
	if string.find(string.lower(kitOf(lp)), "lasso", 1, true) then
		local t, r = pick(get(m, "Range"), { visible = true })
		if t then
			sendAttack(t, r, "silent")
		end
	end
end, 0.3)

add("Utility", "AutoKit", "Fires your kit ability near enemies", function(m)
	opt(m, "Range", "slider", 20, { min = 6, max = 40, suffix = " st" })
end, nil, function(m)
	if not pick(get(m, "Range")) then
		return
	end
	local ctrls = BW.knit and BW.knit.Controllers
	local kit = ctrls and (ctrls.AbilityController or ctrls.KitAbilityController)
	if kit then
		for _, n in ipairs({ "useAbility", "activateAbility" }) do
			if type(kit[n]) == "function" then
				pcall(kit[n], kit)
			end
		end
	end
end, 0.25)

add("Utility", "ChestSteal", "Opens chests you walk near", function(m)
	opt(m, "Range", "slider", 12, { min = 4, max = 24, suffix = " st" })
end, nil, function(m)
	prompts({ "chest", "loot", "open" }, get(m, "Range"))
end, 0.3)

add("Utility", "FastPlace", "Places blocks fast while you hold M2", function(m)
	opt(m, "Delay", "slider", 40, { min = 10, max = 200, step = 5, suffix = "ms" })
end, nil, function()
	if not held(M2) then
		return
	end
	if handKind() == "block" and blockPlacer() then
		task.spawn(placeGrid, mouseGrid())
	else
		click(1)
	end
end, function(m)
	return get(m, "Delay") / 1000
end)

add("World", "Nuker", "Fast-breaks bed defense, then the bed", function(m)
	opt(m, "Range", "slider", 30, { min = 10, max = 40, suffix = " st" })
	opt(m, "Delay", "slider", 50, { min = 10, max = 300, step = 10, suffix = "ms" })
	opt(m, "Defense first", "toggle", true)
	opt(m, "Auto tool", "toggle", true)
end, nil, function(m)
	breakBedStep(get(m, "Range"), get(m, "Defense first"), get(m, "Auto tool"))
end, function(m)
	return get(m, "Delay") / 1000
end)

add("World", "BlockIn", "Boxes you in with blocks", function(m)
	opt(m, "Roof", "toggle", true)
	opt(m, "Floor", "toggle", true)
	opt(m, "Delay", "slider", 350, { min = 100, max = 1500, step = 50, suffix = "ms" })
end, nil, function(m)
	local r = root()
	if not r or not equipBlock() then
		return
	end
	local base = Vector3.new(math.round(r.Position.X / 3), math.round((r.Position.Y - 1.5) / 3), math.round(r.Position.Z / 3))
	local spots = {}
	for _, o in ipairs({ Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0), Vector3.new(0, 0, 1), Vector3.new(0, 0, -1) }) do
		table.insert(spots, base + o)
		table.insert(spots, base + o + Vector3.yAxis)
	end
	if get(m, "Roof") then
		table.insert(spots, base + Vector3.new(0, 2, 0))
	end
	if get(m, "Floor") then
		table.insert(spots, base - Vector3.yAxis)
	end
	for _, g in ipairs(spots) do
		task.spawn(placeGrid, g)
	end
end, function(m)
	return get(m, "Delay") / 1000
end)

add("Inventory", "AutoBank", "Uses bank and shop prompts near you", function(m)
	opt(m, "Range", "slider", 16, { min = 4, max = 30, suffix = " st" })
end, nil, function(m)
	prompts({ "bank", "shop", "upgrade", "deposit" }, get(m, "Range"))
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

local kitNames = {}
for name in pairs(KIT) do
	table.insert(kitNames, name)
end
table.sort(kitNames)

for _, name in ipairs(kitNames) do
	local keys = KIT[name]
	add("Kits", name, "Runs only when you have this kit", function(m)
		opt(m, "Range", "slider", 18, { min = 6, max = 22, suffix = " st" })
		opt(m, "Walls", "toggle", false)
	end, nil, function(m)
		if not kitOn(keys) then
			return
		end
		local walls = get(m, "Walls")
		local t, r = pick(get(m, "Range"), { visible = not walls })
		if t then
			sendAttack(t, r, walls and "walls" or "silent")
		end
		if name == "AutoBuilder" and Modules.BlockIn then
			Modules.BlockIn.tick(Modules.BlockIn)
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
overlay.BackgroundColor3 = Color3.fromRGB(6, 8, 14)
overlay.BackgroundTransparency = 0.55
overlay.Parent = screen

local worldBlur = Instance.new("BlurEffect")
worldBlur.Size = 10
worldBlur.Parent = Lighting

local menu = Instance.new("Frame")
menu.BackgroundTransparency = 1
menu.Size = UDim2.fromScale(1, 1)
menu.Parent = overlay

local COL_W, COL_GAP = 176, 12
local COLS = { "Combat", "Blatant", "Render", "Utility", "World", "Inventory", "Kits" }
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
	if i.KeyCode == Enum.KeyCode.RightShift then
		local show = not overlay.Visible
		overlay.Visible = show
		worldBlur.Enabled = show
		menuOpen = show
		if not show then
			closePanel()
		end
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
	if ti.enabled then
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
