--[[
    GuildZoneOverview - Gilden-Zonenübersicht (WoW Retail)

    Zeigt online Gildenmitglieder nach Kategorien (Instanzen, Raids, Tiefen, Städte, Sonstiges).
    Sichtbar je nach Option auch in Gruppe (z. B. in Tiefen). Klick auf eine Kategorie öffnet
    die Detail-Liste (Name - Zone, klassengefärbt). Bei Änderungen in Instanz/Raid/Tiefe erscheinen
    optional grüne/rote Striche (ein Strich pro Änderung); neue Striche werden rechts angehängt,
    nach jedem 5. Strich ein Abstand, Anzeige-Dauer in den Optionen einstellbar (Standard 10 s).

    Optionen (Interface → AddOns → Gilden Zonenübersicht):
    - Allgemein: Fenster-Hintergrund, Klassenfarbe, Pulsierung wenn inaktiv, Fenster auch in Gruppe anzeigen (z. B. Tiefen).
    - Animation & Benachrichtigung: Dauer, Farbe, Klassenfarbe, Sound bei "jemand online", Button "Online-Anzeige testen".
    - Veränderungen tracken: Strich-Anzeige Dauer (Sekunden), Checkboxen Instanzen/Raids/Tiefen, Buttons +1/-1 zum Testen der Strich-Anzeige.

    SavedVariables: GuildZoneOverviewDB
    DB-Keys: point, relativePoint, xOfs, yOfs, width, animationDurationSec, animationColor, backgroundColor,
             useClassColorAnimation, useClassColorBackground, pulseWhenInactive, playSoundOnOnline,
             showFrameInGroup, floatingLineDurationSec, trackChangesInstance, trackChangesRaid, trackChangesDelve.
]]
local addonName = ...
local ADDON_VERSION = "1.3.0"

local GuildZoneOverview = {}

GuildZoneOverviewDB = GuildZoneOverviewDB or {}

local function ApplyDBDefaults()
    local db = _G["GuildZoneOverviewDB"]
    if type(db) ~= "table" then
        _G["GuildZoneOverviewDB"] = {}
        db = _G["GuildZoneOverviewDB"]
    end
    db.animationDurationSec = db.animationDurationSec or 10
    db.animationColor = db.animationColor or { 1, 1, 1 }
    if not db.backgroundColor then
        db.backgroundColor = { 0.05, 0.05, 0.08, 0.9 }
    end
    if db.useClassColorAnimation == nil then db.useClassColorAnimation = false end
    if db.useClassColorBackground == nil then db.useClassColorBackground = false end
    if db.pulseWhenInactive == nil then db.pulseWhenInactive = true end
    if db.playSoundOnOnline == nil then db.playSoundOnOnline = true end
    if db.showFrameInGroup == nil then db.showFrameInGroup = true end
    if db.trackChangesInstance == nil then db.trackChangesInstance = true end
    if db.trackChangesRaid == nil then db.trackChangesRaid = true end
    if db.trackChangesDelve == nil then db.trackChangesDelve = true end
    if db.floatingLineDurationSec == nil then db.floatingLineDurationSec = 10 end
end

local function GetPlayerClassColor()
    local _, classFileName = UnitClass("player")
    if not classFileName then return nil end
    local colors = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName])
    if not colors then return nil end
    return colors.r, colors.g, colors.b
end

local FONT_PATH = "Fonts\\ARIALN.TTF"

local headerFont = CreateFont("GZOHeaderFont")
headerFont:SetFont(FONT_PATH, 14, "OUTLINE")

local lineFont = CreateFont("GZOLineFont")
lineFont:SetFont(FONT_PATH, 13, "")

local measureFS = UIParent:CreateFontString(nil, "OVERLAY")
measureFS:Hide()

local CITY_ZONES = { ["Sturmwind"]=true, ["Orgrimmar"]=true, ["Eisenschmiede"]=true, ["Darnassus"]=true, ["Unterstadt"]=true, ["Silbermond"]=true, ["Exodar"]=true, ["Shattrath"]=true, ["Dalaran"]=true, ["Oribos"]=true, ["Valdrakken"]=true, ["Dornogal"]=true }
local RAID_ZONES = {
    ["Geschmolzener Kern"]=true, ["Pechschwingenhort"]=true, ["Naxxramas"]=true, ["Karazhan"]=true, ["Der Schwarze Tempel"]=true, ["Ulduar"]=true, ["Prüfung des Kreuzfahrers"]=true, ["Eiskronenzitadelle"]=true, ["Drachenseele"]=true, ["Hochfels"]=true, ["Schwarzfelsgießerei"]=true, ["Höllenfeuerzitadelle"]=true, ["Smaragdnachtmahr"]=true, ["Die Nachtfestung"]=true, ["Grabmal des Sargeras"]=true, ["Antorus, der Brennende Thron"]=true, ["Uldir"]=true, ["Der Tiegel der Stürme"]=true, ["Der Ewige Palast"]=true, ["Ny'alotha, die Erwachte Stadt"]=true, ["Schloss Nathria"]=true, ["Sanktum der Herrschaft"]=true, ["Mausoleum der Ersten"]=true, ["Palast der Nerub'ar"]=true,
    ["Der Traumriss"]=true, ["Die Leerenspitze"]=true, ["Marsch auf Quel'Danas"]=true,
}
local DUNGEON_ZONES = {
    ["Todesminen"]=true, ["Scharlachrotes Kloster"]=true, ["Der Tiefensumpf"]=true, ["Der Schwarze Morast"]=true, ["Die Sklavenunterkünfte"]=true, ["Die Zerschmetterten Hallen"]=true, ["Brauenwirbelkeller"]=true, ["Sturmbräu-Brauerei"]=true, ["Tempel der Jadeschlange"]=true, ["Hallen der Tapferkeit"]=true, ["Das Finsterherzdickicht"]=true, ["Hof der Sterne"]=true, ["Rabenwehr"]=true, ["Neltharions Hort"]=true, ["Rückkehr nach Karazhan"]=true,
    ["Windläuferturm"]=true, ["Terrasse der Magister"]=true, ["Mördergasse"]=true, ["Nalorakks Bau"]=true, ["Arena der Leerennarbe"]=true, ["Das blendende Tal"]=true, ["Maisarakavernen"]=true, ["Nexuspunkt Xenas"]=true,
    ["Windrunner Spire"]=true, ["Magister's Terrace"]=true, ["Murder Row"]=true, ["Den of Nalorakk"]=true, ["Voidscar Arena"]=true, ["The Blinding Vale"]=true, ["Maisara Caverns"]=true, ["Nexus-Point Xenas"]=true,
}
local DELVE_ZONES = { ["Tiefen"]=true }

local membersByCategory = { instance = {}, raid = {}, delve = {}, city = {}, other = {} }
local currentDetailsCategory = nil
local prevOnlineCount = nil

-- State tracking für Floating Numbers
local prevCategoryCounts = { instance = 0, raid = 0, delve = 0, city = 0, other = 0 }
local isInitialLoad = true
-- Y unter der letzten sichtbaren Kategoriezeile (für Test-Floating: Zeile darunter anzeigen)
local layoutBottomY = -26

local RefreshAlpha

local function ClassifyZone(zoneName)
    if not zoneName or zoneName == "" then return "other" end
    if CITY_ZONES[zoneName] then return "city"
    elseif RAID_ZONES[zoneName] then return "raid"
    elseif DUNGEON_ZONES[zoneName] then return "instance"
    elseif DELVE_ZONES[zoneName] then return "delve"
    else return "other" end
end

local frame = CreateFrame("Frame", "GuildZoneOverviewFrame", UIParent)
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

local INACTIVE_ALPHA = 0.55
local ACTIVE_ALPHA = 1.0
local PULSE_ALPHA_MIN, PULSE_ALPHA_MAX = 0.45, 0.58
frame:SetAlpha(INACTIVE_ALPHA)

local function CreateTexture(parent, layer, r, g, b, a, h)
    local t = parent:CreateTexture(nil, layer)
    t:SetColorTexture(r, g, b, a)
    if h then t:SetHeight(h) else t:SetAllPoints() end
    return t
end

local frameBg = CreateTexture(frame, "BACKGROUND", 0.05, 0.05, 0.08, 0.9)
local function ApplyBackgroundColor()
    if not frameBg then return end
    local r, g, b, a
    if GuildZoneOverviewDB.useClassColorBackground then
        local cr, cg, cb = GetPlayerClassColor()
        if cr and cg and cb then
            r, g, b = cr, cg, cb
        end
    end
    local c = GuildZoneOverviewDB.backgroundColor
    if not r then
        if not c or #c < 4 then return end
        r, g, b, a = c[1], c[2], c[3], c[4]
    else
        a = (c and c[4]) or 0.9
    end
    frameBg:SetColorTexture(r, g, b, a)
end
ApplyBackgroundColor()

local topBorder = CreateTexture(frame, "ARTWORK", 0, 0.8, 1, 1, 2)
topBorder:ClearAllPoints()
topBorder:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
topBorder:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)

local animationTimer = nil
local isAnimatingAlert = false

local function PlayOnlineBlink()
    if not topBorder or not C_Timer then return end
    if animationTimer then
        animationTimer:Cancel()
        animationTimer = nil
    end
    
    if GuildZoneOverviewDB.playSoundOnOnline then
        PlaySound(SOUNDKIT.UI_BNET_TOAST)
    end

    local r, g, b
    if GuildZoneOverviewDB.useClassColorAnimation then
        local cr, cg, cb = GetPlayerClassColor()
        r, g, b = cr or 1, cg or 1, cb or 1
    else
        local col = GuildZoneOverviewDB.animationColor
        r, g, b = (col and col[1]) or 1, (col and col[2]) or 1, (col and col[3]) or 1
    end
    
    topBorder:SetHeight(4)
    topBorder:SetColorTexture(r, g, b, 1)
    
    local duration = tonumber(GuildZoneOverviewDB.animationDurationSec) or 10
    duration = math.max(1, math.min(60, duration))
    local startTime = GetTime()
    
    isAnimatingAlert = true
    RefreshAlpha() 
    
    animationTimer = C_Timer.NewTicker(0.05, function()
        if not topBorder then return end
        local elapsed = GetTime() - startTime
        
        if elapsed >= duration then
            if animationTimer then animationTimer:Cancel() end
            animationTimer = nil
            isAnimatingAlert = false
            topBorder:SetHeight(2)
            topBorder:SetColorTexture(0, 0.8, 1, 1)
            topBorder:SetAlpha(1)
            RefreshAlpha()
            return
        end
        
        local pulseAlpha = 0.3 + 0.7 * math.abs(math.sin(elapsed * math.pi * 1.5))
        topBorder:SetAlpha(pulseAlpha)
    end)
end

local frameGloss = frame:CreateTexture(nil, "ARTWORK")
frameGloss:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -2)
frameGloss:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, -2)
frameGloss:SetHeight(30)
frameGloss:SetGradient("VERTICAL", CreateColor(1, 1, 1, 0), CreateColor(1, 1, 1, 0.05))

local title = frame:CreateFontString(nil, "OVERLAY")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 10, -8)
title:SetFontObject(headerFont)
title:SetText("GILDENÜBERSICHT")
title:SetTextColor(0.9, 0.9, 0.9)

local function CreateRow(yOffset, hue, label)
    local btn = CreateFrame("Button", nil, frame)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, yOffset)
    btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, yOffset)
    btn:SetHeight(18)

    local bar = btn:CreateTexture(nil, "BACKGROUND")
    bar:SetAllPoints()
    
    local topColor, bottomColor, hoverColor
    if hue == "cyan" then
        topColor, bottomColor, hoverColor = CreateColor(0.0, 0.3, 0.5, 0.3), CreateColor(0.0, 0.1, 0.2, 0.3), CreateColor(0.0, 0.5, 0.8, 0.5)
    else
        topColor, bottomColor, hoverColor = CreateColor(0.4, 0.1, 0.6, 0.3), CreateColor(0.15, 0.0, 0.3, 0.3), CreateColor(0.6, 0.2, 0.9, 0.5)
    end
    bar:SetGradient("VERTICAL", bottomColor, topColor)

    local text = btn:CreateFontString(nil, "OVERLAY", "GZOLineFont")
    text:SetPoint("LEFT", btn, "LEFT", 10, 0)
    text:SetPoint("RIGHT", btn, "RIGHT", -10, 0)
    text:SetText(label .. ": 0")
    text:SetTextColor(0.8, 0.8, 0.8)
    text:SetJustifyH("LEFT")
    text:SetWordWrap(false)
    text:SetMaxLines(1)

    btn:SetScript("OnEnter", function()
        bar:SetColorTexture(hoverColor:GetRGBA())
        text:SetTextColor(1, 1, 1)
        if RefreshAlpha then RefreshAlpha() end
    end)
    btn:SetScript("OnLeave", function()
        bar:SetGradient("VERTICAL", bottomColor, topColor)
        text:SetTextColor(0.8, 0.8, 0.8)
        if RefreshAlpha then RefreshAlpha() end
    end)

    return btn, text
end

local btnInst, instancesText = CreateRow(-26, "cyan", "Instanzen")
local btnRaid, raidsText = CreateRow(-44, "violet", "Raids")
local btnDelve, delvesText = CreateRow(-62, "cyan", "Tiefen")
local btnCity, citiesText = CreateRow(-80, "violet", "Städte")
local btnOther, otherText = CreateRow(-98, "cyan", "Sonstiges")

local categoryRows = {
    instance = { btn = btnInst,  text = instancesText },
    raid     = { btn = btnRaid,  text = raidsText     },
    delve    = { btn = btnDelve, text = delvesText    },
    city     = { btn = btnCity,  text = citiesText    },
    other    = { btn = btnOther, text = otherText     },
}

--[[ Striche (grün/rot) für Änderungen: ein Strich pro +1/-1, rechts angehängt, nach 5ern Abstand. ]]
local LINE_WIDTH, LINE_HEIGHT = 3, 12
local LINE_GAP, LINE_GROUP_GAP = 2, 6   -- Abstand zwischen Strichen; Zusatzabstand nach jedem 5.
local LINE_OFFSET_RIGHT = 60            -- Abstand des Strich-Containers vom rechten Buttonrand (px)
local LINE_GREEN = { 0.2, 1, 0.2, 1 }
local LINE_RED   = { 1, 0.2, 0.2, 1 }

local FLOATING_LINE_KEYS = { "instance", "raid", "delve" }

local function LineGapForIndex(i)
    return LINE_GAP + ((i % 5 == 1 and i > 1) and LINE_GROUP_GAP or 0)
end

local function RepositionFloatingLines(row)
    if not row.floatingLineContainer or not row.floatingLines then return end
    local prev
    for i, entry in ipairs(row.floatingLines) do
        local tex = entry.tex
        if tex and tex.SetPoint then
            tex:ClearAllPoints()
            if not prev then
                tex:SetPoint("LEFT", row.floatingLineContainer, "LEFT", 0, 0)
            else
                tex:SetPoint("LEFT", prev, "RIGHT", LineGapForIndex(i), 0)
            end
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
        row.floatingLineContainer:SetPoint("RIGHT", row.btn, "RIGHT", -LINE_OFFSET_RIGHT, 0)
        row.floatingLineContainer:SetSize(1, LINE_HEIGHT)
        row.floatingLines = {}
    end
    local container, list = row.floatingLineContainer, row.floatingLines
    local n = #list
    local lastTex = n > 0 and list[n].tex or nil
    local count = math.abs(diff)
    local isGreen = diff > 0
    local r, g, b = isGreen and LINE_GREEN[1] or LINE_RED[1], isGreen and LINE_GREEN[2] or LINE_RED[2], isGreen and LINE_GREEN[3] or LINE_RED[3]

    for j = 1, count do
        local tex = container:CreateTexture(nil, "OVERLAY")
        tex:SetColorTexture(r, g, b, 1)
        tex:SetSize(LINE_WIDTH, LINE_HEIGHT)
        tex:ClearAllPoints()
        if not lastTex then
            tex:SetPoint("LEFT", container, "LEFT", 0, 0)
        else
            tex:SetPoint("LEFT", lastTex, "RIGHT", LineGapForIndex(n + j), 0)
        end
        lastTex = tex
        list[#list + 1] = { tex = tex, removeAt = removeAt }
    end
end

local floatingLineTicker
local function StartFloatingLineTicker()
    if floatingLineTicker then return end
    floatingLineTicker = C_Timer.NewTicker(0.5, function()
        if not frame or not frame:IsShown() then return end
        local now = GetTime()
        for _, key in ipairs(FLOATING_LINE_KEYS) do
            local row = categoryRows[key]
            if row and row.floatingLines and #row.floatingLines > 0 then
                local removed
                local i, n = 1, #row.floatingLines
                while i <= n do
                    if row.floatingLines[i].removeAt <= now then
                        local entry = table.remove(row.floatingLines, i)
                        if entry and entry.tex then entry.tex:SetParent(nil); entry.tex = nil end
                        n, removed = n - 1, true
                    else
                        i = i + 1
                    end
                end
                if removed then RepositionFloatingLines(row) end
            end
        end
    end)
end
StartFloatingLineTicker()

local detailsFrame = CreateFrame("Frame", nil, frame)
detailsFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
detailsFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
detailsFrame:Hide()

CreateTexture(detailsFrame, "BACKGROUND", 0.05, 0.05, 0.08, 0.95)

local dTopBorder = CreateTexture(detailsFrame, "ARTWORK", 0.6, 0.2, 0.9, 1, 2)
dTopBorder:ClearAllPoints()
dTopBorder:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 0, 0)
dTopBorder:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", 0, 0)

detailsFrame:EnableMouse(true)

function RefreshAlpha()
    if isAnimatingAlert or (detailsFrame:IsShown() and currentDetailsCategory ~= nil) or frame:IsMouseOver() or detailsFrame:IsMouseOver() then
        frame:SetAlpha(ACTIVE_ALPHA)
        detailsFrame:SetAlpha(ACTIVE_ALPHA)
    else
        local a = (GuildZoneOverviewDB.pulseWhenInactive and (PULSE_ALPHA_MIN + PULSE_ALPHA_MAX) / 2) or INACTIVE_ALPHA
        frame:SetAlpha(a)
        detailsFrame:SetAlpha(a)
    end
end

local pulsePhase = 0
if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(0.05, function()
        if not frame:IsShown() then return end
        if isAnimatingAlert or (detailsFrame:IsShown() and currentDetailsCategory ~= nil) or frame:IsMouseOver() or detailsFrame:IsMouseOver() then
            frame:SetAlpha(ACTIVE_ALPHA)
            detailsFrame:SetAlpha(ACTIVE_ALPHA)
            return
        end
        if GuildZoneOverviewDB.pulseWhenInactive then
            pulsePhase = pulsePhase + 0.02
            if pulsePhase > 1 then pulsePhase = 0 end
            local a = PULSE_ALPHA_MIN + (PULSE_ALPHA_MAX - PULSE_ALPHA_MIN) * (0.5 + 0.5 * math.sin(pulsePhase * 2 * math.pi))
            frame:SetAlpha(a)
            detailsFrame:SetAlpha(a)
        else
            frame:SetAlpha(INACTIVE_ALPHA)
            detailsFrame:SetAlpha(INACTIVE_ALPHA)
        end
    end)
end

frame:SetScript("OnEnter", RefreshAlpha)
frame:HookScript("OnLeave", RefreshAlpha)
detailsFrame:SetScript("OnEnter", RefreshAlpha)
detailsFrame:SetScript("OnLeave", RefreshAlpha)

local detailLines = {}

local function ClearDetailLines()
    for _, fs in ipairs(detailLines) do fs:SetText(""); fs:Hide() end
end

local function ShowDetails(categoryKey)
    local members = membersByCategory[categoryKey]

    if currentDetailsCategory == categoryKey and detailsFrame:IsShown() then
        detailsFrame:Hide()
        currentDetailsCategory = nil
        return
    end

    table.sort(members, function(a, b)
        if a.zone == b.zone then return a.name < b.name end
        return a.zone < b.zone
    end)

    currentDetailsCategory = categoryKey
    ClearDetailLines()

    local yOffset = -10
    local index = 1

    if members and #members > 0 then
        for _, info in ipairs(members) do
            local fs = detailLines[index]
            if not fs then
                fs = detailsFrame:CreateFontString(nil, "OVERLAY", "GZOLineFont")
                detailLines[index] = fs
            end

            fs:ClearAllPoints()
            fs:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 10, yOffset)
            fs:SetPoint("TOPRIGHT", detailsFrame, "TOPRIGHT", -10, yOffset)

            local r, g, b = 1, 1, 1
            if info.class then
                local c = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[info.class]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[info.class])
                if c then r, g, b = c.r, c.g, c.b end
            end

            fs:SetText(info.displayText)
            fs:SetTextColor(r, g, b)
            fs:SetJustifyH("LEFT")
            fs:SetWordWrap(false)
            fs:SetMaxLines(1)
            fs:Show()

            yOffset = yOffset - 16
            index = index + 1
        end
    else
        local fs = detailLines[1]
        if not fs then
            fs = detailsFrame:CreateFontString(nil, "OVERLAY", "GZOLineFont")
            detailLines[1] = fs
        end
        fs:ClearAllPoints()
        fs:SetPoint("TOPLEFT", detailsFrame, "TOPLEFT", 10, yOffset)
        fs:SetText("Keine Spieler online")
        fs:SetTextColor(0.5, 0.5, 0.5)
        fs:SetJustifyH("LEFT")
        fs:SetWordWrap(false)
        fs:SetMaxLines(1)
        fs:Show()
        yOffset = yOffset - 16
    end

    local desiredHeight = math.abs(yOffset) + 10
    detailsFrame:SetHeight(desiredHeight)

    detailsFrame:ClearAllPoints()
    local frameBottom = frame:GetBottom() or 0
    if frameBottom - desiredHeight < 20 then
        detailsFrame:SetPoint("BOTTOMLEFT", frame, "TOPLEFT", 0, 2)
        detailsFrame:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", 0, 2)
    else
        detailsFrame:SetPoint("TOPLEFT", frame, "BOTTOMLEFT", 0, -2)
        detailsFrame:SetPoint("TOPRIGHT", frame, "BOTTOMRIGHT", 0, -2)
    end

    detailsFrame:Show()
    RefreshAlpha()
end

btnInst:SetScript("OnClick", function() ShowDetails("instance") end)
btnRaid:SetScript("OnClick", function() ShowDetails("raid") end)
btnDelve:SetScript("OnClick", function() ShowDetails("delve") end)
btnCity:SetScript("OnClick", function() ShowDetails("city") end)
btnOther:SetScript("OnClick", function() ShowDetails("other") end)

local function RestorePosition()
    if GuildZoneOverviewDB.point then
        frame:ClearAllPoints()
        frame:SetPoint(GuildZoneOverviewDB.point, UIParent, GuildZoneOverviewDB.relativePoint or GuildZoneOverviewDB.point, GuildZoneOverviewDB.xOfs or 0, GuildZoneOverviewDB.yOfs or 0)
    end
    frame:SetWidth(GuildZoneOverviewDB.width or 180)
end

local function UpdateVisibility()
    if not IsInGuild() then
        frame:Hide()
        return
    end
    if (IsInGroup() or IsInRaid()) and not (GuildZoneOverviewDB.showFrameInGroup) then
        frame:Hide()
        return
    end
    frame:Show()
end

local function UpdateGuildZoneCounts()
    if not IsInGuild() then return end

    for _, tbl in pairs(membersByCategory) do table.wipe(tbl) end
    local counts = { instance = 0, raid = 0, delve = 0, city = 0, other = 0 }

    local minWidth = 180
    local maxContentWidth = minWidth

    measureFS:SetFontObject(headerFont)
    measureFS:SetText("GILDENÜBERSICHT")
    local titleWidth = measureFS:GetStringWidth() or 0
    if titleWidth > maxContentWidth then maxContentWidth = titleWidth end

    measureFS:SetFontObject(lineFont)

    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, zone, _, _, isOnline, _, class = GetGuildRosterInfo(i)
        if isOnline then
            name = name or "?"
            zone = zone or "Unbekannte Zone"
            local category = ClassifyZone(zone)
            
            counts[category] = counts[category] + 1
            local displayText = string.format("%s - %s", name, zone)
            
            table.insert(membersByCategory[category], { name = name, class = class, zone = zone, displayText = displayText })

            measureFS:SetText(displayText)
            local totalLineWidth = measureFS:GetStringWidth() or 0
            if totalLineWidth > maxContentWidth then
                maxContentWidth = totalLineWidth
            end
        end
    end

    maxContentWidth = math.max(minWidth, maxContentWidth + 24)

    frame:SetWidth(maxContentWidth)
    GuildZoneOverviewDB.width = maxContentWidth

    instancesText:SetText("Instanzen: " .. counts.instance)
    raidsText:SetText("Raids: " .. counts.raid)
    delvesText:SetText("Tiefen: " .. counts.delve)
    citiesText:SetText("Städte: " .. counts.city)
    otherText:SetText("Sonstiges: " .. counts.other)

    local totalOnline = counts.instance + counts.raid + counts.delve + counts.city + counts.other
    if prevOnlineCount ~= nil and totalOnline > prevOnlineCount then
        PlayOnlineBlink()
    end
    prevOnlineCount = totalOnline

    local orderedKeys = { "instance", "raid", "delve", "city", "other" }
    local y = -26
    local step = -18
    for _, key in ipairs(orderedKeys) do
        local row = categoryRows[key]
        if row and counts[key] and counts[key] > 0 then
            row.btn:Show()
            row.btn:ClearAllPoints()
            row.btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, y)
            row.btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, y)
            y = y + step
        elseif row then
            row.btn:Hide()
        end
    end
    layoutBottomY = y  -- nächste freie Y-Position (unter der letzten Zeile)

    -- Floating Text Logik für Tiefen, Instanzen, Raids (nur wenn Option für Kategorie aktiv)
    if not isInitialLoad then
        local floatCategories = { "instance", "raid", "delve" }
        for _, key in ipairs(floatCategories) do
            local track = (key == "instance" and GuildZoneOverviewDB.trackChangesInstance) or (key == "raid" and GuildZoneOverviewDB.trackChangesRaid) or (key == "delve" and GuildZoneOverviewDB.trackChangesDelve)
            if track then
                local diff = counts[key] - (prevCategoryCounts[key] or 0)
                if diff ~= 0 and categoryRows[key] and categoryRows[key].btn:IsShown() then
                    SpawnFloatingDiff(categoryRows[key], diff)
                end
            end
        end
    end

    -- Counter für den nächsten Durchlauf speichern
    for k, v in pairs(counts) do
        prevCategoryCounts[k] = v
    end
    isInitialLoad = false
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:RegisterEvent("PLAYER_LOGIN")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("PLAYER_GUILD_UPDATE")
eventFrame:RegisterEvent("GUILD_ROSTER_UPDATE")
eventFrame:RegisterEvent("GROUP_ROSTER_UPDATE")

eventFrame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        ApplyDBDefaults()
        GuildZoneOverviewDB = _G["GuildZoneOverviewDB"]
        ApplyBackgroundColor()
        RestorePosition()
        if GuildZoneOverviewOptionsPanel and GuildZoneOverviewOptionsPanel.refresh then
            GuildZoneOverviewOptionsPanel:refresh()
        end
    elseif event == "PLAYER_LOGIN" then
        C_GuildInfo.GuildRoster()
        UpdateVisibility()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_GUILD_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        if event == "PLAYER_GUILD_UPDATE" then C_GuildInfo.GuildRoster() end
        UpdateVisibility()
    elseif event == "GUILD_ROSTER_UPDATE" then
        UpdateGuildZoneCounts()
    end
end)

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(30, function() if IsInGuild() then C_GuildInfo.GuildRoster() end end)
end

-- ========== Options-Panel ==========
do
    local panel = CreateFrame("Frame", "GuildZoneOverviewOptionsPanel", UIParent)
    panel.name = "Gilden Zonenübersicht"
    panel:SetWidth(500)
    panel:SetHeight(520)

    local function OpenColorPicker(r, g, b, a, hasOpacity, swatchFunc, cancelFunc)
        a = a or 1
        if ColorPickerFrame.SetupColorPickerAndShow then
            ColorPickerFrame.previousValues = { r = r, g = g, b = b, a = a }
            ColorPickerFrame:SetupColorPickerAndShow({
                r = r, g = g, b = b,
                opacity = a,
                hasOpacity = hasOpacity,
                swatchFunc = swatchFunc,
                cancelFunc = cancelFunc,
            })
        else
            ColorPickerFrame.previousValues = { r, g, b, a }
            ColorPickerFrame.func = swatchFunc
            ColorPickerFrame.cancelFunc = cancelFunc
            ColorPickerFrame.hasOpacity = hasOpacity
            if ColorPickerFrame.SetColorRGB then ColorPickerFrame:SetColorRGB(r, g, b) end
            if hasOpacity and ColorPickerFrame.SetColorAlpha then ColorPickerFrame:SetColorAlpha(a) end
            if OpacitySliderFrame and OpacitySliderFrame.SetValue and hasOpacity then OpacitySliderFrame:SetValue(a) end
            ColorPickerFrame:Show()
        end
    end

    local genTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    genTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
    genTitle:SetText("Allgemein")

    local bgColorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    bgColorLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -44)
    bgColorLabel:SetText("Fenster-Hintergrund")

    local bgColorBtn = CreateFrame("Button", nil, panel)
    bgColorBtn:SetSize(24, 24)
    bgColorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -64)
    local bgColorTex = bgColorBtn:CreateTexture(nil, "BACKGROUND")
    bgColorTex:SetAllPoints()
    
    local bgClassColorCheck = CreateFrame("CheckButton", "GZOBgClassColorCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    bgClassColorCheck:SetPoint("LEFT", bgColorBtn, "RIGHT", 8, 0)
    if _G[bgClassColorCheck:GetName().."Text"] then _G[bgClassColorCheck:GetName().."Text"]:SetText("Klassenfarbe") end
    bgClassColorCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB.useClassColorBackground = self:GetChecked()
        ApplyBackgroundColor()
        local c = GuildZoneOverviewDB.backgroundColor or { 0.05, 0.05, 0.08, 0.9 }
        local r, g, b = c[1], c[2], c[3]
        if GuildZoneOverviewDB.useClassColorBackground then
            local cr, cg, cb = GetPlayerClassColor()
            if cr and cg and cb then r, g, b = cr, cg, cb end
        end
        bgColorTex:SetColorTexture(r, g, b, c[4] or 1)
    end)
    bgColorBtn:SetScript("OnClick", function()
        local c = GuildZoneOverviewDB.backgroundColor or { 0.05, 0.05, 0.08, 0.9 }
        local a = c[4] or 1
        OpenColorPicker(c[1], c[2], c[3], a, true, function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            local a2 = 1
            if ColorPickerFrame.GetColorAlpha then a2 = ColorPickerFrame:GetColorAlpha()
            elseif OpacitySliderFrame and OpacitySliderFrame.GetValue then a2 = OpacitySliderFrame:GetValue() end
            GuildZoneOverviewDB.backgroundColor = { r, g, b, a2 }
            GuildZoneOverviewDB.useClassColorBackground = false
            bgClassColorCheck:SetChecked(false)
            bgColorTex:SetColorTexture(r, g, b, a2)
            if frameBg then frameBg:SetColorTexture(r, g, b, a2) end
        end, function()
            local p = ColorPickerFrame.previousValues
            if p then
                local r = p.r or p[1]
                local g = p.g or p[2]
                local b = p.b or p[3]
                local a2 = p.a or p[4] or 1
                if r and g and b then GuildZoneOverviewDB.backgroundColor = { r, g, b, a2 } end
            end
            local bc = GuildZoneOverviewDB.backgroundColor or { 0.05, 0.05, 0.08, 0.9 }
            bgColorTex:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 1)
            if frameBg then frameBg:SetColorTexture(bc[1], bc[2], bc[3], bc[4] or 1) end
        end)
    end)

    local pulseCheck = CreateFrame("CheckButton", "GZOPulseWhenInactive", panel, "InterfaceOptionsCheckButtonTemplate")
    pulseCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -90)
    if _G[pulseCheck:GetName().."Text"] then _G[pulseCheck:GetName().."Text"]:SetText("Dezente Pulsierung wenn inaktiv") end
    pulseCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB.pulseWhenInactive = self:GetChecked()
    end)

    local showInGroupCheck = CreateFrame("CheckButton", "GZOShowInGroupCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    showInGroupCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -112)
    if _G[showInGroupCheck:GetName().."Text"] then _G[showInGroupCheck:GetName().."Text"]:SetText("Fenster auch in Gruppe anzeigen (z. B. in Tiefen)") end
    showInGroupCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB.showFrameInGroup = self:GetChecked()
        UpdateVisibility()
    end)

    local animTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    animTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -148)
    animTitle:SetText("Animation & Benachrichtigung")

    local durationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    durationLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -176)
    durationLabel:SetText("Dauer (Sekunden)")

    local durationSlider = CreateFrame("Slider", "GZODurationSlider", panel, "OptionsSliderTemplate")
    durationSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -196)
    durationSlider:SetWidth(200)
    durationSlider:SetMinMaxValues(1, 60)
    durationSlider:SetValueStep(1)
    durationSlider:SetObeyStepOnDrag(true)
    local skipDurationSliderWrite = false
    local lowLab, highLab = durationSlider:GetName() .. "Low", durationSlider:GetName() .. "High"
    if _G[lowLab] then _G[lowLab]:SetText("1") end
    if _G[highLab] then _G[highLab]:SetText("60") end
    local durationValueText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    durationValueText:SetPoint("LEFT", durationSlider, "RIGHT", 12, 0)
    
    durationSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if not skipDurationSliderWrite then
            GuildZoneOverviewDB.animationDurationSec = value
        end
        durationValueText:SetText(tostring(value))
    end)

    local animColorLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    animColorLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -232)
    animColorLabel:SetText("Animationsfarbe")

    local animColorBtn = CreateFrame("Button", nil, panel)
    animColorBtn:SetSize(24, 24)
    animColorBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -250)
    local animColorTex = animColorBtn:CreateTexture(nil, "BACKGROUND")
    animColorTex:SetAllPoints()
    
    local animClassColorCheck = CreateFrame("CheckButton", "GZOAnimClassColorCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    animClassColorCheck:SetPoint("LEFT", animColorBtn, "RIGHT", 8, 0)
    if _G[animClassColorCheck:GetName().."Text"] then _G[animClassColorCheck:GetName().."Text"]:SetText("Klassenfarbe") end
    animClassColorCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB.useClassColorAnimation = self:GetChecked()
        local r, g, b = 1, 1, 1
        if GuildZoneOverviewDB.useClassColorAnimation then
            local cr, cg, cb = GetPlayerClassColor()
            if cr and cg and cb then r, g, b = cr, cg, cb end
        else
            local c = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
            r, g, b = c[1], c[2], c[3]
        end
        animColorTex:SetColorTexture(r, g, b, 1)
    end)
    animColorBtn:SetScript("OnClick", function()
        local c = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
        OpenColorPicker(c[1], c[2], c[3], 1, false, function()
            local r, g, b = ColorPickerFrame:GetColorRGB()
            GuildZoneOverviewDB.animationColor = { r, g, b }
            GuildZoneOverviewDB.useClassColorAnimation = false
            animClassColorCheck:SetChecked(false)
            animColorTex:SetColorTexture(r, g, b, 1)
        end, function()
            local p = ColorPickerFrame.previousValues
            if p then
                local r = p.r or p[1]
                local g = p.g or p[2]
                local b = p.b or p[3]
                if r and g and b then GuildZoneOverviewDB.animationColor = { r, g, b } end
            end
            local rec = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
            animColorTex:SetColorTexture(rec[1], rec[2], rec[3], 1)
        end)
    end)

    local soundCheck = CreateFrame("CheckButton", "GZOSoundCheck", panel, "InterfaceOptionsCheckButtonTemplate")
    soundCheck:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -278)
    if _G[soundCheck:GetName().."Text"] then _G[soundCheck:GetName().."Text"]:SetText("Sound abspielen ('Bnet Toast'), wenn jemand online kommt") end
    soundCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB.playSoundOnOnline = self:GetChecked()
    end)

    local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    testBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -308)
    testBtn:SetSize(180, 22)
    if testBtn.SetText then
        testBtn:SetText("Online-Anzeige testen")
    else
        local t = testBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        t:SetText("Online-Anzeige testen")
        t:SetPoint("CENTER", testBtn, "CENTER", 0, 0)
    end
    testBtn:SetScript("OnClick", function()
        PlayOnlineBlink()
    end)

    -- Abschnitt: Veränderungen tracken (Striche grün/rot pro Kategorie, Test-Buttons)
    local trackTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    trackTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -338)
    trackTitle:SetText("Veränderungen tracken")

    local lineDurationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineDurationLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -358)
    lineDurationLabel:SetText("Strich-Anzeige Dauer (Sekunden)")

    local lineDurationSlider = CreateFrame("Slider", "GZOLineDurationSlider", panel, "OptionsSliderTemplate")
    lineDurationSlider:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -378)
    lineDurationSlider:SetWidth(200)
    lineDurationSlider:SetMinMaxValues(1, 60)
    lineDurationSlider:SetValueStep(1)
    lineDurationSlider:SetObeyStepOnDrag(true)
    local skipLineDurationSliderWrite = false
    local lineLow, lineHigh = lineDurationSlider:GetName() .. "Low", lineDurationSlider:GetName() .. "High"
    if _G[lineLow] then _G[lineLow]:SetText("1") end
    if _G[lineHigh] then _G[lineHigh]:SetText("60") end
    local lineDurationValueText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lineDurationValueText:SetPoint("LEFT", lineDurationSlider, "RIGHT", 12, 0)
    lineDurationSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if not skipLineDurationSliderWrite then
            GuildZoneOverviewDB.floatingLineDurationSec = value
        end
        lineDurationValueText:SetText(tostring(value))
    end)

    -- Test-Zeile in der nächsten freien Zeile unter den sichtbaren Kategorien (layoutBottomY aus UpdateGuildZoneCounts)
    local function makeTrackRow(y, key, label, dbKey)
        local cb = CreateFrame("CheckButton", "GZOTrack" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
        if _G[cb:GetName().."Text"] then _G[cb:GetName().."Text"]:SetText(label) end
        cb:SetScript("OnClick", function(self) GuildZoneOverviewDB[dbKey] = self:GetChecked() end)
        local function runFloatingSimulation(diff)
            local row = categoryRows[key]
            if not row then return end
            local wasShown = row.btn:IsShown()
            if not wasShown then
                local testY = layoutBottomY  -- nächste freie Zeile unter den sichtbaren Kategorien
                row.btn:Show()
                row.btn:ClearAllPoints()
                row.btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, testY)
                row.btn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, testY)
            end
            SpawnFloatingDiff(row, diff)
            if not wasShown and C_Timer then
                C_Timer.After(1.5, function() UpdateGuildZoneCounts() end)
            end
        end
        local btnPlus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btnPlus:SetPoint("LEFT", cb, "RIGHT", 180, 0)
        btnPlus:SetSize(36, 22)
        if btnPlus.SetText then btnPlus:SetText("+1") else local t = btnPlus:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t:SetText("+1"); t:SetPoint("CENTER"); end
        btnPlus:SetScript("OnClick", function() runFloatingSimulation(1) end)
        local btnMinus = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
        btnMinus:SetPoint("LEFT", btnPlus, "RIGHT", 4, 0)
        btnMinus:SetSize(36, 22)
        if btnMinus.SetText then btnMinus:SetText("-1") else local t = btnMinus:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t:SetText("-1"); t:SetPoint("CENTER"); end
        btnMinus:SetScript("OnClick", function() runFloatingSimulation(-1) end)
        return cb
    end
    local trackInstCheck = makeTrackRow(-398, "instance", "Instanzen", "trackChangesInstance")
    local trackRaidCheck = makeTrackRow(-426, "raid", "Raids", "trackChangesRaid")
    local trackDelveCheck = makeTrackRow(-454, "delve", "Tiefen", "trackChangesDelve")

    panel.refresh = function()
        skipDurationSliderWrite = true
        durationSlider:SetValue(GuildZoneOverviewDB.animationDurationSec or 10)
        durationValueText:SetText(tostring(GuildZoneOverviewDB.animationDurationSec or 10))
        skipDurationSliderWrite = false
        skipLineDurationSliderWrite = true
        lineDurationSlider:SetValue(GuildZoneOverviewDB.floatingLineDurationSec or 10)
        lineDurationValueText:SetText(tostring(GuildZoneOverviewDB.floatingLineDurationSec or 10))
        skipLineDurationSliderWrite = false

        bgClassColorCheck:SetChecked(GuildZoneOverviewDB.useClassColorBackground)
        animClassColorCheck:SetChecked(GuildZoneOverviewDB.useClassColorAnimation)
        pulseCheck:SetChecked(GuildZoneOverviewDB.pulseWhenInactive)
        showInGroupCheck:SetChecked(GuildZoneOverviewDB.showFrameInGroup)
        soundCheck:SetChecked(GuildZoneOverviewDB.playSoundOnOnline)
        trackInstCheck:SetChecked(GuildZoneOverviewDB.trackChangesInstance)
        trackRaidCheck:SetChecked(GuildZoneOverviewDB.trackChangesRaid)
        trackDelveCheck:SetChecked(GuildZoneOverviewDB.trackChangesDelve)
        
        local bc = GuildZoneOverviewDB.backgroundColor or { 0.05, 0.05, 0.08, 0.9 }
        local br, bg, bb = bc[1], bc[2], bc[3]
        if GuildZoneOverviewDB.useClassColorBackground then
            local cr, cg, cb = GetPlayerClassColor()
            if cr and cg and cb then br, bg, bb = cr, cg, cb end
        end
        bgColorTex:SetColorTexture(br, bg, bb, bc[4] or 1)
        
        local ac = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
        local ar, ag, ab = ac[1], ac[2], ac[3]
        if GuildZoneOverviewDB.useClassColorAnimation then
            local cr, cg, cb = GetPlayerClassColor()
            if cr and cg and cb then ar, ag, ab = cr, cg, cb end
        end
        animColorTex:SetColorTexture(ar, ag, ab, 1)
    end

    panel:SetScript("OnShow", function(self)
        if self.refresh then self:refresh() end
    end)

    if InterfaceOptions_AddCategory then
        InterfaceOptions_AddCategory(panel)
    end
    if Settings and Settings.RegisterCanvasLayoutCategory and Settings.RegisterAddOnCategory then
        local ok, category = pcall(Settings.RegisterCanvasLayoutCategory, panel, "Gilden Zonenübersicht")
        if ok and category then
            Settings.RegisterAddOnCategory(category)
        end
    end
end