# GuildZoneOverview

WoW-Addon für Retail (Midnight / 12.0.1), das in einem verschiebbaren Frame anzeigt, wie viele Gildenmitglieder sich in **Instanzen**, **Raids**, **Tiefen**, **Städten** und **Sonstiges** befinden.

- **Sichtbarkeit:** Standardmäßig nur ohne Gruppe/Raid; optional (in den Optionen) auch **in Gruppe anzeigen** (z. B. in Tiefen).
- **Klick auf eine Kategorie:** Detail-Liste mit allen Spielern (Name – Zone, klassengefärbt). Bei Instanzen, Raids, Tiefen und Städten: **Dauer-Indikator** (grün 0–10 min, orange 10–40 min, rot >40 min in der Zone). Bei Sonstiges, Instanzen und Raids: **Zonen-Trenner** zwischen verschiedenen Zonen.
- **Schriftfarben pro Kategorie:** Instanzen Blau, Raids Lila, Tiefen Grün, Städte Rosa, Sonstiges Grau.
- **Änderungs-Striche:** Bei Änderungen in Instanz/Raid/Tiefe optional **grüne Striche** (mehr Spieler) bzw. **rote Striche** (weniger Spieler), pro Änderung ein Strich, rechts angehängt, nach jedem 5. Strich ein Abstand; Anzeige-Dauer in den Optionen einstellbar (1–60 s).
- **Online-Hinweis:** Wenn mehr Gildenmitglieder online kommen: **blinkender oberer Balken** + **Countdown-Balken unten** (Dauer in Optionen, 1–60 s), optional Sound.

Die Versionsnummer findest du in `GuildZoneOverview.toc` und im Lua-Code (`ADDON_VERSION`).

---

## Installation

1. Ordner `GuildZoneOverview` nach  
   `World of Warcraft/_retail_/Interface/AddOns/GuildZoneOverview` kopieren.
2. Enthalten sein müssen: `GuildZoneOverview.toc`, `GuildZoneOverview.lua`.
3. WoW neu starten oder `/reload`, Addon im Charakter-Auswahlbildschirm aktivieren.

---

## Funktionsweise

- Liest das **Gilden-Roster** (Zone/Instanz) der Online-Mitglieder aus.
- Ordnet jede Zone einer Kategorie zu:
  - **Instanz** (5er-Dungeons, Midnight-Dungeons; siehe `DUNGEON_ZONES` in der Lua)
  - **Raid** (`RAID_ZONES`)
  - **Tiefen** (Delves; `DELVE_ZONES`)
  - **Stadt** (Hauptstädte; `CITY_ZONES`)
  - **Sonstiges** (alles andere)
- **Dauer-Tracking:** Pro Spieler wird die Zeit in der aktuellen Zone erfasst; Wechsel der Zone setzt die Anzeige zurück.
- **GUILD_ROSTER_UPDATE** wird um 0,75 s **gedebounced**, um bei großen Gilden Performance-Spitzen zu vermeiden.

### UI

- **Hauptframe:** Fünf Zeilen mit Zählern (z. B. „Instanzen: 3“, „Raids: 1“, …), jede Kategorie in eigener Schriftfarbe.
- **Klick auf eine Zeile:** Detail-Liste darunter mit „Name – Zone“ (Klassenfarbe). Bei Instanz/Raid/Tiefe/Stadt ein **farbiger Punkt** links (Dauer: grün/orange/rot). Bei Sonstiges, Instanzen und Raids **Trennlinien** zwischen verschiedenen Zonen.
- **Verschieben:** Frame per Linksklick ziehen; Position wird in `GuildZoneOverviewDB` gespeichert.

---

## Optionen (Interface → AddOns → Gilden Zonenübersicht)

- **Allgemein:** Fenster-Hintergrund (Farbe + Transparenz), Klassenfarbe, Pulsierung wenn inaktiv, **Fenster auch in Gruppe anzeigen**.
- **Animation & Benachrichtigung:** Dauer (1–60 s) für Online-Blink und Countdown-Balken, Animationsfarbe, Klassenfarbe, Sound bei „jemand online“, Button „Online-Anzeige testen“.
- **Veränderungen tracken:** **Strich-Anzeige Dauer** (1–60 s), Checkboxen für Instanzen/Raids/Tiefen, Test-Buttons zum Simulieren (ein grüner bzw. roter Strich).

---

## Design

- Halbtransparenter Hintergrund, **farbige Kategoriezeilen** (Blau, Lila, Grün, Rosa, Grau) mit vertikalem Verlauf und Hover-Aufhellung.
- Oben schmaler Rahmen; bei Online-Benachrichtigung **blinkender Balken** + **Countdown-Balken** unten.
- Schrift: Arial Narrow (`ARIALN.TTF`).

---

## Konfiguration / Erweiterung

- Zonenzuordnung in `GuildZoneOverview.lua`:  
  `CITY_ZONES`, `RAID_ZONES`, `DUNGEON_ZONES`, `DELVE_ZONES`.  
  Weitere Zonennamen (de/en) können dort ergänzt werden.
- **SavedVariables:** `GuildZoneOverviewDB` (Position, Breite, alle Optionen).
