local addonName = ...
local GZO = _G.GZO

local function ApplyDBDefaults()
    local db = _G["GuildZoneOverviewDB"]
    if type(db) ~= "table" then
        _G["GuildZoneOverviewDB"] = {}
        db = _G["GuildZoneOverviewDB"]
    end
    for key, default in pairs(GZO.DB_DEFAULTS) do
        if db[key] == nil then db[key] = default end
    end
end

local function GetPlayerClassColor()
    local _, classFileName = UnitClass("player")
    if not classFileName then return nil end
    local colors = (CUSTOM_CLASS_COLORS and CUSTOM_CLASS_COLORS[classFileName]) or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[classFileName])
    if not colors then return nil end
    return colors.r, colors.g, colors.b
end

local function BuildDynamicZoneCaches()
    if not EJ_GetNumTiers then return end
    for tier = 1, EJ_GetNumTiers() do
        EJ_SelectTier(tier)
        local i = 1
        while true do
            local instanceID = EJ_GetInstanceByIndex(i, false)
            if not instanceID or instanceID == 0 then break end
            local name = EJ_GetInstanceInfo(instanceID)
            if name and name ~= "" then GZO.DUNGEON_ZONES[name] = true end
            i = i + 1
        end
        i = 1
        while true do
            local instanceID = EJ_GetInstanceByIndex(i, true)
            if not instanceID or instanceID == 0 then break end
            local name = EJ_GetInstanceInfo(instanceID)
            if name and name ~= "" then GZO.RAID_ZONES[name] = true end
            i = i + 1
        end
    end
end

local function ClassifyZone(zoneName)
    if not zoneName or zoneName == "" then return "other" end
    if GZO.CITY_ZONES[zoneName] then return "city" end
    if GZO.ZONE_AS_OTHER_BLACKLIST[zoneName] then return "other" end
    if GZO.RAID_ZONES[zoneName] then return "raid"
    elseif GZO.DUNGEON_ZONES[zoneName] then return "instance"
    elseif GZO.DELVE_ZONES[zoneName] then return "delve"
    else return "other" end
end

local function GetBaseName(name)
    return name and string.match(name, "^([^%-]+)") or name
end

local function ParseMainFromGuildNote(publicNote, charName, guildMemberNamesLower)
    local baseName = string.match(charName, "^([^%-]+)") or charName
    if type(publicNote) ~= "string" or publicNote == "" then return baseName end
    local noteTrimmed = string.match(publicNote, "^%s*(.-)%s*$")
    if not noteTrimmed then return baseName end
    local noteLower = string.lower(noteTrimmed)
    local function useOnlyIfInGuild(extractedName)
        if not guildMemberNamesLower then return extractedName end
        if guildMemberNamesLower[string.lower(extractedName)] then return extractedName end
        return baseName
    end
    if noteLower == "main" or noteLower == "twink" or noteLower == "alt" then return baseName end
    local professionKeywords = {
        "juwe", "bergbau", "alchemie", "kräuter", "vz", "verzauberer",
        "schmied", "lederer", "inschrift", "schneider", "ingi",
        "ingenieur", "kürschner", "koch", "angler"
    }
    for _, keyword in ipairs(professionKeywords) do
        if string.find(noteLower, keyword) then return baseName end
    end
    if string.match(noteLower, "^main %-") then return baseName end
    local mainName = string.match(noteTrimmed, "^[Mm]ain[,:]?%s+([A-ZÄÖÜ][a-zäöüß]+)")
    if mainName then return useOnlyIfInGuild(mainName) end
    mainName = string.match(noteTrimmed, "^([A-ZÄÖÜ][a-zäöüß]+)$")
    if mainName then return useOnlyIfInGuild(mainName) end
    return baseName
end

local function GetDurationColor(minutes)
    if not minutes or minutes < 0 then return nil end
    for _, b in ipairs(GZO.DURATION_BUCKETS) do
        if minutes <= b.maxMin then return b.color end
    end
    return GZO.DURATION_BUCKETS[#GZO.DURATION_BUCKETS].color
end

GZO.membersByCategory = { instance = {}, raid = {}, delve = {}, city = {}, other = {} }
GZO.currentDetailsCategory = nil
local prevOnlineCount = nil
GZO.prevCategoryCounts = { instance = 0, raid = 0, delve = 0, city = 0, other = 0 }
GZO.isInitialLoad = true
GZO.isTestingFloating = false
GZO.prevPlayerZones = {}
GZO.playerZoneFirstSeen = {}
GZO.guildMemberNamesLower = {}
GZO.onlineList = {}
GZO.currentPlayers = {}
GZO.layoutBottomY = -26

local headerFont = CreateFont("GZOHeaderFont")
headerFont:SetFont(GZO.FONT_PATH, 14, "OUTLINE")
local lineFont = CreateFont("GZOLineFont")
lineFont:SetFont(GZO.FONT_PATH, 13, "")
local measureFS = UIParent:CreateFontString(nil, "OVERLAY")
measureFS:Hide()

local function UpdateGuildZoneCounts()
    if not IsInGuild() then return end
    if GZO.isTestingFloating then return end
    local membersByCategory = GZO.membersByCategory
    local guildMemberNamesLower = GZO.guildMemberNamesLower
    local onlineList = GZO.onlineList
    local currentPlayers = GZO.currentPlayers

    for _, tbl in pairs(membersByCategory) do table.wipe(tbl) end
    table.wipe(guildMemberNamesLower)
    table.wipe(onlineList)
    table.wipe(currentPlayers)
    local counts = { instance = 0, raid = 0, delve = 0, city = 0, other = 0 }

    for i = 1, GetNumGuildMembers() do
        local memberName = select(1, GetGuildRosterInfo(i))
        if memberName then
            guildMemberNamesLower[string.lower(GetBaseName(memberName))] = true
        end
    end

    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, zone, publicNote, _, isOnline, _, class = GetGuildRosterInfo(i)
        if isOnline and name then
            local baseName = GetBaseName(name)
            local displayName = ParseMainFromGuildNote(publicNote, name, guildMemberNamesLower)
            zone = zone or "Unbekannte Zone"
            currentPlayers[baseName] = zone
            table.insert(onlineList, { name = displayName, charName = baseName, zone = zone, class = class })
        end
    end
    local now = GetTime()
    for name, zone in pairs(currentPlayers) do
        if GZO.prevPlayerZones[name] ~= zone then
            GZO.playerZoneFirstSeen[name] = now
        end
        GZO.prevPlayerZones[name] = zone
    end
    for name in pairs(GZO.prevPlayerZones) do
        if not currentPlayers[name] then
            GZO.prevPlayerZones[name] = nil
            GZO.playerZoneFirstSeen[name] = nil
        end
    end

    local minWidth = 180
    local maxContentWidth = minWidth
    measureFS:SetFontObject(headerFont)
    measureFS:SetText("GILDENÜBERSICHT")
    local titleWidth = measureFS:GetStringWidth() or 0
    if titleWidth > maxContentWidth then maxContentWidth = titleWidth end
    measureFS:SetFontObject(lineFont)

    for _, info in ipairs(onlineList) do
        local name, zone, class = info.name, info.zone, info.class
        local charName = info.charName or name
        local category = ClassifyZone(zone)
        counts[category] = counts[category] + 1
        local durationMin = GZO.playerZoneFirstSeen[charName] and (now - GZO.playerZoneFirstSeen[charName]) / 60 or 0
        local durationColor = (category ~= "other") and GetDurationColor(durationMin) or nil
        table.insert(membersByCategory[category], { name = name, charName = charName, class = class, zone = zone, displayText = string.format("%s - %s", name, zone), durationColor = durationColor, durationMin = durationMin })

        measureFS:SetText(string.format("%s - %s", name, zone))
        local totalLineWidth = measureFS:GetStringWidth() or 0
        if totalLineWidth > maxContentWidth then maxContentWidth = totalLineWidth end
    end

    maxContentWidth = math.max(minWidth, maxContentWidth + 24)
    GZO.mainFrame:SetWidth(maxContentWidth)
    GuildZoneOverviewDB.width = maxContentWidth

    for _, key in ipairs(GZO.ORDERED_CATEGORY_KEYS) do
        GZO.categoryRows[key].text:SetText(GZO.CATEGORY_LABELS[key] .. ": " .. counts[key])
    end

    local totalOnline = counts.instance + counts.raid + counts.delve + counts.city + counts.other
    if prevOnlineCount ~= nil and totalOnline > prevOnlineCount then
        GZO.PlayOnlineBlink()
    end
    prevOnlineCount = totalOnline

    if not GZO.isInitialLoad then
        for _, key in ipairs(GZO.FLOATING_LINE_KEYS) do
            local dbKey = GZO.TRACK_CHANGES_DB_KEYS[key]
            if dbKey and GuildZoneOverviewDB[dbKey] then
                local diff = counts[key] - (GZO.prevCategoryCounts[key] or 0)
                if diff ~= 0 and GZO.categoryRows[key] then
                    GZO.SpawnFloatingDiff(GZO.categoryRows[key], diff)
                end
            end
        end
    end

    local y = -26
    local step = -18
    for _, key in ipairs(GZO.ORDERED_CATEGORY_KEYS) do
        local row = GZO.categoryRows[key]
        local hasCount = row and counts[key] and counts[key] > 0
        local hasLines = row and row.floatingLines and #row.floatingLines > 0
        if hasCount or hasLines then
            row.btn:Show()
            row.btn:ClearAllPoints()
            row.btn:SetPoint("TOPLEFT", GZO.mainFrame, "TOPLEFT", 0, y)
            row.btn:SetPoint("TOPRIGHT", GZO.mainFrame, "TOPRIGHT", 0, y)
            y = y + step
        elseif row then
            row.btn:Hide()
        end
    end
    GZO.layoutBottomY = y

    for _, key in ipairs(GZO.ORDERED_CATEGORY_KEYS) do
        GZO.prevCategoryCounts[key] = counts[key]
    end
    if GZO.detailsFrame and GZO.detailsFrame:IsShown() and GZO.currentDetailsCategory then
        GZO.BuildDetailLines(GZO.currentDetailsCategory)
    end
    GZO.isInitialLoad = false
end

GZO.ApplyDBDefaults = ApplyDBDefaults
GZO.GetPlayerClassColor = GetPlayerClassColor
GZO.BuildDynamicZoneCaches = BuildDynamicZoneCaches
GZO.ClassifyZone = ClassifyZone
GZO.GetBaseName = GetBaseName
GZO.ParseMainFromGuildNote = ParseMainFromGuildNote
GZO.GetDurationColor = GetDurationColor
GZO.UpdateGuildZoneCounts = UpdateGuildZoneCounts

local guildRosterDebounceTimer = nil
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
        local ok, err = pcall(function()
            GZO.RestorePosition()
            GZO.ApplyFrameTheme(GuildZoneOverviewDB.frameTheme or GZO.DEFAULT_FRAME_THEME)
        end)
        if not ok and err then
            geterrorhandler()("GuildZoneOverview init: " .. tostring(err))
        end
        GZO.UpdateVisibility()
        if GuildZoneOverviewOptionsPanel and GuildZoneOverviewOptionsPanel.refresh then
            GuildZoneOverviewOptionsPanel:refresh()
        end
    elseif event == "PLAYER_LOGIN" then
        BuildDynamicZoneCaches()
        C_GuildInfo.GuildRoster()
        GZO.UpdateVisibility()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_GUILD_UPDATE" or event == "GROUP_ROSTER_UPDATE" then
        if event == "PLAYER_GUILD_UPDATE" then C_GuildInfo.GuildRoster() end
        GZO.UpdateVisibility()
    elseif event == "GUILD_ROSTER_UPDATE" then
        if guildRosterDebounceTimer and guildRosterDebounceTimer.Cancel then
            guildRosterDebounceTimer:Cancel()
        end
        guildRosterDebounceTimer = C_Timer.After(GZO.GUILD_ROSTER_DEBOUNCE_SEC, function()
            guildRosterDebounceTimer = nil
            UpdateGuildZoneCounts()
        end)
    end
end)

if C_Timer and C_Timer.NewTicker then
    C_Timer.NewTicker(30, function() if IsInGuild() then C_GuildInfo.GuildRoster() end end)
end
