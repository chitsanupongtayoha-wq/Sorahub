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
	["เพื่อน"] = "Friends", ["รีเฟรชรายชื่อเพื่อน"] = "Refresh friends", ["ดูโปรไฟล์"] = "Profile",
	["ตามไป (กดจอย)"] = "Join", ["เพื่อนคนนี้เข้าร่วมไม่ได้"] = "Cannot join this friend",
	["กำลังเข้าร่วม..."] = "Joining...", ["เข้าร่วมไม่สำเร็จ (เกมอาจไม่อนุญาต)"] = "Join failed (game may block it)",
	["โหลดรายชื่อเพื่อนไม่ได้"] = "Could not load friends", ["เพื่อนที่อยู่ในเกม"] = "Friends in game",
	["ป้องกันปลิว"] = "Anti-fling",
	["ย้ายเซิร์ฟ (ต้องไม่โดนตี 1 นาที + เลือดเต็ม)"] = "Hop server (no hits for 1 min + full HP)",
	["ไม่พบตัวละคร"] = "Character not found", ["เลือดยังไม่เต็ม"] = "Health not full",
	["พร้อมย้ายเซิร์ฟ"] = "Ready to hop", ["กำลังย้ายเซิร์ฟ..."] = "Hopping...", ["ย้ายไม่สำเร็จ"] = "Hop failed", ["กล้องทะลุ + ซูมไม่จำกัด"] = "NC cam (through walls, unlimited zoom)", ["ขนาด Hitbox ผู้เล่น"] = "Hitbox size: players", ["ขนาด Hitbox ม็อบ"] = "Hitbox size: mobs",
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
