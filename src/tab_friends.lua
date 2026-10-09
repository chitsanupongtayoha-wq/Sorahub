
-- ===== แท็บเพื่อน: ดูเพื่อนที่ออนไลน์ + ตามไปเซิร์ฟเดียวกัน =====
local function renderFriends(parent)
	local r1 = gridRow(parent, 1, 2, 48)
	local refreshBtn = makeCellButton(r1[1], tr("รีเฟรชรายชื่อเพื่อน"), ACCENT)
	local statusCard = Instance.new("TextLabel")
	statusCard.Size = UDim2.fromScale(1, 1)
	statusCard.BackgroundTransparency = 1
	statusCard.Text = ""
	statusCard.TextColor3 = Color3.fromRGB(170, 170, 180)
	statusCard.Font = Enum.Font.GothamMedium
	statusCard.TextSize = 14
	statusCard.TextWrapped = true
	statusCard.Parent = r1[2]

	local rows = {}
	local token = 0

	local function clearRows()
		for _, r in ipairs(rows) do r:Destroy() end
		table.clear(rows)
	end

	local function addFriendRow(order, f)
		local card = Instance.new("Frame")
		card.LayoutOrder = order
		card.Size = UDim2.new(1, -8, 0, 96)
		card.BackgroundColor3 = BG2
		card.Parent = parent
		round(card, 12)
		outline(card, BORDER, 1)
		table.insert(rows, card)

		local name = Instance.new("TextLabel")
		name.BackgroundTransparency = 1
		name.Position = UDim2.fromOffset(10, 6)
		name.Size = UDim2.new(1, -20, 0, 22)
		name.TextXAlignment = Enum.TextXAlignment.Left
		name.Text = (f.DisplayName or f.UserName or "?") .. "  (@" .. tostring(f.UserName) .. ")"
		name.TextColor3 = WHITE
		name.Font = Enum.Font.GothamBold
		name.TextSize = 15
		name.TextTruncate = Enum.TextTruncate.AtEnd
		name.Parent = card

		local loc = Instance.new("TextLabel")
		loc.BackgroundTransparency = 1
		loc.Position = UDim2.fromOffset(10, 28)
		loc.Size = UDim2.new(1, -20, 0, 20)
		loc.TextXAlignment = Enum.TextXAlignment.Left
		loc.Text = tostring(f.LastLocation or "-")
		loc.TextColor3 = Color3.fromRGB(170, 170, 180)
		loc.Font = Enum.Font.GothamMedium
		loc.TextSize = 13
		loc.TextTruncate = Enum.TextTruncate.AtEnd
		loc.Parent = card

		local btnRow = Instance.new("Frame")
		btnRow.BackgroundTransparency = 1
		btnRow.Position = UDim2.fromOffset(8, 52)
		btnRow.Size = UDim2.new(1, -16, 0, 36)
		btnRow.Parent = card
		local lay = Instance.new("UIListLayout")
		lay.FillDirection = Enum.FillDirection.Horizontal
		lay.Padding = UDim.new(0, 8)
		lay.Parent = btnRow

		local profBtn = Instance.new("TextButton")
		profBtn.Size = UDim2.new(0.5, -4, 1, 0)
		profBtn.BackgroundColor3 = GRAY
		profBtn.Text = tr("ดูโปรไฟล์")
		profBtn.TextColor3 = WHITE
		profBtn.Font = Enum.Font.GothamMedium
		profBtn.TextSize = 14
		profBtn.Parent = btnRow
		round(profBtn, 10)

		local joinBtn = Instance.new("TextButton")
		joinBtn.Size = UDim2.new(0.5, -4, 1, 0)
		joinBtn.Text = tr("ตามไป (กดจอย)")
		joinBtn.TextColor3 = WHITE
		joinBtn.Font = Enum.Font.GothamMedium
		joinBtn.TextSize = 14
		joinBtn.Parent = btnRow
		round(joinBtn, 10)
		local canJoin = f.PlaceId and f.GameId and f.PlaceId ~= 0
		joinBtn.BackgroundColor3 = canJoin and GREEN or GRAY

		local showInfo = false
		profBtn.MouseButton1Click:Connect(function()
			showInfo = not showInfo
			if showInfo then
				loc.Text = "ID " .. tostring(f.VisitorId) .. " · " .. tostring(f.LastLocation or "-")
					.. (f.PlaceId and (" · Place " .. tostring(f.PlaceId)) or "")
			else
				loc.Text = tostring(f.LastLocation or "-")
			end
		end)

		joinBtn.MouseButton1Click:Connect(function()
			if not canJoin then
				statusCard.Text = tr("เพื่อนคนนี้เข้าร่วมไม่ได้")
				return
			end
			local ok = pcall(function()
				TeleportService:TeleportToPlaceInstance(f.PlaceId, f.GameId, player)
			end)
			statusCard.Text = ok and tr("กำลังเข้าร่วม...") or tr("เข้าร่วมไม่สำเร็จ (เกมอาจไม่อนุญาต)")
		end)
	end

	local function load()
		token += 1
		local my = token
		statusCard.Text = tr("กำลังโหลด...")
		clearRows()
		task.spawn(function()
			local ok, list = pcall(function() return player:GetFriendsOnline(200) end)
			if my ~= token or not parent.Parent then return end
			if not ok or type(list) ~= "table" then
				statusCard.Text = tr("โหลดรายชื่อเพื่อนไม่ได้")
				return
			end
			local inGame = {}
			for _, f in ipairs(list) do
				if f.PlaceId and f.PlaceId ~= 0 then table.insert(inGame, f) end
			end
			statusCard.Text = tr("เพื่อนที่อยู่ในเกม") .. ": " .. #inGame
			for i, f in ipairs(inGame) do addFriendRow(10 + i, f) end
			if OPT.themeHook then OPT.themeHook() end
		end)
	end

	refreshBtn.MouseButton1Click:Connect(load)
	load()
end
