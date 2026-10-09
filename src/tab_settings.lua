local function renderSettings(parent)
	local r1 = gridRow(parent, 1, 2, 48)
	local saveBtn = makeCellButton(r1[1], tr("เซฟการตั้งค่า"), ACCENT)
	local loadBtn = makeCellButton(r1[2], tr("โหลดค่าที่เซฟ"), GRAY)

	local r2 = gridRow(parent, 2, 2, 48)
	local langBtn = makeCellButton(r2[1],
		tr("ภาษา") .. ": " .. (lang == "th" and "ไทย" or "English"), ORANGE)
	makeSwitchCard(r2[2], "แสดง Ping/FPS",
		function() return statsHudOn end,
		function(b) statsHudOn = b; hudApply() end)

	local r3 = gridRow(parent, 3, 1, 40)
	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.fromScale(1, 1)
	msg.BackgroundTransparency = 1
	msg.Text = ""
	msg.TextColor3 = Color3.fromRGB(170, 170, 180)
	msg.Font = Enum.Font.GothamMedium
	msg.TextSize = 15
	msg.Parent = r3[1]

	saveBtn.MouseButton1Click:Connect(function()
		msg.Text = saveSettings() and tr("เซฟแล้ว") or tr("เซฟไม่ได้ (executor ไม่รองรับ)")
	end)
	loadBtn.MouseButton1Click:Connect(function()
		if loadSettings(false) then
			applyLang()
		else
			msg.Text = tr("ไม่มีไฟล์ที่เซฟ")
		end
	end)
	langBtn.MouseButton1Click:Connect(function()
		lang = (lang == "th") and "en" or "th"
		applyLang()
	end)

	OPT.renderLook(parent, 10)
end
