local replayTabOn = false
local function setReplayTab(on)
	replayTabOn = on
	if not on then
		stopRecording()
		stopPlay()
		if currentKey == "replay" then currentKey = "misc" end
	end
	buildTabButtons()
	if on then showTab("replay") else showTab(currentKey) end
end

local function renderMisc(parent)
	local r1 = gridRow(parent, 1, 3, 46)
	makeSwitchCard(r1[1], "กันหลุด (Anti-AFK)",
		function() return antiAfk end,
		function(b) antiAfk = b end)
	makeSwitchCard(r1[2], "Auto Rejoin",
		function() return autoRejoin end,
		function(b) autoRejoin = b end)
	makeSwitchCard(r1[3], "ลอยฟ้า 100000",
		function() return skyOn end,
		function(b) setSky(b) end)

	local r2 = gridRow(parent, 2, 3, 48)
	local eq = makeCellButton(r2[1], tr("ถือของทั้งหมด (Equip All)"), ACCENT)
	eq.MouseButton1Click:Connect(equipAll)
	makeSwitchCard(r2[2], "บูส FPS",
		function() return fpsOn end,
		function(b) setFpsBoost(b) end)
	local rejoin = makeCellButton(r2[3], tr("เข้าเซิร์ฟใหม่ (Rejoin)"), ORANGE)
	rejoin.MouseButton1Click:Connect(function()
		pcall(function()
			if #Players:GetPlayers() <= 1 then
				TeleportService:Teleport(game.PlaceId, player)
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
			end
		end)
	end)

	local r3 = gridRow(parent, 3, 3, 48)
	local leave = makeCellButton(r3[1], tr("ออกเกมทันที"), Color3.fromRGB(170, 60, 60))
	leave.MouseButton1Click:Connect(leaveGame)
	local rp = makeCellButton(r3[2], tr("รีเพลย์การเล่น"), replayTabOn and GREEN or ACCENT)
	rp.MouseButton1Click:Connect(function()
		setReplayTab(not replayTabOn)
	end)

	local r4 = gridRow(parent, 4, 2, 48)
	makeSwitchCard(r4[1], "กล้องทะลุ + ซูมไม่จำกัด",
		function() return OPT.getNcCam() end,
		function(b) OPT.setNcCam(b) end)
	makeSwitchCard(r4[2], "ป้องกันปลิว",
		function() return OPT.getAntiFling() end,
		function(b) OPT.setAntiFling(b) end)

	local r6 = gridRow(parent, 6, 1, 48)
	makeSwitchCard(r6[1], "ตรวจจับคนโกง (ป้ายเหนือหัว)",
		function() return OPT.getDetect() end,
		function(b) OPT.setDetect(b) end)

	local r5 = gridRow(parent, 5, 1, 52)
	local HOP_TXT = "ย้ายเซิร์ฟ (ต้องไม่โดนตี 1 นาที + เลือดเต็ม)"
	local hopBtn = makeCellButton(r5[1], tr(HOP_TXT), ORANGE)
	local hopBusy = false
	hopBtn.MouseButton1Click:Connect(function()
		if hopBusy then return end
		local _, msg = OPT.safeHop()
		hopBusy = true
		hopBtn.Text = tr(msg)
		task.delay(2.5, function()
			hopBusy = false
			if hopBtn.Parent then hopBtn.Text = tr(HOP_TXT) end
		end)
	end)
end
