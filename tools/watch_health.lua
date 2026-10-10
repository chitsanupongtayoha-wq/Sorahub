-- อ่านอย่างเดียว: ดูว่าใครมีเลือดเป็น NaN และเป็นต่อเนื่องหรือไม่ (ไม่แก้อะไรในเกม)
local Players = game:GetService("Players")
local seen = {}
local t0 = os.clock()
local function line(s) print(("[%5.1fs] "):format(os.clock() - t0) .. s) end
while os.clock() - t0 < 60 do
	for _, p in ipairs(Players:GetPlayers()) do
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hum then
			local h, m = hum.Health, hum.MaxHealth
			local nan = (h ~= h) or (m ~= m)
			local s = seen[p] or {n = 0, ok = 0, last = nil}
			seen[p] = s
			if nan then s.n += 1 else s.ok += 1 end
			if s.last ~= nan then
				s.last = nan
				line(p.Name .. (nan and " -> NaN" or " -> ปกติ") .. " (hp " .. tostring(h) .. "/" .. tostring(m)
					.. ", state " .. tostring(hum:GetState()) .. ", attrs " .. #hum:GetAttributes() .. ")")
			end
		end
	end
	task.wait(0.5)
end
for p, s in pairs(seen) do
	if s.n > 0 then
		line(("สรุป %s: NaN %d ครั้ง / ปกติ %d ครั้ง -> %s"):format(p.Name, s.n, s.ok,
			s.ok == 0 and "NaN ตลอด (ตั้งใจ=โปรอมตะ)" or "สลับไปมา (อาจเป็นบั๊ก/เกมรีเซ็ต)"))
	end
end
