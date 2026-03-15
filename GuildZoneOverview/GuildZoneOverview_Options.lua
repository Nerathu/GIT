local addonName = ...
local GZO = _G.GZO

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

local function makeCheckBox(parent, y, id, label, dbKey, onChecked)
    local cb = CreateFrame("CheckButton", id, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    if _G[cb:GetName().."Text"] then _G[cb:GetName().."Text"]:SetText(label) end
    cb:SetScript("OnClick", function(self)
        GuildZoneOverviewDB[dbKey] = self:GetChecked()
        if onChecked then onChecked(self) end
    end)
    return cb
end

local function makeColorPickerRow(parent, y, label, dbKey, hasOpacity, classColorDbKey, classCheckId, getColor, onApply, updateSwatch)
    local lbl = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    lbl:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y)
    lbl:SetText(label)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(24, 24)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, y - 20)
    local tex = btn:CreateTexture(nil, "BACKGROUND")
    tex:SetAllPoints()
    local classCheck = CreateFrame("CheckButton", classCheckId, parent, "InterfaceOptionsCheckButtonTemplate")
    classCheck:SetPoint("LEFT", btn, "RIGHT", 8, 0)
    if classCheckId and _G[classCheckId.."Text"] then _G[classCheckId.."Text"]:SetText("Klassenfarbe") end
    classCheck:SetScript("OnClick", function(self)
        GuildZoneOverviewDB[classColorDbKey] = self:GetChecked()
        updateSwatch(tex)
    end)
    btn:SetScript("OnClick", function()
        local r, g, b, a = getColor()
        OpenColorPicker(r, g, b, a, hasOpacity, function()
            local r2, g2, b2 = ColorPickerFrame:GetColorRGB()
            local a2 = hasOpacity and (ColorPickerFrame.GetColorAlpha and ColorPickerFrame:GetColorAlpha() or (OpacitySliderFrame and OpacitySliderFrame.GetValue and OpacitySliderFrame:GetValue() or 1)) or 1
            onApply(r2, g2, b2, a2)
            updateSwatch(tex)
        end, function()
            local p = ColorPickerFrame.previousValues
            if p then
                local r2 = p.r or p[1]
                local g2 = p.g or p[2]
                local b2 = p.b or p[3]
                local a2 = p.a or p[4] or 1
                if r2 and g2 and b2 then onApply(r2, g2, b2, a2) end
            end
            updateSwatch(tex)
        end)
    end)
    return { tex = tex, classCheck = classCheck, updateSwatch = updateSwatch }
end

local genTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
genTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -16)
genTitle:SetText("Allgemein")

local themeLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
themeLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -44)
themeLabel:SetText("Fenster-Design")

local themeDropdown = CreateFrame("Frame", "GZOFrameThemeDropDown", panel, "UIDropDownMenuTemplate")
themeDropdown:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -64)
local themeOrder = { "minimal", "talente", "berufe" }
UIDropDownMenu_Initialize(themeDropdown, function(self, level, menuList)
    for _, key in ipairs(themeOrder) do
        local theme = GZO.UI_THEMES[key]
        if theme then
            local k, label = key, theme.label
            UIDropDownMenu_AddButton({
                text = label,
                value = k,
                func = function()
                    GuildZoneOverviewDB.frameTheme = k
                    GZO.ApplyFrameTheme(k)
                    UIDropDownMenu_SetSelectedValue(themeDropdown, k)
                    if UIDropDownMenu_SetSelectedName then UIDropDownMenu_SetSelectedName(themeDropdown, label) end
                end,
            })
        end
    end
end)
UIDropDownMenu_SetSelectedValue(themeDropdown, GuildZoneOverviewDB.frameTheme or GZO.DEFAULT_FRAME_THEME)
UIDropDownMenu_JustifyText(themeDropdown, "LEFT")

local pulseCheck = makeCheckBox(panel, -92, "GZOPulseWhenInactive", "Dezente Pulsierung wenn inaktiv", "pulseWhenInactive")
local showInGroupCheck = makeCheckBox(panel, -114, "GZOShowInGroupCheck", "Fenster auch in Gruppe anzeigen (z. B. in Tiefen)", "showFrameInGroup", function()
    GZO.UpdateVisibility()
end)

local animTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
animTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -148)
animTitle:SetText("Animation & Benachrichtigung")

local durationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
durationLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -176)
durationLabel:SetText("Dauer (Sekunden)")

local function makeDurationSlider(panel, sliderY, frameName, dbKey)
    local cfg = { skipWrite = false, dbKey = dbKey }
    local slider = CreateFrame("Slider", frameName, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, sliderY)
    slider:SetWidth(200)
    slider:SetMinMaxValues(1, 60)
    slider:SetValueStep(1)
    slider:SetObeyStepOnDrag(true)
    local lowLab, highLab = slider:GetName() .. "Low", slider:GetName() .. "High"
    if _G[lowLab] then _G[lowLab]:SetText("1") end
    if _G[highLab] then _G[highLab]:SetText("60") end
    local valueText = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    valueText:SetPoint("LEFT", slider, "RIGHT", 12, 0)
    slider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        if not cfg.skipWrite then GuildZoneOverviewDB[dbKey] = value end
        valueText:SetText(tostring(value))
    end)
    cfg.slider = slider
    cfg.valueText = valueText
    return cfg
end
local durationSliderConfig = makeDurationSlider(panel, -196, "GZODurationSlider", "animationDurationSec")

local function animGetColor()
    local c = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
    local r, g, b = c[1], c[2], c[3]
    if GuildZoneOverviewDB.useClassColorAnimation then
        local cr, cg, cb = GZO.GetPlayerClassColor()
        if cr and cg and cb then r, g, b = cr, cg, cb end
    end
    return r, g, b, 1
end
local function animUpdateSwatch(tex)
    local c = GuildZoneOverviewDB.animationColor or { 1, 1, 1 }
    local r, g, b = c[1], c[2], c[3]
    if GuildZoneOverviewDB.useClassColorAnimation then
        local cr, cg, cb = GZO.GetPlayerClassColor()
        if cr and cg and cb then r, g, b = cr, cg, cb end
    end
    tex:SetColorTexture(r, g, b, 1)
end
local animRow = makeColorPickerRow(panel, -232, "Animationsfarbe", "animationColor", false, "useClassColorAnimation", "GZOAnimClassColorCheck",
    animGetColor,
    function(r, g, b)
        GuildZoneOverviewDB.animationColor = { r, g, b }
        GuildZoneOverviewDB.useClassColorAnimation = false
        animRow.classCheck:SetChecked(false)
    end,
    animUpdateSwatch
)

local soundCheck = makeCheckBox(panel, -278, "GZOSoundCheck", "Sound abspielen ('Bnet Toast'), wenn jemand online kommt", "playSoundOnOnline")

local testBtn = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
testBtn:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -308)
testBtn:SetSize(180, 22)
if testBtn.SetText then testBtn:SetText("Online-Anzeige testen")
else local t = testBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal"); t:SetText("Online-Anzeige testen"); t:SetPoint("CENTER", testBtn, "CENTER", 0, 0) end
testBtn:SetScript("OnClick", function() GZO.PlayOnlineBlink() end)

local trackTitle = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
trackTitle:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -338)
trackTitle:SetText("Veränderungen tracken")

local lineDurationLabel = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
lineDurationLabel:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, -358)
lineDurationLabel:SetText("Strich-Anzeige Dauer (Sekunden)")

local lineDurationSliderConfig = makeDurationSlider(panel, -378, "GZOLineDurationSlider", "floatingLineDurationSec")

local function makeTrackRow(y, key, label, dbKey)
    local cb = CreateFrame("CheckButton", "GZOTrack" .. key, panel, "InterfaceOptionsCheckButtonTemplate")
    cb:SetPoint("TOPLEFT", panel, "TOPLEFT", 16, y)
    if _G[cb:GetName().."Text"] then _G[cb:GetName().."Text"]:SetText(label) end
    cb:SetScript("OnClick", function(self) GuildZoneOverviewDB[dbKey] = self:GetChecked() end)
    local function runFloatingSimulation(diff)
        local row = GZO.categoryRows[key]
        if not row then return end
        GZO.isTestingFloating = true
        local wasShown = row.btn:IsShown()
        if not wasShown then
            local testY = GZO.layoutBottomY
            row.btn:Show()
            row.btn:ClearAllPoints()
            row.btn:SetPoint("TOPLEFT", GZO.mainFrame, "TOPLEFT", 0, testY)
            row.btn:SetPoint("TOPRIGHT", GZO.mainFrame, "TOPRIGHT", 0, testY)
        end
        GZO.SpawnFloatingDiff(row, diff)
        if C_Timer then
            C_Timer.After(1.5, function()
                GZO.isTestingFloating = false
                if not wasShown then GZO.UpdateGuildZoneCounts() end
            end)
        else
            GZO.isTestingFloating = false
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

local durationSliderConfigs = { durationSliderConfig, lineDurationSliderConfig }
panel.refresh = function()
    local themeKey = GuildZoneOverviewDB.frameTheme or GZO.DEFAULT_FRAME_THEME
    UIDropDownMenu_SetSelectedValue(themeDropdown, themeKey)
    local theme = GZO.UI_THEMES[themeKey]
    if theme and UIDropDownMenu_SetSelectedName then UIDropDownMenu_SetSelectedName(themeDropdown, theme.label) end
    for _, cfg in ipairs(durationSliderConfigs) do
        cfg.skipWrite = true
        local val = GuildZoneOverviewDB[cfg.dbKey] or 10
        cfg.slider:SetValue(val)
        cfg.valueText:SetText(tostring(val))
        cfg.skipWrite = false
    end
    animRow.classCheck:SetChecked(GuildZoneOverviewDB.useClassColorAnimation)
    pulseCheck:SetChecked(GuildZoneOverviewDB.pulseWhenInactive)
    showInGroupCheck:SetChecked(GuildZoneOverviewDB.showFrameInGroup)
    soundCheck:SetChecked(GuildZoneOverviewDB.playSoundOnOnline)
    trackInstCheck:SetChecked(GuildZoneOverviewDB.trackChangesInstance)
    trackRaidCheck:SetChecked(GuildZoneOverviewDB.trackChangesRaid)
    trackDelveCheck:SetChecked(GuildZoneOverviewDB.trackChangesDelve)
    animRow.updateSwatch(animRow.tex)
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
