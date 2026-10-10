-- Sora Hub loader: ดึงไฟล์ย่อยจาก src/ มาต่อกันแล้วรันเป็นสคริปต์เดียว
local BASE = "https://raw.githubusercontent.com/chitsanupongtayoha-wq/Sorahub/main/src/"
local PARTS = {
	"core", "tab_profile", "features_a", "tab_replay", "features_b", "safety", "detector",
	"tab_player", "tab_view", "tab_misc", "look", "tab_settings", "tab_friends", "tab_check", "tab_report", "tab_fruit", "main",
}

local bodies, pending, failed = {}, #PARTS, nil
for i, name in ipairs(PARTS) do
	task.spawn(function()
		local ok, body = pcall(function() return game:HttpGet(BASE .. name .. ".lua?v=" .. os.time()) end)
		if ok and type(body) == "string" and #body > 0 then
			bodies[i] = body
		else
			failed = failed or name
		end
		pending -= 1
	end)
end

local t0 = os.clock()
while pending > 0 and not failed and os.clock() - t0 < 30 do task.wait() end
if failed or pending > 0 then
	warn("[Sora Hub] โหลดไฟล์ไม่สำเร็จ: " .. tostring(failed or "timeout"))
	return
end

local fn, err = loadstring(table.concat(bodies, "\n"))
if not fn then
	warn("[Sora Hub] โค้ดผิดพลาด: " .. tostring(err))
	return
end
fn()
