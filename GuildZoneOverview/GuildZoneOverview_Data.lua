local addonName = ...
if not _G.GZO then _G.GZO = {} end
local GZO = _G.GZO

GZO.ADDON_VERSION = "1.4.1"
GZO.addonName = addonName

GuildZoneOverviewDB = GuildZoneOverviewDB or {}

GZO.DB_DEFAULTS = {
    frameTheme = "minimal",
    animationDurationSec = 10,
    animationColor = { 1, 1, 1 },
    useClassColorAnimation = false,
    pulseWhenInactive = true,
    playSoundOnOnline = true,
    showFrameInGroup = true,
    trackChangesInstance = true,
    trackChangesRaid = true,
    trackChangesDelve = true,
    floatingLineDurationSec = 10,
}

GZO.FONT_PATH = "Fonts\\ARIALN.TTF"

GZO.CITY_ZONES = { ["Sturmwind"]=true, ["Orgrimmar"]=true, ["Eisenschmiede"]=true, ["Darnassus"]=true, ["Unterstadt"]=true, ["Silbermond"]=true, ["Exodar"]=true, ["Shattrath"]=true, ["Dalaran"]=true, ["Oribos"]=true, ["Valdrakken"]=true, ["Dornogal"]=true }
GZO.RAID_ZONES = {}
GZO.DUNGEON_ZONES = {}
GZO.DELVE_ZONES = { ["Tiefen"]=true }
GZO.ZONE_AS_OTHER_BLACKLIST = { ["Zul'Aman"] = true }

GZO.DURATION_BUCKETS = {
    { maxMin = 25,  color = { 0.4, 0.85, 0.4 } },
    { maxMin = 45,  color = { 0.95, 0.65, 0.35 } },
    { maxMin = 1e9, color = { 0.9, 0.35, 0.35 } },
}
GZO.ORDERED_CATEGORY_KEYS = { "instance", "raid", "delve", "city", "other" }
GZO.CATEGORY_LABELS = { instance = "Instanzen", raid = "Raids", delve = "Tiefen", city = "Städte", other = "Sonstiges" }
GZO.CATEGORIES_WITH_ZONE_SEPARATOR = { other = true, instance = true, raid = true }
GZO.TRACK_CHANGES_DB_KEYS = { instance = "trackChangesInstance", raid = "trackChangesRaid", delve = "trackChangesDelve" }

GZO.TOOLTIP_BACKDROP = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true,
    tileEdge = true,
    tileSize = 8,
    edgeSize = 16,
    insets = { left = 4, right = 4, top = 4, bottom = 4 },
}
GZO.DIALOG_BACKDROP = {
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileEdge = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
}
GZO.UI_THEMES = {
    minimal = {
        label = "Minimal (Standard)",
        backdrop = GZO.TOOLTIP_BACKDROP,
        bgColor = { 0.05, 0.05, 0.08, 0.95 },
        borderColor = { 0.4, 0.4, 0.5, 0.8 },
    },
    talente = {
        label = "Talente",
        backdrop = GZO.DIALOG_BACKDROP,
        bgColor = { 0.06, 0.06, 0.12, 0.98 },
        borderColor = { 0.35, 0.35, 0.55, 0.9 },
    },
    berufe = {
        label = "Berufe",
        backdrop = GZO.DIALOG_BACKDROP,
        bgColor = { 0.18, 0.14, 0.1, 0.98 },
        borderColor = { 0.5, 0.38, 0.28, 0.9 },
    },
}
GZO.DEFAULT_FRAME_THEME = "minimal"

GZO.GUILD_ROSTER_DEBOUNCE_SEC = 0.75

GZO.ROW_Y_START = -26
GZO.ROW_STEP = -18
GZO.CATEGORY_TEXT_COLORS = {
    instance = { 0.45, 0.65, 0.92 },
    raid     = { 0.72, 0.58, 0.92 },
    delve    = { 0.45, 0.68, 0.52 },
    city     = { 0.92, 0.72, 0.82 },
    other    = { 0.52, 0.52, 0.56 },
}
GZO.HUE_COLORS = {
    cyan   = { CreateColor(0.0, 0.3, 0.5, 0.3), CreateColor(0.0, 0.1, 0.2, 0.3), CreateColor(0.0, 0.5, 0.8, 0.5) },
    violet = { CreateColor(0.4, 0.1, 0.6, 0.3), CreateColor(0.15, 0.0, 0.3, 0.3), CreateColor(0.6, 0.2, 0.9, 0.5) },
}
GZO.ROW_HUE = { instance = "cyan", raid = "violet", delve = "cyan", city = "violet", other = "cyan" }

GZO.LINE_WIDTH = 3
GZO.LINE_HEIGHT = 12
GZO.LINE_GAP = 2
GZO.LINE_GROUP_GAP = 6
GZO.LINE_OFFSET_RIGHT = 60
GZO.LINE_GREEN = { 0.2, 1, 0.2, 1 }
GZO.LINE_RED   = { 1, 0.2, 0.2, 1 }
GZO.FLOATING_LINE_KEYS = { "instance", "raid", "delve" }

GZO.INACTIVE_ALPHA = 0.55
GZO.ACTIVE_ALPHA = 1.0
GZO.PULSE_ALPHA_MIN = 0.45
GZO.PULSE_ALPHA_MAX = 0.58
GZO.TOP_BORDER_PAD = 4
GZO.COUNTDOWN_BAR_HEIGHT = 4

GZO.DETAIL_INDICATOR_SIZE = 8
GZO.DETAIL_INDICATOR_GAP = 4
GZO.DETAIL_LEFT_PAD = 10
GZO.DETAIL_RIGHT_PAD = -10
GZO.DETAIL_ROW_HEIGHT = 16
GZO.DETAIL_TOP_PAD = 10
GZO.DETAIL_FLIP_THRESHOLD = 20
GZO.SEPARATOR_HEIGHT = 2
GZO.SEPARATOR_PADDING = 4
