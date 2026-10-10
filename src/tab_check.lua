
-- ===== แท็บตรวจผู้เล่น: ติดป้าย ปกติ / เครื่องกาก / ตรวจแล้วโปร (รายงานอยู่แท็บรายงาน) =====
local function renderCheck(parent)
	local TIER_ORDER = {"⚫", "🔴", "🟠", "🟡", "🔵", "🟢"}

	local summaryRow = gridRow(parent, 1, 3, 40)
	local sumLabels = {}
	for i = 1, 3 do
		local l = Instance.new("TextLabel")
		l.Size = UDim2.fromScale(1, 1)
		l.BackgroundColor3 = BG2
		l.TextColor3 = WHITE
		l.Font = Enum.Font.GothamBold
		l.TextSize = 13
		l.TextWrapped = true
		l.Parent = summaryRow[i]
		round(l, 10)
		sumLabels[i] = l
	end

	local msgRow = gridRow(parent, 2, 1, 36)
	local msg = Instance.new("TextLabel")
	msg.Size = UDim2.fromScale(1, 1)
	msg.BackgroundTransparency = 1
	msg.Text = tr("หมายเหตุ: Roblox ไม่เปิดเผยประวัติการแบน ช่องนับด้านล่างคือที่คุณตรวจ/รายงานเอง")
	msg.TextColor3 = Color3.fromRGB(170, 170, 180)
	msg.Font = Enum.Font.GothamMedium
	msg.TextSize = 12
	msg.TextWrapped = true
	msg.Parent = msgRow[1]

	local cards = {}
	local signature = ""

	local function tierRank(t)
		local first = utf8.char(utf8.codepoint(t.text, 1))
		for i, e in ipairs(TIER_ORDER) do if e == first then return i end end
		return #TIER_ORDER
	end

	local function refreshCard(c)
		local pl = c.pl
		local tier = OPT.tierOf(pl)
		local why = OPT.riskReasons and OPT.riskReasons(pl)
		c.tierLabel.Text = tr(tier.text) .. (why and ("  (" .. why .. ")") or "")
		c.tierLabel.TextColor3 = (tier.text:sub(1, 3) == "⚫") and WHITE or tier.color
		local cheats, reports = OPT.markStats(pl)
		c.stat.Text = tr("ตรวจเจอโปร") .. " " .. cheats .. " " .. tr("ครั้ง") .. " | "
			.. tr("รายงานแล้ว") .. " " .. reports .. " " .. tr("ครั้ง")
	end

	local function refreshSummary()
		local n, lag, cheat = 0, 0, 0
		for _, c in ipairs(cards) do
			local m = OPT.getMark(c.pl)
			if m == "cheat" then cheat += 1 elseif m == "lag" then lag += 1 else n += 1 end
		end
		sumLabels[1].Text = "🟢 " .. tr("ปกติ/ยังไม่ตรวจ") .. ": " .. n
		sumLabels[2].Text = "🔵 " .. tr("เครื่องกาก") .. ": " .. lag
		sumLabels[3].Text = "⚫ " .. tr("ตรวจแล้วโปร") .. ": " .. cheat
	end

	local function makeBtn(parentFrame, text, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1/3, -6, 1, 0)
		b.BackgroundColor3 = color
		b.Text = tr(text)
		b.TextColor3 = WHITE
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 12
		b.TextWrapped = true
		b.Parent = parentFrame
		round(b, 8)
		return b
	end

	local function build()
		for _, c in ipairs(cards) do c.frame:Destroy() end
		table.clear(cards)

		local list = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then table.insert(list, pl) end
		end
		table.sort(list, function(a, b)
			local ra, rb = tierRank(OPT.tierOf(a)), tierRank(OPT.tierOf(b))
			if ra ~= rb then return ra < rb end
			return a.Name < b.Name
		end)

		local sig = {}
		for i, pl in ipairs(list) do
			sig[i] = pl.UserId
			local frame = Instance.new("Frame")
			frame.LayoutOrder = 10 + i
			frame.Size = UDim2.new(1, -8, 0, 120)
			frame.BackgroundColor3 = BG2
			frame.Parent = parent
			round(frame, 12)
			outline(frame, BORDER, 1)

			local nameL = Instance.new("TextLabel")
			nameL.BackgroundTransparency = 1
			nameL.Position = UDim2.fromOffset(10, 4)
			nameL.Size = UDim2.new(1, -20, 0, 22)
			nameL.TextXAlignment = Enum.TextXAlignment.Left
			nameL.Text = pl.DisplayName .. "  (@" .. pl.Name .. ")"
			nameL.TextColor3 = WHITE
			nameL.Font = Enum.Font.GothamBold
			nameL.TextSize = 15
			nameL.TextTruncate = Enum.TextTruncate.AtEnd
			nameL.Parent = frame

			local tierL = Instance.new("TextLabel")
			tierL.BackgroundTransparency = 1
			tierL.Position = UDim2.fromOffset(10, 26)
			tierL.Size = UDim2.new(1, -20, 0, 20)
			tierL.TextXAlignment = Enum.TextXAlignment.Left
			tierL.Font = Enum.Font.GothamBold
			tierL.TextSize = 13
			tierL.TextTruncate = Enum.TextTruncate.AtEnd
			tierL.Parent = frame

			local statL = Instance.new("TextLabel")
			statL.BackgroundTransparency = 1
			statL.Position = UDim2.fromOffset(10, 46)
			statL.Size = UDim2.new(1, -20, 0, 20)
			statL.TextXAlignment = Enum.TextXAlignment.Left
			statL.TextColor3 = Color3.fromRGB(170, 170, 180)
			statL.Font = Enum.Font.GothamMedium
			statL.TextSize = 12
			statL.Parent = frame

			local btnRow = Instance.new("Frame")
			btnRow.BackgroundTransparency = 1
			btnRow.Position = UDim2.fromOffset(8, 74)
			btnRow.Size = UDim2.new(1, -16, 0, 38)
			btnRow.Parent = frame
			local lay = Instance.new("UIListLayout")
			lay.FillDirection = Enum.FillDirection.Horizontal
			lay.Padding = UDim.new(0, 6)
			lay.Parent = btnRow

			local normalB = makeBtn(btnRow, "ปกติ", GREEN)
			local lagB = makeBtn(btnRow, "เครื่องกาก", Color3.fromRGB(60, 120, 200))
			local cheatB = makeBtn(btnRow, "โปรแล้ว", Color3.fromRGB(30, 30, 30))

			local c = {pl = pl, frame = frame, tierLabel = tierL, stat = statL}
			table.insert(cards, c)

			normalB.MouseButton1Click:Connect(function()
				OPT.setMark(pl, "normal"); refreshCard(c); refreshSummary()
			end)
			lagB.MouseButton1Click:Connect(function()
				OPT.setMark(pl, "lag"); refreshCard(c); refreshSummary()
			end)
			cheatB.MouseButton1Click:Connect(function()
				OPT.setMark(pl, "cheat"); refreshCard(c); refreshSummary()
			end)
			refreshCard(c)
		end
		signature = table.concat(sig, ",")
		refreshSummary()
		if OPT.themeHook then OPT.themeHook() end
	end

	build()

	local acc = 0
	table.insert(connections, RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < 1 then return end
		acc = 0
		-- รายชื่อเปลี่ยน (มีคนเข้า/ออก) ให้สร้างใหม่ ไม่งั้นแค่อัปเดตข้อความ
		local sig = {}
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl ~= player then table.insert(sig, pl.UserId) end
		end
		table.sort(sig)
		local cur = {}
		for _, c in ipairs(cards) do table.insert(cur, c.pl.UserId) end
		table.sort(cur)
		if table.concat(sig, ",") ~= table.concat(cur, ",") then
			build()
		else
			for _, c in ipairs(cards) do refreshCard(c) end
		end
	end))
end
