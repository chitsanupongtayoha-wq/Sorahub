-- หาว่าเกมมีวิธี "ทิ้ง/ลบไอเทม" อะไรบ้าง (อ่านอย่างเดียว ไม่กดหรือยิงอะไร)
-- พิมพ์ผลลง console (F9) และเซฟที่ drop_scan.txt ถ้า executor รองรับ
local Players = game:GetService("Players")
local RS = game:GetService("ReplicatedStorage")
local player = Players.LocalPlayer

local keys = {"drop", "discard", "delete", "trash", "remove", "destroy", "sell", "throw", "ทิ้ง", "ลบ"}
local function hit(name)
	local n = tostring(name):lower()
	for _, k in ipairs(keys) do
		if n:find(k, 1, true) then return true end
	end
	return false
end

local lines = {}
local function out(s) table.insert(lines, s) end

out("== Remotes ที่ชื่อเกี่ยวกับทิ้ง/ลบ ==")
for _, root in ipairs({RS, game:GetService("ReplicatedFirst"), workspace}) do
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("RemoteEvent") or d:IsA("RemoteFunction")) and hit(d.Name) then
			out(d.ClassName .. "  " .. d:GetFullName())
		end
	end
end

out("== ปุ่มใน GUI ที่ชื่อ/ข้อความเกี่ยวกับทิ้ง/ลบ ==")
for _, d in ipairs(player.PlayerGui:GetDescendants()) do
	if d:IsA("GuiButton") then
		local txt = d:IsA("TextButton") and d.Text or ""
		if hit(d.Name) or hit(txt) then
			out(d.ClassName .. "  " .. d:GetFullName() .. "  text=" .. txt)
		end
	end
end

out("== ไอเทม (Tool) ใน Backpack ==")
for _, t in ipairs(player.Backpack:GetChildren()) do
	out(t.ClassName .. "  " .. t.Name .. "  CanBeDropped=" .. tostring(t:IsA("Tool") and t.CanBeDropped))
end

local text = table.concat(lines, "\n")
print(text)
pcall(function() writefile("drop_scan.txt", text) end)
print("[scan] เสร็จแล้ว")
