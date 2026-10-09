
-- ===== Safety: ป้องกันปลิว + ย้ายเซิร์ฟอย่างปลอดภัย =====
do
	-- ป้องกันปลิว: ไม่ชนตัวผู้เล่นอื่น + ตัดแรงหมุน/แรงพุ่งที่สูงผิดปกติ
	local afOn = false
	local afStep, afBeat = nil, nil

	function OPT.setAntiFling(on)
		if on == afOn then return end
		afOn = on
		if afStep then afStep:Disconnect(); afStep = nil end
		if afBeat then afBeat:Disconnect(); afBeat = nil end
		if not on then return end

		afStep = RunService.Stepped:Connect(function()
			for _, pl in ipairs(Players:GetPlayers()) do
				if pl ~= player and pl.Character then
					for _, d in ipairs(pl.Character:GetDescendants()) do
						if d:IsA("BasePart") and d.CanCollide then d.CanCollide = false end
					end
				end
			end
		end)

		afBeat = RunService.Heartbeat:Connect(function()
			local char = player.Character
			local root = char and char:FindFirstChild("HumanoidRootPart")
			if not root then return end
			if root.AssemblyAngularVelocity.Magnitude > 60 then
				root.AssemblyAngularVelocity = Vector3.zero
			end
			-- ความเร็วเกิน 2000 ถือว่าโดนปลิว (บิน/วิ่งเร็วของเราไม่ถึงค่านี้)
			if not flyOn and not skyOn and root.AssemblyLinearVelocity.Magnitude > 2000 then
				root.AssemblyLinearVelocity = Vector3.zero
			end
		end)
	end
	function OPT.getAntiFling() return afOn end

	-- ย้ายเซิร์ฟ: ใช้ได้เมื่อไม่โดนตีมา 60 วิ และเลือดเต็ม
	local lastHit = -math.huge
	local hookedHum = nil
	local hookConn = nil

	local function hookHumanoid(hum)
		if hookConn then hookConn:Disconnect(); hookConn = nil end
		hookedHum = hum
		if not hum then return end
		local last = hum.Health
		hookConn = hum.HealthChanged:Connect(function(h)
			if h < last then lastHit = os.clock() end
			last = h
		end)
	end

	local function watchChar(char)
		if not char then return end
		lastHit = -math.huge
		hookHumanoid(char:WaitForChild("Humanoid", 10))
	end
	track(player.CharacterAdded:Connect(watchChar))
	if player.Character then task.spawn(watchChar, player.Character) end

	local HOP_WAIT = 60
	function OPT.hopStatus()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if not hum then return false, "ไม่พบตัวละคร" end
		local left = HOP_WAIT - (os.clock() - lastHit)
		if left > 0 then
			return false, "รอก่อน (เพิ่งโดนตี) เหลือ " .. math.ceil(left) .. " วิ"
		end
		if hum.Health < hum.MaxHealth - 0.01 then
			return false, "เลือดยังไม่เต็ม"
		end
		return true, "พร้อมย้ายเซิร์ฟ"
	end

	function OPT.safeHop()
		local ok, why = OPT.hopStatus()
		if not ok then return false, why end
		local okT = pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
		return okT, okT and "กำลังย้ายเซิร์ฟ..." or "ย้ายไม่สำเร็จ"
	end
end
