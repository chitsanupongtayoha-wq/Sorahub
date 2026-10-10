
-- ===== แท็บรายงาน: แสดงเฉพาะคนที่มาร์กดำ (โปรแล้ว) + ปุ่มรายงาน บิน/วาร์ป/เกรียน =====
local function renderReport(parent)
	local msgRow = gridRow(parent, 1, 1, 36)
	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.fromScale(1, 1)
	msg.BackgroundTransparency = 1
	msg.Text = tr("แสดงเฉพาะคนที่มาร์กดำ (กด \"โปรแล้ว\" ในแท็บตรวจผู้เล่น) | รายงาน 1 ครั้ง/คน/10 นาที")
	msg.TextColor3 = Color3.fromRGB(170, 170, 180)
	msg.Font = Enum.Font.GothamMedium
	msg.TextSize = 12
	msg.TextWrapped = true
	msg.Parent = msgRow[1]

	local cards, shown = {}, ""

	local function build()
		for _, c in ipairs(cards) do c:Destroy() end
		table.clear(cards)
		local list = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and OPT.getMark(pl) == "cheat" then table.insert(list, pl) end
		end
		table.sort(list, function(a, b) return a.Name < b.Name end)
		local sig = {}
		for i, pl in ipairs(list) do
			sig[i] = pl.UserId
			local frame = Instance.new("Frame")
			frame.LayoutOrder = 10 + i
			frame.Size = UDim2.new(1, -8, 0, 92)
			frame.BackgroundColor3 = BG2
			frame.Parent = parent
			round(frame, 12)
			outline(frame, BORDER, 1)
			table.insert(cards, frame)

			local nameL = Instance.new("TextLabel")
			nameL.BackgroundTransparency = 1
			nameL.Position = UDim2.fromOffset(10, 4)
			nameL.Size = UDim2.new(1, -20, 0, 24)
			nameL.TextXAlignment = Enum.TextXAlignment.Left
			nameL.Text = "⚫ " .. pl.DisplayName .. "  (@" .. pl.Name .. ")"
			nameL.TextColor3 = WHITE
			nameL.Font = Enum.Font.GothamBold
			nameL.TextSize = 15
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			nameL.Parent = frame

			local btnRow = Instance.new("Frame")
			btnRow.BackgroundTransparency = 1
			btnRow.Position = UDim2.fromOffset(8, 40)
			btnRow.Size = UDim2.new(1, -16, 0, 42)
			btnRow.Parent = frame
			local lay = Instance.new("UIListLayout")
			lay.FillDirection = Enum.FillDirection.Horizontal
			lay.Padding = UDim.new(0, 6)
			lay.Parent = btnRow

			for _, k in ipairs({{"fly", "รายงานบิน"}, {"warp", "รายงานวาร์ป"}, {"troll", "รายงานเกรียน"}}) do
				local b = Instance.new("TextButton")
				b.Size = UDim2.new(1/3, -6, 1, 0)
				b.BackgroundColor3 = RED
				b.Text = tr(k[2])
				b.TextColor3 = WHITE
				b.Font = Enum.Font.GothamMedium
				b.TextSize = 13
				b.TextWrapped = true
				b.Parent = btnRow
				round(b, 8)
				b.MouseButton1Click:Connect(function()
					local _, text = OPT.reportPlayer(pl, k[1])
					msg.Text = tr(text)
				end)
			end
		end
		shown = table.concat(sig, ",")
		if OPT.themeHook then OPT.themeHook() end
	end
	build()

	local acc = 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 then return end
		acc = 0
		local sig = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player and OPT.getMark(pl) == "cheat" then table.insert(sig, pl) end
		end
		table.sort(sig, function(a, b) return a.Name < b.Name end)
		local ids = {}
		for i, pl in ipairs(sig) do ids[i] = pl.UserId end
		if table.concat(ids, ",") ~= shown then build() end
	end))
end
