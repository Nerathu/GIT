local addonName = ...

-- Constants (SpellID 119611 = Renewing Mist HoT)
local RENEWING_MIST_SPELL_NAME = "Erneuernder Nebel"
local GLOW_THRESHOLD_M_PLUS = 5  -- Leuchten in M+ ab 5 Nebeln
local GLOW_THRESHOLD_RAID = 12   -- Leuchten im Raid ab 12 Nebeln

-- State
local db
local updatePending

--======================================================================
-- UI Setup (Clean & Classic)
--======================================================================
local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetSize(50, 50) -- Quadratisch für den klassischen Look
frame:SetPoint("CENTER", UIParent, "CENTER", 0, -150)
frame:SetMovable(true)
frame:SetClampedToScreen(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")

-- Schwarzer 2-Pixel-Hintergrund (Harter Rand)
local bg = frame:CreateTexture(nil, "BACKGROUND")
bg:SetPoint("TOPLEFT", frame, "TOPLEFT", -2, 2)
bg:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 2, -2)
bg:SetColorTexture(0, 0, 0, 1)

-- Das Zauber-Icon
local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(frame)
icon:SetTexCoord(0.07, 0.93, 0.07, 0.93) -- Zoomt leicht rein, um den Blizzard-Rand zu entfernen

-- Der Glow-Rahmen (Versteckt bis zum Threshold/Maximum)
local glow = CreateFrame("Frame", nil, frame, "BackdropTemplate")
glow:SetPoint("TOPLEFT", frame, "TOPLEFT", -5, 5)
glow:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 5, -5)
glow:SetFrameLevel(frame:GetFrameLevel() + 10)  -- Über Icon/Text zeichnen
glow:SetBackdrop({
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    edgeSize = 6,
})
glow:SetBackdropBorderColor(0, 1, 0.5, 1)  -- Türkises Mönch-Leuchten
glow:Hide()

-- Text Setup (Groß & Fett)
local text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightOutline")
text:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
text:SetFont("Fonts\\FRIZQT__.TTF", 20, "THICKOUTLINE")

--======================================================================
-- Logic
--======================================================================

local MISTWEAVER_SPEC_ID = 270

local function IsMistweaver()
    if select(2, UnitClass("player")) ~= "MONK" then return false end
    local specIndex = GetSpecialization()
    if not specIndex then return false end
    local specID = select(1, GetSpecializationInfo(specIndex))
    return specID == MISTWEAVER_SPEC_ID
end

local function GetActiveRemCount()
    local count = 0
    -- Wir nutzen die Gruppen-Iteratoren für maximale Performance
    local units = IsInRaid() and "raid" or "party"
    local numMembers = IsInRaid() and GetNumGroupMembers() or GetNumSubgroupMembers()
    
    -- Check Player
    local playerAura = C_UnitAuras.GetAuraDataBySpellName("player", RENEWING_MIST_SPELL_NAME, "HELPFUL")
    if playerAura and playerAura.sourceUnit == "player" then count = count + 1 end

    -- Check Group
    for i = 1, numMembers do
        local unit = units .. i
        if not UnitIsUnit(unit, "player") then
            local aura = C_UnitAuras.GetAuraDataBySpellName(unit, RENEWING_MIST_SPELL_NAME, "HELPFUL")
            if aura and aura.sourceUnit == "player" then
                count = count + 1
            end
        end
    end
    return count
end

local function GetMaxRemTargets()
    if IsInRaid() then
        return GetNumGroupMembers()
    end
    return 1 + GetNumSubgroupMembers()  -- player + party (0 when solo = 1)
end

local function UpdateUI()
    if not db or not IsMistweaver() then
        frame:Hide()
        return
    end
    if db.hideInCombat and UnitAffectingCombat("player") then
        frame:Hide()
        return
    end
    if db.hideInInstance and IsInInstance() then
        frame:Hide()
        return
    end

    local count = GetActiveRemCount()
    local max = GetMaxRemTargets()
    if max and max > 0 then
        text:SetText(count .. "/" .. max)
    else
        text:SetText(count .. "/1")
    end

    -- Farbe basierend auf Stack-Anzahl
    if count == 0 then text:SetTextColor(1, 0.2, 0.2)
    elseif count < 3 then text:SetTextColor(1, 0.8, 0)
    else text:SetTextColor(0.2, 1, 0.2) end

    -- Glow: bei Maximum oder ab Schwellenwert
    local threshold = (db.glowThresholdMPlus and db.glowThresholdRaid) and (IsInRaid() and db.glowThresholdRaid or db.glowThresholdMPlus)
        or (IsInRaid() and GLOW_THRESHOLD_RAID or GLOW_THRESHOLD_M_PLUS)
    local atMax = (max and max > 0 and count == max)
    local atThreshold = (count >= threshold)
    local showGlow = (db.glowOnMaxOnly and atMax) or (not db.glowOnMaxOnly and (atMax or atThreshold))
    if showGlow then
        glow:Show()
    else
        glow:Hide()
    end
    
    frame:Show()
end

--======================================================================
-- Boilerplate & Events
--======================================================================

frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    if db then
        local p, _, rp, x, y = self:GetPoint()
        db.pos = { p, rp, x, y }
    end
end)

local function ApplyFrameLock()
    if not db then return end
    local locked = (db.lockFrame == true)
    frame:EnableMouse(true)
    if locked then
        frame:RegisterForDrag()
    else
        frame:RegisterForDrag("LeftButton")
    end
end

local function ScheduleUpdate()
    if updatePending then return end
    updatePending = true
    C_Timer.After(0.05, function()
        updatePending = nil
        UpdateUI()
    end)
end

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        RenewingMistTrackerDB = RenewingMistTrackerDB or {}
        db = RenewingMistTrackerDB
        -- Defaults für neue Optionen (alte SavedVariables kompatibel)
        if db.lockFrame == nil then db.lockFrame = false end
        if db.glowOnMaxOnly == nil then db.glowOnMaxOnly = false end
        if db.glowThresholdMPlus == nil then db.glowThresholdMPlus = GLOW_THRESHOLD_M_PLUS end
        if db.glowThresholdRaid == nil then db.glowThresholdRaid = GLOW_THRESHOLD_RAID end
        if db.hideInCombat == nil then db.hideInCombat = false end
        if db.hideInInstance == nil then db.hideInInstance = false end
        local info = C_Spell.GetSpellInfo(115151)
        if info then icon:SetTexture(info.iconID) end
        if db.pos then
            self:ClearAllPoints()
            self:SetPoint(db.pos[1], UIParent, db.pos[2], db.pos[3], db.pos[4])
        end
        ApplyFrameLock()
        -- Optionspanel unter ESC -> Optionen -> Addons (ohne deprecated Templates)
        if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
            local optFrame = CreateFrame("Frame")
            optFrame.name = "RenewingMistTracker"
            optFrame:SetSize(600, 400)

            local title = optFrame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
            title:SetPoint("TOPLEFT", 16, -16)
            title:SetText("RenewingMistTracker")

            local function CreateOptionCheckbox(parent, yOffset, labelText, getValue, setValue)
                local cb = CreateFrame("CheckButton", nil, parent)
                cb:SetSize(24, 24)
                cb:SetPoint("TOPLEFT", 16, yOffset)
                local bg = cb:CreateTexture(nil, "BACKGROUND")
                bg:SetAllPoints(cb)
                bg:SetColorTexture(0.3, 0.3, 0.3, 0.8)
                local check = cb:CreateTexture(nil, "ARTWORK")
                check:SetAllPoints(cb)
                check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
                cb:SetCheckedTexture(check)
                cb:SetChecked(getValue())
                cb:SetScript("OnClick", function(self) setValue(self:GetChecked()) end)
                local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
                lbl:SetPoint("LEFT", cb, "RIGHT", 8, 0)
                lbl:SetText(labelText)
                return cb
            end

            CreateOptionCheckbox(optFrame, -52, "Rahmen sperren (nicht verschiebbar)", function() return db.lockFrame end, function(v) db.lockFrame = v; ApplyFrameLock() end)
            CreateOptionCheckbox(optFrame, -86, "Leuchten nur bei Maximum (alle haben Buff)", function() return db.glowOnMaxOnly end, function(v) db.glowOnMaxOnly = v; UpdateUI() end)
            CreateOptionCheckbox(optFrame, -120, "Nicht im Kampf anzeigen", function() return db.hideInCombat end, function(v) db.hideInCombat = v; UpdateUI() end)
            CreateOptionCheckbox(optFrame, -154, "Nicht in Instanzen anzeigen", function() return db.hideInInstance end, function(v) db.hideInInstance = v; UpdateUI() end)

            local category = Settings.RegisterCanvasLayoutCategory(optFrame, "RenewingMistTracker")
            Settings.RegisterAddOnCategory(category)
        end
    end
    if event == "UNIT_AURA" then
        ScheduleUpdate()
    else
        UpdateUI()
    end
end)

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_AURA")
frame:RegisterEvent("PLAYER_REGEN_ENABLED")   -- Kampf verlassen -> ggf. anzeigen
frame:RegisterEvent("PLAYER_REGEN_DISABLED")  -- Kampf betreten -> ggf. verstecken
frame:RegisterEvent("ZONE_CHANGED_NEW_AREA")  -- Instanz-Wechsel -> ggf. anzeigen/verstecken
frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")  -- Spec-Wechsel (z.B. zu/weg Mistweaver)