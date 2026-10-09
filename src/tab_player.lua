local function renderStats(parent)
	local r1 = gridRow(parent, 1, 2, 128)
	makeStatCard(r1[1], "ความเร็ว", 8, SPEED_MAX, {
		get = function() return speedVal end,
		isOn = function() return speedOn end,
		setVal = function(v) speedVal = v; applyStats() end,
		setOn = function(b) speedOn = b; applyStats() end,
		reset = resetSpeed,
	})
	makeStatCard(r1[2], "กระโดด", 20, JUMP_MAX, {
		get = function() return jumpVal end,
		isOn = function() return jumpOn end,
		setVal = function(v) jumpVal = v; applyStats() end,
		setOn = function(b) jumpOn = b; applyStats() end,
		reset = resetJump,
	})

	local r2 = gridRow(parent, 2, 2, 46)
	makeSwitchCard(r2[1], "กระโดดกลางอากาศ",
		function() return airJump end,
		function(b) airJump = b end)
	makeSwitchCard(r2[2], "Noclip (ทะลุ)",
		function() return noclipOn end,
		function(b) setNoclip(b) end)

	local r3 = gridRow(parent, 3, 2, 46)
	makeSwitchCard(r3[1], "ล่องหน (ปุ่มซ้ายล่าง)",
		function() return invisBtnOn end,
		function(b) setInvisBtn(b) end)
	makeSwitchCard(r3[2], "เมนูบินลอย",
		function() return flyHudOn end,
		function(b) setFlyHud(b) end)

	local r4 = gridRow(parent, 4, 2, 128)
	makeStatCard(r4[1], "บิน", 10, FLY_MAX, {
		get = function() return flyVal end,
		isOn = function() return flyOn end,
		setVal = function(v) setFlyVal(v) end,
		setOn = function(b) setFly(b) end,
		reset = resetFly,
	})
	makeStatCard(r4[2], "TP Walk", 1, TPWALK_MAX, {
		get = function() return tpVal end,
		isOn = function() return tpOn end,
		setVal = function(v) tpVal = v end,
		setOn = function(b) tpOn = b end,
		reset = resetTp,
	})

	local r5 = gridRow(parent, 5, 2, 48)
	local resetBoth = makeCellButton(r5[1], tr("รีเซ็ตทั้งสอง (ความเร็ว + กระโดด)"), ORANGE)
	resetBoth.MouseButton1Click:Connect(function()
		resetSpeed()
		resetJump()
		showTab(currentKey)
	end)
	local resetAll = makeCellButton(r5[2], tr("รีเซ็ตทั้งหมด (ทุกอย่างในหน้านี้)"), Color3.fromRGB(170, 60, 60))
	resetAll.MouseButton1Click:Connect(function()
		resetSpeed()
		resetJump()
		resetFly()
		resetTp()
		setNoclip(false)
		airJump = false
		showTab(currentKey)
	end)
end
