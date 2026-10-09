local setFlyHud
do
	local flyHud = Instance.new("Frame")
	flyHud.Name = "FlyHud"
	flyHud.AnchorPoint = Vector2.new(0.5, 0.5)
	flyHud.Position = UDim2.fromScale(0.6, 0.62)
	flyHud.Size = UDim2.fromOffset(230, 120)
	flyHud.BackgroundColor3 = BG
	flyHud.BackgroundTransparency = 0.2
	flyHud.Active = true
	flyHud.Visible = false
	flyHud.Parent = gui
	round(flyHud, 14)
	outline(flyHud, ACCENT, 2)

	local flyHudTitle = Instance.new("TextLabel")
	flyHudTitle.BackgroundTransparency = 1
	flyHudTitle.Position = UDim2.fromOffset(10, 2)
	flyHudTitle.Size = UDim2.new(1, -20, 0, 22)
	flyHudTitle.TextXAlignment = Enum.TextXAlignment.Left
	flyHudTitle.TextColor3 = Color3.fromRGB(170, 170, 180)
	flyHudTitle.Font = Enum.Font.GothamMedium
	flyHudTitle.TextSize = 13
	flyHudTitle.Parent = flyHud

	local flyHudBox = Instance.new("TextBox")
	flyHudBox.Position = UDim2.fromOffset(8, 26)
	flyHudBox.Size = UDim2.new(1, -16, 0, 34)
	flyHudBox.BackgroundColor3 = BG2
	flyHudBox.TextColor3 = WHITE
	flyHudBox.Font = Enum.Font.GothamBold
	flyHudBox.TextSize = 16
	flyHudBox.ClearTextOnFocus = true
	flyHudBox.Parent = flyHud
	round(flyHudBox, 10)

	local flyHudRow = Instance.new("Frame")
	flyHudRow.BackgroundTransparency = 1
	flyHudRow.Position = UDim2.fromOffset(8, 68)
	flyHudRow.Size = UDim2.new(1, -16, 0, 40)
	flyHudRow.Parent = flyHud

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 6)
	lay.Parent = flyHudRow

	local function hudButton(order, text, color)
		local b = Instance.new("TextButton")
		b.LayoutOrder = order
		b.Size = UDim2.new(1 / 3, -4, 1, 0)
		b.BackgroundColor3 = color
		b.Text = text
		b.TextColor3 = WHITE
		b.Font = Enum.Font.GothamBold
		b.TextSize = 16
		b.Parent = flyHudRow
		round(b, 10)
		return b
	end

	local flyPlus = hudButton(1, "+", ACCENT)
	local flyToggleBtn = hudButton(2, "", GREEN)
	local flyMinus = hudButton(3, "-", ACCENT)

	flyHudRefresh = function()
		flyHudBox.Text = tostring(flyVal)
		flyToggleBtn.Text = flyOn and tr("ปิดบิน") or tr("บิน")
		flyToggleBtn.BackgroundColor3 = flyOn and RED or GREEN
		flyHudTitle.Text = tr("บิน") .. " (" .. tr("ลากย้าย") .. ")"
	end

	flyPlus.MouseButton1Click:Connect(function() setFlyVal(flyVal + OPT.FLY_STEP) end)
	flyMinus.MouseButton1Click:Connect(function() setFlyVal(flyVal - OPT.FLY_STEP) end)
	flyToggleBtn.MouseButton1Click:Connect(function() setFly(not flyOn) end)
	flyHudBox.FocusLost:Connect(function()
		local n = tonumber(flyHudBox.Text)
		if n then setFlyVal(n) end
		flyHudRefresh()
	end)
	makeDraggable(flyHud, flyHud)
	makeDraggable(flyHudTitle, flyHud)
	flyHudRefresh()
	table.insert(langHooks, function() flyHudRefresh() end)

	function setFlyHud(on)
		flyHudOn = on
		flyHud.Visible = on
	end
end

local setInvisBtn
do
	local invisBtn = Instance.new("TextButton")
	invisBtn.Name = "InvisBtn"
	invisBtn.AnchorPoint = Vector2.new(0, 0.5)
	invisBtn.Position = UDim2.new(0, 16, 0.62, 0)
	invisBtn.Size = UDim2.fromOffset(56, 56)
	invisBtn.BackgroundColor3 = BG
	invisBtn.BackgroundTransparency = 0.15
	invisBtn.TextColor3 = WHITE
	invisBtn.Font = Enum.Font.GothamBold
	invisBtn.TextSize = 13
	invisBtn.TextWrapped = true
	invisBtn.Visible = false
	invisBtn.Parent = gui
	round(invisBtn, 12)
	outline(invisBtn, ACCENT, 2)

	invisRefresh = function()
		invisBtn.Text = tr("ล่องหน")
		invisBtn.BackgroundColor3 = skyOn and GREEN or BG
	end
	invisRefresh()
	table.insert(langHooks, function() invisRefresh() end)

	local invisMoved = makeDraggable(invisBtn, invisBtn)
	invisBtn.MouseButton1Click:Connect(function()
		if invisMoved() then return end
		setSky(not skyOn)
	end)

	function setInvisBtn(on)
		invisBtnOn = on
		invisBtn.Visible = on
		if not on then
			setInvis(false)
			if skyOn then setSky(false) end
		end
	end
end

do
	local statsHud = Instance.new("Frame")
	statsHud.Name = "StatsHud"
	statsHud.AnchorPoint = Vector2.new(1, 0)
	statsHud.Position = UDim2.new(1, -16, 0, 14)
	statsHud.Size = UDim2.fromOffset(150, 58)
	statsHud.BackgroundColor3 = BG
	statsHud.BackgroundTransparency = 0.4
	statsHud.Active = true
	statsHud.Visible = statsHudOn
	statsHud.Parent = gui
	round(statsHud, 10)
	outline(statsHud, ACCENT, 1)

	local statsLabel = Instance.new("TextLabel")
	statsLabel.BackgroundTransparency = 1
	statsLabel.Position = UDim2.fromOffset(8, 3)
	statsLabel.Size = UDim2.new(1, -16, 1, -6)
	statsLabel.RichText = true
	statsLabel.TextXAlignment = Enum.TextXAlignment.Left
	statsLabel.TextYAlignment = Enum.TextYAlignment.Center
	statsLabel.TextColor3 = WHITE
	statsLabel.Font = Enum.Font.GothamBold
	statsLabel.TextSize = 13
	statsLabel.Text = ""
	statsLabel.Parent = statsHud
	makeDraggable(statsHud, statsHud)

	hudApply = function() statsHud.Visible = statsHudOn end

	local function colorFor(v, good, mid, higherIsBetter)
		local G, M, B = "#50dc78", "#ffc83c", "#ff5050"
		if higherIsBetter then
			if v >= good then return G elseif v >= mid then return M else return B end
		else
			if v <= good then return G elseif v <= mid then return M else return B end
		end
	end

	local hudAcc, hudFrames = 0, 0
	track(RunService.Heartbeat:Connect(function(dt)
		hudAcc += dt
		hudFrames += 1
		if hudAcc < 0.5 then return end
		local fps = math.floor(hudFrames / hudAcc + 0.5)
		hudAcc, hudFrames = 0, 0
		if not statsHud.Visible then return end

		local ping = 0
		pcall(function()
			ping = math.floor(StatsService.Network.ServerStatsItem["Data Ping"]:GetValue() + 0.5)
		end)
		statsLabel.Text = string.format(
			'%s <font color="%s">%d ms</font>\nFPS <font color="%s">%d</font>\n%s %d/%d',
			tr("ปิง"), colorFor(ping, 100, 200, false), ping,
			colorFor(fps, 50, 30, true), fps,
			tr("คน"), #Players:GetPlayers(), Players.MaxPlayers
		)
	end))
end
