local baseTabs = {
	{key = "info", name = "ข้อมูลผู้เล่น", render = renderProfile},
	{key = "player", name = "ผู้เล่น", render = renderStats},
	{key = "view", name = "มุมมอง", render = renderView},
	{key = "misc", name = "อื่นๆ", render = renderMisc},
	{key = "replay", name = "รีเพลย์", render = function(p) renderReplay(p) end},
	{key = "friends", name = "เพื่อน", render = renderFriends},
	{key = "settings", name = "ตั้งค่า", render = renderSettings},
}

local function getTabs()
	local list = {}
	for _, t in ipairs(baseTabs) do
		if t.key ~= "replay" or replayTabOn then table.insert(list, t) end
	end
	return list
end

local tabButtons = {}

function showTab(key)
	local found
	for _, t in ipairs(getTabs()) do
		if t.key == key then
			found = t
			break
		end
	end
	if not found then return end

	currentKey = key
	title.Text = tr(found.name)
	for k, b in pairs(tabButtons) do
		b.BackgroundColor3 = (k == key) and ACCENT or BG2
	end

	for _, c in ipairs(connections) do c:Disconnect() end
	table.clear(connections)
	scroll.ScrollingEnabled = true
	scroll.CanvasPosition = Vector2.new(0, 0)
	for _, child in ipairs(scroll:GetChildren()) do
		if not child:IsA("UIListLayout") then child:Destroy() end
	end

	found.render(scroll)
	if OPT.themeHook then OPT.themeHook() end
end

function buildTabButtons()
	for _, b in pairs(tabButtons) do b:Destroy() end
	table.clear(tabButtons)

	for i, t in ipairs(getTabs()) do
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(1, -6, 0, 44)
		b.BackgroundColor3 = (t.key == currentKey) and ACCENT or BG2
		b.Text = tr(t.name)
		b.TextColor3 = WHITE
		b.Font = Enum.Font.GothamMedium
		b.TextScaled = true
		b.LayoutOrder = i
		b.Parent = tabBar
		round(b, 10)
		local pad = Instance.new("UIPadding")
		pad.PaddingTop = UDim.new(0, 8)
		pad.PaddingBottom = UDim.new(0, 8)
		pad.PaddingLeft = UDim.new(0, 6)
		pad.PaddingRight = UDim.new(0, 6)
		pad.Parent = b
		tabButtons[t.key] = b
		b.MouseButton1Click:Connect(function() showTab(t.key) end)
	end
end

function applyLang()
	openBtn.Text = tr("เมนู")
	for _, h in ipairs(langHooks) do pcall(h) end
	buildTabButtons()
	showTab(currentKey)
end

buildTabButtons()
showTab("info")

do
	local resizeHandle = Instance.new("TextButton")
	resizeHandle.AnchorPoint = Vector2.new(1, 1)
	resizeHandle.Position = UDim2.new(1, -6, 1, -6)
	resizeHandle.Size = UDim2.fromOffset(36, 36)
	resizeHandle.BackgroundColor3 = BG2
	resizeHandle.Text = "◢"
	resizeHandle.TextColor3 = ACCENT
	resizeHandle.TextSize = 20
	resizeHandle.ZIndex = 5
	resizeHandle.Parent = panel
	round(resizeHandle, 10)

	local MIN_W, MIN_H = 280, 240
	local resizing, rInput, rStart, rSize, rPos = false, nil, nil, nil, nil

	resizeHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			resizing = true
			rInput = input
			rStart = input.Position
			rSize = panel.AbsoluteSize
			rPos = panel.Position
		end
	end)

	track(UserInputService.InputChanged:Connect(function(input)
		if not resizing then return end
		if input == rInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - rStart
			local maxSize = gui.AbsoluteSize
			local w = math.clamp(rSize.X + d.X, MIN_W, maxSize.X - 20)
			local h = math.clamp(rSize.Y + d.Y, MIN_H, maxSize.Y - 20)
			local dw, dh = w - rSize.X, h - rSize.Y

			panel.Size = UDim2.fromOffset(w, h)
			panel.Position = UDim2.new(
				rPos.X.Scale, rPos.X.Offset + dw / 2,
				rPos.Y.Scale, rPos.Y.Offset + dh / 2
			)
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if input == rInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
			resizing = false
		end
	end))

	local openInfo = TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	local closeInfo = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local isOpen = false

	local function openPanel()
		if isOpen then return end
		isOpen = true
		panel.Visible = true
		TweenService:Create(scale, openInfo, {Scale = 1}):Play()
	end

	local function closePanel()
		if not isOpen then return end
		isOpen = false
		local t = TweenService:Create(scale, closeInfo, {Scale = 0})
		t:Play()
		t.Completed:Connect(function()
			if not isOpen then panel.Visible = false end
		end)
	end

	local openWasDragged = makeDraggable(openBtn, openBtn)
	makeDraggable(title, panel)

	OPT.togglePanel = function()
		if isOpen then closePanel() else openPanel() end
	end

	openBtn.MouseButton1Click:Connect(function()
		if openWasDragged() then return end
		if isOpen then closePanel() else openPanel() end
	end)
	closeBtn.MouseButton1Click:Connect(closePanel)

	local function killScript()
		pcall(function() RunService:UnbindFromRenderStep("MobileUIAim") end)
		pcall(function() RunService:UnbindFromRenderStep("MobileUIRec") end)
		pcall(function() RunService:UnbindFromRenderStep("MobileUIPlay") end)
		restoreOriginals()
		if OPT.cleanupLook then OPT.cleanupLook() end
		for _, c in ipairs(connections) do c:Disconnect() end
		table.clear(connections)
		for _, c in ipairs(allConns) do c:Disconnect() end
		table.clear(allConns)
		gui:Destroy()
		env.MobileUI_Kill = nil
	end
	env.MobileUI_Kill = killScript

	local armed = false
	killBtn.MouseButton1Click:Connect(function()
		if armed then
			killScript()
			return
		end
		armed = true
		killBtn.Text = "?"
		killBtn.BackgroundColor3 = Color3.fromRGB(230, 140, 40)
		task.delay(2, function()
			if gui.Parent and armed then
				armed = false
				killBtn.Text = "OFF"
				killBtn.BackgroundColor3 = GRAY
			end
		end)
	end)
end

print("[Sora Hub] ready")