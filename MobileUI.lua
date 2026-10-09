if not game:IsLoaded() then game.Loaded:Wait() end
print("[Sora Hub] loading...")

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Lighting = game:GetService("Lighting")
local MarketplaceService = game:GetService("MarketplaceService")
local TeleportService = game:GetService("TeleportService")
local VirtualUser = game:GetService("VirtualUser")
local GuiService = game:GetService("GuiService")
local HttpService = game:GetService("HttpService")
local StatsService = game:GetService("Stats")

local player = Players.LocalPlayer
while not player do
	task.wait()
	player = Players.LocalPlayer
end
local playerGui = player:WaitForChild("PlayerGui")

local env = (getgenv and getgenv()) or _G
if env.MobileUI_Kill then
	pcall(env.MobileUI_Kill)
	env.MobileUI_Kill = nil
end

local guiParent
do
	local okH, h = pcall(function() return gethui and gethui() end)
	if okH and h then
		guiParent = h
	else
		local okC, core = pcall(function() return game:GetService("CoreGui") end)
		if okC and core then
			local t = Instance.new("Folder")
			local okP = pcall(function() t.Parent = core end)
			t:Destroy()
			if okP then guiParent = core end
		end
	end
	guiParent = guiParent or playerGui
	for _, p in ipairs({playerGui, guiParent}) do
		local o = p:FindFirstChild("MobileUI")
		if o then o:Destroy() end
	end
end

local BG = Color3.fromRGB(28, 28, 32)
local BG2 = Color3.fromRGB(45, 45, 52)
local ACCENT = Color3.fromRGB(80, 160, 255)
local BORDER = Color3.fromRGB(70, 70, 80)
local GREEN = Color3.fromRGB(60, 180, 90)
local GRAY = Color3.fromRGB(90, 90, 100)
local RED = Color3.fromRGB(220, 60, 60)
local ORANGE = Color3.fromRGB(200, 90, 60)
local WHITE = Color3.new(1, 1, 1)

local SPEED_MAX, JUMP_MAX, FLY_MAX, TPWALK_MAX = 500, 500, 500, 500
local AIM_RANGE_MAX = 100000
local OPT = {
	FLY_STEP = 10,
	AIM_DELAY = 0.01,
	SKY_HEIGHT = 100000,
	FPS_CAP = 240,
	REC_MAX = 600,
	SAVE_FILE = "MobileUI_settings.json",
	CLICK_DX = 50,
	CLICK_DY = -10,
}
local aimRange = 200

local lang = "th"
local EN = {
	["เมนู"] = "Menu",
	["ข้อมูลผู้เล่น"] = "Profile", ["ผู้เล่น"] = "Player", ["มุมมอง"] = "View",
	["อื่นๆ"] = "Misc", ["รีเพลย์"] = "Replay", ["ตั้งค่า"] = "Settings",
	["ไอดีผู้เล่น"] = "User ID", ["อายุบัญชี"] = "Account age", ["วัน"] = "days",
	["เลือด"] = "Health", ["แมพ"] = "Map", ["กำลังโหลด..."] = "Loading...",
	["ผู้เล่นในเซิร์ฟ"] = "Players",
	["ความเร็ว"] = "Speed", ["กระโดด"] = "Jump", ["บิน"] = "Fly",
	["รีเซ็ต"] = "Reset", ["สูงสุด"] = "max", ["พิมพ์ตัวเลข"] = "Type number",
	["กระโดดกลางอากาศ"] = "Air jump", ["Noclip (ทะลุ)"] = "Noclip",
	["ล่องหน (ปุ่มซ้ายล่าง)"] = "Invisible (side button)",
	["เมนูบินลอย"] = "Floating fly menu",
	["รีเซ็ตทั้งสอง (ความเร็ว + กระโดด)"] = "Reset speed + jump",
	["รีเซ็ตทั้งหมด (ทุกอย่างในหน้านี้)"] = "Reset everything here",
	["ESP ผู้เล่นอื่น"] = "ESP players", ["มองกลางคืน"] = "Fullbright",
	["ล็อคเป้า (Aimbot)"] = "Aimbot", ["ระยะล็อคคนใกล้สุด"] = "Nearest lock range",
	["พิมพ์ชื่อผู้เล่นที่จะระบุ..."] = "Type player name...",
	["ตั้งเป้าหมาย"] = "Set target", ["ล้างเป้าหมาย"] = "Clear target",
	["เป้าหมาย:"] = "Target:", ["ไม่ได้ระบุ (ล็อคคนใกล้สุด)"] = "None (locks nearest)",
	["ไม่พบผู้เล่นชื่อนี้"] = "Player not found", ["ไม่พบผู้เล่น"] = "No players",
	["ส่องกล้องเป้าหมาย"] = "Spectate target",
	["วาร์ปไปด้านหลังเป้าหมาย"] = "Teleport behind target",
	["ถือ:"] = "Holding:", ["ไม่มี"] = "none",
	["กันหลุด (Anti-AFK)"] = "Anti-AFK", ["ลอยฟ้า 100000"] = "Sky 100000",
	["ถือของทั้งหมด (Equip All)"] = "Equip all tools", ["บูส FPS"] = "FPS boost",
	["เข้าเซิร์ฟใหม่ (Rejoin)"] = "Rejoin", ["ออกเกมทันที"] = "Leave game now",
	["รีเพลย์การเล่น"] = "Replay",
	["เริ่มอัด"] = "Record", ["หยุดอัด"] = "Stop rec", ["รัน"] = "Play", ["หยุดรัน"] = "Stop",
	["วนซ้ำ"] = "Loop", ["ล้างที่อัด"] = "Clear", ["ยังไม่มีการอัด"] = "Nothing recorded",
	["กำลังอัด"] = "Recording", ["พร้อมรัน"] = "Ready", ["กำลังรัน"] = "Playing", ["วิ"] = "s",
	["ต้องเริ่มอัดก่อนถึงจะรันได้"] = "Record first before playing",
	["เซฟการตั้งค่า"] = "Save settings", ["โหลดค่าที่เซฟ"] = "Load saved",
	["ภาษา"] = "Language", ["แสดง Ping/FPS"] = "Show Ping/FPS",
	["เซฟแล้ว"] = "Saved", ["โหลดแล้ว"] = "Loaded", ["ไม่มีไฟล์ที่เซฟ"] = "No saved file",
	["เซฟไม่ได้ (executor ไม่รองรับ)"] = "Cannot save (executor unsupported)",
	["ล่องหน"] = "Hide", ["ปิดบิน"] = "Stop fly", ["ปิง"] = "Ping", ["คน"] = "Players",
	["ลากย้าย"] = "drag", ["ออกเกมแล้ว"] = "Left the game",
	["Hitbox ขยาย"] = "Hitbox expand", ["ขนาด Hitbox"] = "Hitbox size",
	["Hitbox: ผู้เล่น"] = "Hitbox: players", ["Hitbox: ขยายตัวจริง"] = "Hitbox: resize real part", ["Hitbox: ม็อบ (NPC)"] = "Hitbox: mobs (NPC)",
	["🎨 ธีมสี"] = "🎨 Color theme", ["🖼 รูปภาพและโลโก้"] = "🖼 Images & logo",
	["✨ ความโปร่งแสงและเอฟเฟกต์"] = "✨ Transparency & effects",
	["สีหลัก (Accent)"] = "Accent color", ["สีพื้นหลัง"] = "Background color",
	["สีแถบ/ปุ่ม (Tab)"] = "Sidebar / tab color", ["สีตัวอักษร"] = "Text color",
	["โลโก้ (ไอดี/ลิงก์รูป)"] = "Logo (ID / image URL)", ["รูปพื้นหลัง (ไอดี/ลิงก์)"] = "Background image (ID / URL)",
	["ความโปร่งรูปพื้นหลัง %"] = "Background image transparency %", ["ความโปร่ง UI %"] = "UI transparency %",
	["Acrylic (เบลอ)"] = "Acrylic (blur)", ["ปุ่มเปิด/ปิดเมนู"] = "Menu toggle key",
	["กดปุ่มที่ต้องการ (Esc ยกเลิก)"] = "Press a key (Esc to cancel)", ["ล้างปุ่ม"] = "Clear key",
	["รีเซ็ตหน้าตาทั้งหมด"] = "Reset all looks", ["โหลดรูปจากลิงก์ไม่ได้"] = "Could not load image from URL",
	["ชดเชยจุดกด แกน X (px)"] = "Click offset X (px)", ["ชดเชยจุดกด แกน Y (px)"] = "Click offset Y (px)",
}
local function tr(s)
	if lang == "en" then return EN[s] or s end
	return s
end
local langHooks = {}

local gui = Instance.new("ScreenGui")
gui.Name = "MobileUI"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 999
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = guiParent

local arrowLayer = Instance.new("Frame")
arrowLayer.Name = "ArrowLayer"
arrowLayer.Size = UDim2.fromScale(1, 1)
arrowLayer.BackgroundTransparency = 1
arrowLayer.Active = false
arrowLayer.Parent = gui

local allConns = {}
local function track(conn)
	table.insert(allConns, conn)
	return conn
end

local function round(obj, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = obj
end

local function outline(obj, color, thick)
	local s = Instance.new("UIStroke")
	s.Color = color
	s.Thickness = thick
	s.Parent = obj
end

local function makeDraggable(handle, target)
	local dragging, dragInput, startPos, startTarget = false, nil, nil, nil
	local moved = false

	local function isPress(i)
		return i.UserInputType == Enum.UserInputType.MouseButton1
			or i.UserInputType == Enum.UserInputType.Touch
	end

	handle.InputBegan:Connect(function(input)
		if isPress(input) then
			dragging = true
			moved = false
			dragInput = input
			startPos = input.Position
			startTarget = target.Position
		end
	end)

	track(UserInputService.InputChanged:Connect(function(input)
		if not dragging then return end
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseMovement then
			local d = input.Position - startPos
			if d.Magnitude > 6 then moved = true end
			if moved then
				target.Position = UDim2.new(
					startTarget.X.Scale, startTarget.X.Offset + d.X,
					startTarget.Y.Scale, startTarget.Y.Offset + d.Y
				)
			end
		end
	end))

	track(UserInputService.InputEnded:Connect(function(input)
		if input == dragInput or input.UserInputType == Enum.UserInputType.MouseButton1 then
			dragging = false
		end
	end))

	return function() return moved end
end

local openBtn = Instance.new("TextButton")
openBtn.AnchorPoint = Vector2.new(0, 0.5)
openBtn.Position = UDim2.new(0, 16, 0.25, 0)
openBtn.Size = UDim2.fromOffset(60, 60)
openBtn.BackgroundColor3 = BG
openBtn.Text = tr("เมนู")
openBtn.TextSize = 15
openBtn.Font = Enum.Font.GothamBold
openBtn.TextColor3 = WHITE
openBtn.Parent = gui
round(openBtn, 30)
outline(openBtn, ACCENT, 2)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromScale(0.78, 0.72)
panel.BackgroundColor3 = BG
panel.ClipsDescendants = true
panel.Visible = false
panel.Parent = gui
round(panel, 18)
outline(panel, ACCENT, 2)

local scale = Instance.new("UIScale")
scale.Scale = 0
scale.Parent = panel

local title = Instance.new("TextLabel")
title.Position = UDim2.fromOffset(16, 8)
title.Size = UDim2.new(1, -120, 0, 36)
title.BackgroundTransparency = 1
title.Text = tr("เมนู")
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = WHITE
title.Font = Enum.Font.GothamBold
title.TextSize = 24
title.Parent = panel

local closeBtn = Instance.new("TextButton")
closeBtn.AnchorPoint = Vector2.new(1, 0)
closeBtn.Position = UDim2.new(1, -10, 0, 8)
closeBtn.Size = UDim2.fromOffset(40, 40)
closeBtn.BackgroundColor3 = RED
closeBtn.Text = "X"
closeBtn.TextColor3 = WHITE
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = panel
round(closeBtn, 10)

local killBtn = Instance.new("TextButton")
killBtn.AnchorPoint = Vector2.new(1, 0)
killBtn.Position = UDim2.new(1, -56, 0, 8)
killBtn.Size = UDim2.fromOffset(40, 40)
killBtn.BackgroundColor3 = GRAY
killBtn.Text = "OFF"
killBtn.TextColor3 = WHITE
killBtn.TextSize = 14
killBtn.Font = Enum.Font.GothamBold
killBtn.Parent = panel
round(killBtn, 10)

local tabBar = Instance.new("ScrollingFrame")
tabBar.Position = UDim2.fromOffset(10, 54)
tabBar.Size = UDim2.new(0.22, 0, 1, -64)
tabBar.BackgroundTransparency = 1
tabBar.BorderSizePixel = 0
tabBar.ScrollBarThickness = 3
tabBar.CanvasSize = UDim2.new()
tabBar.AutomaticCanvasSize = Enum.AutomaticSize.Y
tabBar.Parent = panel

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.new(0.22, 20, 0, 54)
scroll.Size = UDim2.new(0.78, -30, 1, -100)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel

do
	local l1 = Instance.new("UIListLayout")
	l1.Padding = UDim.new(0, 8)
	l1.SortOrder = Enum.SortOrder.LayoutOrder
	l1.Parent = tabBar

	local l2 = Instance.new("UIListLayout")
	l2.Padding = UDim.new(0, 8)
	l2.SortOrder = Enum.SortOrder.LayoutOrder
	l2.Parent = scroll
end

local connections = {}
local showTab, buildTabButtons, applyLang
local currentKey = "info"

local function infoRow(parent, order, label, value)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, 48)
	row.BackgroundColor3 = BG2
	row.Parent = parent
	round(row, 12)
	outline(row, BORDER, 1)

	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Position = UDim2.fromOffset(14, 0)
	l.Size = UDim2.new(0.4, -14, 1, 0)
	l.Text = label
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.TextColor3 = Color3.fromRGB(170, 170, 180)
	l.Font = Enum.Font.GothamMedium
	l.TextSize = 18
	l.TextTruncate = Enum.TextTruncate.AtEnd
	l.Parent = row

	local v = Instance.new("TextLabel")
	v.BackgroundTransparency = 1
	v.Position = UDim2.new(0.4, 0, 0, 0)
	v.Size = UDim2.new(0.6, -14, 1, 0)
	v.Text = tostring(value)
	v.TextXAlignment = Enum.TextXAlignment.Right
	v.TextColor3 = WHITE
	v.Font = Enum.Font.GothamBold
	v.TextSize = 18
	v.TextTruncate = Enum.TextTruncate.AtEnd
	v.Parent = row
	return v
end

local mapName = nil

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

local speedOn, jumpOn, airJump = false, false, false
local noclipOn = false
local flyOn, tpOn = false, false
local speedVal, jumpVal = 16, 50
local flyVal, tpVal = 50, 10
local orig = nil
local initialized = false
local antiAfk = false
local autoRejoin = false
local skyOn = false
local skyAnchor = nil
local invisOn = false
local invisBtnOn = false
local flyHudOn = false
local statsHudOn = true

local flyHudRefresh = function() end
local invisRefresh = function() end
local hudApply = function() end

local function getHum()
	local char = player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

local function getRoot()
	local char = player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function captureOrig(hum)
	orig = {
		speed = hum.WalkSpeed,
		jump = hum.JumpPower,
		useJP = hum.UseJumpPower,
	}
	if not initialized then
		initialized = true
		speedVal = math.clamp(math.floor(orig.speed + 0.5), 8, SPEED_MAX)
		jumpVal = math.clamp(math.floor(orig.jump + 0.5), 20, JUMP_MAX)
	end
end

local function applyStats()
	local hum = getHum()
	if not hum then return end
	if not orig then captureOrig(hum) end

	if speedOn then
		hum.WalkSpeed = math.min(speedVal, SPEED_MAX)
	else
		hum.WalkSpeed = orig.speed
	end

	if jumpOn then
		hum.UseJumpPower = true
		hum.JumpPower = math.min(jumpVal, JUMP_MAX)
	else
		hum.UseJumpPower = orig.useJP
		hum.JumpPower = orig.jump
	end
end

local function enforceStats()
	if not (speedOn or jumpOn) then return end
	local hum = getHum()
	if not hum then return end
	if speedOn then
		local sv = math.min(speedVal, SPEED_MAX)
		if hum.WalkSpeed ~= sv then hum.WalkSpeed = sv end
	end
	if jumpOn then
		local jv = math.min(jumpVal, JUMP_MAX)
		if not hum.UseJumpPower then hum.UseJumpPower = true end
		if hum.JumpPower ~= jv then hum.JumpPower = jv end
	end
end
track(RunService.Stepped:Connect(enforceStats))
track(RunService.Heartbeat:Connect(enforceStats))

local noclipParts = {}

local function setNoclip(on)
	noclipOn = on
	if not on then
		for part in pairs(noclipParts) do
			if part and part.Parent then part.CanCollide = true end
		end
		table.clear(noclipParts)
	end
end

track(RunService.Stepped:Connect(function()
	if not noclipOn then return end
	local char = player.Character
	if not char then return end
	for _, part in ipairs(char:GetDescendants()) do
		if part:IsA("BasePart") and part.CanCollide then
			noclipParts[part] = true
			part.CanCollide = false
		end
	end
end))

local flyBV, flyBG = nil, nil

local function stopFly()
	if flyBV then flyBV:Destroy() flyBV = nil end
	if flyBG then flyBG:Destroy() flyBG = nil end
	local hum = getHum()
	if hum then hum.PlatformStand = false end
end

local function startFly()
	stopFly()
	local hum, root = getHum(), getRoot()
	if not hum or not root then return end
	hum.PlatformStand = true

	flyBV = Instance.new("BodyVelocity")
	flyBV.MaxForce = Vector3.new(1e5, 1e5, 1e5)
	flyBV.Velocity = Vector3.zero
	flyBV.Parent = root

	flyBG = Instance.new("BodyGyro")
	flyBG.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
	flyBG.P = 1e4
	flyBG.CFrame = root.CFrame
	flyBG.Parent = root
end

local function setFly(on)
	flyOn = on
	if on then startFly() else stopFly() end
	flyHudRefresh()
end

local function setFlyVal(v)
	flyVal = math.clamp(math.floor(v + 0.5), 10, FLY_MAX)
	flyHudRefresh()
end

track(RunService.Heartbeat:Connect(function(dt)
	local hum, root = getHum(), getRoot()
	if not hum or not root then return end

	if flyOn then
		if not (flyBV and flyBV.Parent) then startFly() end
		local cam = workspace.CurrentCamera
		if cam and flyBV then
			local cf = cam.CFrame
			local look = cf.LookVector
			local right = cf.RightVector
			local flatLook = Vector3.new(look.X, 0, look.Z)
			if flatLook.Magnitude < 0.01 then flatLook = Vector3.new(0, 0, -1) end
			flatLook = flatLook.Unit
			local flatRight = Vector3.new(right.X, 0, right.Z)
			flatRight = flatRight.Magnitude > 0.01 and flatRight.Unit or Vector3.new(1, 0, 0)

			local move = hum.MoveDirection
			local fwd = move:Dot(flatLook)
			local side = move:Dot(flatRight)

			local vert = 0
			if hum.Jump or UserInputService:IsKeyDown(Enum.KeyCode.Space) then vert += 1 end
			if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then vert -= 1 end

			local dir = look * fwd + flatRight * side + Vector3.new(0, vert, 0)
			if dir.Magnitude > 1 then dir = dir.Unit end

			flyBV.Velocity = dir * math.min(flyVal, FLY_MAX)
			flyBG.CFrame = CFrame.lookAt(root.Position, root.Position + flatLook)
		end
	elseif tpOn then
		local move = hum.MoveDirection
		if move.Magnitude > 0 then
			root.CFrame = root.CFrame + move * math.min(tpVal, TPWALK_MAX) * dt
		end
	end
end))

local setSky
do
	local skyPlat, skyOrigCF, skyPlatY

	-- หาความสูงพื้นใต้จุดที่กำหนด (ข้ามตัวละคร/ม็อบ และพาร์ทที่ไม่ชน)
	local function skyFindGround(x, y, z, up, dist)
		local ex = {}
		if player.Character then table.insert(ex, player.Character) end
		if skyPlat then table.insert(ex, skyPlat) end
		for _, pl in ipairs(Players:GetPlayers()) do
			if pl.Character then table.insert(ex, pl.Character) end
		end
		local rp = RaycastParams.new()
		rp.FilterType = Enum.RaycastFilterType.Exclude
		local origin = Vector3.new(x, y + up, z)
		for _ = 1, 6 do
			rp.FilterDescendantsInstances = ex
			local hit = workspace:Raycast(origin, Vector3.new(0, -dist, 0), rp)
			if not hit then return nil end
			local inst = hit.Instance
			local model = inst:FindFirstAncestorOfClass("Model")
			local isChar = model and model:FindFirstChildOfClass("Humanoid")
			if isChar then
				table.insert(ex, model)
			elseif inst.CanCollide == false then
				table.insert(ex, inst)
			else
				return hit.Position.Y
			end
		end
		return nil
	end

	function setSky(on, skipReturn)
		local cam = workspace.CurrentCamera
		if on then
			local root, hum = getRoot(), getHum()
			if skyOn or not root or not hum or not cam then return end
			skyOrigCF = root.CFrame

			-- หาพื้นจริงใต้ตัว (ไกลได้ถึง 20000) ถ้าอยู่กลางอากาศ ตัวจะตกลงพื้นเหมือนปกติ
			local groundY = skyFindGround(root.Position.X, root.Position.Y, root.Position.Z, 5, 20000)
				or (root.Position.Y - 3)
			skyPlatY = groundY + OPT.SKY_HEIGHT - 1

			skyAnchor = Instance.new("Part")
			skyAnchor.Name = "SkyCamAnchor"
			skyAnchor.Anchored = true
			skyAnchor.CanCollide = false
			skyAnchor.CanQuery = false
			skyAnchor.CanTouch = false
			skyAnchor.Transparency = 1
			skyAnchor.Size = Vector3.new(1, 1, 1)
			skyAnchor.CFrame = CFrame.new(root.Position + Vector3.new(0, 1.5, 0))
			skyAnchor.Parent = workspace

			skyPlat = Instance.new("Part")
			skyPlat.Name = "SkyPlatform"
			skyPlat.Anchored = true
			skyPlat.CanCollide = true
			skyPlat.Transparency = 1
			skyPlat.Size = Vector3.new(200, 2, 200)
			skyPlat.CFrame = CFrame.new(root.Position.X, skyPlatY, root.Position.Z)
			skyPlat.Parent = workspace

			skyOn = true
			root.AssemblyLinearVelocity = Vector3.zero
			root.CFrame = skyOrigCF + Vector3.new(0, OPT.SKY_HEIGHT, 0)
			cam.CameraType = Enum.CameraType.Custom
			cam.CameraSubject = skyAnchor
			invisRefresh()
		else
			if not skyOn then return end
			skyOn = false

			-- ตอนปิด: กลับลงมาตรงจุดที่กล้อง/ตัวเสมือนอยู่ตอนนี้ ไม่ใช่จุดที่กดเปิด
			local returnCF = skyOrigCF
			local rootNow = getRoot()
			if skyAnchor and rootNow then
				local ap = skyAnchor.Position
				local rpp = RaycastParams.new()
				rpp.FilterDescendantsInstances = {player.Character}
				rpp.FilterType = Enum.RaycastFilterType.Exclude
				local hit = workspace:Raycast(ap + Vector3.new(0, 4, 0), Vector3.new(0, -60, 0), rpp)
				if not hit then
					hit = workspace:Raycast(ap + Vector3.new(0, 300, 0), Vector3.new(0, -700, 0), rpp)
				end
				local pos = hit and (hit.Position + Vector3.new(0, 3.5, 0)) or ap
				returnCF = CFrame.new(pos) * (rootNow.CFrame - rootNow.CFrame.Position)
			end

			if skyPlat then skyPlat:Destroy() skyPlat = nil end
			if skyAnchor then skyAnchor:Destroy() skyAnchor = nil end
			local root, hum = getRoot(), getHum()
			if not skipReturn and root and returnCF then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = returnCF
			end
			if cam then
				cam.CameraType = Enum.CameraType.Custom
				if hum then cam.CameraSubject = hum end
			end
			invisRefresh()
		end
	end

	-- แพลตฟอร์มลอกพื้นจริง: เดินขึ้นภูเขา/ลงเนินได้เหมือนอยู่บนพื้น (ผนังทะลุได้)
	local groundAcc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not skyOn then return end
		local root = getRoot()
		if root and skyPlat then
			groundAcc += dt
			if groundAcc >= 0.03 then
				groundAcc = 0
				local vy = root.Position.Y - OPT.SKY_HEIGHT -- ความสูงเสมือนบนพื้นจริง
				local g = skyFindGround(root.Position.X, vy, root.Position.Z, 12, 3000)
				if g then skyPlatY = g + OPT.SKY_HEIGHT - 1 end
			end
			skyPlat.CFrame = CFrame.new(root.Position.X, skyPlatY, root.Position.Z)
			-- ตกนุ่ม: จำกัดความเร็วตกไม่ให้เกิน 40 กันเกมที่มีดาเมจตกจากที่สูง
			local vel = root.AssemblyLinearVelocity
			if vel.Y < -40 then
				root.AssemblyLinearVelocity = Vector3.new(vel.X, -40, vel.Z)
			end
			if root.Position.Y < skyPlatY - 40 then
				root.AssemblyLinearVelocity = Vector3.zero
				root.CFrame = CFrame.new(root.Position.X, skyPlatY + 4, root.Position.Z)
			end
		end
	end))

	track(RunService.RenderStepped:Connect(function()
		if not skyOn or not skyAnchor then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		-- กล้องตามตัวเสมือน: ตำแหน่งตัวบนฟ้า ลบความสูงฟ้า = ตำแหน่งบนพื้นจริง
		local sroot = getRoot()
		if sroot then
			skyAnchor.CFrame = CFrame.new(sroot.Position - Vector3.new(0, OPT.SKY_HEIGHT - 1.5, 0))
		end
		if cam.CameraType ~= Enum.CameraType.Custom then cam.CameraType = Enum.CameraType.Custom end
		if cam.CameraSubject ~= skyAnchor then cam.CameraSubject = skyAnchor end
	end))
end

local invisStore = {}
local setInvis
do
	local invisAcc = 0

	local function invisApply()
		local char = player.Character
		if not char then return end
		for _, d in ipairs(char:GetDescendants()) do
			if (d:IsA("BasePart") and d.Name ~= "HumanoidRootPart") or d:IsA("Decal") then
				if invisStore[d] == nil then invisStore[d] = d.Transparency end
				if d.Transparency ~= 1 then d.Transparency = 1 end
			end
		end
	end

	function setInvis(on)
		if on == invisOn then return end
		invisOn = on
		if on then
			invisApply()
		else
			for inst, v in pairs(invisStore) do
				pcall(function() inst.Transparency = v end)
			end
			table.clear(invisStore)
		end
		invisRefresh()
	end

	track(RunService.Heartbeat:Connect(function(dt)
		if not invisOn then return end
		invisAcc += dt
		if invisAcc < 0.2 then return end
		invisAcc = 0
		invisApply()
	end))
end

local espOn, fullbrightOn, aimOn, spectateOn = false, false, false, false
local targetPlayer = nil

local function getChar(p)
	return p and p.Character
end

local function getPlayerHum(p)
	local c = getChar(p)
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function getPlayerRoot(p)
	local c = getChar(p)
	return c and c:FindFirstChild("HumanoidRootPart")
end

local clearEsp
do
	local espObjs = {}

	local function removeEsp(p)
		local o = espObjs[p]
		if not o then return end
		for _, inst in ipairs({o.hl, o.box, o.bb, o.arrow}) do
			pcall(function() inst:Destroy() end)
		end
		espObjs[p] = nil
	end

	function clearEsp()
		for p in pairs(espObjs) do removeEsp(p) end
	end

	local function createEsp(p, char)
		local root = char:FindFirstChild("HumanoidRootPart")
		local head = char:FindFirstChild("Head")
		if not root or not head then return end

		local hl = Instance.new("Highlight")
		hl.Adornee = char
		hl.FillColor = WHITE
		hl.FillTransparency = 0.85
		hl.OutlineColor = WHITE
		hl.OutlineTransparency = 0
		hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
		hl.Parent = gui

		local box = Instance.new("BoxHandleAdornment")
		box.Adornee = root
		box.Size = Vector3.new(4, 5.5, 3)
		box.Color3 = WHITE
		box.Transparency = 0.8
		box.AlwaysOnTop = true
		box.ZIndex = 1
		box.Parent = gui

		local bb = Instance.new("BillboardGui")
		bb.Adornee = head
		bb.Size = UDim2.fromOffset(220, 64)
		bb.StudsOffset = Vector3.new(0, 2.8, 0)
		bb.AlwaysOnTop = true
		bb.Parent = gui

		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextColor3 = WHITE
		label.TextStrokeTransparency = 0.4
		label.Font = Enum.Font.GothamBold
		label.TextSize = 14
		label.TextYAlignment = Enum.TextYAlignment.Bottom
		label.Text = ""
		label.Parent = bb

		local arrow = Instance.new("Frame")
		arrow.AnchorPoint = Vector2.new(0.5, 0.5)
		arrow.Size = UDim2.fromOffset(90, 52)
		arrow.BackgroundTransparency = 1
		arrow.Visible = false
		arrow.Parent = arrowLayer

		local tri = Instance.new("TextLabel")
		tri.BackgroundTransparency = 1
		tri.Size = UDim2.new(1, 0, 0, 26)
		tri.Text = "▲"
		tri.TextSize = 24
		tri.TextColor3 = WHITE
		tri.TextStrokeTransparency = 0.3
		tri.Font = Enum.Font.GothamBold
		tri.Parent = arrow

		local atext = Instance.new("TextLabel")
		atext.BackgroundTransparency = 1
		atext.Position = UDim2.fromOffset(0, 26)
		atext.Size = UDim2.new(1, 0, 0, 24)
		atext.Text = ""
		atext.TextSize = 13
		atext.TextColor3 = WHITE
		atext.TextStrokeTransparency = 0.3
		atext.Font = Enum.Font.GothamBold
		atext.TextTruncate = Enum.TextTruncate.AtEnd
		atext.Parent = arrow

		espObjs[p] = {
			char = char, hl = hl, box = box, bb = bb, label = label,
			arrow = arrow, tri = tri, atext = atext,
		}
	end

	local espAcc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not espOn then
			if next(espObjs) then clearEsp() end
			return
		end
		espAcc += dt
		if espAcc < 0.1 then return end
		espAcc = 0

		local myRoot = getRoot()
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local char = p.Character
				local o = espObjs[p]
				if char and char.Parent then
					if o and o.char ~= char then
						removeEsp(p)
						o = nil
					end
					if not o then
						createEsp(p, char)
						o = espObjs[p]
					end
					if o then
						local hum = char:FindFirstChildOfClass("Humanoid")
						local root = char:FindFirstChild("HumanoidRootPart")
						local tool = char:FindFirstChildOfClass("Tool")
						local hpText = hum and (math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)) or "-"
						local dist = (myRoot and root) and math.floor((root.Position - myRoot.Position).Magnitude) or 0
						o.label.Text = p.DisplayName .. " (@" .. p.Name .. ")\n"
							.. tr("เลือด") .. " " .. hpText .. " | " .. dist .. " studs\n"
							.. tr("ถือ:") .. " " .. (tool and tool.Name or tr("ไม่มี"))
						o.atext.Text = p.DisplayName .. " " .. dist .. "m"
					end
				elseif o then
					removeEsp(p)
				end
			end
		end
	end))

	track(RunService.RenderStepped:Connect(function()
		if not espOn then return end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local size = cam.ViewportSize
		local center = size / 2
		local margin = 48
		local mx, my = center.X - margin, center.Y - margin

		for _, o in pairs(espObjs) do
			local root = o.char and o.char:FindFirstChild("HumanoidRootPart")
			if root and o.arrow then
				local v = cam:WorldToViewportPoint(root.Position)
				local onScreen = v.Z > 0 and v.X > 0 and v.X < size.X and v.Y > 0 and v.Y < size.Y
				if onScreen then
					o.arrow.Visible = false
				else
					local dir = Vector2.new(v.X, v.Y) - center
					if v.Z < 0 then dir = -dir end
					if dir.Magnitude < 0.001 then dir = Vector2.new(0, 1) end
					dir = dir.Unit
					local tx = dir.X ~= 0 and mx / math.abs(dir.X) or math.huge
					local ty = dir.Y ~= 0 and my / math.abs(dir.Y) or math.huge
					local t = math.min(tx, ty)
					local pos = center + dir * t
					o.arrow.Position = UDim2.fromOffset(pos.X, pos.Y)
					o.tri.Rotation = math.deg(math.atan2(dir.X, -dir.Y))
					o.arrow.Visible = true
				end
			end
		end
	end))

	track(Players.PlayerRemoving:Connect(function(p)
		removeEsp(p)
		if p == targetPlayer then
			targetPlayer = nil
			if spectateOn then
				spectateOn = false
				local h = getHum()
				local cam = workspace.CurrentCamera
				if h and cam then cam.CameraSubject = skyAnchor or h end
			end
		end
	end))
end

-- ====== Hitbox: ขยายขนาด hitbox ระบุเป็นตัวเลขได้ (ผู้เล่น + ม็อบ/NPC) ======
-- ใช้พาร์ทเสริมที่เชื่อมติดกับ HumanoidRootPart (ไม่แตะพาร์ทจริงของตัวละคร)
-- ตัวละคร/ม็อบจึงเดิน ขยับ และวาร์ปได้ตามปกติ และ hitbox ตามตัวไปด้วย
local HB_MAX = 2048
local hitboxOn, hitboxSize = false, 10
local hitboxPlayers, hitboxMobs = true, true
local hitboxReal = false -- true = ขยายพาร์ทจริงของตัวละคร (ไม่ใช้พาร์ทเสริม)
local setHitbox, setHitboxReal
do
	local HB_NAME = "SoraHitbox"
	local HB_TRANSP = 0.7 -- ความโปร่งใสของกล่อง (ล็อกไว้ ไม่ให้เกมเปลี่ยนเป็นขาวทึบ)

	-- ล็อกหน้าตา: ถ้าเกมแก้ Transparency/Color ของพาร์ทนี้ (เช่น fade ตัวละคร) ให้ตั้งกลับทันที
	local function lockLook(part)
		return {
			part:GetPropertyChangedSignal("Transparency"):Connect(function()
				if part.Transparency ~= HB_TRANSP then part.Transparency = HB_TRANSP end
			end),
			part:GetPropertyChangedSignal("Color"):Connect(function()
				if part.Color ~= WHITE then part.Color = WHITE end
			end),
		}
	end
	local function unlock(cs)
		if not cs then return end
		for _, c in ipairs(cs) do c:Disconnect() end
	end
	local humSet = {}   -- [Humanoid] = true
	local ext = {}      -- [Humanoid] = {part = Part, root = BasePart}
	local realStore = {} -- [BasePart] = ค่าเดิม (โหมดขยายตัวจริง)
	local addConn = nil
	local scanToken = 0

	local function pickPart(model)
		return model:FindFirstChild("HumanoidRootPart")
			or model.PrimaryPart
			or model:FindFirstChild("Torso")
			or model:FindFirstChild("UpperTorso")
	end

	local function removeExt(hum)
		local o = ext[hum]
		if not o then return end
		ext[hum] = nil
		unlock(o.locks)
		pcall(function() o.part:Destroy() end)
	end

	local function restoreReal(part)
		local o = realStore[part]
		if not o then return end
		realStore[part] = nil
		unlock(o.locks) -- ต้องปลดล็อกก่อนคืนค่า ไม่งั้นจะถูกตั้งกลับเป็นกล่องขาว
		if part.Parent then
			pcall(function()
				part.Size = o.Size
				part.Transparency = o.Transparency
				part.CanCollide = o.CanCollide
				part.Color = o.Color
				part.Material = o.Material
			end)
		end
	end

	local function isTarget(hum)
		local model = hum.Parent
		if not model or not model:IsA("Model") then return false end
		local myChar = player.Character
		if myChar and (model == myChar or model:IsDescendantOf(myChar)) then return false end
		if hum.Health <= 0 then return false end
		-- มี ForceField = โดนดาเมจไม่ได้ ไม่ต้องมี hitbox (จะกลับมาเองเมื่อเกราะหมด)
		if model:FindFirstChildOfClass("ForceField") then return false end
		if Players:GetPlayerFromCharacter(model) then
			return hitboxPlayers
		end
		return hitboxMobs
	end

	local function applyOne(hum)
		local model = hum.Parent
		if not model then return end

		local root = pickPart(model)

		if not isTarget(hum) then
			removeExt(hum)
			if root and root:IsA("BasePart") then restoreReal(root) end
			return
		end

		if not root or not root:IsA("BasePart") then
			removeExt(hum)
			return
		end

		if hitboxReal then
			-- โหมดขยายพาร์ทจริง: ไม่ตั้ง Massless เพื่อไม่ให้ฟิสิกส์ของตัวละครเพี้ยน
			removeExt(hum)
			if not realStore[root] then
				realStore[root] = {
					Size = root.Size,
					Transparency = root.Transparency,
					CanCollide = root.CanCollide,
					Color = root.Color,
					Material = root.Material,
				}
				realStore[root].locks = lockLook(root)
			end
			local rs = math.clamp(hitboxSize, 1, HB_MAX)
			local rwant = Vector3.new(rs, rs, rs)
			if root.Size ~= rwant then root.Size = rwant end
			if root.Transparency ~= HB_TRANSP then root.Transparency = HB_TRANSP end
			if root.Color ~= WHITE then root.Color = WHITE end
			root.Material = Enum.Material.SmoothPlastic
			root.CanCollide = false
			return
		end
		restoreReal(root)

		local o = ext[hum]
		if o and (not o.part.Parent or o.root ~= root or o.part.Parent ~= model) then
			removeExt(hum)
			o = nil
		end

		local s = math.clamp(hitboxSize, 1, HB_MAX)
		if not o then
			local p = Instance.new("Part")
			p.Name = HB_NAME
			p.Size = Vector3.new(s, s, s)
			p.CFrame = root.CFrame
			p.Anchored = false
			p.CanCollide = false
			p.CanQuery = true
			p.CanTouch = true
			p.Massless = true
			p.Transparency = HB_TRANSP
			p.Color = WHITE
			p.Material = Enum.Material.SmoothPlastic
			p.CastShadow = false
			pcall(function() p.CollisionGroup = root.CollisionGroup end)

			local w = Instance.new("WeldConstraint")
			w.Part0 = root
			w.Part1 = p
			w.Parent = p

			p.Parent = model
			o = {part = p, root = root, locks = lockLook(p)}
			ext[hum] = o
		else
			local want = Vector3.new(s, s, s)
			if o.part.Size ~= want then o.part.Size = want end
			if o.part.Transparency ~= HB_TRANSP then o.part.Transparency = HB_TRANSP end
			if o.part.Color ~= WHITE then o.part.Color = WHITE end
			if o.part.CollisionGroup ~= root.CollisionGroup then
				pcall(function() o.part.CollisionGroup = root.CollisionGroup end)
			end
		end
	end

	local function addHum(inst)
		if inst:IsA("Humanoid") then humSet[inst] = true end
	end

	local function restoreAll()
		for hum in pairs(ext) do removeExt(hum) end
		for part in pairs(realStore) do restoreReal(part) end
	end

	-- ===== รายบุคคล: ทุกครั้งที่ผู้เล่นคนหนึ่งตาย/เกิดใหม่ ล้างแล้วสร้าง hitbox ของคนนั้นใหม่ =====
	local playerConns = {} -- [Player] = {Connection...}
	local plrAddConn = nil

	local function releasePlayer(p)
		local ch = p.Character
		if not ch then return end
		local hum = ch:FindFirstChildOfClass("Humanoid")
		if hum then
			removeExt(hum)
			humSet[hum] = nil
		end
		local r = pickPart(ch)
		if r then restoreReal(r) end
	end

	local function watchPlayer(p)
		if p == player or playerConns[p] then return end

		local function onChar(ch)
			if not hitboxOn then return end
			task.spawn(function()
				local hum = ch:WaitForChild("Humanoid", 10)
				ch:WaitForChild("HumanoidRootPart", 10)
				if not hum then return end
				-- ตายแล้ว: ล้าง hitbox ของคนนี้ทันที
				hum.Died:Connect(function() releasePlayer(p) end)
				-- สร้างใหม่หลังเกิด และย้ำอีกสองรอบ เผื่อเกมประกอบตัวละครหลังเกิด
				for i = 1, 3 do
					if not hitboxOn or not ch.Parent then return end
					addHum(hum)
					applyOne(hum)
					task.wait(i == 1 and 0.5 or 1.5)
				end
			end)
		end

		playerConns[p] = {
			p.CharacterAdded:Connect(onChar),
			p.CharacterRemoving:Connect(function() releasePlayer(p) end),
		}
		if p.Character then onChar(p.Character) end
	end

	local function unwatchAll()
		for _, cs in pairs(playerConns) do
			for _, c in ipairs(cs) do c:Disconnect() end
		end
		table.clear(playerConns)
		if plrAddConn then plrAddConn:Disconnect() plrAddConn = nil end
	end

	function setHitbox(on)
		if on == hitboxOn then return end
		hitboxOn = on
		scanToken += 1
		local myToken = scanToken

		if on then
			if addConn then addConn:Disconnect() end
			addConn = workspace.DescendantAdded:Connect(addHum)
			for _, pl in ipairs(Players:GetPlayers()) do watchPlayer(pl) end
			plrAddConn = Players.PlayerAdded:Connect(watchPlayer)
			task.spawn(function()
				local n = 0
				for _, inst in ipairs(workspace:GetDescendants()) do
					if myToken ~= scanToken then return end
					addHum(inst)
					n += 1
					if n % 3000 == 0 then task.wait() end
				end
			end)
		else
			if addConn then addConn:Disconnect() addConn = nil end
			unwatchAll()
			restoreAll()
			table.clear(humSet)
		end
	end

	-- สลับโหมด: คืนค่าของโหมดเก่าก่อน
	function setHitboxReal(b)
		hitboxReal = b
		if hitboxOn then restoreAll() end
	end

	local acc = 0
	track(RunService.Heartbeat:Connect(function(dt)
		if not hitboxOn then return end
		acc += dt
		if acc < 0.2 then return end
		acc = 0

		-- กวาดล้าง: ตัวที่ตาย/หมดสภาพ/ถูกลบ Humanoid ออก ต้องไม่เหลือ hitbox ค้าง
		for part in pairs(realStore) do
			if not part:IsDescendantOf(workspace) then
				realStore[part] = nil
			else
				local model = part.Parent
				local h = model and model:FindFirstChildOfClass("Humanoid")
				if not h or not isTarget(h) then restoreReal(part) end
			end
		end
		for hum in pairs(ext) do
			if not hum.Parent or not hum:IsDescendantOf(workspace) or not isTarget(hum) then
				removeExt(hum)
			end
		end

		for hum in pairs(humSet) do
			if not hum.Parent or not hum:IsDescendantOf(workspace) then
				humSet[hum] = nil
				removeExt(hum)
			else
				applyOne(hum)
			end
		end
	end))
end

local setFullbright
do
	local lightOrig = nil

	local function applyFullbright()
		Lighting.Brightness = 2
		Lighting.ClockTime = 14
		Lighting.FogEnd = 1e6
		Lighting.GlobalShadows = false
		Lighting.Ambient = Color3.fromRGB(200, 200, 200)
		Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
	end

	function setFullbright(on)
		if on then
			if not lightOrig then
				lightOrig = {
					Brightness = Lighting.Brightness,
					ClockTime = Lighting.ClockTime,
					FogEnd = Lighting.FogEnd,
					GlobalShadows = Lighting.GlobalShadows,
					Ambient = Lighting.Ambient,
					OutdoorAmbient = Lighting.OutdoorAmbient,
				}
			end
			fullbrightOn = true
			applyFullbright()
		else
			fullbrightOn = false
			if lightOrig then
				for k, v in pairs(lightOrig) do
					pcall(function() Lighting[k] = v end)
				end
				lightOrig = nil
			end
		end
	end

	track(RunService.Heartbeat:Connect(function()
		if fullbrightOn then applyFullbright() end
	end))
end

local fpsOn = false
local setFpsBoost
do
	local fpsStore = {}
	local fpsConn, fpsOrigQuality, fpsOrigCap = nil, nil, nil

	local function fpsSet(inst, prop, val)
		local ok, cur = pcall(function() return inst[prop] end)
		if not ok or cur == val then return end
		local s = fpsStore[inst]
		if not s then
			s = {}
			fpsStore[inst] = s
		end
		if s[prop] == nil then s[prop] = cur end
		pcall(function() inst[prop] = val end)
	end

	local function fpsOptimize(inst)
		if inst:IsA("BasePart") then
			fpsSet(inst, "Material", Enum.Material.SmoothPlastic)
			fpsSet(inst, "Reflectance", 0)
			fpsSet(inst, "CastShadow", false)
		elseif inst:IsA("Decal") or inst:IsA("Texture") then
			fpsSet(inst, "Transparency", 1)
		elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Smoke")
			or inst:IsA("Fire") or inst:IsA("Sparkles") or inst:IsA("PostEffect") then
			fpsSet(inst, "Enabled", false)
		end
	end

	function setFpsBoost(on)
		if on == fpsOn then return end
		fpsOn = on
		if on then
			pcall(function()
				fpsOrigQuality = settings().Rendering.QualityLevel
				settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
			end)
			pcall(function()
				if getfpscap then fpsOrigCap = getfpscap() end
				if setfpscap then setfpscap(OPT.FPS_CAP) end
			end)
			fpsSet(Lighting, "GlobalShadows", false)
			pcall(function()
				local t = workspace.Terrain
				fpsSet(t, "Decoration", false)
				fpsSet(t, "WaterWaveSize", 0)
				fpsSet(t, "WaterReflectance", 0)
			end)
			for _, c in ipairs(Lighting:GetChildren()) do fpsOptimize(c) end

			task.spawn(function()
				local n = 0
				for _, inst in ipairs(workspace:GetDescendants()) do
					if not fpsOn then return end
					fpsOptimize(inst)
					n += 1
					if n % 400 == 0 then task.wait() end
				end
			end)
			fpsConn = workspace.DescendantAdded:Connect(function(inst)
				if fpsOn then fpsOptimize(inst) end
			end)
		else
			if fpsConn then fpsConn:Disconnect() fpsConn = nil end
			for inst, props in pairs(fpsStore) do
				for k, v in pairs(props) do
					pcall(function() inst[k] = v end)
				end
			end
			table.clear(fpsStore)
			pcall(function()
				if fpsOrigQuality then settings().Rendering.QualityLevel = fpsOrigQuality end
			end)
			pcall(function()
				if setfpscap then setfpscap(fpsOrigCap or 60) end
			end)
		end
	end
end

local function findPlayer(text)
	text = (text or ""):lower()
	text = text:gsub("^%s+", "")
	text = text:gsub("%s+$", "")
	if text == "" then return nil end
	local partial
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			local n, d = p.Name:lower(), p.DisplayName:lower()
			if n == text or d == text then return p end
			if not partial and (n:find(text, 1, true) or d:find(text, 1, true)) then
				partial = p
			end
		end
	end
	return partial
end

do
	local function getAimPart()
		if targetPlayer then
			local hum = getPlayerHum(targetPlayer)
			local c = getChar(targetPlayer)
			if hum and hum.Health > 0 and c then
				return c:FindFirstChild("Head") or c:FindFirstChild("HumanoidRootPart")
			end
			return nil
		end

		local myRoot = getRoot()
		if not myRoot then return nil end
		local origin = (skyOn and skyAnchor) and skyAnchor.Position or myRoot.Position
		local best, bestDist = nil, aimRange
		for _, p in ipairs(Players:GetPlayers()) do
			if p ~= player then
				local c = p.Character
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				local root = c and c:FindFirstChild("HumanoidRootPart")
				if hum and root and hum.Health > 0 then
					local d = (root.Position - origin).Magnitude
					if d < bestDist then
						bestDist = d
						best = c:FindFirstChild("Head") or root
					end
				end
			end
		end
		return best
	end

	local lastAim, lastAimPos = 0, nil
	pcall(function() RunService:UnbindFromRenderStep("MobileUIAim") end)
	RunService:BindToRenderStep("MobileUIAim", Enum.RenderPriority.Camera.Value + 1, function()
		if not aimOn or spectateOn then
			lastAimPos = nil
			return
		end
		local cam = workspace.CurrentCamera
		if not cam then return end
		local now = os.clock()
		if not lastAimPos or now - lastAim >= OPT.AIM_DELAY then
			local part = getAimPart()
			if not part then
				lastAimPos = nil
				return
			end
			lastAimPos = part.Position
			lastAim = now
		end
		cam.CFrame = CFrame.lookAt(cam.CFrame.Position, lastAimPos)
	end)
end

local function setSpectate(on)
	local cam = workspace.CurrentCamera
	if not cam then return end
	if on then
		local hum = getPlayerHum(targetPlayer)
		if not hum then return end
		spectateOn = true
		cam.CameraSubject = hum
	else
		spectateOn = false
		local h = getHum()
		if skyOn and skyAnchor then
			cam.CameraSubject = skyAnchor
		elseif h then
			cam.CameraSubject = h
		end
	end
end

track(RunService.Heartbeat:Connect(function()
	if not spectateOn then return end
	local cam = workspace.CurrentCamera
	local hum = getPlayerHum(targetPlayer)
	if hum then
		if cam and cam.CameraSubject ~= hum then cam.CameraSubject = hum end
	else
		setSpectate(false)
	end
end))

local function tpBehind()
	local tRoot = getPlayerRoot(targetPlayer)
	local root = getRoot()
	if tRoot and root then
		root.CFrame = tRoot.CFrame * CFrame.new(0, 0, 4)
	end
end

track(player.Idled:Connect(function()
	if not antiAfk then return end
	pcall(function()
		VirtualUser:CaptureController()
		VirtualUser:ClickButton2(Vector2.new())
	end)
end))

local function equipAll()
	local char = player.Character
	local bp = player:FindFirstChildOfClass("Backpack")
	if not char or not bp then return end
	for _, t in ipairs(bp:GetChildren()) do
		if t:IsA("Tool") then pcall(function() t.Parent = char end) end
	end
end

do
	local rejoining = false
	local function doRejoin()
		if rejoining then return end
		rejoining = true
		task.spawn(function()
			task.wait(1)
			pcall(function()
				if #Players:GetPlayers() <= 1 then
					TeleportService:Teleport(game.PlaceId, player)
				else
					TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
				end
			end)
			task.wait(8)
			pcall(function() TeleportService:Teleport(game.PlaceId, player) end)
			rejoining = false
		end)
	end

	track(GuiService.ErrorMessageChanged:Connect(function(msg)
		if autoRejoin and msg ~= "" then doRejoin() end
	end))
	task.spawn(function()
		local ok, overlay = pcall(function()
			return game:GetService("CoreGui"):WaitForChild("RobloxPromptGui", 10):WaitForChild("promptOverlay", 10)
		end)
		if ok and overlay then
			track(overlay.ChildAdded:Connect(function(c)
				if c.Name == "ErrorPrompt" and autoRejoin then doRejoin() end
			end))
		end
	end)
end

local function leaveGame()
	pcall(function() game:Shutdown() end)
	task.wait(0.5)
	pcall(function() player:Kick(tr("ออกเกมแล้ว")) end)
end

local stopPlay, stopRecording, renderReplay

local function resetSpeed()
	speedOn = false
	speedVal = orig and math.clamp(math.floor(orig.speed + 0.5), 8, SPEED_MAX) or 16
	applyStats()
end

local function resetJump()
	jumpOn = false
	jumpVal = orig and math.clamp(math.floor(orig.jump + 0.5), 20, JUMP_MAX) or 50
	applyStats()
end

local function resetFly()
	setFly(false)
	setFlyVal(50)
end

local function resetTp()
	tpOn = false
	tpVal = 10
end

local function restoreOriginals()
	if stopPlay then stopPlay() end
	if stopRecording then stopRecording() end
	speedOn, jumpOn, airJump, tpOn = false, false, false, false
	aimOn = false
	antiAfk = false
	autoRejoin = false
	setInvis(false)
	setSky(false)
	setNoclip(false)
	setFly(false)
	setSpectate(false)
	setFpsBoost(false)
	setFullbright(false)
	espOn = false
	clearEsp()
	setHitbox(false)
	applyStats()
end

do
	local hum = getHum()
	if hum then captureOrig(hum) end
end

track(player.CharacterAdded:Connect(function(char)
	table.clear(noclipParts)
	table.clear(invisStore)
	local hum = char:WaitForChild("Humanoid")
	char:WaitForChild("HumanoidRootPart")
	setSky(false, true)
	task.wait(0.1)
	captureOrig(hum)
	applyStats()
	if flyOn then startFly() end
	if spectateOn then setSpectate(false) end
end))

track(UserInputService.JumpRequest:Connect(function()
	if not airJump or flyOn then return end
	local hum = getHum()
	if hum then hum:ChangeState(Enum.HumanoidStateType.Jumping) end
end))

local function saveSettings()
	local data = {
		lang = lang, speed = speedVal, jump = jumpVal, fly = flyVal,
		tp = tpVal, aim = aimRange, hud = statsHudOn,
		hitbox = hitboxSize, hbPlayers = hitboxPlayers, hbMobs = hitboxMobs,
	}
	local ok = pcall(function()
		writefile(OPT.SAVE_FILE, HttpService:JSONEncode(data))
	end)
	return ok
end

local function loadSettings(startup)
	local ok, raw = pcall(function() return readfile(OPT.SAVE_FILE) end)
	if not ok or type(raw) ~= "string" then return false end
	local ok2, data = pcall(function() return HttpService:JSONDecode(raw) end)
	if not ok2 or type(data) ~= "table" then return false end
	if data.lang == "th" or data.lang == "en" then lang = data.lang end
	if type(data.fly) == "number" then flyVal = math.clamp(math.floor(data.fly), 10, FLY_MAX) end
	if type(data.tp) == "number" then tpVal = math.clamp(math.floor(data.tp), 1, TPWALK_MAX) end
	if type(data.aim) == "number" then aimRange = math.clamp(math.floor(data.aim), 1, AIM_RANGE_MAX) end
	if type(data.hud) == "boolean" then statsHudOn = data.hud end
	if type(data.hitbox) == "number" then hitboxSize = math.clamp(math.floor(data.hitbox), 1, HB_MAX) end
	if type(data.hbPlayers) == "boolean" then hitboxPlayers = data.hbPlayers end
	if type(data.hbMobs) == "boolean" then hitboxMobs = data.hbMobs end
	if not startup then
		if type(data.speed) == "number" then speedVal = math.clamp(math.floor(data.speed), 8, SPEED_MAX) end
		if type(data.jump) == "number" then jumpVal = math.clamp(math.floor(data.jump), 20, JUMP_MAX) end
		applyStats()
		hudApply()
		flyHudRefresh()
	end
	return true
end
loadSettings(true)
openBtn.Text = tr("เมนู")
title.Text = tr("เมนู")

local function styleToggle(btn, on)
	btn.Text = on and "ON" or "OFF"
	btn.BackgroundColor3 = on and GREEN or GRAY
end

local function makeToggleButton(parent)
	local b = Instance.new("TextButton")
	b.AnchorPoint = Vector2.new(1, 0)
	b.Position = UDim2.new(1, -8, 0, 8)
	b.Size = UDim2.fromOffset(52, 30)
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamBold
	b.TextSize = 14
	b.Parent = parent
	round(b, 10)
	return b
end

local function gridRow(parent, order, cols, h)
	local row = Instance.new("Frame")
	row.LayoutOrder = order
	row.Size = UDim2.new(1, -8, 0, h)
	row.BackgroundTransparency = 1
	row.Parent = parent

	local lay = Instance.new("UIListLayout")
	lay.FillDirection = Enum.FillDirection.Horizontal
	lay.SortOrder = Enum.SortOrder.LayoutOrder
	lay.Padding = UDim.new(0, 8)
	lay.Parent = row

	local cells = {}
	for i = 1, cols do
		local c = Instance.new("Frame")
		c.LayoutOrder = i
		c.Size = UDim2.new(1 / cols, -8 * (cols - 1) / cols, 1, 0)
		c.BackgroundTransparency = 1
		c.Parent = row
		cells[i] = c
	end
	return cells, row
end

local function makeSwitchCard(cell, name, getOn, setOn)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(1, -72, 1, 0)
	label.Text = tr(name)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 14
	label.TextWrapped = true
	label.Parent = card

	local toggle = makeToggleButton(card)
	toggle.Position = UDim2.new(1, -8, 0.5, -15)
	styleToggle(toggle, getOn())
	toggle.MouseButton1Click:Connect(function()
		setOn(not getOn())
		styleToggle(toggle, getOn())
	end)
	return card
end

local function makeCellButton(cell, text, color)
	local b = Instance.new("TextButton")
	b.Size = UDim2.fromScale(1, 1)
	b.BackgroundColor3 = color
	b.Text = text
	b.TextColor3 = WHITE
	b.Font = Enum.Font.GothamMedium
	b.TextSize = 14
	b.TextWrapped = true
	b.Parent = cell
	round(b, 12)
	return b
end

local function makeNumberCard(cell, name, minV, maxV, getV, setV)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 0)
	label.Size = UDim2.new(1, -100, 1, 0)
	label.Text = tr(name) .. " (" .. tr("สูงสุด") .. " " .. maxV .. ")"
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 13
	label.TextWrapped = true
	label.Parent = card

	local box = Instance.new("TextBox")
	box.AnchorPoint = Vector2.new(1, 0.5)
	box.Position = UDim2.new(1, -8, 0.5, 0)
	box.Size = UDim2.fromOffset(84, 34)
	box.BackgroundColor3 = BG
	box.Text = tostring(getV())
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 15
	box.ClearTextOnFocus = true
	box.Parent = card
	round(box, 10)

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			setV(math.clamp(math.floor(n + 0.5), minV, maxV))
		end
		box.Text = tostring(getV())
	end)
	return card
end

local function makeSlider(parent, y, minV, maxV, startV, onChange)
	local hit = Instance.new("TextButton")
	hit.BackgroundTransparency = 1
	hit.Text = ""
	hit.AutoButtonColor = false
	hit.Position = UDim2.fromOffset(8, y)
	hit.Size = UDim2.new(1, -16, 0, 34)
	hit.Parent = parent

	local bar = Instance.new("Frame")
	bar.AnchorPoint = Vector2.new(0, 0.5)
	bar.Position = UDim2.new(0, 10, 0.5, 0)
	bar.Size = UDim2.new(1, -20, 0, 10)
	bar.BackgroundColor3 = BG
	bar.Parent = hit
	round(bar, 5)

	local fill = Instance.new("Frame")
	fill.BackgroundColor3 = ACCENT
	fill.Parent = bar
	round(fill, 5)

	local knob = Instance.new("Frame")
	knob.AnchorPoint = Vector2.new(0.5, 0.5)
	knob.Size = UDim2.fromOffset(24, 24)
	knob.BackgroundColor3 = WHITE
	knob.Parent = bar
	round(knob, 12)

	local function setFrac(f)
		f = math.clamp(f, 0, 1)
		fill.Size = UDim2.new(f, 0, 1, 0)
		knob.Position = UDim2.new(f, 0, 0.5, 0)
		return math.floor(minV + f * (maxV - minV) + 0.5)
	end

	local function setValue(val)
		setFrac((math.clamp(val, minV, maxV) - minV) / (maxV - minV))
	end
	setValue(startV)

	local dragging, dragInput = false, nil
	local function update(input)
		local f = (input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X
		onChange(setFrac(f))
	end

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1
			or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragInput = input
			scroll.ScrollingEnabled = false
			update(input)
		end
	end)

	table.insert(connections, UserInputService.InputChanged:Connect(function(input)
		if dragging and (input == dragInput
			or input.UserInputType == Enum.UserInputType.MouseMovement) then
			update(input)
		end
	end))

	table.insert(connections, UserInputService.InputEnded:Connect(function(input)
		if dragging and (input == dragInput
			or input.UserInputType == Enum.UserInputType.MouseButton1) then
			dragging = false
			scroll.ScrollingEnabled = true
		end
	end))

	return setValue
end

local function makeStatCard(cell, name, minV, maxV, cfg)
	local card = Instance.new("Frame")
	card.Size = UDim2.fromScale(1, 1)
	card.BackgroundColor3 = BG2
	card.Parent = cell
	round(card, 12)
	outline(card, BORDER, 1)

	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Position = UDim2.fromOffset(10, 8)
	label.Size = UDim2.new(1, -72, 0, 30)
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.TextColor3 = WHITE
	label.Font = Enum.Font.GothamBold
	label.TextSize = 15
	label.TextTruncate = Enum.TextTruncate.AtEnd
	label.Parent = card

	local toggle = makeToggleButton(card)

	local box = Instance.new("TextBox")
	box.Position = UDim2.fromOffset(10, 84)
	box.Size = UDim2.new(0.4, -15, 0, 34)
	box.BackgroundColor3 = BG
	box.PlaceholderText = tr("พิมพ์ตัวเลข")
	box.PlaceholderColor3 = Color3.fromRGB(130, 130, 140)
	box.TextColor3 = WHITE
	box.Font = Enum.Font.GothamBold
	box.TextSize = 15
	box.ClearTextOnFocus = true
	box.Text = tostring(cfg.get())
	box.Parent = card
	round(box, 10)

	local function labelText(v)
		return tr(name) .. " " .. v .. " /" .. maxV
	end

	local setSlider = makeSlider(card, 40, minV, maxV, cfg.get(), function(val)
		cfg.setVal(val)
		label.Text = labelText(val)
		box.Text = tostring(val)
	end)

	local resetBtn = Instance.new("TextButton")
	resetBtn.AnchorPoint = Vector2.new(1, 0)
	resetBtn.Position = UDim2.new(1, -10, 0, 84)
	resetBtn.Size = UDim2.new(0.6, -15, 0, 34)
	resetBtn.BackgroundColor3 = BG
	resetBtn.Text = tr("รีเซ็ต") .. " " .. tr(name)
	resetBtn.TextColor3 = WHITE
	resetBtn.Font = Enum.Font.GothamMedium
	resetBtn.TextSize = 13
	resetBtn.TextTruncate = Enum.TextTruncate.AtEnd
	resetBtn.Parent = card
	round(resetBtn, 10)

	local function refresh()
		label.Text = labelText(cfg.get())
		styleToggle(toggle, cfg.isOn())
		setSlider(cfg.get())
		box.Text = tostring(cfg.get())
	end

	box.FocusLost:Connect(function()
		local n = tonumber(box.Text)
		if n then
			cfg.setVal(math.clamp(math.floor(n + 0.5), minV, maxV))
		end
		refresh()
	end)

	toggle.MouseButton1Click:Connect(function()
		cfg.setOn(not cfg.isOn())
		styleToggle(toggle, cfg.isOn())
	end)

	resetBtn.MouseButton1Click:Connect(function()
		cfg.reset()
		refresh()
	end)

	refresh()
	return refresh
end

do
	local VIM = nil
	pcall(function() VIM = game:GetService("VirtualInputManager") end)

	local rec = {frames = {}, events = {}, duration = 0}
	local recording, playing = false, false
	local replayLoop = false
	local recStart = 0
	local recConns = {}
	local active = {}
	local held = {}
	local heldKeys = {}
	local playStart, playF, playE = 0, 1, 1
	local nextId = 0

	local function getInset()
		local ok, inset = pcall(function() return GuiService:GetGuiInset() end)
		return ok and inset or Vector2.new(0, 0)
	end

	local function objInset(obj)
		local sg = obj:FindFirstAncestorWhichIsA("ScreenGui")
		if sg and sg.IgnoreGuiInset then return Vector2.new(0, 0) end
		return getInset()
	end

	local function objCenter(obj)
		return obj.AbsolutePosition + obj.AbsoluteSize / 2 + objInset(obj)
	end

	local function isShown(o)
		local cur = o
		while cur and cur ~= playerGui do
			if cur:IsA("GuiObject") and not cur.Visible then return false end
			if cur:IsA("ScreenGui") and not cur.Enabled then return false end
			cur = cur.Parent
		end
		return true
	end

	local function pickTarget(pos)
		local screenPt = Vector2.new(pos.X, pos.Y) + getInset()
		local cam = workspace.CurrentCamera
		local vp = cam and cam.ViewportSize or Vector2.new(1000, 1000)
		local best, bestScore = nil, math.huge
		for _, o in ipairs(playerGui:GetDescendants()) do
			if o:IsA("GuiObject") and (o:IsA("GuiButton") or o.Active)
				and not o:IsDescendantOf(gui)
				and not o:FindFirstAncestor("TouchGui")
				and isShown(o) then
				local size = o.AbsoluteSize
				local area = size.X * size.Y
				local isBtn = o:IsA("GuiButton")
				if area > 0 and (isBtn or area < vp.X * vp.Y * 0.5) then
					local c = objCenter(o)
					local half = size / 2
					if math.abs(screenPt.X - c.X) <= half.X and math.abs(screenPt.Y - c.Y) <= half.Y then
						local score = (isBtn and 0 or 1e9) + area
						if score < bestScore then
							best, bestScore = o, score
						end
					end
				end
			end
		end
		return best
	end

	local function pathOf(o)
		local t = {}
		local cur = o
		while cur and cur ~= playerGui do
			table.insert(t, 1, cur.Name)
			cur = cur.Parent
		end
		return t
	end

	local function resolve(ev)
		local o = ev.obj
		if o and o.Parent and o:IsDescendantOf(playerGui) then return o end
		if not ev.path then return nil end
		local cur = playerGui
		for _, n in ipairs(ev.path) do
			cur = cur and cur:FindFirstChild(n)
		end
		if cur and cur ~= playerGui and cur:IsA("GuiObject") then return cur end
		return nil
	end

	local function recAdd(ev)
		ev.t = os.clock() - recStart
		rec.events[#rec.events + 1] = ev
	end

	local function emitPointer(kind, info, pos)
		local screenPt = Vector2.new(pos.X, pos.Y) + getInset()
		local ev = {k = kind, id = info.id, sx = screenPt.X, sy = screenPt.Y}
		local o = info.obj
		if o and o.Parent then
			local c = objCenter(o)
			ev.obj = o
			ev.path = info.path
			ev.ox = screenPt.X - c.X
			ev.oy = screenPt.Y - c.Y
		end
		info.lastPos = pos
		recAdd(ev)
	end

	local dot = Instance.new("Frame")
	dot.AnchorPoint = Vector2.new(0.5, 0.5)
	dot.Size = UDim2.fromOffset(18, 18)
	dot.BackgroundColor3 = Color3.fromRGB(255, 60, 60)
	dot.BackgroundTransparency = 0.2
	dot.Visible = false
	dot.Active = false
	dot.ZIndex = 100
	dot.Parent = gui
	round(dot, 9)
	outline(dot, WHITE, 2)

	local function moveDot(p)
		dot.Position = UDim2.fromOffset(p.X, p.Y)
		dot.Visible = true
	end

	function stopRecording()
		if not recording then return end
		recording = false
		pcall(function() RunService:UnbindFromRenderStep("MobileUIRec") end)
		for _, info in pairs(active) do
			if info.lastPos then emitPointer("up", info, info.lastPos) end
		end
		table.clear(active)
		for _, c in ipairs(recConns) do c:Disconnect() end
		table.clear(recConns)
		rec.duration = os.clock() - recStart
	end

	function stopPlay()
		if not playing then return end
		playing = false
		pcall(function() RunService:UnbindFromRenderStep("MobileUIPlay") end)
		if VIM then
			for key in pairs(heldKeys) do
				pcall(function() VIM:SendKeyEvent(false, key, false, game) end)
			end
			for _, h in pairs(held) do
				pcall(function() VIM:SendMouseButtonEvent(h.pos.X, h.pos.Y, 0, false, game, 0) end)
			end
		end
		table.clear(heldKeys)
		table.clear(held)
		dot.Visible = false
		local hum = getHum()
		if hum then pcall(function() hum:Move(Vector3.zero, false) end) end
	end

	local function startRecording()
		if recording or playing then return end
		rec = {frames = {}, events = {}, duration = 0}
		table.clear(active)
		recording = true
		recStart = os.clock()

		RunService:BindToRenderStep("MobileUIRec", Enum.RenderPriority.Camera.Value + 2, function()
			local root, hum = getRoot(), getHum()
			local cam = workspace.CurrentCamera
			if not root or not cam then return end
			local t = os.clock() - recStart
			if t > OPT.REC_MAX then
				stopRecording()
				return
			end
			rec.frames[#rec.frames + 1] = {
				t = t, cf = root.CFrame, cam = cam.CFrame,
				md = hum and hum.MoveDirection or Vector3.zero,
			}
		end)

		local downKeys = {}
		table.insert(recConns, UserInputService.InputBegan:Connect(function(input, gp)
			local ut = input.UserInputType
			if ut == Enum.UserInputType.Keyboard then
				if gp then return end
				downKeys[input.KeyCode] = true
				recAdd({k = "key", a = input.KeyCode, b = true})
			elseif ut == Enum.UserInputType.Touch or ut == Enum.UserInputType.MouseButton1 then
				local obj = pickTarget(input.Position)
				if obj then
					nextId += 1
					local info = {id = nextId, obj = obj, path = pathOf(obj), lastMove = 0}
					active[input] = info
					emitPointer("down", info, input.Position)
				end
			end
		end))

		table.insert(recConns, UserInputService.InputChanged:Connect(function(input)
			local ut = input.UserInputType
			if ut == Enum.UserInputType.Touch then
				local info = active[input]
				if info and os.clock() - info.lastMove >= 0.02 then
					info.lastMove = os.clock()
					emitPointer("move", info, input.Position)
				end
			elseif ut == Enum.UserInputType.MouseMovement then
				for inp, info in pairs(active) do
					if inp.UserInputType == Enum.UserInputType.MouseButton1
						and os.clock() - info.lastMove >= 0.02 then
						info.lastMove = os.clock()
						emitPointer("move", info, input.Position)
					end
				end
			end
		end))

		table.insert(recConns, UserInputService.InputEnded:Connect(function(input)
			local ut = input.UserInputType
			if ut == Enum.UserInputType.Keyboard then
				if downKeys[input.KeyCode] then
					downKeys[input.KeyCode] = nil
					recAdd({k = "key", a = input.KeyCode, b = false})
				end
			else
				local info = active[input]
				if info then
					active[input] = nil
					emitPointer("up", info, input.Position)
				end
			end
		end))

		table.insert(recConns, UserInputService.JumpRequest:Connect(function()
			recAdd({k = "jump"})
		end))

		local hooked = {}
		local function hookTool(tool)
			if hooked[tool] then return end
			hooked[tool] = true
			table.insert(recConns, tool.Activated:Connect(function()
				recAdd({k = "activate", a = tool.Name})
			end))
		end
		local function hookContainer(cont)
			if not cont then return end
			for _, c in ipairs(cont:GetChildren()) do
				if c:IsA("Tool") then hookTool(c) end
			end
			table.insert(recConns, cont.ChildAdded:Connect(function(c)
				if c:IsA("Tool") then hookTool(c) end
			end))
		end
		local char = player.Character
		hookContainer(char)
		hookContainer(player:FindFirstChildOfClass("Backpack"))
		if char then
			table.insert(recConns, char.ChildAdded:Connect(function(c)
				if c:IsA("Tool") then recAdd({k = "equip", a = c.Name}) end
			end))
			table.insert(recConns, char.ChildRemoved:Connect(function(c)
				if c:IsA("Tool") then recAdd({k = "unequip", a = c.Name}) end
			end))
		end
	end

	local function eventScreenPos(ev)
		local h = held[ev.id]
		local o = (h and h.obj) or resolve(ev)
		local p
		if o and ev.ox then
			p = objCenter(o) + Vector2.new(ev.ox, ev.oy)
		else
			p = Vector2.new(ev.sx, ev.sy)
		end
		return p + Vector2.new(OPT.CLICK_DX or 0, OPT.CLICK_DY or 0), o
	end

	-- หา ScrollingFrame ที่นิ้วลากอยู่ (VIM ลากเมาส์ไม่เลื่อนเมนูบนมือถือ เลยเลื่อนเองด้วย CanvasPosition)
	local function findScroller(o, p)
		if o then
			if o:IsA("ScrollingFrame") then return o end
			local a = o:FindFirstAncestorWhichIsA("ScrollingFrame")
			if a and not a:IsDescendantOf(gui) then return a end
		end
		local best, bestArea = nil, math.huge
		for _, f in ipairs(playerGui:GetDescendants()) do
			if f:IsA("ScrollingFrame") and not f:IsDescendantOf(gui) and isShown(f) then
				local size = f.AbsoluteSize
				local c = objCenter(f)
				if math.abs(p.X - c.X) <= size.X / 2 and math.abs(p.Y - c.Y) <= size.Y / 2 then
					local area = size.X * size.Y
					if area > 0 and area < bestArea then best, bestArea = f, area end
				end
			end
		end
		return best
	end

	local function dragScroll(h, p)
		local sf = h.sf
		if not sf or not sf.Parent then return end
		local d = p - h.start
		if not h.dragging then
			if d.Magnitude < 8 then return end
			h.dragging = true
		end
		local maxP = sf.AbsoluteCanvasSize - sf.AbsoluteWindowSize
		local np = h.sfStart - d
		local dir = sf.ScrollingDirection
		local x, y = h.sfStart.X, h.sfStart.Y
		if dir ~= Enum.ScrollingDirection.Y then x = math.clamp(np.X, 0, math.max(maxP.X, 0)) end
		if dir ~= Enum.ScrollingDirection.X then y = math.clamp(np.Y, 0, math.max(maxP.Y, 0)) end
		sf.CanvasPosition = Vector2.new(x, y)
	end

	local function doEvent(ev)
		local k = ev.k
		if k == "key" then
			if VIM then pcall(function() VIM:SendKeyEvent(ev.b, ev.a, false, game) end) end
			heldKeys[ev.a] = ev.b or nil
		elseif k == "down" then
			local p, o = eventScreenPos(ev)
			held[ev.id] = {obj = o, pos = p, start = p}
			local sf = findScroller(o, p)
			if sf then
				held[ev.id].sf = sf
				held[ev.id].sfStart = sf.CanvasPosition
			end
			moveDot(p)
			if VIM then
				pcall(function() VIM:SendMouseMoveEvent(p.X, p.Y, game) end)
				pcall(function() VIM:SendMouseButtonEvent(p.X, p.Y, 0, true, game, 0) end)
			end
		elseif k == "move" then
			local h = held[ev.id]
			if not h then return end
			local p = eventScreenPos(ev)
			h.pos = p
			dragScroll(h, p)
			moveDot(p)
			if VIM then pcall(function() VIM:SendMouseMoveEvent(p.X, p.Y, game) end) end
		elseif k == "up" then
			local p = eventScreenPos(ev)
			if held[ev.id] then dragScroll(held[ev.id], p) end
			moveDot(p)
			if VIM then
				pcall(function() VIM:SendMouseMoveEvent(p.X, p.Y, game) end)
				pcall(function() VIM:SendMouseButtonEvent(p.X, p.Y, 0, false, game, 0) end)
			end
			held[ev.id] = nil
			task.delay(0.15, function()
				if not next(held) then dot.Visible = false end
			end)
		elseif k == "jump" then
			local hum = getHum()
			if hum then
				hum.Jump = true
				pcall(function() hum:ChangeState(Enum.HumanoidStateType.Jumping) end)
			end
		elseif k == "equip" then
			local hum = getHum()
			local bp = player:FindFirstChildOfClass("Backpack")
			local tool = bp and bp:FindFirstChild(ev.a)
			if hum and tool and tool:IsA("Tool") then
				pcall(function() hum:EquipTool(tool) end)
			end
		elseif k == "unequip" then
			local hum = getHum()
			if hum then pcall(function() hum:UnequipTools() end) end
		elseif k == "activate" then
			local char = player.Character
			local tool = char and char:FindFirstChild(ev.a)
			if tool and tool:IsA("Tool") then pcall(function() tool:Activate() end) end
		end
	end

	local function startPlay()
		if playing or recording or #rec.frames < 2 then return end
		playing = true
		playStart = os.clock()
		playF, playE = 1, 1
		table.clear(held)
		local frames, events = rec.frames, rec.events
		local duration = math.min(rec.duration, frames[#frames].t)

		pcall(function() RunService:UnbindFromRenderStep("MobileUIPlay") end)
		RunService:BindToRenderStep("MobileUIPlay", Enum.RenderPriority.Camera.Value + 3, function()
			local root, hum = getRoot(), getHum()
			local cam = workspace.CurrentCamera
			if not root or not cam then return end
			local el = os.clock() - playStart

			while events[playE] and events[playE].t <= el do
				doEvent(events[playE])
				playE += 1
			end

			if el >= duration then
				if replayLoop then
					for _, h in pairs(held) do
						if VIM then pcall(function() VIM:SendMouseButtonEvent(h.pos.X, h.pos.Y, 0, false, game, 0) end) end
					end
					table.clear(held)
					playStart = os.clock()
					playF, playE = 1, 1
				else
					stopPlay()
				end
				return
			end

			while frames[playF + 1] and frames[playF + 1].t <= el do playF += 1 end
			local f1 = frames[playF]
			local f2 = frames[playF + 1] or f1
			local cf, camcf, vel = f1.cf, f1.cam, Vector3.zero
			if f2 ~= f1 then
				local span = f2.t - f1.t
				if span > 0 then
					local a = math.clamp((el - f1.t) / span, 0, 1)
					local dist = (f2.cf.Position - f1.cf.Position).Magnitude
					if dist < 25 then
						cf = f1.cf:Lerp(f2.cf, a)
						vel = (f2.cf.Position - f1.cf.Position) / span
					end
					camcf = f1.cam:Lerp(f2.cam, a)
				end
			end
			root.CFrame = cf
			root.AssemblyLinearVelocity = vel
			cam.CFrame = camcf
			if hum then pcall(function() hum:Move(f1.md, false) end) end
		end)
	end

	function renderReplay(parent)
		local r1 = gridRow(parent, 1, 1, 52)
		local sCard = Instance.new("Frame")
		sCard.Size = UDim2.fromScale(1, 1)
		sCard.BackgroundColor3 = BG2
		sCard.Parent = r1[1]
		round(sCard, 12)
		outline(sCard, BORDER, 1)
		local status = Instance.new("TextLabel")
		status.BackgroundTransparency = 1
		status.Position = UDim2.fromOffset(12, 0)
		status.Size = UDim2.new(1, -24, 1, 0)
		status.TextXAlignment = Enum.TextXAlignment.Left
		status.TextColor3 = WHITE
		status.Font = Enum.Font.GothamBold
		status.TextSize = 16
		status.TextWrapped = true
		status.Parent = sCard

		local r2 = gridRow(parent, 2, 2, 52)
		local recBtn = makeCellButton(r2[1], "", GREEN)
		local runBtn = makeCellButton(r2[2], "", GRAY)

		local r3 = gridRow(parent, 3, 2, 46)
		makeSwitchCard(r3[1], "วนซ้ำ",
			function() return replayLoop end,
			function(b) replayLoop = b end)
		local clearBtn = makeCellButton(r3[2], tr("ล้างที่อัด"), GRAY)

		local r4 = gridRow(parent, 4, 2, 48)
		makeNumberCard(r4[1], "ชดเชยจุดกด แกน X (px)", -300, 300,
			function() return math.floor(OPT.CLICK_DX or 0) end,
			function(v) OPT.CLICK_DX = v end)
		makeNumberCard(r4[2], "ชดเชยจุดกด แกน Y (px)", -300, 300,
			function() return math.floor(OPT.CLICK_DY or 0) end,
			function(v) OPT.CLICK_DY = v end)

		local flash = nil
		local function refresh()
			local hasRec = #rec.frames > 1
			if recording then
				status.Text = tr("กำลังอัด") .. "  " .. string.format("%.1f", os.clock() - recStart) .. " " .. tr("วิ")
			elseif playing then
				status.Text = tr("กำลังรัน") .. "  " .. string.format("%.1f", os.clock() - playStart) .. " / "
					.. string.format("%.1f", rec.duration) .. " " .. tr("วิ")
			elseif flash and os.clock() < flash then
				status.Text = tr("ต้องเริ่มอัดก่อนถึงจะรันได้")
			elseif hasRec then
				status.Text = tr("พร้อมรัน") .. "  (" .. string.format("%.1f", rec.duration) .. " " .. tr("วิ") .. ")"
			else
				status.Text = tr("ยังไม่มีการอัด")
			end

			recBtn.Text = recording and tr("หยุดอัด") or tr("เริ่มอัด")
			recBtn.BackgroundColor3 = recording and RED or GREEN
			runBtn.Text = playing and tr("หยุดรัน") or tr("รัน")
			if playing then
				runBtn.BackgroundColor3 = RED
			elseif hasRec and not recording then
				runBtn.BackgroundColor3 = ACCENT
			else
				runBtn.BackgroundColor3 = GRAY
			end
		end

		recBtn.MouseButton1Click:Connect(function()
			if recording then
				stopRecording()
			else
				if playing then stopPlay() end
				startRecording()
			end
			refresh()
		end)
		runBtn.MouseButton1Click:Connect(function()
			if playing then
				stopPlay()
			elseif not recording and #rec.frames > 1 then
				startPlay()
			else
				flash = os.clock() + 2
			end
			refresh()
		end)
		clearBtn.MouseButton1Click:Connect(function()
			stopPlay()
			stopRecording()
			rec = {frames = {}, events = {}, duration = 0}
			refresh()
		end)

		table.insert(connections, RunService.Heartbeat:Connect(refresh))
		refresh()
	end
end

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
	makeNumberCard(r5[2], "ขนาด Hitbox", 1, HB_MAX,
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
end

local replayTabOn = false
local function setReplayTab(on)
	replayTabOn = on
	if not on then
		stopRecording()
		stopPlay()
		if currentKey == "replay" then currentKey = "misc" end
	end
	buildTabButtons()
	if on then showTab("replay") else showTab(currentKey) end
end

local function renderMisc(parent)
	local r1 = gridRow(parent, 1, 3, 46)
	makeSwitchCard(r1[1], "กันหลุด (Anti-AFK)",
		function() return antiAfk end,
		function(b) antiAfk = b end)
	makeSwitchCard(r1[2], "Auto Rejoin",
		function() return autoRejoin end,
		function(b) autoRejoin = b end)
	makeSwitchCard(r1[3], "ลอยฟ้า 100000",
		function() return skyOn end,
		function(b) setSky(b) end)

	local r2 = gridRow(parent, 2, 3, 48)
	local eq = makeCellButton(r2[1], tr("ถือของทั้งหมด (Equip All)"), ACCENT)
	eq.MouseButton1Click:Connect(equipAll)
	makeSwitchCard(r2[2], "บูส FPS",
		function() return fpsOn end,
		function(b) setFpsBoost(b) end)
	local rejoin = makeCellButton(r2[3], tr("เข้าเซิร์ฟใหม่ (Rejoin)"), ORANGE)
	rejoin.MouseButton1Click:Connect(function()
		pcall(function()
			if #Players:GetPlayers() <= 1 then
				TeleportService:Teleport(game.PlaceId, player)
			else
				TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, player)
			end
		end)
	end)

	local r3 = gridRow(parent, 3, 3, 48)
	local leave = makeCellButton(r3[1], tr("ออกเกมทันที"), Color3.fromRGB(170, 60, 60))
	leave.MouseButton1Click:Connect(leaveGame)
	local rp = makeCellButton(r3[2], tr("รีเพลย์การเล่น"), replayTabOn and GREEN or ACCENT)
	rp.MouseButton1Click:Connect(function()
		setReplayTab(not replayTabOn)
	end)
end

-- ===== Look / Theme module =====
do
	local Lighting = game:GetService("Lighting")
	local LOOK_FILE = "MobileUI_look.json"
	local function C(r, g, b) return Color3.fromRGB(r, g, b) end

	local DEF = {bg = BG, bg2 = BG2, accent = ACCENT, border = BORDER, text = WHITE}
	local PRESETS = {
		{name = "Dark", bg = C(28, 28, 32), bg2 = C(45, 45, 52), accent = C(80, 160, 255), text = C(255, 255, 255)},
		{name = "Light", bg = C(240, 240, 245), bg2 = C(222, 222, 232), accent = C(60, 120, 230), text = C(25, 25, 30)},
		{name = "Amethyst", bg = C(30, 22, 42), bg2 = C(50, 38, 70), accent = C(160, 100, 255), text = C(255, 255, 255)},
		{name = "Aqua", bg = C(18, 36, 40), bg2 = C(28, 58, 64), accent = C(0, 200, 200), text = C(255, 255, 255)},
		{name = "Blood", bg = C(36, 18, 20), bg2 = C(60, 30, 34), accent = C(220, 40, 50), text = C(255, 255, 255)},
	}
	local FONTS = {"Default", "Arial", "SourceSans", "Ubuntu", "FredokaOne", "Nunito", "Code", "Cartoon", "Arcade"}

	local look = {
		bg = DEF.bg, bg2 = DEF.bg2, accent = DEF.accent, text = DEF.text,
		logo = "", bgimg = "", imgT = 60, uiT = 0, acrylic = false, font = "Default", key = "",
	}
	local function border() return look.bg2:Lerp(look.text, 0.18) end

	local function toHex(c)
		return string.format("#%02X%02X%02X",
			math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
	end
	local function parseColor(s)
		s = tostring(s or "")
		local r, g, b = s:match("^%s*#?(%x%x)(%x%x)(%x%x)%s*$")
		if r then return C(tonumber(r, 16), tonumber(g, 16), tonumber(b, 16)) end
		local a, b2, c2 = s:match("^%s*(%d+)[%s,]+(%d+)[%s,]+(%d+)%s*$")
		if a then
			return C(math.clamp(tonumber(a), 0, 255), math.clamp(tonumber(b2), 0, 255), math.clamp(tonumber(c2), 0, 255))
		end
		return nil
	end

	local function saveLook()
		pcall(function()
			writefile(LOOK_FILE, HttpService:JSONEncode({
				bg = toHex(look.bg), bg2 = toHex(look.bg2), accent = toHex(look.accent), text = toHex(look.text),
				logo = look.logo, bgimg = look.bgimg, imgT = look.imgT, uiT = look.uiT,
				acrylic = look.acrylic, font = look.font, key = look.key,
			}))
		end)
	end
	local function loadLook()
		local ok, raw = pcall(function() return readfile(LOOK_FILE) end)
		if not ok or type(raw) ~= "string" then return end
		local ok2, d = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok2 or type(d) ~= "table" then return end
		for _, k in ipairs({"bg", "bg2", "accent", "text"}) do
			local c = parseColor(d[k])
			if c then look[k] = c end
		end
		if type(d.logo) == "string" then look.logo = d.logo end
		if type(d.bgimg) == "string" then look.bgimg = d.bgimg end
		if type(d.imgT) == "number" then look.imgT = math.clamp(d.imgT, 0, 100) end
		if type(d.uiT) == "number" then look.uiT = math.clamp(d.uiT, 0, 90) end
		if type(d.acrylic) == "boolean" then look.acrylic = d.acrylic end
		if type(d.font) == "string" and table.find(FONTS, d.font) then look.font = d.font end
		if type(d.key) == "string" then look.key = d.key end
	end

	-- ---- recolor pass (remembers each object's original value) ----
	local rec = setmetatable({}, {__mode = "k"})
	local function setProp(o, prop, fn)
		local r = rec[o]
		if not r then r = {}; rec[o] = r end
		local p = r[prop]
		local cur = o[prop]
		local base = (p and p.applied == cur) and p.orig or cur
		local new = fn(base)
		if new == nil then new = base end
		if not p then p = {}; r[prop] = p end
		p.orig = base
		p.applied = new
		if cur ~= new then o[prop] = new end
	end
	local function mapColor(c)
		if c == DEF.bg then return look.bg end
		if c == DEF.bg2 then return look.bg2 end
		if c == DEF.accent then return look.accent end
		if c == DEF.border then return border() end
		return nil
	end

	local logoImg = Instance.new("ImageLabel")
	logoImg.Name = "SoraLogo"
	logoImg.BackgroundTransparency = 1
	logoImg.Position = UDim2.fromOffset(12, 10)
	logoImg.Size = UDim2.fromOffset(32, 32)
	logoImg.ZIndex = 3
	logoImg.Visible = false
	logoImg.Parent = panel
	round(logoImg, 8)

	local bgImg = Instance.new("ImageLabel")
	bgImg.Name = "SoraBg"
	bgImg.BackgroundTransparency = 1
	bgImg.Size = UDim2.fromScale(1, 1)
	bgImg.ScaleType = Enum.ScaleType.Crop
	bgImg.ZIndex = 0
	bgImg.Visible = false
	bgImg.Parent = panel
	round(bgImg, 18)

	local function panelT()
		return look.acrylic and math.max(look.uiT / 100, 0.25) or look.uiT / 100
	end

	local function applyLook()
		local pt = panelT()
		for _, o in ipairs(gui:GetDescendants()) do
			if o:IsA("GuiObject") and o ~= logoImg and o ~= bgImg then
				setProp(o, "BackgroundColor3", mapColor)
				local isText = o:IsA("TextLabel") or o:IsA("TextButton") or o:IsA("TextBox")
				if isText then
					setProp(o, "TextColor3", function(base)
						if base == DEF.text then
							local bgc = o.BackgroundColor3
							if o.BackgroundTransparency >= 0.99 or bgc == look.bg or bgc == look.bg2 then
								return look.text
							end
							return nil
						end
						return mapColor(base)
					end)
					if look.font ~= "Default" then
						setProp(o, "Font", function() return Enum.Font[look.font] end)
					else
						setProp(o, "Font", function(base) return base end)
					end
				end
				if o == panel then
					setProp(o, "BackgroundTransparency", function(base)
						if base == 0 then return pt end
					end)
				elseif o:IsDescendantOf(panel) then
					setProp(o, "BackgroundTransparency", function(base)
						local bgc = o.BackgroundColor3
						if base == 0 and (bgc == look.bg or bgc == look.bg2) then return pt * 0.6 end
					end)
				end
			elseif o:IsA("UIStroke") then
				setProp(o, "Color", mapColor)
			end
		end
	end
	OPT.themeHook = applyLook

	-- ---- images ----
	local imgMsg = ""
	local function resolveImage(s, cb)
		s = tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")
		if s == "" then cb(nil); return end
		if tonumber(s) then cb("rbxassetid://" .. math.floor(tonumber(s))); return end
		if s:match("^rbxassetid://") or s:match("^rbxasset://") then cb(s); return end
		if s:match("^https?://") then
			task.spawn(function()
				local ok, res = pcall(function()
					local data = game:HttpGet(s)
					local name = "SoraHub_img_" .. tostring(#s) .. "_" .. tostring(#data) .. ".png"
					writefile(name, data)
					return getcustomasset(name)
				end)
				if ok and res then cb(res) else imgMsg = "โหลดรูปจากลิงก์ไม่ได้"; cb(nil) end
			end)
			return
		end
		cb(nil)
	end

	local function applyImages()
		resolveImage(look.logo, function(a)
			logoImg.Image = a or ""
			logoImg.Visible = a ~= nil
			title.Position = UDim2.fromOffset(a and 52 or 16, 8)
			title.Size = UDim2.new(1, a and -156 or -120, 0, 36)
		end)
		resolveImage(look.bgimg, function(a)
			bgImg.Image = a or ""
			bgImg.Visible = a ~= nil
		end)
		bgImg.ImageTransparency = look.imgT / 100
	end

	-- ---- blur ----
	local blur
	local function blurRefresh()
		local want = look.acrylic and panel.Visible
		if want and not blur then
			blur = Instance.new("BlurEffect")
			blur.Name = "SoraAcrylicBlur"
			blur.Size = 18
			blur.Parent = Lighting
		end
		if blur then blur.Enabled = want end
	end
	track(panel:GetPropertyChangedSignal("Visible"):Connect(blurRefresh))

	-- ---- toggle key ----
	local capturing, captureDone = false, nil
	track(UserInputService.InputBegan:Connect(function(input, gp)
		if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
		if capturing then
			capturing = false
			if input.KeyCode ~= Enum.KeyCode.Escape then
				look.key = input.KeyCode.Name
				saveLook()
			end
			if captureDone then captureDone() end
			return
		end
		if gp or look.key == "" then return end
		if UserInputService:GetFocusedTextBox() then return end
		if input.KeyCode.Name == look.key and OPT.togglePanel then OPT.togglePanel() end
	end))

	OPT.cleanupLook = function()
		if blur then pcall(function() blur:Destroy() end); blur = nil end
	end

	loadLook()
	applyImages()
	blurRefresh()

	-- ---- Settings UI ----
	function OPT.renderLook(parent, startOrder)
		local order = startOrder
		local function nextOrder() order = order + 1; return order end
		local boxes = {}

		local function header(text)
			local cells = gridRow(parent, nextOrder(), 1, 28)
			local l = Instance.new("TextLabel")
			l.Size = UDim2.fromScale(1, 1)
			l.BackgroundTransparency = 1
			l.Text = tr(text)
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.TextColor3 = ACCENT
			l.Font = Enum.Font.GothamBold
			l.TextSize = 16
			l.Parent = cells[1]
		end

		local msg
		local function say(t) if msg then msg.Text = tr(t) end end

		local function boxCard(cell, name, initial, boxW, onCommit)
			local card = Instance.new("Frame")
			card.Size = UDim2.fromScale(1, 1)
			card.BackgroundColor3 = BG2
			card.Parent = cell
			round(card, 12)
			outline(card, BORDER, 1)
			local label = Instance.new("TextLabel")
			label.BackgroundTransparency = 1
			label.Position = UDim2.fromOffset(10, 0)
			label.Size = UDim2.new(1, -(boxW + 20), 1, 0)
			label.Text = tr(name)
			label.TextXAlignment = Enum.TextXAlignment.Left
			label.TextColor3 = WHITE
			label.Font = Enum.Font.GothamBold
			label.TextSize = 13
			label.TextWrapped = true
			label.Parent = card
			local box = Instance.new("TextBox")
			box.AnchorPoint = Vector2.new(1, 0.5)
			box.Position = UDim2.new(1, -8, 0.5, 0)
			box.Size = UDim2.fromOffset(boxW, 34)
			box.BackgroundColor3 = BG
			box.Text = initial
			box.PlaceholderText = ""
			box.TextColor3 = WHITE
			box.Font = Enum.Font.GothamMedium
			box.TextSize = 13
			box.ClearTextOnFocus = false
			box.TextTruncate = Enum.TextTruncate.AtEnd
			box.Parent = card
			round(box, 10)
			box.FocusLost:Connect(function() onCommit(box) end)
			return box
		end

		local function changed()
			applyLook()
			saveLook()
		end

		-- presets
		header("🎨 ธีมสี")
		local pr1 = gridRow(parent, nextOrder(), 3, 44)
		local pr2 = gridRow(parent, nextOrder(), 3, 44)
		local function refreshBoxes()
			for k, b in pairs(boxes) do b.Text = toHex(look[k]) end
		end
		for i, p in ipairs(PRESETS) do
			local cell = (i <= 3) and pr1[i] or pr2[i - 3]
			local b = makeCellButton(cell, p.name, p.accent)
			b.TextColor3 = (p.name == "Light") and Color3.new(1, 1, 1) or WHITE
			b.MouseButton1Click:Connect(function()
				look.bg, look.bg2, look.accent, look.text = p.bg, p.bg2, p.accent, p.text
				refreshBoxes()
				changed()
			end)
		end
		local fields = {
			{"accent", "สีหลัก (Accent)"}, {"bg", "สีพื้นหลัง"},
			{"bg2", "สีแถบ/ปุ่ม (Tab)"}, {"text", "สีตัวอักษร"},
		}
		local hr1 = gridRow(parent, nextOrder(), 2, 48)
		local hr2 = gridRow(parent, nextOrder(), 2, 48)
		for i, f in ipairs(fields) do
			local cell = (i <= 2) and hr1[i] or hr2[i - 2]
			boxes[f[1]] = boxCard(cell, f[2], toHex(look[f[1]]), 84, function(box)
				local c = parseColor(box.Text)
				if c then look[f[1]] = c; changed() end
				box.Text = toHex(look[f[1]])
			end)
		end

		-- images
		header("🖼 รูปภาพและโลโก้")
		local ir1 = gridRow(parent, nextOrder(), 1, 48)
		boxCard(ir1[1], "โลโก้ (ไอดี/ลิงก์รูป)", look.logo, 150, function(box)
			look.logo = box.Text
			imgMsg = ""
			applyImages(); saveLook()
			task.delay(1.5, function() say(imgMsg) end)
		end)
		local ir2 = gridRow(parent, nextOrder(), 1, 48)
		boxCard(ir2[1], "รูปพื้นหลัง (ไอดี/ลิงก์)", look.bgimg, 150, function(box)
			look.bgimg = box.Text
			imgMsg = ""
			applyImages(); saveLook()
			task.delay(1.5, function() say(imgMsg) end)
		end)
		local ir3 = gridRow(parent, nextOrder(), 1, 48)
		makeNumberCard(ir3[1], "ความโปร่งรูปพื้นหลัง %", 0, 100,
			function() return math.floor(look.imgT) end,
			function(v) look.imgT = v; applyImages(); saveLook() end)

		-- effects
		header("✨ ความโปร่งแสงและเอฟเฟกต์")
		local er1 = gridRow(parent, nextOrder(), 1, 48)
		makeNumberCard(er1[1], "ความโปร่ง UI %", 0, 90,
			function() return math.floor(look.uiT) end,
			function(v) look.uiT = v; changed() end)
		local er2 = gridRow(parent, nextOrder(), 2, 48)
		makeSwitchCard(er2[1], "Acrylic (เบลอ)",
			function() return look.acrylic end,
			function(b) look.acrylic = b; blurRefresh(); changed() end)
		local fontBtn = makeCellButton(er2[2], "Font: " .. look.font, GRAY)
		fontBtn.MouseButton1Click:Connect(function()
			local i = table.find(FONTS, look.font) or 1
			look.font = FONTS[i % #FONTS + 1]
			fontBtn.Text = "Font: " .. look.font
			changed()
		end)
		local er3 = gridRow(parent, nextOrder(), 2, 48)
		local keyBtn = makeCellButton(er3[1], "", ACCENT)
		local function keyText()
			keyBtn.Text = tr("ปุ่มเปิด/ปิดเมนู") .. ": " .. (look.key == "" and "-" or look.key)
		end
		keyText()
		keyBtn.MouseButton1Click:Connect(function()
			capturing = true
			captureDone = keyText
			keyBtn.Text = tr("กดปุ่มที่ต้องการ (Esc ยกเลิก)")
		end)
		local clearKey = makeCellButton(er3[2], tr("ล้างปุ่ม"), GRAY)
		clearKey.MouseButton1Click:Connect(function()
			capturing = false
			look.key = ""
			keyText(); saveLook()
		end)

		local rr = gridRow(parent, nextOrder(), 1, 44)
		local resetBtn = makeCellButton(rr[1], tr("รีเซ็ตหน้าตาทั้งหมด"), RED)
		resetBtn.MouseButton1Click:Connect(function()
			look.bg, look.bg2, look.accent, look.text = DEF.bg, DEF.bg2, DEF.accent, DEF.text
			look.logo, look.bgimg, look.imgT, look.uiT = "", "", 60, 0
			look.acrylic, look.font, look.key = false, "Default", ""
			blurRefresh(); applyImages(); changed()
			showTab(currentKey)
		end)

		local mr = gridRow(parent, nextOrder(), 1, 30)
		msg = Instance.new("TextLabel")
		msg.Size = UDim2.fromScale(1, 1)
		msg.BackgroundTransparency = 1
		msg.Text = ""
		msg.TextColor3 = Color3.fromRGB(170, 170, 180)
		msg.Font = Enum.Font.GothamMedium
		msg.TextSize = 13
		msg.Parent = mr[1]
	end
end

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

local baseTabs = {
	{key = "info", name = "ข้อมูลผู้เล่น", render = renderProfile},
	{key = "player", name = "ผู้เล่น", render = renderStats},
	{key = "view", name = "มุมมอง", render = renderView},
	{key = "misc", name = "อื่นๆ", render = renderMisc},
	{key = "replay", name = "รีเพลย์", render = function(p) renderReplay(p) end},
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