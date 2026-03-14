# GuildZoneOverview (v1.1.1)

Ein WoW-Addon für Retail (The War Within / 12.0.1), das in einem verschiebbaren, modernen Frame anzeigt, wie viele Gildenmitglieder sich aktuell in:

- Instanzen
- Raids
- Tiefen
- Städten
- Sonstiges

befinden. Der Frame wird **nur angezeigt, wenn du in keiner Gruppe/Raid bist**.

## Installation

1. Lade den Ordner `GuildZoneOverview` in dein WoW-Addons-Verzeichnis:
   - `World of Warcraft/_retail_/Interface/AddOns/GuildZoneOverview`
2. Stelle sicher, dass die Dateien vorhanden sind:
   - `GuildZoneOverview.toc`
   - `GuildZoneOverview.lua`
   - (optional später) zusätzliche Medien/Dateien
3. Starte WoW neu oder benutze `/reload`.
4. Aktiviere das Addon im Charakter-Auswahlbildschirm.

## Funktionsweise

- Das Addon liest das **Gilden-Roster** (Zone / Instanzname) der Online-Gildenmitglieder aus.
- Es ordnet jede Zone einer Kategorie zu:
  - **Instanz** (5er Dungeons inkl. Midnight-Dungeons, siehe `DUNGEON_ZONES`)
  - **Raid** (Raids in `RAID_ZONES`)
  - **Tiefen** (Delves / Tiefen-Hub in `DELVE_ZONES`)
  - **Stadt** (Hauptstädte in `CITY_ZONES`)
  - **Sonstiges** (alles andere)
- Offline-Gildenmitglieder werden ignoriert.

### UI / Bedienung

- Der Hauptframe zeigt fünf Zeilen mit Zählern, z.B.:
  - `Instanzen: 3`
  - `Raids: 1`
  - `Tiefen: 2`
  - `Städte: 5`
  - `Sonstiges: 4`
- **Klick auf eine Zeile**:
  - Unterhalb des Frames klappt eine Detail-Liste aus (Dropdown-Stil).
  - Dort werden alle Gildies der Kategorie angezeigt:
    - Format: `Name - Zone`
    - Name in **Klassenfarbe** (RAID_CLASS_COLORS).
  - Nochmaliger Klick auf dieselbe Zeile klappt die Liste wieder zu.
- **Verschieben**:
  - Den Hauptframe kannst du per Linksklick-Drag an der Fläche ziehen.
  - Die Position wird in `GuildZoneOverviewDB` gespeichert.

## Design (Glassmorphism)

- Semi-transparenter Hintergrund (Alpha ~0.7) mit leicht bläulichem Ton.
- Leuchtende **Cyan-/Violett-Akzente** an Rahmen und Zeilenbalken.
- Jeder Zeileneintrag liegt auf einem subtilen **vertikalen Farbverlauf** mit einem kleinen Gloss-Overlay oben.
- Einblendungen (Hauptframe + Detail-Liste) verwenden, falls verfügbar, `UIFrameFadeIn` für ein sanftes Fade-In.

### Schriften

- Das Addon nutzt eine saubere Sans-Serif-Schrift (aktuell `ARIALN.TTF` = Arial Narrow).

## Konfiguration / Erweiterung

- Die Zonenzuordnungstabellen findest du im Kopf von `GuildZoneOverview.lua`:
  - `CITY_ZONES`
  - `RAID_ZONES`
  - `DUNGEON_ZONES`
  - `DELVE_ZONES`
- Du kannst dort weitere deutsche oder englische Zonennamen ergänzen, wenn Blizzard neue Inhalte hinzufügt.

## Versionierung

- Aktuelle Version: **1.1.1**
- Die Version ist sowohl in `GuildZoneOverview.toc` (Feld `## Version`) als auch im Lua-Code (`ADDON_VERSION`) hinterlegt und wird im Titel angezeigt.

