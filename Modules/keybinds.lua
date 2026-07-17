local SCM = select(2, ...)

local Keybinds = {}
SCM.Keybinds = Keybinds

local LSM = LibStub("LibSharedMedia-3.0", true)
local DEFAULT_FONT = "Interface\\AddOns\\SkironCooldownManager\\Media\\fonts\\Expressway.ttf"

-- ── State ─────────────────────────────────────────────────────────────────────

local enabled    = false   -- false = module is off; all hook callbacks return immediately
local keyMap     = nil
-- Persistent cache: survives bonus/override bar changes (skyriding, druid forms, vehicles).
-- Cleared on spec / equipment / macro changes, and on ACTIONBAR_HIDEGRID when off the override bar.
local keyCache   = { spells = {}, items = {}, spellNames = {}, itemNames = {} }
local combatDirty   = false
local rebuildTimer  = nil   -- C_Timer.NewTimer handle; replaced when a longer delay is needed
local rebuildDelay  = 0     -- delay of the currently pending timer
local styleVersion  = 0     -- bumped on display-settings change; skips redundant SetFont calls
local extraHooksSet = false -- hooks for modules that load after this file, set on first login

local function ClearKeyCache()
    wipe(keyCache.spells)
    wipe(keyCache.items)
    wipe(keyCache.spellNames)
    wipe(keyCache.itemNames)
end

-- ── Override bar detection ────────────────────────────────────────────────────

-- Returns true when the action bar has switched away from the player's normal layout,
-- so cache-clearing events (UPDATE_BINDINGS, ACTIONBAR_HIDEGRID) are suppressed.
--
-- Confirmed in TWW 11.x: skyriding uses the bonus bar (GetBonusBarIndex = 11).
-- HasOverrideActionBar / HasVehicleActionBar return nil for skyriding.
local function IsInOverrideBar()
    if C_ActionBar then
        if C_ActionBar.GetBonusBarIndex          and C_ActionBar.GetBonusBarIndex() > 0          then return true end
        if C_ActionBar.HasOverrideActionBar       and C_ActionBar.HasOverrideActionBar()          then return true end
        if C_ActionBar.HasVehicleActionBar        and C_ActionBar.HasVehicleActionBar()           then return true end
        if C_ActionBar.HasTempShapeshiftActionBar and C_ActionBar.HasTempShapeshiftActionBar()    then return true end
        if C_ActionBar.HasExtraActionBar          and C_ActionBar.HasExtraActionBar()             then return true end
    end
    -- Legacy globals (kept for classic/era compat)
    if HasOverrideActionBar and HasOverrideActionBar() then return true end
    if HasVehicleActionBar  and HasVehicleActionBar()  then return true end
    local bar = _G["OverrideActionBar"]
    if bar and bar:IsShown() then return true end
    return false
end

-- ── Key abbreviation ──────────────────────────────────────────────────────────

local abbrevCache = {}
local function AbbreviateKey(key)
    if not key or key == "" then return "" end
    local cached = abbrevCache[key]
    if cached then return cached end
    local orig = key
    key = key:upper()

    key = key:gsub("MOUSE%s*WHEEL%s*UP",   "MWUP")
              :gsub("MOUSE%s*WHEEL%s*DOWN", "MWDN")
              :gsub("MOUSEBUTTON", "MB")
              :gsub("BUTTON",      "MB")

    key = key:gsub("SHIFT%-", "S")
              :gsub("CTRL%-",  "C")
              :gsub("ALT%-",   "A")

    key = key:gsub("MWUP",        "WU")
              :gsub("MWDN",       "WD")
              :gsub("NUMPADPLUS", "N+")
              :gsub("NUMPADMINUS","N%-")
              :gsub("NUMPAD",     "N")
              :gsub("PAGEUP",     "PU")
              :gsub("PAGEDOWN",   "PD")
              :gsub("INSERT",     "Ins")
              :gsub("DELETE",     "Del")
              :gsub("BACKSPACE",  "Bs")
              :gsub("SPACEBAR",   "Sp")
              :gsub("ESCAPE",     "Esc")
              :gsub("ENTER",      "Ent")
              :gsub("HOME",       "Hm")
              :gsub("END",        "En")
              :gsub("TAB",        "Tab")

    local trailing = key:sub(-1) == "-"
    if trailing then
        key = key:sub(1, -2):gsub("%-", "") .. "-"
    else
        key = key:gsub("%-", "")
    end
    abbrevCache[orig] = key
    return key
end

-- ── Spell / item helpers ──────────────────────────────────────────────────────

local function ResolveSpellName(spellID)
    if not spellID or spellID == 0 then return nil end
    local n = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
    return (n and n ~= "") and n or nil
end

local function ResolveSpellIDFromToken(token)
    if not token or token == "" then return nil end
    local n = tonumber(token)
    if n then
        return (C_Spell and C_Spell.DoesSpellExist and C_Spell.DoesSpellExist(n)) and n or nil
    end
    if C_Spell then
        if C_Spell.GetSpellIDForSpellIdentifier then
            local id = C_Spell.GetSpellIDForSpellIdentifier(token)
            if id and id ~= 0 then return id end
        end
        if C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(token)
            if info and info.spellID ~= 0 then return info.spellID end
        end
    end
    return nil
end

local function ResolveItemName(itemID)
    if not itemID or itemID == 0 then return nil end
    local n = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(itemID)
    return (n and n ~= "") and n or nil
end

-- ── Key map stores and queries ────────────────────────────────────────────────

local function StoreSpell(map, spellID, fmtKey, force)
    if not spellID or spellID == 0 or not fmtKey or fmtKey == "" then return end
    if not force and map.spells[spellID] then return end
    map.spells[spellID] = fmtKey
    local name = ResolveSpellName(spellID)
    if name then map.spellNames[name:lower()] = fmtKey end
    if C_Spell then
        local ov = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
        if ov and ov ~= 0 and (force or not map.spells[ov]) then
            map.spells[ov] = fmtKey
            local on = ResolveSpellName(ov)
            if on then map.spellNames[on:lower()] = fmtKey end
        end
        local base = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
        if base and base ~= 0 and (force or not map.spells[base]) then
            map.spells[base] = fmtKey
            local bn = ResolveSpellName(base)
            if bn then map.spellNames[bn:lower()] = fmtKey end
        end
    end
end

local function StoreItem(map, itemID, fmtKey, force)
    if not itemID or itemID == 0 or not fmtKey or fmtKey == "" then return end
    if not force and map.items[itemID] then return end
    map.items[itemID] = fmtKey
    local name = ResolveItemName(itemID)
    if name then map.itemNames[name:lower()] = fmtKey end
end

local function QuerySpell(map, spellID)
    if not map or not spellID then return nil end
    local k = map.spells[spellID]
    if k then return k end
    if C_Spell then
        local ov = C_Spell.GetOverrideSpell and C_Spell.GetOverrideSpell(spellID)
        if ov and map.spells[ov] then return map.spells[ov] end
        local base = C_Spell.GetBaseSpell and C_Spell.GetBaseSpell(spellID)
        if base and map.spells[base] then return map.spells[base] end
    end
    local name = ResolveSpellName(spellID)
    return name and map.spellNames[name:lower()] or nil
end

local function QueryItem(map, itemID)
    if not map or not itemID then return nil end
    local k = map.items[itemID]
    if k then return k end
    local name = ResolveItemName(itemID)
    return name and map.itemNames[name:lower()] or nil
end

-- ── Macro parsing ─────────────────────────────────────────────────────────────

local function TrimStr(s)
    return s and s:match("^%s*(.-)%s*$") or ""
end

local function DropConditionals(s)
    s = TrimStr(s)
    while true do
        local blk = s:match("^(%b[])")
        if not blk then break end
        s = TrimStr(s:sub(#blk + 1))
    end
    return s
end

local function ScrubToken(tok)
    tok = tok:gsub("%[.-%]", ""):gsub("#.*$", ""):gsub("!+", "")
    return TrimStr(tok)
end

local function FirstCastToken(body)
    for line in body:gmatch("[^\r\n]+") do
        local cmd, rest = TrimStr(line):match("^/(%S+)%s+(.+)$")
        if cmd then
            cmd = cmd:lower()
            if cmd == "cast" or cmd == "castsequence" then
                rest = DropConditionals(rest)
                if cmd == "castsequence" then rest = rest:gsub("^reset=%S+%s*", "") end
                rest = ScrubToken((rest:match("^([^;]+)") or rest))
                if rest ~= "" then return TrimStr(rest:match("^([^,]+)") or rest) end
            end
        end
    end
    return nil
end

local function ShowtooltipToken(body)
    for line in body:gmatch("[^\r\n]+") do
        local rest = TrimStr(line):match("^#showtooltip%s+(.+)$")
        if rest then
            rest = ScrubToken(rest)
            return rest ~= "" and rest or nil
        end
    end
    return nil
end

local function ExtractUseTokens(body)
    local found = {}
    for line in body:gmatch("[^\r\n]+") do
        local cmd, rest = TrimStr(line):match("^/(%S+)%s+(.+)$")
        if cmd and (cmd:lower() == "use" or cmd:lower() == "item") then
            for seg in rest:gmatch("([^;]+)") do
                local tok = ScrubToken(seg)
                if tok ~= "" then
                    for part in tok:gmatch("([^,]+)") do
                        local p = ScrubToken(part)
                        if p ~= "" then found[p:lower()] = p end
                    end
                end
            end
        end
    end
    local out = {}
    for _, v in pairs(found) do out[#out + 1] = v end
    return #out > 0 and out or nil
end

local function ResolveMacroSpellID(macroIdx, body)
    if GetMacroSpell then
        local v = GetMacroSpell(macroIdx)
        if type(v) == "number" and v > 0 then return v end
        if type(v) == "string" and v ~= "" then return ResolveSpellIDFromToken(v) end
    end
    local st = ShowtooltipToken(body)
    if st then
        local id = ResolveSpellIDFromToken(st)
        if id then return id end
    end
    local ct = FirstCastToken(body)
    if ct then return ResolveSpellIDFromToken(ct) end
    return nil
end

-- ── Button key detection ──────────────────────────────────────────────────────

local function ReadButtonKey(btn)
    if not btn then return nil end
    if btn.config and btn.config.keyBoundTarget then
        local k = GetBindingKey(btn.config.keyBoundTarget)
        if k and k ~= "" then return k end
    end
    if btn.commandName then
        local k = GetBindingKey(btn.commandName)
        if k and k ~= "" then return k end
    end
    local name = btn.GetName and btn:GetName()
    if name then
        local k = GetBindingKey("CLICK " .. name .. ":LeftButton")
        if k and k ~= "" then return k end
    end
    if btn.HotKey and btn.HotKey.GetText then
        local t = btn.HotKey:GetText()
        if t and t ~= "" and t ~= "●" then return t end
    end
    return nil
end

-- ── Bar scan ──────────────────────────────────────────────────────────────────

-- Yields (slot, key) for the OverrideActionBar buttons (skyriding, vehicles).
-- In TWW the bonus bar uses slots 1-6 which overlap with the main bar; BuildKeyMap's
-- seenSlots table deduplicates them, so these only contribute when the main bar is hidden.
local function YieldOverrideBarButtons()
    for i = 1, 12 do
        local btn = _G["OverrideActionBarButton" .. i]
        if not btn then break end
        local slot = btn.action
        if slot and slot > 0 then
            local k = ReadButtonKey(btn)
            if k and k ~= "●" then coroutine.yield(slot, k) end
        end
    end
end

-- Returns a coroutine iterator that yields (slot, key) for every bound action button.
-- Detects Dominos, Bartender4, ElvUI, and the default Blizzard bars automatically.
-- The OverrideActionBar is appended to every path.
local function MakeBarIterator()
    -- Dominos
    if _G["DominosActionButton1"] and _G["DominosActionButton1"].action then
        return coroutine.wrap(function()
            for i = 1, 180 do
                local btn = _G["DominosActionButton" .. i]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then coroutine.yield(btn.action, k) end
                end
            end
            YieldOverrideBarButtons()
        end)
    end

    -- Bartender4
    if _G["BT4Button1"] and _G["BT4Button1"].action then
        return coroutine.wrap(function()
            for i = 1, 180 do
                local btn = _G["BT4Button" .. i]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then coroutine.yield(btn.action, k) end
                end
            end
            YieldOverrideBarButtons()
        end)
    end

    -- ElvUI
    if _G["ElvUI_Bar1Button1"] and _G["ElvUI_Bar1Button1"].action then
        return coroutine.wrap(function()
            for bar = 1, 15 do
                if _G["ElvUI_Bar" .. bar .. "Button1"] then
                    for j = 1, 12 do
                        local btn = _G["ElvUI_Bar" .. bar .. "Button" .. j]
                        if btn and btn.action then
                            local k = ReadButtonKey(btn)
                            if k and k ~= "●" then coroutine.yield(btn.action, k) end
                        end
                    end
                end
            end
            YieldOverrideBarButtons()
        end)
    end

    -- Default Blizzard bars (ActionButton1-12 + all MultiBar variants)
    local barPrefixes = {
        "ActionButton",
        "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton",      "MultiBarLeftButton",
        "MultiBar5Button",          "MultiBar6Button", "MultiBar7Button",
    }
    return coroutine.wrap(function()
        for _, prefix in ipairs(barPrefixes) do
            for j = 1, 12 do
                local btn = _G[prefix .. j]
                if btn and btn.action then
                    local k = ReadButtonKey(btn)
                    if k and k ~= "●" then
                        local slot = btn.action
                        if ActionButton_GetPagedID then
                            local paged = ActionButton_GetPagedID(btn)
                            if type(paged) == "number" and paged > 0 then slot = paged end
                        end
                        coroutine.yield(slot, k)
                    end
                end
            end
        end
        YieldOverrideBarButtons()
    end)
end

-- ── Map construction ──────────────────────────────────────────────────────────

-- Scans all action bar buttons, stores results in both a fresh map and the persistent cache,
-- then merges cache entries for spells/items absent from the current bar (e.g. normal-bar
-- spells that are off-screen while skyriding or in druid cat form).
local function BuildKeyMap()
    local map = { spells = {}, spellNames = {}, items = {}, itemNames = {} }
    local macros    = {}
    local seenSlots = {}

    for slot, rawKey in MakeBarIterator() do
        if not seenSlots[slot] then
            seenSlots[slot] = true
            local fmt = AbbreviateKey(rawKey)
            if fmt ~= "" and GetActionInfo then
                local aType, id = GetActionInfo(slot)
                if aType == "spell" then
                    StoreSpell(map, id, fmt)
                    StoreSpell(keyCache, id, fmt, true)
                elseif aType == "item" then
                    StoreItem(map, id, fmt)
                    StoreItem(keyCache, id, fmt, true)
                elseif aType == "macro" then
                    macros[#macros + 1] = { slot = slot, id = id, fmt = fmt }
                end
            end
        end
    end

    for _, m in ipairs(macros) do
        local macroIdx
        if GetActionText and GetMacroIndexByName then
            local mname = GetActionText(m.slot)
            if mname and mname ~= "" then macroIdx = GetMacroIndexByName(mname) end
        end
        if (not macroIdx or macroIdx == 0) and type(m.id) == "number" and m.id > 0 and GetMacroInfo then
            if GetMacroInfo(m.id) then macroIdx = m.id end
        end

        if macroIdx and macroIdx > 0 then
            local body
            if GetMacroInfo then
                local _, _, b = GetMacroInfo(macroIdx)
                body = (b and b ~= "") and b or nil
            end
            body = body or (GetMacroBody and GetMacroBody(macroIdx))

            if body then
                local spellID = ResolveMacroSpellID(macroIdx, body)
                if spellID then
                    StoreSpell(map, spellID, m.fmt, true)
                    StoreSpell(keyCache, spellID, m.fmt, true)
                end

                local bodyLower = body:lower()
                local hasSlash = bodyLower:find("/cast", 1, true) or bodyLower:find("/castsequence", 1, true)
                local tokens   = ExtractUseTokens(body)
                if tokens then
                    for _, tok in ipairs(tokens) do
                        local n = tonumber(tok)
                        if n then
                            if (n == 13 or n == 14) and not hasSlash then
                                local equipped = GetInventoryItemID and GetInventoryItemID("player", n)
                                if equipped then
                                    StoreItem(map, equipped, m.fmt, true)
                                    StoreItem(keyCache, equipped, m.fmt, true)
                                end
                            elseif n > 14 then
                                StoreItem(map, n, m.fmt, true)
                                StoreItem(keyCache, n, m.fmt, true)
                            end
                        else
                            local rawID = tok:match("^[Ii]tem:(%d+)")
                            if rawID then
                                StoreItem(map, tonumber(rawID), m.fmt, true)
                                StoreItem(keyCache, tonumber(rawID), m.fmt, true)
                            elseif GetItemInfo then
                                local _, link = GetItemInfo(tok)
                                if link then
                                    local id = link:match("item:(%d+)")
                                    if id then
                                        StoreItem(map, tonumber(id), m.fmt, true)
                                        StoreItem(keyCache, tonumber(id), m.fmt, true)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Merge cache: fills in keybinds for spells/items not on the active bar right now.
    -- Current bar always wins; cache only fills gaps.
    for spellID, key in pairs(keyCache.spells) do
        if not map.spells[spellID] then map.spells[spellID] = key end
    end
    for name, key in pairs(keyCache.spellNames) do
        if not map.spellNames[name] then map.spellNames[name] = key end
    end
    for itemID, key in pairs(keyCache.items) do
        if not map.items[itemID] then map.items[itemID] = key end
    end
    for name, key in pairs(keyCache.itemNames) do
        if not map.itemNames[name] then map.itemNames[name] = key end
    end

    return map
end

-- ── Overlay creation & styling ────────────────────────────────────────────────

local function GetOverlay(frame)
    if frame.SCMKeybindOverlay then return frame.SCMKeybindOverlay end
    local overlay = CreateFrame("Frame", nil, frame)
    overlay:SetFrameLevel(frame:GetFrameLevel() + 5)
    overlay:SetAllPoints(frame)
    local text = overlay:CreateFontString(nil, "OVERLAY")
    text:SetDrawLayer("OVERLAY", 7)
    text:SetShadowColor(0, 0, 0, 1)
    text:SetShadowOffset(1, -1)
    overlay.text = text
    frame.SCMKeybindOverlay = overlay
    return overlay
end

local function GetKeybindCfg()
    return SCM.db and SCM.db.profile and SCM.db.profile.options and SCM.db.profile.options.keybinds
end

local function ApplyStyle(overlay, cfg)
    if overlay._scmStyleVersion == styleVersion then return end
    overlay._scmStyleVersion = styleVersion
    local fontPath = DEFAULT_FONT
    if LSM then
        local p = LSM:Fetch("font", cfg.fontName)
        if p then fontPath = p end
    end
    overlay.text:SetFont(fontPath, cfg.fontSize or 11, cfg.fontFlags or "OUTLINE")
    local c = cfg.color or { 1, 1, 1, 1 }
    overlay.text:SetTextColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
end

local function ShowKeybind(frame, key, cfg)
    local overlay = GetOverlay(frame)
    ApplyStyle(overlay, cfg)
    local anchor = cfg.anchor or "TOPRIGHT"
    overlay.text:ClearAllPoints()
    overlay.text:SetPoint(anchor, frame, anchor, cfg.offsetX or -1, cfg.offsetY or -1)
    overlay.text:SetText(key)
    overlay.text:Show()
    overlay:Show()
end

local function HideKeybind(frame)
    if frame and frame.SCMKeybindOverlay then
        frame.SCMKeybindOverlay:Hide()
    end
end

-- ── Per-frame application ─────────────────────────────────────────────────────

local function ApplyToViewerChild(child, map, cfg)
    local spellID = child.SCMSpellID or child.SCMLinkedSpellID
    if not spellID then HideKeybind(child); return end
    local key = QuerySpell(map, spellID)
    if not key or key == "" then HideKeybind(child); return end
    ShowKeybind(child, key, cfg)
end

local function ApplyToCustomFrame(frame, map, cfg)
    local config   = frame.SCMConfig
    if not config then return end
    local key
    local iconType = frame.SCMIconType
    if iconType == "spell" or iconType == "timer" then
        key = config.spellID and QuerySpell(map, config.spellID)
    elseif iconType == "item" then
        key = config.itemID and QueryItem(map, config.itemID)
        if not key and frame.SCMSpellID then key = QuerySpell(map, frame.SCMSpellID) end
    elseif iconType == "slot" then
        if config.slotID and GetInventoryItemID then
            local itemID = GetInventoryItemID("player", config.slotID)
            if itemID and itemID ~= 0 then key = QueryItem(map, itemID) end
        end
        if not key and config.spellID then key = QuerySpell(map, config.spellID) end
    end
    if not key or key == "" then HideKeybind(frame); return end
    ShowKeybind(frame, key, cfg)
end

-- ── Public API ────────────────────────────────────────────────────────────────

function Keybinds.ApplyToFrame(frame)
    if not keyMap then return end
    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then HideKeybind(frame); return end
    ApplyToCustomFrame(frame, keyMap, cfg)
end

function Keybinds.ApplyToViewerChild(child)
    if not keyMap then return end
    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then HideKeybind(child); return end
    ApplyToViewerChild(child, keyMap, cfg)
end

function Keybinds.HideFromFrame(frame)
    HideKeybind(frame)
end

function Keybinds.RefreshAllFrames()
    if not enabled then return end
    local map     = keyMap
    local cfg     = GetKeybindCfg()
    local cfgEnabled = cfg and cfg.enabled

    if SCM.CustomIcons and SCM.CustomIcons.ForEachActiveFrame then
        SCM.CustomIcons.ForEachActiveFrame(function(frame)
            if not frame.SCMConfig then return end
            if cfgEnabled and map then
                ApplyToCustomFrame(frame, map, cfg)
            else
                HideKeybind(frame)
            end
        end)
    end

    for _, viewerName in ipairs({ "EssentialCooldownViewer", "UtilityCooldownViewer" }) do
        local viewer = _G[viewerName]
        if viewer then
            for _, child in ipairs({ viewer:GetChildren() }) do
                if child.SCMSpellID then
                    if cfgEnabled and map then
                        ApplyToViewerChild(child, map, cfg)
                    else
                        HideKeybind(child)
                    end
                end
            end
        end
    end
end

function Keybinds.Rebuild()
    if not enabled then return end
    if InCombatLockdown and InCombatLockdown() then
        combatDirty = true
        return
    end
    keyMap = BuildKeyMap()
    Keybinds.RefreshAllFrames()
end

-- ── Event handling ────────────────────────────────────────────────────────────

-- Single debounced rebuild scheduler. Uses C_Timer.NewTimer so a pending short-delay
-- rebuild can be upgraded to a longer delay when a bar-swap event arrives.
local function ScheduleRebuild(delay)
    delay = delay or 0.15
    if rebuildTimer then
        if rebuildDelay >= delay then return end  -- existing timer already covers this
        rebuildTimer:Cancel()
        rebuildTimer = nil
    end
    rebuildDelay  = delay
    rebuildTimer  = C_Timer.NewTimer(delay, function()
        rebuildTimer = nil
        rebuildDelay = 0
        Keybinds.Rebuild()
    end)
end

-- Debounced RefreshAllFrames, for hooks that can fire many times back-to-back
-- (e.g. one CreateSpellIcon/CreateItemIcon call per icon while the whole icon
-- set is built on first login). Coalesces a burst of calls into a single scan
-- instead of running the full frame scan once per call.
local refreshTimer = nil
local function ScheduleRefresh()
    if refreshTimer or not enabled then return end
    refreshTimer = C_Timer.NewTimer(0.05, function()
        refreshTimer = nil
        Keybinds.RefreshAllFrames()
    end)
end

local eventFrame = CreateFrame("Frame")
eventFrame:SetScript("OnEvent", function(_, event, arg1, arg2)
    -- Always-on: deferred hook registration and initial setup on first login/reload
    if event == "PLAYER_ENTERING_WORLD" then
        if not extraHooksSet then
            extraHooksSet = true
            hooksecurefunc(SCM, "ApplyAllCDManagerConfigs",     ScheduleRefresh)
            hooksecurefunc(SCM, "ApplyEssentialCDManagerConfig", ScheduleRefresh)
            hooksecurefunc(SCM, "ApplyUtilityCDManagerConfig",   ScheduleRefresh)
        end
        if arg1 or arg2 then  -- isInitialLogin or isReload
            Keybinds.OnSettingChanged()
        end
        return
    end

    -- Flush any deferred rebuild that was blocked by combat
    if event == "PLAYER_REGEN_ENABLED" then
        if combatDirty then
            combatDirty = false
            Keybinds.Rebuild()
        end
        return
    end

    -- Bar-swap events: a new bar is populating, give it 0.3 s before scanning.
    -- UPDATE_BONUS_ACTIONBAR covers skyriding (confirmed TWW 11.x, GetBonusBarIndex=11)
    -- and druid forms. UPDATE_OVERRIDE_ACTIONBAR covers vehicles / boss mechanics.
    if event == "UPDATE_BONUS_ACTIONBAR"
    or event == "UPDATE_OVERRIDE_ACTIONBAR"
    or event == "UPDATE_EXTRA_ACTIONBAR"
    or event == "PLAYER_MOUNT_DISPLAY_CHANGED" then
        ScheduleRebuild(0.3)
        return
    end

    local cfg = GetKeybindCfg()
    if not cfg or not cfg.enabled then return end

    if InCombatLockdown and InCombatLockdown() then
        combatDirty = true
        return
    end

    -- Hard resets: spec, equipment, and macro changes fully invalidate the spell loadout.
    -- Binding changes and bar drag only clear cache when the normal bar is active; while
    -- skyriding / in a vehicle / in a druid form, the normal-bar keybinds must survive.
    if event == "ACTIVE_PLAYER_SPECIALIZATION_CHANGED"
    or event == "PLAYER_EQUIPMENT_CHANGED"
    or event == "UPDATE_MACROS" then
        ClearKeyCache()
    elseif (event == "UPDATE_BINDINGS" or event == "ACTIONBAR_HIDEGRID" or event == "ACTIONBAR_SLOT_CHANGED") and not IsInOverrideBar() then
        ClearKeyCache()
    end

    ScheduleRebuild(0.15)
end)

-- ── Lifecycle ─────────────────────────────────────────────────────────────────

function Keybinds.Enable()
    enabled = true
    if rebuildTimer then rebuildTimer:Cancel(); rebuildTimer = nil; rebuildDelay = 0 end
    ClearKeyCache()
    eventFrame:RegisterEvent("UPDATE_BINDINGS")
    eventFrame:RegisterEvent("UPDATE_MACROS")
    eventFrame:RegisterEvent("ACTIONBAR_HIDEGRID")
    eventFrame:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
    eventFrame:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
    eventFrame:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
    eventFrame:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
    eventFrame:RegisterEvent("UPDATE_EXTRA_ACTIONBAR")
    eventFrame:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
    eventFrame:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    eventFrame:RegisterEvent("ACTIVE_PLAYER_SPECIALIZATION_CHANGED")
    eventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    Keybinds.Rebuild()
end

function Keybinds.Disable()
    if rebuildTimer then rebuildTimer:Cancel(); rebuildTimer = nil; rebuildDelay = 0 end
    eventFrame:UnregisterAllEvents()
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    keyMap        = nil
    combatDirty   = false
    -- Clear overlays before flipping the flag so RefreshAllFrames' early-return doesn't skip the wipe.
    local function hideAll(frame) HideKeybind(frame) end
    if SCM.CustomIcons and SCM.CustomIcons.ForEachActiveFrame then
        SCM.CustomIcons.ForEachActiveFrame(hideAll)
    end
    for _, viewerName in ipairs({ "EssentialCooldownViewer", "UtilityCooldownViewer" }) do
        local viewer = _G[viewerName]
        if viewer then
            for _, child in ipairs({ viewer:GetChildren() }) do
                if child.SCMSpellID then HideKeybind(child) end
            end
        end
    end
    enabled = false
end

function Keybinds.OnSettingChanged()
    styleVersion = styleVersion + 1
    local cfg = GetKeybindCfg()
    if cfg and cfg.enabled then
        Keybinds.Enable()
    else
        Keybinds.Disable()
    end
end

-- ── Bootstrap ─────────────────────────────────────────────────────────────────

-- Re-apply keybinds after any full viewer rebuild (profile/spec/scale changes).
-- Debounced: can fire once per icon while the whole viewer is rebuilt on login.
hooksecurefunc(SCM, "RefreshCooldownViewerData", ScheduleRefresh)

-- Force a bar rescan when a custom icon is added so the new spell's keybind is found.
-- Debounced: restoring a saved profile can call this once per custom icon.
hooksecurefunc(SCM, "AddCustomIcon", function() ScheduleRebuild() end)

-- Spell/item data may load asynchronously after AddCustomIcon; apply once the frame exists.
-- Debounced: fires once per icon, so bulk icon creation on first login collapses
-- into a single scan instead of one full RefreshAllFrames per icon.
hooksecurefunc(SCM.CustomIcons, "CreateSpellIcon", ScheduleRefresh)
hooksecurefunc(SCM.CustomIcons, "CreateItemIcon",  ScheduleRefresh)

-- Keep PLAYER_ENTERING_WORLD registered at all times so it survives Disable().
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
