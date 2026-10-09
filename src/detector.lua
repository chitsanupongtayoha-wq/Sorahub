
-- ===== ตรวจจับผู้เล่นที่เคลื่อนที่ผิดปกติ (ขึ้นป้ายเหนือหัว) =====
do
	local TAG = "SoraDetectTag"
	local TICK = 0.1
	local FREEZE_MIN = 0.4      -- นิ่งนานเท่านี้แล้วพุ่ง = น่าสงสัยโปรตัดเน็ต
	local JUMP_AFTER_FREEZE = 12
	local TELEPORT_DIST = 70    -- ขยับเกินนี้ในเสี้ยววิ = วาร์ป
	local SPEED_LIMIT = 150     -- ความเร็วเฉลี่ยแนวราบ (studs/s)
	local FLY_TIME = 6          -- ลอยกลางอากาศนิ่งๆ นานเท่านี้ = บิน
	local FLAG_TTL = 8

	local on = false
	-- เปิด/ปิดเป็นรายประเภท (ลอย/บิน ปิดไว้ก่อน เพราะบางเกมมีคนค้างลอยเอง)
	local kinds = {lag = true, speed = true, fly = false}
	local conn = nil
	local acc = 0
	local state = setmetatable({}, {__mode = "k"})   -- player -> data

	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Exclude

	local function removeTag(pl)
		local st = state[pl]
		if st and st.gui then pcall(function() st.gui:Destroy() end); st.gui = nil end
	end

	local function ensureTag(st, root)
		if st.gui and st.gui.Parent then return st.gui end
		local b = Instance.new("BillboardGui")
		b.Name = TAG
		b.AlwaysOnTop = true
		b.Size = UDim2.fromOffset(220, 44)
		b.StudsOffset = Vector3.new(0, 5, 0)
		b.Adornee = root
		b.Parent = root
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundTransparency = 1
		l.TextColor3 = Color3.fromRGB(255, 120, 60)
		l.TextStrokeTransparency = 0
		l.Font = Enum.Font.GothamBold
		l.TextSize = 15
		l.TextWrapped = true
		l.Parent = b
		st.gui = b
		st.label = l
		return b
	end

	local function flag(pl, st, root, reason)
		st.flags[reason] = os.clock()
	end

	local function refreshTag(pl, st, root)
		local now = os.clock()
		local list = {}
		for reason, t in pairs(st.flags) do
			if now - t > FLAG_TTL then
				st.flags[reason] = nil
			else
				table.insert(list, reason)
			end
		end
		if #list == 0 then
			if st.gui then removeTag(pl) end
			return
		end
		table.sort(list)
		ensureTag(st, root)
		st.label.Text = "⚠ " .. table.concat(list, " / ")
	end

	local function step()
		local now = os.clock()
		rayParams.FilterDescendantsInstances = {player.Character}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				local char = pl.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local st = state[pl]
				if not st then
					st = {flags = {}}
					state[pl] = st
				end
				if not root or not hum or hum.Health <= 0 then
					removeTag(pl)
					st.char = nil
					table.clear(st.flags)
				else
					if st.char ~= char then
						st.char = char
						st.born = now
						st.lastPos = root.Position
						st.frozenFor = 0
						st.hist = {}
						st.airFor = 0
						table.clear(st.flags)
						removeTag(pl)
					end
					local pos = root.Position
					local d = (pos - st.lastPos).Magnitude
					local settled = now - st.born > 3

					if d < 0.3 then
						st.frozenFor += TICK
					else
						if settled then
							if kinds.lag then
								if d > TELEPORT_DIST then
									flag(pl, st, root, "วาร์ป")
								elseif st.frozenFor >= FREEZE_MIN and d > JUMP_AFTER_FREEZE then
									flag(pl, st, root, "น่าสงสัยโปรตัดเน็ต")
								end
							end
						end
						st.frozenFor = 0
					end

					-- ความเร็วเฉลี่ยแนวราบใน ~1 วิ (ไม่นับก้าวที่ถูกนับเป็นวาร์ปไปแล้ว)
					if d <= TELEPORT_DIST and not (st.frozenFor == 0 and d > JUMP_AFTER_FREEZE) then
						table.insert(st.hist, {t = now, p = pos})
					else
						table.clear(st.hist)
					end
					while st.hist[1] and now - st.hist[1].t > 1 do table.remove(st.hist, 1) end
					local first = st.hist[1]
					if settled and first and now - first.t > 0.7 then
						local h = Vector3.new(pos.X - first.p.X, 0, pos.Z - first.p.Z).Magnitude / (now - first.t)
						if kinds.speed and h > SPEED_LIMIT then flag(pl, st, root, "ความเร็วผิดปกติ") end
					end

					-- ลอยกลางอากาศนิ่งๆ นาน = บิน
					local hit = workspace:Raycast(pos, Vector3.new(0, -15, 0), rayParams)
					local vy = root.AssemblyLinearVelocity.Y
					if not hit and vy > -15 and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
						st.airFor += TICK
					else
						st.airFor = 0
					end
					if kinds.fly and settled and st.airFor >= FLY_TIME then flag(pl, st, root, "ลอย/บิน?") end

					st.lastPos = pos
					refreshTag(pl, st, root)
				end
			end
		end
	end

	function OPT.setDetect(v)
		if v == on then return end
		on = v
		if conn then conn:Disconnect(); conn = nil end
		if on then
			acc = 0
			conn = RunService.Heartbeat:Connect(function(dt)
				acc += dt
				if acc < TICK then return end
				acc = 0
				pcall(step)
			end)
		else
			for pl in pairs(state) do removeTag(pl) end
			table.clear(state)
		end
	end
	function OPT.getDetect() return on end
	function OPT.getDetectKind(k) return kinds[k] end
	function OPT.setDetectKind(k, v)
		kinds[k] = v and true or false
		if not v then
			local label = ({lag = {"วาร์ป", "น่าสงสัยโปรตัดเน็ต"}, speed = {"ความเร็วผิดปกติ"}, fly = {"ลอย/บิน?"}})[k]
			for _, st in pairs(state) do
				if label then for _, r in ipairs(label) do st.flags[r] = nil end end
			end
		end
	end
end
