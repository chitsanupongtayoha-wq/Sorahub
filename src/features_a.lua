
local speedOn, jumpOn, airJump = false, false, false
local noclipOn = false
local flyOn, tpOn = false, false
local speedVal, jumpVal = 16, 50
local flyVal, tpVal = 50, 10
local orig = nil
local initialized = false
local antiAfk = false
local autoRejoin = false
local skyOn = false
local skyAnchor = nil
local invisOn = false
local invisBtnOn = false
local flyHudOn = false
local statsHudOn = true

local flyHudRefresh = function() end
local invisRefresh = function() end
local hudApply = function() end

local function getHum()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function captureOrig(hum)
	orig = {
		speed = hum.WalkSpeed,
		jump = hum.JumpPower,
		useJP = hum.UseJumpPower,
	}
	if not initialized then
		initialized = true
		speedVal = math.clamp(math.floor(orig.speed + 0.5), 8, SPEED_MAX)
		jumpVal = math.clamp(math.floor(orig.jump + 0.5), 20, JUMP_MAX)
	end
end

local function applyStats()
	local hum = getHum()
	if not hum then return end
	if not orig then captureOrig(hum) end

	if speedOn then
		hum.WalkSpeed = math.min(speedVal, SPEED_MAX)
	else
		hum.WalkSpeed = orig.speed
	end

	if jumpOn then
		hum.UseJumpPower = true
		hum.JumpPower = math.min(jumpVal, JUMP_MAX)
	else
		hum.UseJumpPower = orig.useJP
		hum.JumpPower = orig.jump
	end
end

local function enforceStats()
	if not (speedOn or jumpOn) then return end
	local hum = getHum()
	if not hum then return end
	if speedOn then
		local sv = math.min(speedVal, SPEED_MAX)
		if hum.WalkSpeed ~= sv then hum.WalkSpeed = sv end
	end
	if jumpOn then
		local jv = math.min(jumpVal, JUMP_MAX)
		if not hum.UseJumpPower then hum.UseJumpPower = true end
		if hum.JumpPower ~= jv then hum.JumpPower = jv end
	end
end
track(RunService.Stepped:Connect(enforceStats))
track(RunService.Heartbeat:Connect(enforceStats))

local noclipParts = {}

local function setNoclip(on)
	noclipOn = on
	if not on then
		for part in pairs(noclipParts) do
			if part and part.Parent then part.CanCollide = true end
		end
		table.clear(noclipParts)
	end
end

track(RunService.Stepped:Connect(function()
	if not noclipOn then return end
	local char = player.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			noclipParts[part] = true
			part.CanCollide = false
		end
	end
end))

local flyBV, flyBG = nil, nil

local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local hum, root = getHum(), getRoot()
	if not hum or not root then return end
	hum.PlatformStand = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = root

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 1e4
	flyBG.CFrame = root.CFrame
	flyBG.Parent = root
end

local function setFly(on)
	flyOn = on
	if on then startFly() else stopFly() end
	flyHudRefresh()
end

local function setFlyVal(v)
	flyVal = math.clamp(math.floor(v + 0.5), 10, FLY_MAX)
	flyHudRefresh()
end

track(RunService.Heartbeat:Connect(function(dt)
	local hum, root = getHum(), getRoot()
	if not hum or not root then return end

	if flyOn then
		if not (flyBV and flyBV.Parent) then startFly() end
		local cam = workspace.CurrentCamera
		if cam and flyBV then
			local cf = cam.CFrame
			local look = cf.LookVector
			local right = cf.RightVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
			flatLook = flatLook.Unit
			local flatRight = Vector3.new(right.X, 0, right.Z)
			flatRight = flatRight.Magnitude > 0.01 and flatRight.Unit or Vector3.new(1, 0, 0)

			local move = hum.MoveDirection
			local fwd = move:Dot(flatLook)
			local side = move:Dot(flatRight)

			local vert = 0
			if hum.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert += 1 end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vert -= 1 end

			local dir = look * fwd + flatRight * side + Vector3.new(0, vert, 0)
			if dir.Magnitude > 1 then dir = dir.Unit end

			flyBV.Velocity = dir * math.min(flyVal, FLY_MAX)
			flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
		end
	elseif tpOn then
		local move = hum.MoveDirection
		if move.Magnitude > 0 then
			root.CFrame = root.CFrame + move * math.min(tpVal, TPWALK_MAX) * dt
		end
	end
end))

local setSky
do
	local skyPlat, skyOrigCF, skyPlatY

	-- หาความสูงพื้นใต้จุดที่กำหนด (ข้ามตัวละคร/ม็อบ และพาร์ทที่ไม่ชน)
	local function skyFindGround(x, y, z, up, dist)
		local ex = {}
		if player.Character then table.insert(ex, player.Character) end
		if skyPlat then table.insert(ex, skyPlat) end
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then table.insert(ex, pl.Character) end
		end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local origin = Vector3.new(x, y + up, z)
		for _ = 1, 6 do
			rp.FilterDescendantsInstances = ex
			local hit = workspace:Raycast(origin, Vector3.new(0, -dist, 0), rp)
			if not hit then return nil end
			local inst = hit.Instance
			local model = inst:FindFirstAncestorOfClass("Model")
			local isChar = model and model:FindFirstChildOfClass("Humanoid")
			if isChar then
				table.insert(ex, model)
			elseif inst.CanCollide == false then
				table.insert(ex, inst)
			else
				return hit.Position.Y
			end
		end
		return nil
	end

	function setSky(on, skipReturn)
		local cam = workspace.CurrentCamera
		if on then
			local root, hum = getRoot(), getHum()
			if skyOn or not root or not hum or not cam then return end
			skyOrigCF = root.CFrame

			-- หาพื้นจริงใต้ตัว (ไกลได้ถึง 20000) ถ้าอยู่กลางอากาศ ตัวจะตกลงพื้นเหมือนปกติ
			local groundY = skyFindGround(root.Position.X, root.Position.Y, root.Position.Z, 5, 20000)
				or (root.Position.Y - 3)
			skyPlatY = groundY + OPT.SKY_HEIGHT - 1

			skyAnchor = Instance.new("Part")
			skyAnchor.Name = "SkyCamAnchor"
			skyAnchor.Anchored = true
			skyAnchor.CanCollide = false
			skyAnchor.CanQuery = false
			skyAnchor.CanTouch = false
			skyAnchor.Transparency = 1
			skyAnchor.Size = Vector3.new(1, 1, 1)
			skyAnchor.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.5, 0))
			skyAnchor.Parent = workspace

			skyPlat = Instance.new("Part")
			skyPlat.Name = "SkyPlatform"
			skyPlat.Anchored = true
			skyPlat.CanCollide = true
			skyPlat.Transparency = 1
			skyPlat.Size = Vector3.new(200, 2, 200)
			skyPlat.CFrame = CFrame.new(root.Position.X, skyPlatY, root.Position.Z)
			skyPlat.Parent = workspace

			skyOn = true
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = skyOrigCF + Vector3.new(0, OPT.SKY_HEIGHT, 0)
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = skyAnchor
			invisRefresh()
		else
			if not skyOn then return end
			skyOn = false

			-- ตอนปิด: กลับลงมาตรงจุดที่กล้อง/ตัวเสมือนอยู่ตอนนี้ ไม่ใช่จุดที่กดเปิด
			local returnCF = skyOrigCF
			local rootNow = getRoot()
			if skyAnchor and rootNow then
				local ap = skyAnchor.Position
				local rpp = RaycastParams.new()
				rpp.FilterDescendantsInstances = {player.Character}
				rpp.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(ap + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), rpp)
				if not hit then
					hit = workspace:Raycast(ap + Vector3.new(0, 300, 0), Vector3.new(0, -700, 0), rpp)
				end
				local pos = hit and (hit.Position + Vector3.new(0, 3.5, 0)) or ap
				returnCF = CFrame.new(pos) * (rootNow.CFrame - rootNow.CFrame.Position)
			end

			if skyPlat then skyPlat:Destroy() skyPlat = nil end
			if skyAnchor then skyAnchor:Destroy() skyAnchor = nil end
			local root, hum = getRoot(), getHum()
			if not skipReturn and root and returnCF then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = returnCF
			end
			if cam then
				cam.CameraType = Enum.CameraType.Custom
				if hum then cam.CameraSubject = hum end
			end
			invisRefresh()
		end
	end

	-- แพลตฟอร์มลอกพื้นจริง: เดินขึ้นภูเขา/ลงเนินได้เหมือนอยู่บนพื้น (ผนังทะลุได้)
	local groundAcc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not skyOn then return end
		local root = getRoot()
		if root and skyPlat then
			groundAcc += dt
			if groundAcc >= 0.03 then
				groundAcc = 0
				local vy = root.Position.Y - OPT.SKY_HEIGHT -- ความสูงเสมือนบนพื้นจริง
				local g = skyFindGround(root.Position.X, vy, root.Position.Z, 12, 3000)
				if g then skyPlatY = g + OPT.SKY_HEIGHT - 1 end
			end
			skyPlat.CFrame = CFrame.new(root.Position.X, skyPlatY, root.Position.Z)
			-- ตกนุ่ม: จำกัดความเร็วตกไม่ให้เกิน 40 กันเกมที่มีดาเมจตกจากที่สูง
			local vel = root.AssemblyLinearVelocity
			if vel.Y < -40 then
				root.AssemblyLinearVelocity = Vector3.new(vel.X, -40, vel.Z)
			end
			if root.Position.Y < skyPlatY - 40 then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = CFrame.new(root.Position.X, skyPlatY + 4, root.Position.Z)
			end
		end
	end))

	track(RunService.RenderStepped:Connect(function()
		if not skyOn or not skyAnchor then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		-- กล้องตามตัวเสมือน: ตำแหน่งตัวบนฟ้า ลบความสูงฟ้า = ตำแหน่งบนพื้นจริง
		local sroot = getRoot()
		if sroot then
			skyAnchor.CFrame = CFrame.new(sroot.Position - Vector3.new(0, OPT.SKY_HEIGHT - 1.5, 0))
		end
		if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
		if cam.CameraSubject ~= skyAnchor then cam.CameraSubject = skyAnchor end
	end))
end

local invisStore = {}
local setInvis
do
	local invisAcc = 0

	local function invisApply()
		local char = player.Character
		if not char then return end
		for _, d in ipairs(char:GetDescendants()) do
			if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
				if invisStore[d] == nil then invisStore[d] = d.Transparency end
				if d.Transparency ~= 1 then d.Transparency = 1 end
			end
		end
	end

	function setInvis(on)
		if on == invisOn then return end
		invisOn = on
		if on then
			invisApply()
		else
			for inst, v in pairs(invisStore) do
				pcall(function() inst.Transparency = v end)
			end
			table.clear(invisStore)
		end
		invisRefresh()
	end

	track(RunService.Heartbeat:Connect(function(dt)
		if not invisOn then return end
		invisAcc += dt
		if invisAcc < 0.2 then return end
		invisAcc = 0
		invisApply()
	end))
end

local espOn, fullbrightOn, aimOn, spectateOn = true, false, false, false
local targetPlayer = nil

local function getChar(p)
	return p and p.Character
end

local function getPlayerHum(p)
	local c = getChar(p)
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getPlayerRoot(p)
	local c = getChar(p)
	return c and c:FindFirstChild("HumanoidRootPart")
end

local clearEsp
do
	local espObjs = {}

	local function removeEsp(p)
		local o = espObjs[p]
		if not o then return end
		for _, inst in ipairs({o.hl, o.box, o.bb, o.arrow}) do
			pcall(function() inst:Destroy() end)
		end
		espObjs[p] = nil
	end

	function clearEsp()
		for p in pairs(espObjs) do removeEsp(p) end
	end

	local function createEsp(p, char)
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		if not root or not head then return end

		local hl = Instance.new("Highlight")
		hl.Adornee = char
		hl.FillColor = WHITE
		hl.FillTransparency = 0.85
		hl.OutlineColor = WHITE
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = gui

		local box = Instance.new("BoxHandleAdornment")
		box.Adornee = root
		box.Size = Vector3.new(4, 5.5, 3)
		box.Color3 = WHITE
		box.Transparency = 0.8
		box.AlwaysOnTop = true
		box.ZIndex = 1
		box.Parent = gui

		local bb = Instance.new("BillboardGui")
		bb.Adornee = head
		bb.Size = UDim2.fromOffset(240, 100)
		bb.StudsOffset = Vector3.new(0, 2.8, 0)
		bb.AlwaysOnTop = true
		bb.Parent = gui

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextColor3 = WHITE
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextYAlignment = Enum.TextYAlignment.Bottom
		label.Text = ""
		label.Parent = bb

		local arrow = Instance.new("Frame")
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Size = UDim2.fromOffset(90, 52)
		arrow.BackgroundTransparency = 1
		arrow.Visible = false
		arrow.Parent = arrowLayer

		local tri = Instance.new("TextLabel")
		tri.BackgroundTransparency = 1
		tri.Size = UDim2.new(1, 0, 0, 26)
		tri.Text = "▲"
		tri.TextSize = 24
		tri.TextColor3 = WHITE
		tri.TextStrokeTransparency = 0.3
		tri.Font = Enum.Font.GothamBold
		tri.Parent = arrow

		local atext = Instance.new("TextLabel")
		atext.BackgroundTransparency = 1
		atext.Position = UDim2.fromOffset(0, 26)
		atext.Size = UDim2.new(1, 0, 0, 24)
		atext.Text = ""
		atext.TextSize = 13
		atext.TextColor3 = WHITE
		atext.TextStrokeTransparency = 0.3
		atext.Font = Enum.Font.GothamBold
		atext.TextTruncate = Enum.TextTruncate.AtEnd
		atext.Parent = arrow

		espObjs[p] = {
			char = char, hl = hl, box = box, bb = bb, label = label,
			arrow = arrow, tri = tri, atext = atext,
		}
	end

	local espAcc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not espOn then
			if next(espObjs) then clearEsp() end
			return
		end
		espAcc += dt
		if espAcc < 0.1 then return end
		espAcc = 0

		local myRoot = getRoot()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local char = p.Character
				local o = espObjs[p]
				if char and char.Parent then
					if o and o.char ~= char then
						removeEsp(p)
						o = nil
					end
					if not o then
						createEsp(p, char)
						o = espObjs[p]
					end
					if o then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local root = char:FindFirstChild("HumanoidRootPart")
						local tool = char:FindFirstChildOfClass("Tool")
						local hpText = hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "-"
						local dist = (myRoot and root) and math.floor((root.Position - myRoot.Position).Magnitude) or 0
						o.label.Text = p.DisplayName .. " (@" .. p.Name .. ")\n"
							.. tr("เลือด") .. " " .. hpText .. " | " .. dist .. " studs\n"
							.. tr("ถือ:") .. " " .. (tool and tool.Name or tr("ไม่มี"))
						local extra = OPT.infoLine and OPT.infoLine(p)
						if extra then o.label.Text = o.label.Text .. "\n" .. extra end
						o.atext.Text = p.DisplayName .. " " .. dist .. "m"

						-- สีตามระดับความเสี่ยงจากตัวตรวจจับ (ถ้าเปิดอยู่)
						local tier = OPT.riskInfo and OPT.riskInfo(p)
						local c = tier and tier.color or WHITE
						o.hl.FillColor = c
						o.hl.OutlineColor = c
						o.box.Color3 = c
						o.label.TextColor3 = c
						o.tri.TextColor3 = c
						o.atext.TextColor3 = c
						if tier then o.label.Text = tr(tier.text) .. "\n" .. o.label.Text end
					end
				elseif o then
					removeEsp(p)
				end
			end
		end
	end))

	track(RunService.RenderStepped:Connect(function()
		if not espOn then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local size = cam.ViewportSize
		local center = size / 2
		local margin = 48
		local mx, my = center.X - margin, center.Y - margin

		for _, o in pairs(espObjs) do
			local root = o.char and o.char:FindFirstChild("HumanoidRootPart")
			if root and o.arrow then
				local v = cam:WorldToViewportPoint(root.Position)
				local onScreen = v.Z > 0 and v.X > 0 and v.X < size.X and v.Y > 0 and v.Y < size.Y
				if onScreen then
					o.arrow.Visible = false
				else
					local dir = Vector2.new(v.X, v.Y) - center
					if v.Z < 0 then dir = -dir end
					if dir.Magnitude < 0.001 then dir = Vector2.new(0, 1) end
					dir = dir.Unit
					local tx = dir.X ~= 0 and mx / math.abs(dir.X) or math.huge
					local ty = dir.Y ~= 0 and my / math.abs(dir.Y) or math.huge
					local t = math.min(tx, ty)
					local pos = center + dir * t
					o.arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
					o.tri.Rotation = math.deg(math.atan2(dir.X, -dir.Y))
					o.arrow.Visible = true
				end
			end
		end
	end))

	track(Players.PlayerRemoving:Connect(function(p)
		removeEsp(p)
		if p == targetPlayer then
			targetPlayer = nil
			if spectateOn then
				spectateOn = false
				local h = getHum()
				local cam = workspace.CurrentCamera
				if h and cam then cam.CameraSubject = skyAnchor or h end
			end
		end
	end))
end

-- ====== Hitbox: ขยายขนาด hitbox ระบุเป็นตัวเลขได้ (ผู้เล่น + ม็อบ/NPC) ======
-- ใช้พาร์ทเสริมที่เชื่อมติดกับ HumanoidRootPart (ไม่แตะพาร์ทจริงของตัวละคร)
-- ตัวละคร/ม็อบจึงเดิน ขยับ และวาร์ปได้ตามปกติ และ hitbox ตามตัวไปด้วย
local HB_MAX = 2048
local hitboxOn, hitboxSize = false, 10
local hitboxMobSize = 200
local hitboxPlayers, hitboxMobs = true, true
local hitboxReal = false -- true = ขยายพาร์ทจริงของตัวละคร (ไม่ใช้พาร์ทเสริม)
local setHitbox, setHitboxReal
do
	local HB_NAME = "SoraHitbox"
	local HB_TRANSP = 0.7 -- ความโปร่งใสของกล่อง (ล็อกไว้ ไม่ให้เกมเปลี่ยนเป็นขาวทึบ)

	-- ล็อกหน้าตา: ถ้าเกมแก้ Transparency/Color ของพาร์ทนี้ (เช่น fade ตัวละคร) ให้ตั้งกลับทันที
	local function lockLook(part)
		return {
			part:GetPropertyChangedSignal("Transparency"):Connect(function()
				if part.Transparency ~= HB_TRANSP then part.Transparency = HB_TRANSP end
			end),
			part:GetPropertyChangedSignal("Color"):Connect(function()
				if part.Color ~= WHITE then part.Color = WHITE end
			end),
		}
	end
	local function unlock(cs)
		if not cs then return end
		for _, c in ipairs(cs) do c:Disconnect() end
	end
	local humSet = {}   -- [Humanoid] = true
	local ext = {}      -- [Humanoid] = {part = Part, root = BasePart}
	local realStore = {} -- [BasePart] = ค่าเดิม (โหมดขยายตัวจริง)
	local addConn = nil
	local scanToken = 0

	local function pickPart(model)
		return model:FindFirstChild("HumanoidRootPart")
			or model.PrimaryPart
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
	end

	local function removeExt(hum)
		local o = ext[hum]
		if not o then return end
		ext[hum] = nil
		unlock(o.locks)
		pcall(function() o.part:Destroy() end)
	end

	local function restoreReal(part)
		local o = realStore[part]
		if not o then return end
		realStore[part] = nil
		unlock(o.locks) -- ต้องปลดล็อกก่อนคืนค่า ไม่งั้นจะถูกตั้งกลับเป็นกล่องขาว
		if part.Parent then
			pcall(function()
				part.Size = o.Size
				part.Transparency = o.Transparency
				part.CanCollide = o.CanCollide
				part.Color = o.Color
				part.Material = o.Material
			end)
		end
	end

	local function isTarget(hum)
		local model = hum.Parent
		if not model or not model:IsA("Model") then return false end
		local myChar = player.Character
		if myChar and (model == myChar or model:IsDescendantOf(myChar)) then return false end
		if hum.Health <= 0 then return false end
		-- มี ForceField = โดนดาเมจไม่ได้ ไม่ต้องมี hitbox (จะกลับมาเองเมื่อเกราะหมด)
		if model:FindFirstChildOfClass("ForceField") then return false end
		if Players:GetPlayerFromCharacter(model) then
			return hitboxPlayers
		end
		return hitboxMobs
	end

	local function sizeFor(hum)
		local v = Players:GetPlayerFromCharacter(hum.Parent) and hitboxSize or hitboxMobSize
		return math.clamp(v, 1, HB_MAX)
	end

	local function applyOne(hum)
		local model = hum.Parent
		if not model then return end

		local root = pickPart(model)

		if not isTarget(hum) then
			removeExt(hum)
			if root and root:IsA("BasePart") then restoreReal(root) end
			return
		end

		if not root or not root:IsA("BasePart") then
			removeExt(hum)
			return
		end

		if hitboxReal then
			-- โหมดขยายพาร์ทจริง: ไม่ตั้ง Massless เพื่อไม่ให้ฟิสิกส์ของตัวละครเพี้ยน
			removeExt(hum)
			if not realStore[root] then
				realStore[root] = {
					Size = root.Size,
					Transparency = root.Transparency,
					CanCollide = root.CanCollide,
					Color = root.Color,
					Material = root.Material,
				}
				realStore[root].locks = lockLook(root)
			end
			local rs = sizeFor(hum)
			local rwant = Vector3.new(rs, rs, rs)
			if root.Size ~= rwant then root.Size = rwant end
			if root.Transparency ~= HB_TRANSP then root.Transparency = HB_TRANSP end
			if root.Color ~= WHITE then root.Color = WHITE end
			root.Material = Enum.Material.SmoothPlastic
			root.CanCollide = false
			return
		end
		restoreReal(root)

		local o = ext[hum]
		if o and (not o.part.Parent or o.root ~= root or o.part.Parent ~= model) then
			removeExt(hum)
			o = nil
		end

		local s = sizeFor(hum)
		if not o then
			local p = Instance.new("Part")
			p.Name = HB_NAME
			p.Size = Vector3.new(s, s, s)
			p.CFrame = root.CFrame
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = true
			p.CanTouch = true
			p.Massless = true
			p.Transparency = HB_TRANSP
			p.Color = WHITE
			p.Material = Enum.Material.SmoothPlastic
			p.CastShadow = false
			pcall(function() p.CollisionGroup = root.CollisionGroup end)

			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p

			p.Parent = model
			o = {part = p, root = root, locks = lockLook(p)}
			ext[hum] = o
		else
			local want = Vector3.new(s, s, s)
			if o.part.Size ~= want then o.part.Size = want end
			if o.part.Transparency ~= HB_TRANSP then o.part.Transparency = HB_TRANSP end
			if o.part.Color ~= WHITE then o.part.Color = WHITE end
			if o.part.CollisionGroup ~= root.CollisionGroup then
				pcall(function() o.part.CollisionGroup = root.CollisionGroup end)
			end
		end
	end

	local function addHum(inst)
		if inst:IsA("Humanoid") then humSet[inst] = true end
	end

	local function restoreAll()
		for hum in pairs(ext) do removeExt(hum) end
		for part in pairs(realStore) do restoreReal(part) end
	end

	-- ===== รายบุคคล: ทุกครั้งที่ผู้เล่นคนหนึ่งตาย/เกิดใหม่ ล้างแล้วสร้าง hitbox ของคนนั้นใหม่ =====
	local playerConns = {} -- [Player] = {Connection...}
	local plrAddConn = nil

	local function releasePlayer(p)
		local ch = p.Character
		if not ch then return end
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then
			removeExt(hum)
			humSet[hum] = nil
		end
		local r = pickPart(ch)
		if r then restoreReal(r) end
	end

	local function watchPlayer(p)
		if p == player or playerConns[p] then return end

		local function onChar(ch)
			if not hitboxOn then return end
			task.spawn(function()
				local hum = ch:WaitForChild("Humanoid", 10)
				ch:WaitForChild("HumanoidRootPart", 10)
				if not hum then return end
				-- ตายแล้ว: ล้าง hitbox ของคนนี้ทันที
				hum.Died:Connect(function() releasePlayer(p) end)
				-- สร้างใหม่หลังเกิด และย้ำอีกสองรอบ เผื่อเกมประกอบตัวละครหลังเกิด
				for i = 1, 3 do
					if not hitboxOn or not ch.Parent then return end
					addHum(hum)
					applyOne(hum)
					task.wait(i == 1 and 0.5 or 1.5)
				end
			end)
		end

		playerConns[p] = {
			p.CharacterAdded:Connect(onChar),
			p.CharacterRemoving:Connect(function() releasePlayer(p) end),
		}
		if p.Character then onChar(p.Character) end
	end

	local function unwatchAll()
		for _, cs in pairs(playerConns) do
			for _, c in ipairs(cs) do c:Disconnect() end
		end
		table.clear(playerConns)
		if plrAddConn then plrAddConn:Disconnect() plrAddConn = nil end
	end

	function setHitbox(on)
		if on == hitboxOn then return end
		hitboxOn = on
		scanToken += 1
		local myToken = scanToken

		if on then
			if addConn then addConn:Disconnect() end
			addConn = workspace.DescendantAdded:Connect(addHum)
			for _, pl in ipairs(Players:GetPlayers()) do watchPlayer(pl) end
			plrAddConn = Players.PlayerAdded:Connect(watchPlayer)
			task.spawn(function()
				local n = 0
				for _, inst in ipairs(workspace:GetDescendants()) do
					if myToken ~= scanToken then return end
					addHum(inst)
					n += 1
					if n % 3000 == 0 then task.wait() end
				end
			end)
		else
			if addConn then addConn:Disconnect() addConn = nil end
			unwatchAll()
			restoreAll()
			table.clear(humSet)
		end
	end

	-- สลับโหมด: คืนค่าของโหมดเก่าก่อน
	function setHitboxReal(b)
		hitboxReal = b
		if hitboxOn then restoreAll() end
	end

	local acc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not hitboxOn then return end
		acc += dt
		if acc < 0.2 then return end
		acc = 0

		-- กวาดล้าง: ตัวที่ตาย/หมดสภาพ/ถูกลบ Humanoid ออก ต้องไม่เหลือ hitbox ค้าง
		for part in pairs(realStore) do
			if not part:IsDescendantOf(workspace) then
				realStore[part] = nil
			else
				local model = part.Parent
				local h = model and model:FindFirstChildOfClass("Humanoid")
				if not h or not isTarget(h) then restoreReal(part) end
			end
		end
		for hum in pairs(ext) do
			if not hum.Parent or not hum:IsDescendantOf(workspace) or not isTarget(hum) then
				removeExt(hum)
			end
		end

		for hum in pairs(humSet) do
			if not hum.Parent or not hum:IsDescendantOf(workspace) then
				humSet[hum] = nil
				removeExt(hum)
			else
				applyOne(hum)
			end
		end
	end))
end

local setFullbright
do
	local lightOrig = nil

	local function applyFullbright()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e6
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
	end

	function setFullbright(on)
		if on then
			if not lightOrig then
				lightOrig = {
					Brightness = Lighting.Brightness,
					ClockTime = Lighting.ClockTime,
					FogEnd = Lighting.FogEnd,
					GlobalShadows = Lighting.GlobalShadows,
					Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
				}
			end
			fullbrightOn = true
			applyFullbright()
		else
			fullbrightOn = false
			if lightOrig then
				for k, v in pairs(lightOrig) do
					pcall(function() Lighting[k] = v end)
				end
				lightOrig = nil
			end
		end
	end

	track(RunService.Heartbeat:Connect(function()
		if fullbrightOn then applyFullbright() end
	end))
end

local fpsOn = false
local setFpsBoost
do
	local fpsStore = {}
	local fpsConn, fpsOrigQuality, fpsOrigCap = nil, nil, nil

	local function fpsSet(inst, prop, val)
		local ok, cur = pcall(function() return inst[prop] end)
		if not ok or cur == val then return end
		local s = fpsStore[inst]
		if not s then
			s = {}
			fpsStore[inst] = s
		end
		if s[prop] == nil then s[prop] = cur end
		pcall(function() inst[prop] = val end)
	end

	local function fpsOptimize(inst)
		if inst:IsA("BasePart") then
			fpsSet(inst, "Material", Enum.Material.SmoothPlastic)
			fpsSet(inst, "Reflectance", 0)
			fpsSet(inst, "CastShadow", false)
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			fpsSet(inst, "Transparency", 1)
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke")
			or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("PostEffect") then
			fpsSet(inst, "Enabled", false)
		end
	end

	function setFpsBoost(on)
		if on == fpsOn then return end
		fpsOn = on
		if on then
			pcall(function()
				fpsOrigQuality = settings().Rendering.QualityLevel
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			pcall(function()
				if getfpscap then fpsOrigCap = getfpscap() end
				if setfpscap then setfpscap(OPT.FPS_CAP) end
			end)
			fpsSet(Lighting, "GlobalShadows", false)
			pcall(function()
				local t = workspace.Terrain
				fpsSet(t, "Decoration", false)
				fpsSet(t, "WaterWaveSize", 0)
				fpsSet(t, "WaterReflectance", 0)
			end)
			for _, c in ipairs(Lighting:GetChildren()) do fpsOptimize(c) end

			task.spawn(function()
				local n = 0
				for _, inst in ipairs(workspace:GetDescendants()) do
					if not fpsOn then return end
					fpsOptimize(inst)
					n += 1
					if n % 400 == 0 then task.wait() end
				end
			end)
			fpsConn = workspace.DescendantAdded:Connect(function(inst)
				if fpsOn then fpsOptimize(inst) end
			end)
		else
			if fpsConn then fpsConn:Disconnect() fpsConn = nil end
			for inst, props in pairs(fpsStore) do
				for k, v in pairs(props) do
					pcall(function() inst[k] = v end)
				end
			end
			table.clear(fpsStore)
			pcall(function()
				if fpsOrigQuality then settings().Rendering.QualityLevel = fpsOrigQuality end
			end)
			pcall(function()
				if setfpscap then setfpscap(fpsOrigCap or 60) end
			end)
		end
	end
end

local function findPlayer(text)
	text = (text or ""):lower()
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	if text == "" then return nil end
	local partial
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local n, d = p.Name:lower(), p.DisplayName:lower()
			if n == text or d == text then return p end
			if not partial and (n:find(text, 1, true) or d:find(text, 1, true)) then
				partial = p
			end
		end
	end
	return partial
end

do
	local function getAimPart()
		if targetPlayer then
			local hum = getPlayerHum(targetPlayer)
			local c = getChar(targetPlayer)
			if hum and hum.Health > 0 and c then
				return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
			end
			return nil
		end

		local myRoot = getRoot()
		if not myRoot then return nil end
		local origin = (skyOn and skyAnchor) and skyAnchor.Position or myRoot.Position
		local best, bestDist = nil, aimRange
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local c = p.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				local root = c and c:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local d = (root.Position - origin).Magnitude
					if d < bestDist then
						bestDist = d
						best = c:FindFirstChild("Head") or root
					end
				end
			end
		end
		return best
	end

	local lastAim, lastAimPos = 0, nil
	pcall(function() RunService:UnbindFromRenderStep("MobileUIAim") end)
	RunService:BindToRenderStep("MobileUIAim", Enum.RenderPriority.Camera.Value + 1, function()
		if not aimOn or spectateOn then
			lastAimPos = nil
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local now = os.clock()
		if not lastAimPos or now - lastAim >= OPT.AIM_DELAY then
			local part = getAimPart()
			if not part then
				lastAimPos = nil
				return
			end
			lastAimPos = part.Position
			lastAim = now
		end
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, lastAimPos)
	end)
end

local function setSpectate(on)
	local cam = workspace.CurrentCamera
	if not cam then return end
	if on then
		local hum = getPlayerHum(targetPlayer)
		if not hum then return end
		spectateOn = true
		cam.CameraSubject = hum
	else
		spectateOn = false
		local h = getHum()
		if skyOn and skyAnchor then
			cam.CameraSubject = skyAnchor
		elseif h then
			cam.CameraSubject = h
		end
	end
end

track(RunService.Heartbeat:Connect(function()
	if not spectateOn then return end
	local cam = workspace.CurrentCamera
	local hum = getPlayerHum(targetPlayer)
	if hum then
		if cam and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
	else
		setSpectate(false)
	end
end))

local function tpBehind()
	local tRoot = getPlayerRoot(targetPlayer)
	local root = getRoot()
	if tRoot and root then
		root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
	end
end

track(player.Idled:Connect(function()
	if not antiAfk then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end))

local function equipAll()
	local char = player.Character
	local bp = player:FindFirstChildOfClass("Backpack")
	if not char or not bp then return end
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then pcall(function() t.Parent = char end) end
	end
end

do
	local rejoining = false
	local function doRejoin()
		if rejoining then return end
		rejoining = true
		task.spawn(function()
			task.wait(1)
			pcall(function()
				if #Players:GetPlayers() <= 1 then
					TeleportService:Teleport(game.PlaceId, player)
				else
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
				end
			end)
			task.wait(8)
			pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
			rejoining = false
		end)
	end

	track(GuiService.ErrorMessageChanged:Connect(function(msg)
		if autoRejoin and msg ~= "" then doRejoin() end
	end))
	task.spawn(function()
		local ok, overlay = pcall(function()
			return game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
		end)
		if ok and overlay then
			track(overlay.ChildAdded:Connect(function(c)
				if c.Name == "ErrorPrompt" and autoRejoin then doRejoin() end
			end))
		end
	end)
end

local function leaveGame()
	pcall(function() game:Shutdown() end)
	task.wait(0.5)
	pcall(function() player:Kick(tr("ออกเกมแล้ว")) end)
end

local stopPlay, stopRecording, renderReplay

local function resetSpeed()
	speedOn = false
	speedVal = orig and math.clamp(math.floor(orig.speed + 0.5), 8, SPEED_MAX) or 16
	applyStats()
end

local function resetJump()
	jumpOn = false
	jumpVal = orig and math.clamp(math.floor(orig.jump + 0.5), 20, JUMP_MAX) or 50
	applyStats()
end

local function resetFly()
	setFly(false)
	setFlyVal(50)
end

local function resetTp()
	tpOn = false
	tpVal = 10
end

-- ===== NC Cam: กล้องทะลุกำแพง + ซูมออกไม่จำกัด =====
do
	local ncOn = false
	local saved = nil
	local conn = nil

	local function enforce()
		pcall(function()
			player.CameraMaxZoomDistance = 100000
			player.CameraMinZoomDistance = 0.5
			player.DevCameraOcclusionMode = Enum.DevCameraOcclusionMode.Invisicam
		end)
	end

	function OPT.setNcCam(on)
		if on == ncOn then return end
		ncOn = on
		if on then
			saved = {
				max = player.CameraMaxZoomDistance,
				min = player.CameraMinZoomDistance,
				occ = player.DevCameraOcclusionMode,
			}
			enforce()
			-- เกมบางเกมรีเซ็ตค่ากล้อง เลยย้ำค่าซ้ำเป็นระยะ
			local acc = 0
			conn = RunService.Heartbeat:Connect(function(dt)
				acc += dt
				if acc < 0.5 then return end
				acc = 0
				enforce()
			end)
		else
			if conn then conn:Disconnect(); conn = nil end
			if saved then
				pcall(function()
					player.CameraMaxZoomDistance = saved.max
					player.CameraMinZoomDistance = saved.min
					player.DevCameraOcclusionMode = saved.occ
				end)
				saved = nil
			end
		end
	end
	function OPT.getNcCam() return ncOn end
end

local function restoreOriginals()
	if OPT.setNcCam then OPT.setNcCam(false) end
	if OPT.setDetect then OPT.setDetect(false) end
	if OPT.setAntiFling then OPT.setAntiFling(false) end
	if stopPlay then stopPlay() end
	if stopRecording then stopRecording() end
	speedOn, jumpOn, airJump, tpOn = false, false, false, false
	aimOn = false
	antiAfk = false
	autoRejoin = false
	setInvis(false)
	setSky(false)
	setNoclip(false)
	setFly(false)
	setSpectate(false)
	setFpsBoost(false)
	setFullbright(false)
	espOn = false
	clearEsp()
	setHitbox(false)
	applyStats()
end

do
	local hum = getHum()
	if hum then captureOrig(hum) end
end

track(player.CharacterAdded:Connect(function(char)
	table.clear(noclipParts)
	table.clear(invisStore)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	setSky(false, true)
	task.wait(0.1)
	captureOrig(hum)
	applyStats()
	if flyOn then startFly() end
	if spectateOn then setSpectate(false) end
end))

track(UserInputService.JumpRequest:Connect(function()
	if not airJump or flyOn then return end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

local function saveSettings()
	local data = {
		lang = lang, speed = speedVal, jump = jumpVal, fly = flyVal,
		tp = tpVal, aim = aimRange, hud = statsHudOn,
		hitbox = hitboxSize, hbMobSize = hitboxMobSize, hbPlayers = hitboxPlayers, hbMobs = hitboxMobs,
	}
	local ok = pcall(function()
		writefile(OPT.SAVE_FILE, HttpService:JSONEncode(data))
	end)
	return ok
end

local function loadSettings(startup)
	local ok, raw = pcall(function() return readfile(OPT.SAVE_FILE) end)
	if not ok or type(raw) ~= "string" then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false end
	if data.lang == "th" or data.lang == "en" then lang = data.lang end
	if type(data.fly) == "number" then flyVal = math.clamp(math.floor(data.fly), 10, FLY_MAX) end
	if type(data.tp) == "number" then tpVal = math.clamp(math.floor(data.tp), 1, TPWALK_MAX) end
	if type(data.aim) == "number" then aimRange = math.clamp(math.floor(data.aim), 1, AIM_RANGE_MAX) end
	if type(data.hud) == "boolean" then statsHudOn = data.hud end
	if type(data.hitbox) == "number" then hitboxSize = math.clamp(math.floor(data.hitbox), 1, HB_MAX) end
	if type(data.hbMobSize) == "number" then hitboxMobSize = math.clamp(math.floor(data.hbMobSize), 1, HB_MAX) end
	if type(data.hbPlayers) == "boolean" then hitboxPlayers = data.hbPlayers end
	if type(data.hbMobs) == "boolean" then hitboxMobs = data.hbMobs end
	if not startup then
		if type(data.speed) == "number" then speedVal = math.clamp(math.floor(data.speed), 8, SPEED_MAX) end
		if type(data.jump) == "number" then jumpVal = math.clamp(math.floor(data.jump), 20, JUMP_MAX) end
		applyStats()
		hudApply()
		flyHudRefresh()
	end
	return true
end
loadSettings(true)
openBtn.Text = tr("เมนู")
title.Text = tr("เมนู")

local function styleToggle(btn, on)
	btn.Text = on and "ON" or "OFF"
	btn.BackgroundColor3 = on and GREEN or GRAY
end

local function makeToggleButton(parent)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -8, 0, 8)
	b.Size = UDim2.fromOffset(52, 30)
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = parent
	round(b, 10)
	return b
end

local function gridRow(parent, order, cols, h)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, h)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 8)
	lay.Parent = row

	local cells = {}
	for i = 1, cols do
		local c = Instance.new("Frame")
		c.LayoutOrder = i
		c.Size = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 1, 0)
		c.BackgroundTransparency = 1
		c.Parent = row
		cells[i] = c
	end
	return cells, row
end

local function makeSwitchCard(cell, name, getOn, setOn)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(1, -72, 1, 0)
	label.Text = tr(name)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = card

	local toggle = makeToggleButton(card)
	toggle.Position = UDim2.new(1, -8, 0.5, -15)
	styleToggle(toggle, getOn())
	toggle.MouseButton1Click:Connect(function()
		setOn(not getOn())
		styleToggle(toggle, getOn())
	end)
	return card
end

local function makeCellButton(cell, text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromScale(1, 1)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.TextWrapped = true
	b.Parent = cell
	round(b, 12)
	return b
end

local function makeNumberCard(cell, name, minV, maxV, getV, setV)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(1, -100, 1, 0)
	label.Text = tr(name) .. " (" .. tr("สูงสุด") .. " " .. maxV .. ")"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextWrapped = true
	label.Parent = card

	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -8, 0.5, 0)
	box.Size = UDim2.fromOffset(84, 34)
	box.BackgroundColor3 = BG
	box.Text = tostring(getV())
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 15
	box.ClearTextOnFocus = true
	box.Parent = card
	round(box, 10)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			setV(math.clamp(math.floor(n + 0.5), minV, maxV))
		end
		box.Text = tostring(getV())
	end)
	return card
end

local function makeSlider(parent, y, minV, maxV, startV, onChange)
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Position = UDim2.fromOffset(8, y)
	hit.Size = UDim2.new(1, -16, 0, 34)
	hit.Parent = parent

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 10, 0.5, 0)
	bar.Size = UDim2.new(1, -20, 0, 10)
	bar.BackgroundColor3 = BG
	bar.Parent = hit
	round(bar, 5)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ACCENT
	fill.Parent = bar
	round(fill, 5)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(24, 24)
	knob.BackgroundColor3 = WHITE
	knob.Parent = bar
	round(knob, 12)

	local function setFrac(f)
		f = math.clamp(f, 0, 1)
		fill.Size = UDim2.new(f, 0, 1, 0)
		knob.Position = UDim2.new(f, 0, 0.5, 0)
		return math.floor(minV + f * (maxV - minV) + 0.5)
	end

	local function setValue(val)
		setFrac((math.clamp(val, minV, maxV) - minV) / (maxV - minV))
	end
	setValue(startV)

	local dragging, dragInput = false, nil
	local function update(input)
		local f = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		onChange(setFrac(f))
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			scroll.ScrollingEnabled = false
			update(input)
		end
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragInput
			or input.UserInputType == Enum.UserInputType.MouseMovement) then
			update(input)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragInput
			or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			scroll.ScrollingEnabled = true
		end
	end))

	return setValue
end

local function makeStatCard(cell, name, minV, maxV, cfg)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 8)
	label.Size = UDim2.new(1, -72, 0, 30)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = card

	local toggle = makeToggleButton(card)

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(10, 84)
	box.Size = UDim2.new(0.4, -15, 0, 34)
	box.BackgroundColor3 = BG
	box.PlaceholderText = tr("พิมพ์ตัวเลข")
	box.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 15
	box.ClearTextOnFocus = true
	box.Text = tostring(cfg.get())
	box.Parent = card
	round(box, 10)

	local function labelText(v)
		return tr(name) .. " " .. v .. " /" .. maxV
	end

	local setSlider = makeSlider(card, 40, minV, maxV, cfg.get(), function(val)
		cfg.setVal(val)
		label.Text = labelText(val)
		box.Text = tostring(val)
	end)

	local resetBtn = Instance.new("TextButton")
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, -10, 0, 84)
	resetBtn.Size = UDim2.new(0.6, -15, 0, 34)
	resetBtn.BackgroundColor3 = BG
	resetBtn.Text = tr("รีเซ็ต") .. " " .. tr(name)
	resetBtn.TextColor3 = WHITE
	resetBtn.Font = Enum.Font.GothamMedium
	resetBtn.TextSize = 13
	resetBtn.TextTruncate = Enum.TextTruncate.AtEnd
	resetBtn.Parent = card
	round(resetBtn, 10)

	local function refresh()
		label.Text = labelText(cfg.get())
		styleToggle(toggle, cfg.isOn())
		setSlider(cfg.get())
		box.Text = tostring(cfg.get())
	end

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			cfg.setVal(math.clamp(math.floor(n + 0.5), minV, maxV))
		end
		refresh()
	end)

	toggle.MouseButton1Click:Connect(function()
		cfg.setOn(not cfg.isOn())
		styleToggle(toggle, cfg.isOn())
	end)

	resetBtn.MouseButton1Click:Connect(function()
		cfg.reset()
		refresh()
	end)

	refresh()
	return refresh
end
