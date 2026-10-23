-- 离线运行：lua tests/test_pubg.lua；所有 G HUB 输入输出均使用替身。
local modifiers, logs, primaryEnabled = {}, {}, false
local slept = 0
function EnablePrimaryMouseButtonEvents(enabled) primaryEnabled = enabled end
function IsModifierPressed(key) return modifiers[key] == true end
function OutputLogMessage(message, ...) logs[#logs + 1] = string.format(message, ...) end
function IsMouseButtonPressed() return false end
function Sleep(ms) slept = slept + ms end

local scriptFile = assert(io.open("PUBG.lua", "r"))
local source = scriptFile:read("*a")
scriptFile:close()
local function loadCatalog(edit)
    -- 在表定义后、其余初始化前更换测试数据，检查加载时是否仍依赖固定枪号。
    local changed, replacements = source:gsub("(GunData%s*=%s*%b{})", function(block)
        return block .. "\n" .. edit .. "\n"
    end, 1)
    assert(replacements == 1)
    logs = {}
    assert((loadstring or load)(changed))()
end
loadCatalog([[
GunData = {
    [1] = { name="AKM", interval=99, timeOrigin=1, ballistic={{1,0},{40,40}} },
    [2] = { name="M416", interval=85, timeOrigin=1, ballistic={{1,0},{40,30}} },
    [7] = { name="Beryl M762", interval=86, timeOrigin=1, ballistic={{1,0},{40,45}} },
}
UserConfig.currentGun = 7
]])
assert(logs[#logs]:find(GunData[UserConfig.currentGun].name, 1, true))
assert(primaryEnabled)
UserConfig.gunSwitch = { [8] = 1, [7] = 2 }
UserConfig.currentGun = 7

local function press(button, family)
    OnEvent("MOUSE_BUTTON_PRESSED", button, family or "mouse")
end

local initialLogs = #logs
press(8)
press(7)
assert(UserConfig.currentGun == 7 and #logs == initialLogs)
modifiers.ctrl = true
press(8)
assert(UserConfig.currentGun == 7 and #logs == initialLogs)
modifiers.ctrl, modifiers.alt = false, true
press(8)
assert(UserConfig.currentGun == 1)
assert(logs[#logs]:find("[1] AKM", 1, true))
press(7)
assert(UserConfig.currentGun == 2)
assert(logs[#logs]:find("[2] M416", 1, true))
modifiers.ctrl = true
press(8)
assert(UserConfig.currentGun == 1)
modifiers.ctrl, modifiers.alt = false, true
press(7)
assert(UserConfig.currentGun == 2)
modifiers.ctrl = true
press(8)
assert(UserConfig.currentGun == 1)
assert(logs[#logs]:find("[1] AKM", 1, true))
press(7)
assert(UserConfig.currentGun == 2)
assert(logs[#logs]:find("[2] M416", 1, true))

OnEvent("MOUSE_BUTTON_RELEASED", 8, "mouse")
press(8, "kb")
OnEvent("G_PRESSED", 8, "kb")
press(4)
assert(UserConfig.currentGun == 2)
UserConfig.gunSwitch[8] = 999
press(8)
assert(UserConfig.currentGun == 2)
assert(logs[#logs]:find("999", 1, true))
UserConfig.gunSwitch[8] = 7
press(8)
assert(UserConfig.currentGun == 7)

OnEvent("PROFILE_DEACTIVATED")
assert(not primaryEnabled)
press(7)
assert(UserConfig.currentGun == 7)
OnEvent("PROFILE_ACTIVATED")
assert(primaryEnabled)
assert(logs[#logs]:find("[7] Beryl M762", 1, true))

-- Alt+DPI 切枪优先于倍镜切换；其他按钮的原倍镜逻辑仍正常。
UserConfig.scopeToggleButton = 8
local baseScope = UserConfig.scope
press(8)
assert(UserConfig.scope == baseScope and slept == 0)
modifiers.ctrl, modifiers.alt = false, false
UserConfig.scopeToggleButton = 6
press(8)
assert(UserConfig.scope == baseScope and slept == 0)
press(6)
assert(UserConfig.scope == UserConfig.scope4x)
assert(slept == UserConfig.scopeHoldMs)

loadCatalog([[
GunData = {
    [100] = { name="Custom A", interval=85, timeOrigin=1, ballistic={{1,0},{40,30}} },
    [500] = { name="Custom B", interval=100, ballistic={{1,0},{40,25}} },
}
UserConfig.currentGun = 100
UserConfig.gunSwitch = { [8]=100, [7]=500 }
]])
assert(logs[#logs]:find("[100] Custom A", 1, true))
assert(GunData[100].timeOrigin == 1 and GunData[500].timeOrigin == nil)
modifiers.ctrl, modifiers.alt = true, true
press(7)
assert(UserConfig.currentGun == 500)
assert(logs[#logs]:find("[500] Custom B", 1, true))

loadCatalog("GunData = {}")
assert(logs[#logs]:find("不存在", 1, true))
local previousGun = UserConfig.currentGun
press(8)
assert(UserConfig.currentGun == previousGun)
assert(logs[#logs]:find("切枪失败", 1, true))
function IsMouseButtonPressed() return true end
press(1)
assert(logs[#logs]:find("枪号不存在", 1, true))
print("PASS: sparse/empty catalogs, configurable shortcuts, current-gun logs, invalid target, event filters, profile lifecycle and scope priority")
