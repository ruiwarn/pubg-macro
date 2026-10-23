-- Soldier76 G HUB v2.6.3 · G6 按下 500ms 后立即切换 · Lua 5.1 兼容
-- AK 已合适时，只调前面的 M4 专用后段倍率；切换声音由 scopeFeedback 控制。
UserConfig = {
    -- 【1】当前枪号：必须与你游戏里实际拿的枪一致，不会自动识别
    currentGun = 7,
    -- 1=AKM       2=M416       3=AUG/QBZ        4=G36C       5=SCAR-L
    -- 6=M16A4     7=Beryl M762 8=DP-28      9=UMP45     10=Vector
    -- 11=Micro UZI 12=Tommy Gun
    -- 13=FAMAS   14=K2       15=AUG       16=Groza    17=ACE32
    -- 18=MP5K    19=P90；13-19 的下压力仍为估算，6 只适用于三连发。

    -- 【2】整体下压力：影响基础镜和 4x；这是脚本倍率，不是游戏灵敏度
    -- 弹着点整体上爬：增大，例如 1.00 -> 1.05；整体下沉：减小到 0.95
    -- 每次 0.05，接近合适后每次 0.01；不要同时改 DPI/游戏灵敏度/配件。
    sensitivity = 3.3,

    -- 【M4 专用】AK 已合适时不要动上面的整体力度，只调这两个值
    -- 第 11 个弹道点起，下压力乘 0.85（暂减 15%）；只影响 M416，前段和 AK 不变。
    -- 仍下沉：0.85 -> 0.80；改后上爬：0.85 -> 0.90；1.0 可恢复旧力度。
    m416LateScale = 0.85,
    m416LateStartShot = 11,

    -- 【3】只在“基础镜已调好，4x 仍不合适”时调：仅影响 G6 开启的 4x
    -- 上爬增大，例如 3.9 -> 4.0；下沉减小到 3.8；与 sensitivity 相乘。
    scope4x = 5.4,

    -- 【4】基础镜系数：红点/全息先保持 1.0，主要通过 sensitivity 调力度
    -- 与 sensitivity 相乘；G6 开启 4x 时由 scope4x 替代，不再额外相乘。
    scope = 1.0,

    -- 【5】高低提示音：Windows“切换键”需开启；高音/Scroll Lock 亮=4x，低音/灭=基础镜
    -- false 恢复无反馈；true 会使用 Scroll Lock 状态，不要将它绑定为游戏操作。
    scopeFeedback = false,

    -- 【6】G6 计时：按下后到达此毫秒数就立即切换，不等松开。
    -- G HUB 无法轮询 G6 状态，所以提前松开也会在 500ms 时切换；切换前松开左键。
    scopeHoldMs = 500,

    -- ---------------- 不常改 ----------------
    scopeToggleButton = 0, -- G6 狙击键按下到达门槛：基础镜 <-> 4x，原来是6,关闭4倍模式改成0
    allowFallback = false, -- 保持 false；枪号错误时不下拉
    power = 5,            -- 仅枪号不存在且 allowFallback=true 时生效，正常调参不用它
}

-- ============================================================
-- 2026-09-13 核对 kiccer/Soldier76 master: 1b5a2bc630361b7954fbc7805c1ac94e587e4a94
-- 12 把逐发曲线源自 2020-11-07 的上游表；不是 2026 游戏版本实测数据。
-- 部分射击间隔按官方补丁公布 RPM 更新；依据详见 DATA_AUDIT.md。
-- 先按右键，再按左键：按逐发累计曲线平滑输出整数位移。
-- 单个 PUBG 配置：G6 狙击键切换基础倍镜 / 4x，切回配置恢复基础倍镜。
-- 切换前先松开左键；G HUB 同步事件循环不能在开火循环内处理 G6 事件。
-- G6 在本机原配置中已取消分配；请保持取消分配，避免同时触发原生 DPI Shift。
-- ============================================================


GunData = {
    [1]  = { name = "AKM",       interval = 99,  ballistic = { {1,0},{2,42},{5,25},{10,32},{40,40} } },
    [2]  = { name = "M416",      interval = 85,  ballistic = { {1,0},{2,35},{4,18},{10,24},{15,32},{30,30},{40,37} } },
    [3]  = { name = "QBZ",       interval = 92,  ballistic = { {1,0},{2,34},{5,18},{10,22},{15,32},{20,34},{40,36} } },
    [4]  = { name = "G36C",      interval = 86,  ballistic = { {1,0},{2,40},{5,16},{10,26},{15,30},{20,34},{40,36} } },
    [5]  = { name = "SCAR-L",    interval = 60000/650, ballistic = { {1,0},{2,30},{5,20},{10,24},{15,28},{40,32} } },
    [6]  = { name = "M16A4",     interval = 60000/800, burstShots = 3, ballistic = { {1,0},{5,20},{40,24} } },
    [7]  = { name = "Beryl M762",interval = 86,  ballistic = { {1,0},{2,44},{3,24},{5,28},{10,33},{15,45},{30,47},{40,51} } },
    [8]  = { name = "DP-28",     interval = 100, ballistic = { {1,0},{2,30},{5,20},{47,30} } },
    [9]  = { name = "UMP45",     interval = 94,  ballistic = { {1,0},{5,18},{15,30},{35,32} } },
    [10] = { name = "Vector",    interval = 55,  ballistic = { {1,0},{6,16},{10,20},{13,24},{15,28},{20,32},{33,34} } },
    [11] = { name = "Micro UZI", interval = 46,  ballistic = { {1,0},{2,13},{10,12},{15,20},{35,30} } },
    [12] = { name = "Tommy Gun", interval = 84,  ballistic = { {1,0},{3,20},{6,21},{8,24},{10,30},{15,40},{50,45} } },
    -- 以下 7 把的力度曲线仍是旧版估算，不能当成上游实测；间隔另有部分官方依据。
    [13] = { name = "FAMAS",     interval = 60000/900, ballistic = { {1,0},{5,20},{40,26} } },
    [14] = { name = "K2",        interval = 60000/700, ballistic = { {1,0},{5,22},{40,28} } },
    [15] = { name = "AUG",       interval = 60000/720, ballistic = { {1,0},{5,20},{40,26} } },
    [16] = { name = "Groza",     interval = 86,  ballistic = { {1,0},{2,40},{5,26},{40,42} } },
    [17] = { name = "ACE32",     interval = 60000/680, ballistic = { {1,0},{2,38},{5,24},{40,40} } },
    [18] = { name = "MP5K",      interval = 60,  ballistic = { {1,0},{6,14},{40,28} } },
    [19] = { name = "P90",       interval = 60000/1000, ballistic = { {1,0},{6,16},{40,30} } },
}

-- 上游 auto() 用 ceil(t/interval)+1，第 1 个零点是 t=0 的锚点。
-- 因此原版 12 把枪的第 2 个值从开火后第一个间隔开始施加，不能先空等一发。
-- 估算项没有上游时序依据，保留旧时序；自定义曲线未设置时也按 timeOrigin=0。
for gunKey = 1, 12 do GunData[gunKey].timeOrigin = 1 end

-- 时间与输出限制集中定义，避免分散的魔数。
local TICK_MS = 16
local MAX_STALL_MS = 250  -- 长暂停后停止本轮，避免把积压位移一次性打出去
local MAX_STEP = 127     -- 单次位移保守分块；每块都重新检查左右键
local MAX_TICK_MOVE = 2048 -- 异常配置造成巨量位移时取消，避免分块循环长时间占用
local FALLBACK_LIMIT_MS = 10000
local ScopeBase = UserConfig.scope
local profileActive = true
local scope4xEnabled = false

local function IsFiniteNonnegative(value)
    return type(value) == "number" and value == value
        and value >= 0 and value < math.huge
end

local function ApplyScope()
    if scope4xEnabled then
        UserConfig.scope = UserConfig.scope4x
    else
        UserConfig.scope = ScopeBase
    end
end

-- 等待模拟按键的真实状态，只发送一次，避免重复按键将状态又切回去。
local function SetScopeMode(enabled)
    if UserConfig.scopeFeedback then
        if IsKeyLockOn("scrolllock") ~= enabled then
            PressAndReleaseKey("scrolllock")
            local attempts = 0
            while IsKeyLockOn("scrolllock") ~= enabled and attempts < 10 do
                Sleep(10)
                attempts = attempts + 1
            end
        end
        local actual = IsKeyLockOn("scrolllock")
        if actual ~= enabled then
            OutputLogMessage("Scroll Lock 未确认切换，倍率跟随实际锁定状态\n")
        end
        enabled = actual
    end
    scope4xEnabled = enabled
    ApplyScope()
end

-- 每轮只计算一次前缀和；timeOrigin=1 跳过上游的零起点，不跳过位移。
-- 前缀和直接给出累计目标，因此跨过一个或多个逐发边界都不会漏算/多算。
local function BuildBallistic(gun, gunKey)
    if type(gun) ~= "table" or not IsFiniteNonnegative(gun.interval)
        or gun.interval == 0 or type(gun.ballistic) ~= "table"
        or #gun.ballistic == 0 then
        return nil
    end
    local prefix = { [0] = 0 }
    local count = 0
    local lateStart, lateScale = math.huge, 1
    if gunKey == 2 then
        lateStart, lateScale = UserConfig.m416LateStartShot, UserConfig.m416LateScale
        if not IsFiniteNonnegative(lateScale) or not IsFiniteNonnegative(lateStart)
            or lateStart < 2 or lateStart > 1000 or lateStart ~= math.floor(lateStart) then
            return nil
        end
    end
    -- ipairs 会静默忽略空洞后面的条目；先确认确实是连续数组。
    local segments = 0
    for key in pairs(gun.ballistic) do
        if type(key) ~= "number" or key ~= math.floor(key) or key < 1
            or key > #gun.ballistic then return nil end
        segments = segments + 1
    end
    if segments ~= #gun.ballistic then return nil end
    for _, segment in ipairs(gun.ballistic) do
        if type(segment) ~= "table" then return nil end
        local last, amount = segment[1], segment[2]
        if not IsFiniteNonnegative(last) or last ~= math.floor(last)
            or last <= count or last > 1000 or not IsFiniteNonnegative(amount) then
            return nil
        end
        for shot = count + 1, last do
            local adjusted = amount
            if shot >= lateStart then adjusted = adjusted * lateScale end
            prefix[shot] = prefix[shot - 1] + adjusted
            if not IsFiniteNonnegative(prefix[shot]) then return nil end
        end
        count = last
    end
    local origin = gun.timeOrigin or 0
    if origin ~= 0 and origin ~= 1 then return nil end
    if origin == 1 and (count < 2 or prefix[1] ~= 0) then return nil end
    if gun.burstShots ~= nil then
        if not IsFiniteNonnegative(gun.burstShots)
            or gun.burstShots ~= math.floor(gun.burstShots)
            or gun.burstShots <= origin or gun.burstShots > count then return nil end
        count = gun.burstShots
    end
    return prefix, count, origin
end

local function Main()
    if not profileActive then return end
    -- 保留用户验证过的状态编号：1=左键，3=右键，2=中键。
    local waited = 0
    while not IsMouseButtonPressed(1) and waited < 50 do
        Sleep(10)
        waited = waited + 10
    end
    if not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3) then return end

    -- 若用户直接改变 Scroll Lock，下一轮跟随真实状态，避免提示与倍率脱节。
    if UserConfig.scopeFeedback then
        local actual = IsKeyLockOn("scrolllock")
        if actual ~= scope4xEnabled then
            scope4xEnabled = actual
            ApplyScope()
        end
    end
    local scale = UserConfig.scope
    if not IsFiniteNonnegative(scale) or not IsFiniteNonnegative(UserConfig.sensitivity) then
        OutputLogMessage("配置无效：检查 scope / sensitivity\n")
        return
    end
    scale = scale * UserConfig.sensitivity
    if not IsFiniteNonnegative(scale) or scale == 0 then return end

    local gun = GunData[UserConfig.currentGun]
    local prefix, count, origin
    local duration = FALLBACK_LIMIT_MS
    if gun then
        prefix, count, origin = BuildBallistic(gun, UserConfig.currentGun)
        if not prefix or not IsFiniteNonnegative(prefix[count] * scale) then
            OutputLogMessage("弹道配置无效，本轮取消\n")
            return
        end
        duration = (count - origin) * gun.interval
        if not IsFiniteNonnegative(duration) then
            OutputLogMessage("弹道时长无效，本轮取消\n")
            return
        end
    elseif UserConfig.allowFallback ~= true then
        OutputLogMessage("枪号不存在，请检查 currentGun；恒定力需显式开启 allowFallback\n")
        return
    elseif not IsFiniteNonnegative(UserConfig.power)
        or not IsFiniteNonnegative(UserConfig.power * scale * duration / TICK_MS) then
        OutputLogMessage("兜底力度无效，本轮取消\n")
        return
    end

    local startTime = GetRunningTime()
    local lastTime = startTime
    local sent = 0
    while profileActive and IsMouseButtonPressed(1) and IsMouseButtonPressed(3) do
        -- 连发中途直接改锁定状态时停止；松开左键后以新倍率重新开始。
        if UserConfig.scopeFeedback and IsKeyLockOn("scrolllock") ~= scope4xEnabled then break end
        local now = GetRunningTime()
        if now < lastTime or now - lastTime > MAX_STALL_MS then
            OutputLogMessage("计时异常或长暂停，本轮停止；松开左键后重新开始\n")
            break
        end
        lastTime = now
        local elapsed = math.min(now - startTime, duration)
        local target
        if prefix then
            local curveTime = elapsed + origin * gun.interval
            local complete = math.min(math.floor(curveTime / gun.interval), count)
            target = prefix[complete]
            if complete < count then
                local fraction = (curveTime - complete * gun.interval) / gun.interval
                target = target + (prefix[complete + 1] - prefix[complete]) * fraction
            end
            target = target * scale
        else
            target = elapsed / TICK_MS * UserConfig.power * scale
        end

        -- 输出累计目标的整数部分，余量由累计目标隐式保留，不会逐 tick 丢失。
        -- 极小容差仅消除二进制浮点表示导致的整数边界误差。
        local pending = math.floor(target + 1e-9) - sent
        if pending > MAX_TICK_MOVE then
            OutputLogMessage("单次待输出位移过大，请检查力度配置\n")
            break
        end
        while pending > 0 do
            if not IsMouseButtonPressed(1) or not IsMouseButtonPressed(3) then return end
            local step = math.min(pending, MAX_STEP)
            MoveMouseRelative(0, step)
            sent = sent + step
            pending = pending - step
        end
        -- 弹道表用尽后停止，不再无限重复最后一发；松开后下一轮重新计时。
        if elapsed >= duration then break end
        Sleep(TICK_MS)
    end
end

function OnEvent(event, arg, family)
    -- 配置生命周期先处理，不能被开火判断或按键映射跳过。
    if event == "PROFILE_ACTIVATED" or event == "PROFILE_DEACTIVATED" then
        profileActive = event == "PROFILE_ACTIVATED"
        SetScopeMode(false)
        EnablePrimaryMouseButtonEvents(profileActive)
        return
    end
    if not profileActive then return end
    if event ~= "MOUSE_BUTTON_PRESSED" and event ~= "MOUSE_BUTTON_RELEASED" then return end
    if family ~= nil and family ~= "mouse" then return end

    -- 保留本机验证过的事件 2<->3 映射，且只对鼠标事件生效。
    if arg == 2 then arg = 3 elseif arg == 3 then arg = 2 end
    if arg == UserConfig.scopeToggleButton and type(arg) == "number" and arg >= 4 then
        if event ~= "MOUSE_BUTTON_PRESSED" then return end
        local limit = UserConfig.scopeHoldMs
        if not IsFiniteNonnegative(limit) then return end
        Sleep(math.floor(limit))
        local enabled = scope4xEnabled
        if UserConfig.scopeFeedback then enabled = IsKeyLockOn("scrolllock") end
        SetScopeMode(not enabled)
        return
    end
    if event == "MOUSE_BUTTON_PRESSED" and arg == 1 then
        Main()
    end
    -- 不自动按 Tab，不释放脚本未按下的 Ctrl/Shift/Alt。
end

SetScopeMode(false)
EnablePrimaryMouseButtonEvents(true)
