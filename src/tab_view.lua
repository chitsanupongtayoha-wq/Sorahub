local function renderView(parent)
	local r1 = gridRow(parent, 1, 2, 46)
	makeSwitchCard(r1[1], "ESP ผู้เล่นอื่น",
		function() return espOn end,
		function(b) espOn = b; if not b then clearEsp() end end)
	makeSwitchCard(r1[2], "มองกลางคืน",
		function() return fullbrightOn end,
		function(b) setFullbright(b) end)

	local r2 = gridRow(parent, 2, 2, 56)
	makeSwitchCard(r2[1], "ล็อคเป้า (Aimbot)",
		function() return aimOn end,
		function(b) aimOn = b end)
	makeNumberCard(r2[2], "ระยะล็อคคนใกล้สุด", 1, AIM_RANGE_MAX,
		function() return aimRange end,
		function(v) aimRange = v end)

	local cells3, row3 = gridRow(parent, 3, 1, 130)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cells3[1]
	round(card, 12)
	outline(card, BORDER, 1)

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(10, 8)
	box.Size = UDim2.new(1, -20, 0, 34)
	box.BackgroundColor3 = BG
	box.PlaceholderText = tr("พิมพ์ชื่อผู้เล่นที่จะระบุ...")
	box.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
	box.Text = targetPlayer and targetPlayer.Name or ""
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 16
	box.ClearTextOnFocus = true
	box.Parent = card
	round(box, 10)

	local status = Instance.new("TextLabel")
	status.BackgroundTransparency = 1
	status.Position = UDim2.fromOffset(12, 48)
	status.Size = UDim2.new(1, -24, 0, 28)
	status.TextXAlignment = Enum.TextXAlignment.Left
	status.TextColor3 = Color3.fromRGB(170, 170, 180)
	status.Font = Enum.Font.Gotham
	status.TextSize = 15
	status.TextTruncate = Enum.TextTruncate.AtEnd
	status.Parent = card

	local setBtn = Instance.new("TextButton")
	setBtn.Position = UDim2.fromOffset(10, 84)
	setBtn.Size = UDim2.new(0.5, -15, 0, 34)
	setBtn.BackgroundColor3 = ACCENT
	setBtn.Text = tr("ตั้งเป้าหมาย")
	setBtn.TextColor3 = WHITE
	setBtn.Font = Enum.Font.GothamBold
	setBtn.TextSize = 15
	setBtn.Parent = card
	round(setBtn, 10)

	local clearBtn = Instance.new("TextButton")
	clearBtn.AnchorPoint = Vector2.new(1, 0)
	clearBtn.Position = UDim2.new(1, -10, 0, 84)
	clearBtn.Size = UDim2.new(0.5, -15, 0, 34)
	clearBtn.BackgroundColor3 = GRAY
	clearBtn.Text = tr("ล้างเป้าหมาย")
	clearBtn.TextColor3 = WHITE
	clearBtn.Font = Enum.Font.GothamBold
	clearBtn.TextSize = 15
	clearBtn.Parent = card
	round(clearBtn, 10)

	local list = Instance.new("ScrollingFrame")
	list.Position = UDim2.fromOffset(10, 124)
	list.Size = UDim2.new(1, -20, 0, 156)
	list.BackgroundColor3 = BG
	list.BorderSizePixel = 0
	list.ScrollBarThickness = 4
	list.CanvasSize = UDim2.new()
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.Visible = false
	list.Parent = card
	round(list, 10)

	local listLayout = Instance.new("UIListLayout")
	listLayout.Padding = UDim.new(0, 4)
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Parent = list

	local listPad = Instance.new("UIPadding")
	listPad.PaddingTop = UDim.new(0, 4)
	listPad.PaddingBottom = UDim.new(0, 4)
	listPad.PaddingLeft = UDim.new(0, 4)
	listPad.PaddingRight = UDim.new(0, 4)
	listPad.Parent = list

	local function showList(on)
		list.Visible = on
		row3.Size = UDim2.new(1, -8, 0, on and 290 or 130)
	end

	local function refreshStatus()
		status.Text = targetPlayer
			and (tr("เป้าหมาย:") .. " " .. targetPlayer.DisplayName .. " (@" .. targetPlayer.Name .. ")")
			or tr("ไม่ได้ระบุ (ล็อคคนใกล้สุด)")
		box.Text = targetPlayer and targetPlayer.Name or ""
	end

	local function populate(filter)
		for _, c in ipairs(list:GetChildren()) do
			if c:IsA("TextButton") or c:IsA("TextLabel") then c:Destroy() end
		end
		filter = (filter or ""):lower()

		local plist = {}
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local n, d = p.Name:lower(), p.DisplayName:lower()
				if filter == "" or n:find(filter, 1, true) or d:find(filter, 1, true) then
					table.insert(plist, p)
				end
			end
		end
		table.sort(plist, function(a, b) return a.Name:lower() < b.Name:lower() end)

		if #plist == 0 then
			local empty = Instance.new("TextLabel")
			empty.Size = UDim2.new(1, 0, 0, 34)
			empty.BackgroundTransparency = 1
			empty.Text = tr("ไม่พบผู้เล่น")
			empty.TextColor3 = Color3.fromRGB(170, 170, 180)
			empty.Font = Enum.Font.Gotham
			empty.TextSize = 14
			empty.Parent = list
			return
		end

		for i, p in ipairs(plist) do
			local b = Instance.new("TextButton")
			b.LayoutOrder = i
			b.Size = UDim2.new(1, 0, 0, 34)
			b.BackgroundColor3 = (p == targetPlayer) and ACCENT or BG2
			b.Text = p.DisplayName .. " (@" .. p.Name .. ")"
			b.TextColor3 = WHITE
			b.Font = Enum.Font.GothamMedium
			b.TextSize = 14
			b.TextTruncate = Enum.TextTruncate.AtEnd
			b.Parent = list
			round(b, 8)
			b.Activated:Connect(function()
				targetPlayer = p
				showList(false)
				refreshStatus()
			end)
		end
	end

	box.Focused:Connect(function()
		showList(true)
		populate("")
	end)
	box:GetPropertyChangedSignal("Text"):Connect(function()
		if list.Visible then populate(box.Text) end
	end)
	box.FocusLost:Connect(function(enterPressed)
		if enterPressed then
			local p = findPlayer(box.Text)
			if p then
				targetPlayer = p
				showList(false)
				refreshStatus()
			end
		end
	end)

	setBtn.MouseButton1Click:Connect(function()
		local p = findPlayer(box.Text)
		if p then
			targetPlayer = p
			showList(false)
			refreshStatus()
		else
			status.Text = tr("ไม่พบผู้เล่นชื่อนี้")
		end
	end)

	clearBtn.MouseButton1Click:Connect(function()
		targetPlayer = nil
		setSpectate(false)
		showList(false)
		refreshStatus()
	end)

	local function onPlayersChanged()
		task.delay(0.3, function()
			if list.Parent and list.Visible then populate(box.Text) end
		end)
	end
	table.insert(connections, Players.PlayerAdded:Connect(onPlayersChanged))
	table.insert(connections, Players.PlayerRemoving:Connect(onPlayersChanged))

	refreshStatus()

	local r4 = gridRow(parent, 4, 2, 48)
	makeSwitchCard(r4[1], "ส่องกล้องเป้าหมาย",
		function() return spectateOn end,
		function(b) setSpectate(b) end)
	local tpBtn = makeCellButton(r4[2], tr("วาร์ปไปด้านหลังเป้าหมาย"), ORANGE)
	tpBtn.MouseButton1Click:Connect(tpBehind)

	local r5 = gridRow(parent, 5, 2, 56)
	makeSwitchCard(r5[1], "Hitbox ขยาย",
		function() return hitboxOn end,
		function(b) setHitbox(b) end)
	makeNumberCard(r5[2], "ขนาด Hitbox ผู้เล่น", 1, HB_MAX,
		function() return hitboxSize end,
		function(v) hitboxSize = v end)

	local r6 = gridRow(parent, 6, 2, 46)
	makeSwitchCard(r6[1], "Hitbox: ผู้เล่น",
		function() return hitboxPlayers end,
		function(b) hitboxPlayers = b end)
	makeSwitchCard(r6[2], "Hitbox: ม็อบ (NPC)",
		function() return hitboxMobs end,
		function(b) hitboxMobs = b end)

	local r7 = gridRow(parent, 7, 1, 46)
	makeSwitchCard(r7[1], "Hitbox: ขยายตัวจริง",
		function() return hitboxReal end,
		function(b) setHitboxReal(b) end)

	local r8 = gridRow(parent, 8, 1, 48)
	makeNumberCard(r8[1], "ขนาด Hitbox ม็อบ", 1, HB_MAX,
		function() return hitboxMobSize end,
		function(v) hitboxMobSize = v end)
end
