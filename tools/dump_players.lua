-- ดูว่าเกมเก็บข้อมูลผู้เล่น (เช่น ชื่อผลปีศาจ) ไว้ตรงไหน แล้วพิมพ์ลง console (F9)
-- อ่านอย่างเดียว ไม่แก้อะไรในเกม
local Players = game:GetService("Players")
local lines = {}
local function out(s) table.insert(lines, s) end

local function dumpAttrs(inst, indent)
	for k, v in pairs(inst:GetAttributes()) do
		out(indent .. "@" .. tostring(k) .. " = " .. tostring(v))
	end
end

local function dumpValues(inst, indent, depth)
	if depth > 3 then return end
	for _, c in ipairs(inst:GetChildren()) do
		if c:IsA("ValueBase") then
			out(indent .. c.Name .. " (" .. c.ClassName .. ") = " .. tostring(c.Value))
		elseif c:IsA("Folder") or c:IsA("Configuration") then
			out(indent .. c.Name .. "/")
			dumpAttrs(c, indent .. "  ")
			dumpValues(c, indent .. "  ", depth + 1)
		end
	end
end

for _, pl in ipairs(Players:GetPlayers()) do
	out("=== " .. pl.DisplayName .. " (@" .. pl.Name .. ") ===")
	dumpAttrs(pl, "  [Player] ")
	dumpValues(pl, "  [Player] ", 0)
	local char = pl.Character
	if char then
		dumpAttrs(char, "  [Char] ")
		dumpValues(char, "  [Char] ", 0)
		local tool = char:FindFirstChildOfClass("Tool")
		if tool then out("  [Tool] " .. tool.Name) end
	end
end

local text = table.concat(lines, "\n")
print(text)
pcall(function() writefile("player_dump.txt", text) end)
print("[dump] เสร็จแล้ว (บันทึกที่ player_dump.txt ถ้า executor รองรับ)")
