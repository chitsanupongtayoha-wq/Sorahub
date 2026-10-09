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
