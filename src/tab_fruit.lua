
-- ===== แท็บผลปีศาจ: ดูของในกระเป๋า + ทิ้งผลที่ไม่เก็บ (มีรายการตรวจก่อน + กดยืนยัน) =====
local FRUIT_FILE = "MobileUI_fruitkeep.json"
local FRUIT_DEFAULT_KEEP = "lightning, fire, mochi, quake, dragon, light, sans"
local fruitKeepText = FRUIT_DEFAULT_KEEP
do
	local ok, raw = pcall(function() return readfile(FRUIT_FILE) end)
	if ok and type(raw) == "string" then
		local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
		if ok2 and type(d) == "table" and type(d.keep) == "string" then fruitKeepText = d.keep end
	end
end

local function renderFruit(parent)
	local VIM = nil
	pcall(function() VIM = game:GetService("VirtualInputManager") end)

	local function keepTokens()
		local t = {}
		for tok in tostring(fruitKeepText):gmatch("[^,]+") do
			tok = tok:gsub("^%s+", ""):gsub("%s+$", ""):lower()
			if tok ~= "" then table.insert(t, tok) end
		end
		return t
	end

	local function shouldKeep(name)
		local n = name:lower()
		for _, tok in ipairs(keepTokens()) do
			if n:find(tok, 1, true) then return true end
		end
		return false
	end

	-- ชื่อผลที่เกมเก็บไว้ใน Player.Data.Storage.Fruity
	local function fruitNames()
		local set = {}
		pcall(function()
			local f = player.Data.Storage.Fruity
			for _, c in ipairs(f:GetChildren()) do set[c.Name:lower()] = true end
		end)
		return set
	end

	local function collectFruitTools()
		local names = fruitNames()
		local list = {}
		local function scan(cont)
			if not cont then return end
			for _, t in ipairs(cont:GetChildren()) do
				local ln = t.Name:lower()
				if t:IsA("Tool") and (names[ln] or ln:find("fruity", 1, true) or ln:find("fruit", 1, true)) then
					table.insert(list, t)
				end
			end
		end
		scan(player:FindFirstChildOfClass("Backpack"))
		scan(player.Character)
		return list
	end

	-- แถวบน: ช่องแก้รายการที่เก็บ
	local r1 = gridRow(parent, 1, 1, 56)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = r1[1]
	round(card, 12)
	outline(card, BORDER, 1)
	local lab = Instance.new("TextLabel")
	lab.BackgroundTransparency = 1
	lab.Position = UDim2.fromOffset(10, 0)
	lab.Size = UDim2.new(0.28, 0, 1, 0)
	lab.TextXAlignment = Enum.TextXAlignment.Left
	lab.Text = tr("ผลที่เก็บ (คั่นด้วย ,)")
	lab.TextColor3 = WHITE
	lab.Font = Enum.Font.GothamBold
	lab.TextSize = 13
	lab.TextWrapped = true
	lab.Parent = card
	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -8, 0.5, 0)
	box.Size = UDim2.new(0.68, 0, 0, 38)
	box.BackgroundColor3 = BG
	box.Text = fruitKeepText
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamMedium
	box.TextSize = 13
	box.ClearTextOnFocus = false
	box.TextTruncate = Enum.TextTruncate.AtEnd
	box.Parent = card
	round(box, 10)

	local r2 = gridRow(parent, 2, 3, 46)
	local refreshBtn = makeCellButton(r2[1], tr("รีเฟรชรายการ"), ACCENT)
	local dropBtn = makeCellButton(r2[2], tr("ซ่อนผลที่ไม่เก็บ"), RED)
	local restoreBtn = makeCellButton(r2[3], tr("คืนผลที่ซ่อน"), GRAY)

	local r3 = gridRow(parent, 3, 1, 34)
	local status = Instance.new("TextLabel")
	status.Size = UDim2.fromScale(1, 1)
	status.BackgroundTransparency = 1
	status.TextColor3 = Color3.fromRGB(170, 170, 180)
	status.Font = Enum.Font.GothamMedium
	status.TextSize = 13
	status.TextWrapped = true
	status.Text = ""
	status.Parent = r3[1]

	local rows = {}
	local toDrop = {}

	local function rebuild()
		for _, r in ipairs(rows) do r:Destroy() end
		table.clear(rows)
		table.clear(toDrop)
		local tools = collectFruitTools()
		table.sort(tools, function(a, b) return a.Name < b.Name end)
		local keepN, dropN = 0, 0
		for i, t in ipairs(tools) do
			local keep = shouldKeep(t.Name)
			if keep then keepN += 1 else dropN += 1; table.insert(toDrop, t) end
			local row = Instance.new("Frame")
			row.LayoutOrder = 10 + i
			row.Size = UDim2.new(1, -8, 0, 34)
			row.BackgroundColor3 = BG2
			row.Parent = parent
			round(row, 10)
			table.insert(rows, row)
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Position = UDim2.fromOffset(10, 0)
			l.Size = UDim2.new(1, -90, 1, 0)
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.Text = t.Name
			l.TextColor3 = WHITE
			l.Font = Enum.Font.GothamMedium
			l.TextSize = 14
			l.TextTruncate = Enum.TextTruncate.AtEnd
			l.Parent = row
			local tag = Instance.new("TextLabel")
			tag.AnchorPoint = Vector2.new(1, 0.5)
			tag.Position = UDim2.new(1, -8, 0.5, 0)
			tag.Size = UDim2.fromOffset(70, 24)
			tag.BackgroundColor3 = keep and GREEN or RED
			tag.Text = keep and tr("เก็บ") or tr("จะทิ้ง")
			tag.TextColor3 = WHITE
			tag.Font = Enum.Font.GothamBold
			tag.TextSize = 13
			tag.Parent = row
			round(tag, 8)
		end
		if #tools == 0 then
			status.Text = tr("ไม่พบผลปีศาจในกระเป๋า (หรือเกมเก็บไว้คนละที่)")
		else
			status.Text = tr("เก็บ") .. " " .. keepN .. " | " .. tr("จะทิ้ง") .. " " .. dropN
		end
		dropBtn.Text = tr("ซ่อนผลที่ไม่เก็บ")
		if OPT.themeHook then OPT.themeHook() end
	end

	box.FocusLost:Connect(function()
		fruitKeepText = box.Text
		pcall(function() writefile(FRUIT_FILE, HttpService:JSONEncode({keep = fruitKeepText})) end)
		rebuild()
	end)
	refreshBtn.MouseButton1Click:Connect(rebuild)

	-- เกมนี้ไม่ให้ทิ้งไอเทมจริง (CanBeDropped=false และไม่มี Remote ทิ้ง) จึง "ซ่อน" จากกระเป๋าฝั่งเราแทน
	-- ไม่ได้ลบจริงที่เซิร์ฟเวอร์ กด "คืน" หรือเกิดใหม่/ออกเกมแล้วเข้าใหม่ก็กลับมา
	OPT.fruitStash = OPT.fruitStash or {}
	local stashFolder = gui:FindFirstChild("SoraFruitStash")
	if not stashFolder then
		stashFolder = Instance.new("Folder")
		stashFolder.Name = "SoraFruitStash"
		stashFolder.Parent = gui
	end

	local armed = false
	dropBtn.MouseButton1Click:Connect(function()
		if #toDrop == 0 then status.Text = tr("ไม่มีผลที่ต้องซ่อน"); return end
		if not armed then
			armed = true
			dropBtn.Text = tr("กดอีกครั้งเพื่อยืนยันซ่อน") .. " " .. #toDrop
			task.delay(4, function()
				if armed and dropBtn.Parent then armed = false; dropBtn.Text = tr("ซ่อนผลที่ไม่เก็บ") end
			end)
			return
		end
		armed = false
		local n = 0
		local char = player.Character
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		for _, tool in ipairs(table.clone(toDrop)) do
			if not shouldKeep(tool.Name) and tool.Parent then
				if hum and tool.Parent == char then pcall(function() hum:UnequipTools() end) end
				local ok = pcall(function() tool.Parent = stashFolder end)
				if ok then table.insert(OPT.fruitStash, tool); n += 1 end
			end
		end
		status.Text = tr("ซ่อนแล้ว") .. " " .. n
		rebuild()
	end)

	restoreBtn.MouseButton1Click:Connect(function()
		local bp = player:FindFirstChildOfClass("Backpack")
		local n = 0
		for _, tool in ipairs(OPT.fruitStash) do
			if tool and tool.Parent == stashFolder and bp then
				pcall(function() tool.Parent = bp end)
				n += 1
			end
		end
		table.clear(OPT.fruitStash)
		status.Text = tr("คืนแล้ว") .. " " .. n
		rebuild()
	end)

	rebuild()
end
