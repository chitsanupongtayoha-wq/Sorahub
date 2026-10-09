
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
	local RANGE = 300           -- ไกลกว่านี้เกมส่งตำแหน่งมาห่างและกระตุก ไม่ตรวจ (กันขึ้นมั่ว)

	-- ผลปีศาจที่เร็ว/วาร์ปได้เป็นปกติ: ขยายเกณฑ์ให้ ×3 (แก้ชื่อเพิ่มได้ตามต้องการ ตัวพิมพ์เล็ก)
	local FAST_FRUITS = {"lightning", "light", "fire", "string", "thread", "dragon"}
	local FAST_SCALE = 3

	-- อ่านชื่อผล/สไตล์ต่อสู้จากข้อมูลที่เกมแปะไว้ที่ผู้เล่น (Player.Data.Stats)
	local function statValue(pl, name)
		local ok, v = pcall(function()
			local data = pl:FindFirstChild("Data")
			local stats = data and data:FindFirstChild("Stats")
			local o = stats and stats:FindFirstChild(name)
			return o and o.Value
		end)
		return ok and v or nil
	end
	local function fruitOf(pl) return statValue(pl, "Current_DevilFruit") end
	local function scaleFor(pl)
		local f = fruitOf(pl)
		if type(f) == "string" then
			f = f:lower()
			for _, k in ipairs(FAST_FRUITS) do
				if f:find(k, 1, true) then return FAST_SCALE end
			end
		end
		return 1
	end
	local function commas(n)
		local str = tostring(math.floor(tonumber(n) or 0))
		local out = str:reverse():gsub("(%d%d%d)", "%1,"):reverse()
		return (out:gsub("^,", ""))
	end
	function OPT.infoLine(pl)
		local f, st = fruitOf(pl), statValue(pl, "Current_FightingStyle")
		local lv, money = statValue(pl, "Level"), statValue(pl, "Money")
		if not f and not st and not lv and not money then return nil end
		local l1 = "ผล: " .. tostring(f or "-") .. " | สไตล์: " .. tostring(st or "-")
		local l2 = "เลเวล " .. (lv and commas(lv) or "-") .. " | เงิน " .. (money and commas(money) or "-")
		return l1 .. "\n" .. l2
	end

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

	local WEIGHT = {["วาร์ป"] = 3, ["น่าสงสัยโปรตัดเน็ต"] = 2, ["ความเร็วผิดปกติ"] = 2, ["ลอย/บิน?"] = 2}
	local WINDOW = 90

	local function flag(pl, st, root, reason)
		local now = os.clock()
		st.flags[reason] = now
		-- บันทึกเป็น "เหตุการณ์" สำหรับคิดคะแนนความเสี่ยง (กันนับซ้ำภายใน 2 วิ)
		if now - (st.lastEv[reason] or -math.huge) > 2 then
			st.lastEv[reason] = now
			table.insert(st.events, {t = now, w = WEIGHT[reason] or 1})
		end
	end

	local function trim(list, now)
		while list[1] do
			local t = type(list[1]) == "table" and list[1].t or list[1]
			if now - t <= WINDOW then break end
			table.remove(list, 1)
		end
	end

	local TIERS = {
		red = {color = Color3.fromRGB(255, 60, 60), text = "🔴 โปรแน่นอน"},
		orange = {color = Color3.fromRGB(255, 150, 40), text = "🟠 มีโอกาสสูง"},
		yellow = {color = Color3.fromRGB(255, 220, 60), text = "🟡 มีความเสี่ยง"},
		green = {color = Color3.fromRGB(80, 220, 100), text = "🟢 ปกติ"},
		blue = {color = Color3.fromRGB(80, 170, 255), text = "🔵 เครื่องกาก/แลคง่าย"},
	}

	-- คืนค่า tier ของผู้เล่น (nil ถ้าระบบตรวจจับปิดอยู่)
	function OPT.riskInfo(pl)
		if not on then return nil end
		local st = state[pl]
		if not st or not st.events then return TIERS.green end
		local now = os.clock()
		trim(st.events, now)
		trim(st.stutters, now)
		local score = 0
		for _, e in ipairs(st.events) do score += e.w end
		if score >= 10 then return TIERS.red end
		if score >= 6 then return TIERS.orange end
		if score >= 2 then return TIERS.yellow end
		if #st.stutters >= 6 then return TIERS.blue end
		return TIERS.green
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
		if #list == 0 or espOn then
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
		local myChar = player.Character
		local myRootPart = myChar and myChar:FindFirstChild("HumanoidRootPart")
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then
				local char = pl.Character
				local root = char and char:FindFirstChild("HumanoidRootPart")
				local hum = char and char:FindFirstChildOfClass("Humanoid")
				local st = state[pl]
				if not st then
					st = {flags = {}, events = {}, stutters = {}, lastEv = {}}
					state[pl] = st
				end
				if not root or not hum or hum.Health <= 0 then
					removeTag(pl)
					st.char = nil
					table.clear(st.flags)
				else
					if st.char ~= char then
						st.char = char
						st.dirBefore = nil
						st.prevHV = nil
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
					if not myRootPart or skyOn or (pos - myRootPart.Position).Magnitude > RANGE then
						-- ไกลเกินไป: ข้อมูลตำแหน่งไม่แม่น ข้ามรอบนี้และเริ่มนับ "นิ่ง" ใหม่ตอนกลับเข้าใกล้
						st.born = now
						st.lastPos = pos
						st.frozenFor = 0
						st.dirBefore = nil
						table.clear(st.hist)
						st.airFor = 0
						refreshTag(pl, st, root)
						continue
					end
					local settled = now - st.born > 3
					local sc = scaleFor(pl)

					-- ลอยอยู่กลางอากาศ = อาจเป็นผลบินได้ (สายฟ้า/มังกร ฯลฯ) ไม่นับวาร์ป/ความเร็ว/ตัดเน็ต
					local gHit = workspace:Raycast(pos, Vector3.new(0, -15, 0), rayParams)
					local air = gHit == nil

					local vel = root.AssemblyLinearVelocity
					local hv = Vector3.new(vel.X, 0, vel.Z)
					if d < 0.3 then
						if st.frozenFor == 0 and st.prevHV and st.prevHV.Magnitude > 14 then
							st.dirBefore = st.prevHV.Unit  -- กำลังวิ่งอยู่แล้วค้าง
						end
						st.frozenFor += TICK
					else
						if settled and not air and st.dirBefore and st.frozenFor >= 0.3 and st.frozenFor <= 1.5
							and d >= 1 and d <= 40 then
							local step = Vector3.new(pos.X - st.lastPos.X, 0, pos.Z - st.lastPos.Z)
							if step.Magnitude > 0.1 and step.Unit:Dot(st.dirBefore) > 0.8 then
								table.insert(st.stutters, os.clock())
							end
						end
						st.dirBefore = nil
						if settled and not air then
							if kinds.lag then
								if d > TELEPORT_DIST * sc then
									flag(pl, st, root, "วาร์ป")
								elseif st.frozenFor >= FREEZE_MIN and d > JUMP_AFTER_FREEZE * sc then
									flag(pl, st, root, "น่าสงสัยโปรตัดเน็ต")
								end
							end
						end
						st.frozenFor = 0
					end

					-- ความเร็วเฉลี่ยแนวราบใน ~1 วิ (ไม่นับก้าวที่ถูกนับเป็นวาร์ปไปแล้ว)
					if d <= TELEPORT_DIST * sc and not (st.frozenFor == 0 and d > JUMP_AFTER_FREEZE * sc) then
						table.insert(st.hist, {t = now, p = pos})
					else
						table.clear(st.hist)
					end
					while st.hist[1] and now - st.hist[1].t > 1 do table.remove(st.hist, 1) end
					local first = st.hist[1]
					if settled and first and now - first.t > 0.7 then
						local h = Vector3.new(pos.X - first.p.X, 0, pos.Z - first.p.Z).Magnitude / (now - first.t)
						if kinds.speed and not air and h > SPEED_LIMIT * sc then flag(pl, st, root, "ความเร็วผิดปกติ") end
					end

					-- ลอยกลางอากาศนิ่งๆ นาน = บิน
					local hit = gHit
					local vy = root.AssemblyLinearVelocity.Y
					if not hit and vy > -15 and hum:GetState() ~= Enum.HumanoidStateType.Jumping then
						st.airFor += TICK
					else
						st.airFor = 0
					end
					if kinds.fly and settled and st.airFor >= FLY_TIME then flag(pl, st, root, "ลอย/บิน?") end

					st.lastPos = pos
					st.prevHV = hv
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

OPT.setDetect(true)
