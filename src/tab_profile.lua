local function renderProfile(parent)
	local card = Instance.new("Frame")
	card.LayoutOrder = 1
	card.Size = UDim2.new(1, -8, 0, 100)
	card.BackgroundColor3 = BG2
	card.Parent = parent
	round(card, 14)
	outline(card, ACCENT, 2)

	local avatar = Instance.new("ImageLabel")
	avatar.Position = UDim2.fromOffset(10, 10)
	avatar.Size = UDim2.fromOffset(80, 80)
	avatar.BackgroundColor3 = BG
	avatar.Parent = card
	round(avatar, 40)

	task.spawn(function()
		local ok, img = pcall(function()
			return Players:GetUserThumbnailAsync(
				player.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size150x150
			)
		end)
		if ok and avatar.Parent then avatar.Image = img end
	end)

	local nameLabel = Instance.new("TextLabel")
	nameLabel.BackgroundTransparency = 1
	nameLabel.Position = UDim2.fromOffset(105, 14)
	nameLabel.Size = UDim2.new(1, -115, 0, 36)
	nameLabel.Text = player.DisplayName
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.TextColor3 = WHITE
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextSize = 24
	nameLabel.Parent = card

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(105, 52)
	sub.Size = UDim2.new(1, -115, 0, 28)
	sub.Text = "@" .. player.Name
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextColor3 = Color3.fromRGB(170, 170, 180)
	sub.Font = Enum.Font.Gotham
	sub.TextSize = 18
	sub.Parent = card

	infoRow(parent, 2, tr("ไอดีผู้เล่น"), player.UserId)
	infoRow(parent, 3, tr("อายุบัญชี"), player.AccountAge .. " " .. tr("วัน"))
	local hp = infoRow(parent, 4, tr("เลือด"), "-")

	local mapRow = infoRow(parent, 5, tr("แมพ"), mapName or tr("กำลังโหลด..."))
	if not mapName then
		task.spawn(function()
			local ok, info = pcall(function()
				return MarketplaceService:GetProductInfo(game.PlaceId)
			end)
			mapName = (ok and info and info.Name) or game.Name
			if mapRow.Parent then mapRow.Text = mapName end
		end)
	end
	infoRow(parent, 6, "Place ID", game.PlaceId)
	local pc = infoRow(parent, 7, tr("ผู้เล่นในเซิร์ฟ"), "-")

	table.insert(connections, RunService.Heartbeat:Connect(function()
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hum then
			hp.Text = math.floor(hum.Health) .. " / " .. math.floor(hum.MaxHealth)
		end
		pc.Text = #Players:GetPlayers() .. " / " .. Players.MaxPlayers
	end))

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local order = 10
		for _, stat in ipairs(stats:GetChildren()) do
			if stat:IsA("ValueBase") then
				order += 1
				local v = infoRow(parent, order, stat.Name, stat.Value)
				table.insert(connections, stat.Changed:Connect(function()
					v.Text = tostring(stat.Value)
				end))
			end
		end
	end
end