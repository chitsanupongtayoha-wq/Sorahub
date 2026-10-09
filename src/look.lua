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
