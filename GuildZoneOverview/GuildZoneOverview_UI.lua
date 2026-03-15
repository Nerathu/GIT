local addonName = ...
local GZO = _G.GZO

local frame = CreateFrame("Frame", "GuildZoneOverviewFrame", UIParent, "BackdropTemplate")
frame:SetBackdrop(GZO.TOOLTIP_BACKDROP)
frame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
frame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
frame:SetHeight(120)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 200)
frame:SetMovable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)
frame:SetScript("OnDragStart", function(self) self:StartMoving() end)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    GuildZoneOverviewDB.point = point
    GuildZoneOverviewDB.relativePoint = relativePoint
    GuildZoneOverviewDB.xOfs = xOfs
    GuildZoneOverviewDB.yOfs = yOfs
end)
frame:SetAlpha(GZO.INACTIVE_ALPHA)

GZO.mainFrame = frame

local function CreateTexture(parent, layer, r, g, b, a, h)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a)
    if h then t:SetHeight(h) else t:SetAllPoints() end
    return t
end

local topBorder = CreateTexture(frame, "ARTWORK", 0, 0.8, 1, 1, 2)
topBorder:ClearAllPoints()
topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", GZO.TOP_BORDER_PAD, 0)
topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -GZO.TOP_BORDER_PAD, 0)

local countdownBar = CreateFrame("Frame", nil, frame)
countdownBar:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
countdownBar:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
countdownBar:SetHeight(GZO.COUNTDOWN_BAR_HEIGHT)
local countdownBarBg = countdownBar:CreateTexture(nil, "BACKGROUND")
countdownBarBg:SetAllPoints()
countdownBarBg:SetColorTexture(0.1, 0.1, 0.15, 0.7)
local countdownBarFill = countdownBar:CreateTexture(nil, "ARTWORK")
countdownBarFill:SetPoint("LEFT", countdownBar, "LEFT", 0, 0)
countdownBarFill:SetPoint("BOTTOM", countdownBar, "BOTTOM", 0, 0)
countdownBarFill:SetPoint("TOP", countdownBar, "TOP", 0, 0)
countdownBarFill:SetWidth(0)
countdownBarFill:Hide()

local animationTimer = nil
local isAnimatingAlert = false
local PULSE_ALPHA_MID = (GZO.PULSE_ALPHA_MIN + GZO.PULSE_ALPHA_MAX) / 2

local function PlayOnlineBlink()
    if not topBorder or not C_Timer then return end
    if animationTimer then animationTimer:Cancel(); animationTimer = nil end
    if GuildZoneOverviewDB.playSoundOnOnline then PlaySound(SOUNDKIT.UI_BNET_TOAST) end
    local r, g, b
    if GuildZoneOverviewDB.useClassColorAnimation then
        local cr, cg, cb = GZO.GetPlayerClassColor()
        r, g, b = cr or 1, cg or 1, cb or 1
    else
        local col = GuildZoneOverviewDB.animationColor
        r, g, b = (col and col[1]) or 1, (col and col[2]) or 1, (col and col[3]) or 1
    end
    topBorder:SetHeight(4)
    topBorder:SetColorTexture(r, g, b, 1)
    local duration = math.max(1, math.min(60, tonumber(GuildZoneOverviewDB.animationDurationSec) or 10))
    local startTime = GetTime()
    if countdownBarFill then
        countdownBarFill:SetColorTexture(r, g, b, 1)
        countdownBarFill:SetWidth(countdownBar and countdownBar:GetWidth() or 0)
        countdownBarFill:Show()
    end
    isAnimatingAlert = true
    GZO.RefreshAlpha()
    animationTimer = C_Timer.NewTicker(0.05, function()
        if not topBorder then return end
        local elapsed = GetTime() - startTime
        if elapsed >= duration then
            if animationTimer then animationTimer:Cancel() end
            animationTimer = nil
            isAnimatingAlert = false
            topBorder:SetHeight(2)
            topBorder:SetColorTexture(0, 0.8, 1, 1)
            if countdownBarFill then countdownBarFill:Hide() end
            GZO.RefreshAlpha()
            return
        end
        local remaining = 1 - (elapsed / duration)
        if countdownBar and countdownBarFill then
            local w = countdownBar:GetWidth() * remaining
            countdownBarFill:SetWidth(w >= 0.01 and w or 0)
        end
        local pulseAlpha = 0.3 + 0.7 * math.abs(math.sin(elapsed * math.pi * 1.5))
        topBorder:SetAlpha(pulseAlpha)
    end)
end

GZO.PlayOnlineBlink = PlayOnlineBlink

local headerFont = CreateFont("GZOHeaderFont")
headerFont:SetFont(GZO.FONT_PATH, 14, "OUTLINE")
local lineFont = CreateFont("GZOLineFont")
lineFont:SetFont(GZO.FONT_PATH, 13, "")

local title = frame:CreateFontString(nil, "OVERLAY")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
title:SetFontObject(headerFont)
title:SetText("GILDENÜBERSICHT")
title:SetTextColor(0.9, 0.9, 0.9)

local function CreateRow(yOffset, hue, label, textColorR, textColorG, textColorB)
    local tr, tg, tb = textColorR or 0.8, textColorG or 0.8, textColorB or 0.8
    local btn = CreateFrame("Button", nil, frame)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, yOffset)
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, yOffset)
    btn:SetHeight(18)
    local bar = btn:CreateTexture(nil, "BACKGROUND")
    bar:SetAllPoints()
    local colors = GZO.HUE_COLORS[hue] or GZO.HUE_COLORS.violet
    bar:SetGradient("VERTICAL", colors[2], colors[1])
    local text = btn:CreateFontString(nil, "OVERLAY", "GZOLineFont")
    text:SetPoint("LEFT", btn, "LEFT", 10, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
    text:SetText(label .. ": 0")
    text:SetTextColor(tr, tg, tb)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetMaxLines(1)
    local hoverR, hoverG, hoverB = math.min(1, tr * 0.5 + 0.5), math.min(1, tg * 0.5 + 0.5), math.min(1, tb * 0.5 + 0.5)
    btn:SetScript("OnEnter", function()
        bar:SetColorTexture(colors[3]:GetRGBA())
        text:SetTextColor(hoverR, hoverG, hoverB)
        if GZO.RefreshAlpha then GZO.RefreshAlpha() end
    end)
    btn:SetScript("OnLeave", function()
        bar:SetGradient("VERTICAL", colors[2], colors[1])
        text:SetTextColor(tr, tg, tb)
        if GZO.RefreshAlpha then GZO.RefreshAlpha() end
    end)
    return btn, text
end

local categoryRows = {}
for i, key in ipairs(GZO.ORDERED_CATEGORY_KEYS) do
    local y = GZO.ROW_Y_START + (i - 1) * GZO.ROW_STEP
    local col = GZO.CATEGORY_TEXT_COLORS[key]
    local btn, text = CreateRow(y, GZO.ROW_HUE[key], GZO.CATEGORY_LABELS[key], col[1], col[2], col[3])
    categoryRows[key] = { btn = btn, text = text }
end
GZO.categoryRows = categoryRows

local function LineGapForIndex(i)
    return GZO.LINE_GAP + ((i % 5 == 1 and i > 1) and GZO.LINE_GROUP_GAP or 0)
end

local function RepositionFloatingLines(row)
    if not row.floatingLineContainer or not row.floatingLines then return end
    local prev
    for i, entry in ipairs(row.floatingLines) do
        local tex = entry.tex
        if tex and tex.SetPoint then
            tex:ClearAllPoints()
            if not prev then tex:SetPoint("LEFT", row.floatingLineContainer, "LEFT", 0, 0)
            else tex:SetPoint("LEFT", prev, "RIGHT", LineGapForIndex(i), 0) end
            prev = tex
        end
    end
end

local function SpawnFloatingDiff(row, diff)
    if diff == 0 then return end
    local duration = math.max(1, math.min(60, tonumber(GuildZoneOverviewDB.floatingLineDurationSec) or 10))
    local removeAt = GetTime() + duration
    if not row.floatingLineContainer then
        row.floatingLineContainer = CreateFrame("Frame", nil, row.btn)
        row.floatingLineContainer:SetPoint("RIGHT", row.btn, "RIGHT", -GZO.LINE_OFFSET_RIGHT, 0)
        row.floatingLineContainer:SetSize(1, GZO.LINE_HEIGHT)
        row.floatingLines = {}
    end
    local container, list = row.floatingLineContainer, row.floatingLines
    local n = #list
    local lastTex = n > 0 and list[n].tex or nil
    local count = math.abs(diff)
    local isGreen = diff > 0
    local r, g, b = isGreen and GZO.LINE_GREEN[1] or GZO.LINE_RED[1], isGreen and GZO.LINE_GREEN[2] or GZO.LINE_RED[2], isGreen and GZO.LINE_GREEN[3] or GZO.LINE_RED[3]
    for j = 1, count do
        local tex = container:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(r, g, b, 1)
        tex:SetSize(GZO.LINE_WIDTH, GZO.LINE_HEIGHT)
        tex:ClearAllPoints()
        if not lastTex then tex:SetPoint("LEFT", container, "LEFT", 0, 0)
        else tex:SetPoint("LEFT", lastTex, "RIGHT", LineGapForIndex(n + j), 0) end
        lastTex = tex
        list[#list + 1] = { tex = tex, removeAt = removeAt }
    end
end
GZO.SpawnFloatingDiff = SpawnFloatingDiff

local floatingLineTicker
local function StartFloatingLineTicker()
    if floatingLineTicker then return end
    floatingLineTicker = C_Timer.NewTicker(0.5, function()
        if not frame or not frame:IsShown() then return end
        local now = GetTime()
        for _, key in ipairs(GZO.FLOATING_LINE_KEYS) do
            local row = categoryRows[key]
            if row and row.floatingLines and #row.floatingLines > 0 then
                local removed
                local i, n = 1, #row.floatingLines
                while i <= n do
                    if row.floatingLines[i].removeAt <= now then
                        local entry = table.remove(row.floatingLines, i)
                        if entry and entry.tex then entry.tex:SetParent(nil); entry.tex = nil end
                        n, removed = n - 1, true
                    else i = i + 1 end
                end
                if removed then RepositionFloatingLines(row) end
            end
        end
    end)
end
StartFloatingLineTicker()

local detailsFrame = CreateFrame("Frame", nil, frame, "BackdropTemplate")
frame.detailsFrame = detailsFrame
GZO.detailsFrame = detailsFrame
detailsFrame:SetBackdrop(GZO.TOOLTIP_BACKDROP)
detailsFrame:SetBackdropColor(0.05, 0.05, 0.08, 0.95)
detailsFrame:SetBackdropBorderColor(0.4, 0.4, 0.5, 0.8)
detailsFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
detailsFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
detailsFrame:Hide()

local dTopBorder = CreateTexture(detailsFrame, "ARTWORK", 0.6, 0.2, 0.9, 1, 2)
dTopBorder:ClearAllPoints()
dTopBorder:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", GZO.TOP_BORDER_PAD, 0)
dTopBorder:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", -GZO.TOP_BORDER_PAD, 0)
detailsFrame:EnableMouse(true)

local function ShouldUseActiveAlpha()
    return isAnimatingAlert or (detailsFrame:IsShown() and GZO.currentDetailsCategory ~= nil) or frame:IsMouseOver() or detailsFrame:IsMouseOver()
end

function GZO.RefreshAlpha()
    if ShouldUseActiveAlpha() then
        frame:SetAlpha(GZO.ACTIVE_ALPHA)
        detailsFrame:SetAlpha(GZO.ACTIVE_ALPHA)
    else
        local a = (GuildZoneOverviewDB.pulseWhenInactive and PULSE_ALPHA_MID) or GZO.INACTIVE_ALPHA
        frame:SetAlpha(a)
        detailsFrame:SetAlpha(a)
    end
end

local pulsePhase = 0
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(0.05, function()
        if not frame:IsShown() then return end
        if ShouldUseActiveAlpha() then
            frame:SetAlpha(GZO.ACTIVE_ALPHA)
            detailsFrame:SetAlpha(GZO.ACTIVE_ALPHA)
            return
        end
        if GuildZoneOverviewDB.pulseWhenInactive then
            pulsePhase = pulsePhase + 0.02
            if pulsePhase > 1 then pulsePhase = 0 end
            local a = PULSE_ALPHA_MID + (GZO.PULSE_ALPHA_MAX - GZO.PULSE_ALPHA_MIN) * 0.5 * math.sin(pulsePhase * 2 * math.pi)
            frame:SetAlpha(a)
            detailsFrame:SetAlpha(a)
        else
            frame:SetAlpha(GZO.INACTIVE_ALPHA)
            detailsFrame:SetAlpha(GZO.INACTIVE_ALPHA)
        end
    end)
end

frame:SetScript("OnEnter", GZO.RefreshAlpha)
frame:HookScript("OnLeave", GZO.RefreshAlpha)
detailsFrame:SetScript("OnEnter", GZO.RefreshAlpha)
detailsFrame:SetScript("OnLeave", GZO.RefreshAlpha)

local detailLines = {}
local detailSeparators = {}

local detailBlinkPhase = 0
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(0.1, function()
        if not detailLines or not detailsFrame or not detailsFrame:IsShown() or not GZO.currentDetailsCategory then return end
        detailBlinkPhase = detailBlinkPhase + 0.2
        local now = GetTime()
        for _, entry in ipairs(detailLines) do
            if entry.fs and entry.fs:IsShown() then
                local shouldBlink = false
                local blinkKey = entry.charName or entry.playerName
                if entry.blinkCategory and blinkKey and GZO.playerZoneFirstSeen[blinkKey] then
                    shouldBlink = (now - GZO.playerZoneFirstSeen[blinkKey]) / 60 < 5
                end
                if shouldBlink then entry.fs:SetAlpha(0.65 + 0.35 * math.sin(detailBlinkPhase))
                else entry.fs:SetAlpha(1) end
            end
        end
    end)
end

local function ClearDetailLines()
    for _, entry in ipairs(detailLines) do
        entry.playerName = nil
        entry.charName = nil
        entry.blinkCategory = nil
        if entry.fs then entry.fs:SetText(""); entry.fs:Hide(); entry.fs:SetAlpha(1) end
        if entry.tex then entry.tex:Hide() end
        if entry.hoverFrame then entry.hoverFrame:Hide() end
    end
    for _, sep in ipairs(detailSeparators) do sep:Hide() end
end

local function GetSeparatorLine(i)
    if not detailSeparators[i] then
        detailSeparators[i] = detailsFrame:CreateTexture(nil, "OVERLAY")
        detailSeparators[i]:SetHeight(GZO.SEPARATOR_HEIGHT)
        detailSeparators[i]:SetColorTexture(0.35, 0.35, 0.4, 0.7)
    end
    return detailSeparators[i]
end

local function GetClassColorForDetail(class)
    if not class then return 1, 1, 1 end
    local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class])
    if c then return c.r, c.g, c.b end
    return 1, 1, 1
end

local function SetDetailLineStyle(fs)
    fs:SetJustifyH("LEFT")
    fs:SetWordWrap(false)
    fs:SetMaxLines(1)
end

local function DetailLineOnEnter(self)
    local name = self.entry and self.entry.playerName
    if not name then return end
    GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
    GameTooltip:SetText(name)
    GameTooltip:Show()
end

local function EnsureDetailEntry(index)
    if not detailLines[index] then
        local entry = {
            tex = detailsFrame:CreateTexture(nil, "OVERLAY"),
            fs = detailsFrame:CreateFontString(nil, "OVERLAY", "GZOLineFont"),
        }
        entry.tex:SetSize(GZO.DETAIL_INDICATOR_SIZE, GZO.DETAIL_INDICATOR_SIZE)
        entry.tex:SetColorTexture(0.5, 0.5, 0.5, 1)
        SetDetailLineStyle(entry.fs)
        entry.hoverFrame = CreateFrame("Frame", nil, detailsFrame)
        entry.hoverFrame:EnableMouse(true)
        entry.hoverFrame.entry = entry
        entry.hoverFrame:SetScript("OnEnter", DetailLineOnEnter)
        entry.hoverFrame:SetScript("OnLeave", function() GameTooltip:Hide() end)
        detailLines[index] = entry
    end
    return detailLines[index]
end

local function BuildDetailLines(categoryKey)
    local members = GZO.membersByCategory[categoryKey]
    if not members then return end
    table.sort(members, function(a, b)
        if a.zone == b.zone then return a.name < b.name end
        return a.zone < b.zone
    end)
    ClearDetailLines()
    local yOffset = -GZO.DETAIL_TOP_PAD
    local index = 1
    local leftWithIndicator = GZO.DETAIL_LEFT_PAD + GZO.DETAIL_INDICATOR_SIZE + GZO.DETAIL_INDICATOR_GAP
    local prevZone, sepCount = nil, 0

    if members and #members > 0 then
        for _, info in ipairs(members) do
            if GZO.CATEGORIES_WITH_ZONE_SEPARATOR[categoryKey] and prevZone and info.zone ~= prevZone then
                sepCount = sepCount + 1
                local sep = GetSeparatorLine(sepCount)
                sep:ClearAllPoints()
                sep:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", GZO.DETAIL_LEFT_PAD, yOffset)
                sep:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", GZO.DETAIL_RIGHT_PAD, yOffset)
                sep:Show()
                yOffset = yOffset - GZO.SEPARATOR_HEIGHT - GZO.SEPARATOR_PADDING
            end
            prevZone = info.zone
            local entry = EnsureDetailEntry(index)
            local fs, tex = entry.fs, entry.tex
            entry.playerName = info.name
            entry.charName = info.charName
            entry.blinkCategory = (categoryKey == "instance" or categoryKey == "raid" or categoryKey == "delve") and categoryKey or nil
            tex:ClearAllPoints()
            tex:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", GZO.DETAIL_LEFT_PAD, yOffset - 4)
            if info.durationColor then
                tex:SetColorTexture(info.durationColor[1], info.durationColor[2], info.durationColor[3], 1)
                tex:Show()
            else tex:Hide() end
            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", leftWithIndicator, yOffset)
            fs:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", GZO.DETAIL_RIGHT_PAD, yOffset)
            fs:SetText(info.displayText)
            fs:SetTextColor(GetClassColorForDetail(info.class))
            fs:Show()
            entry.hoverFrame:ClearAllPoints()
            entry.hoverFrame:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", leftWithIndicator, yOffset)
            entry.hoverFrame:SetPoint("BOTTOMRIGHT", detailsFrame, "TOPRIGHT", GZO.DETAIL_RIGHT_PAD, yOffset - GZO.DETAIL_ROW_HEIGHT)
            entry.hoverFrame:Show()
            yOffset = yOffset - GZO.DETAIL_ROW_HEIGHT
            index = index + 1
        end
        for i = sepCount + 1, #detailSeparators do detailSeparators[i]:Hide() end
    else
        local entry = EnsureDetailEntry(1)
        entry.playerName = nil
        entry.blinkCategory = nil
        entry.tex:Hide()
        if entry.hoverFrame then entry.hoverFrame:Hide() end
        entry.fs:ClearAllPoints()
        entry.fs:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", GZO.DETAIL_LEFT_PAD, yOffset)
        entry.fs:SetText("Keine Spieler online")
        entry.fs:SetTextColor(0.5, 0.5, 0.5)
        entry.fs:Show()
        yOffset = yOffset - GZO.DETAIL_ROW_HEIGHT
    end

    local desiredHeight = math.abs(yOffset) + GZO.DETAIL_TOP_PAD
    detailsFrame:SetHeight(desiredHeight)
    detailsFrame:ClearAllPoints()
    local frameBottom = frame:GetBottom() or 0
    if frameBottom - desiredHeight < GZO.DETAIL_FLIP_THRESHOLD then
        detailsFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
        detailsFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    else
        detailsFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
        detailsFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
    end
end
GZO.BuildDetailLines = BuildDetailLines

local function ShowDetails(categoryKey)
    if GZO.currentDetailsCategory == categoryKey and detailsFrame:IsShown() then
        detailsFrame:Hide()
        GZO.currentDetailsCategory = nil
        return
    end
    GZO.currentDetailsCategory = categoryKey
    BuildDetailLines(categoryKey)
    detailsFrame:Show()
    GZO.RefreshAlpha()
end

for _, key in ipairs(GZO.ORDERED_CATEGORY_KEYS) do
    (function(k) categoryRows[k].btn:SetScript("OnClick", function() ShowDetails(k) end) end)(key)
end

local function ApplyFrameTheme(themeKey)
    local mainFrame = _G["GuildZoneOverviewFrame"]
    local detailsFrameRef = mainFrame and mainFrame.detailsFrame
    local theme = GZO.UI_THEMES[themeKey] or GZO.UI_THEMES[GZO.DEFAULT_FRAME_THEME]
    if not theme or not mainFrame or not mainFrame.SetBackdrop then return end
    mainFrame:SetBackdrop(theme.backdrop)
    mainFrame:SetBackdropColor(theme.bgColor[1], theme.bgColor[2], theme.bgColor[3], theme.bgColor[4])
    mainFrame:SetBackdropBorderColor(theme.borderColor[1], theme.borderColor[2], theme.borderColor[3], theme.borderColor[4])
    if detailsFrameRef and detailsFrameRef.SetBackdrop then
        detailsFrameRef:SetBackdrop(theme.backdrop)
        detailsFrameRef:SetBackdropColor(theme.bgColor[1], theme.bgColor[2], theme.bgColor[3], theme.bgColor[4])
        detailsFrameRef:SetBackdropBorderColor(theme.borderColor[1], theme.borderColor[2], theme.borderColor[3], theme.borderColor[4])
    end
end
GZO.ApplyFrameTheme = ApplyFrameTheme

function GZO.RestorePosition()
    local db = _G["GuildZoneOverviewDB"]
    if not db or type(db) ~= "table" then return end
    if db.point then
        frame:ClearAllPoints()
        frame:SetPoint(db.point, UIParent, db.relativePoint or db.point, db.xOfs or 0, db.yOfs or 0)
    end
    frame:SetWidth(db.width or 180)
end

function GZO.UpdateVisibility()
    local db = _G["GuildZoneOverviewDB"]
    if not IsInGuild() then frame:Hide(); return end
    if (IsInGroup() or IsInRaid()) and not (db and db.showFrameInGroup) then frame:Hide(); return end
    frame:Show()
end
