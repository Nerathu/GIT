# GuildZoneOverview

WoW-Addon für Retail (Midnight / 12.0.1), das in einem verschiebbaren Frame anzeigt, wie viele Gildenmitglieder sich in **Instanzen**, **Raids**, **Tiefen**, **Städten** und **Sonstiges** befinden.

- **Sichtbarkeit:** Standardmäßig nur ohne Gruppe/Raid; optional (in den Optionen) auch **in Gruppe anzeigen** (z. B. in Tiefen).
- **Klick auf eine Kategorie:** Detail-Liste mit allen Spielern (Name – Zone, klassengefärbt). Bei Instanzen, Raids, Tiefen und Städten: **Dauer-Indikator** (grün 0–25 min, orange 25–45 min, rot >45 min in der Zone). Bei Sonstiges, Instanzen und Raids: **Zonen-Trenner** zwischen verschiedenen Zonen.
- **Schriftfarben pro Kategorie:** Instanzen Blau, Raids Lila, Tiefen Grün, Städte Rosa, Sonstiges Grau.
- **Änderungs-Striche:** Bei Änderungen in Instanz/Raid/Tiefe optional **grüne Striche** (mehr Spieler) bzw. **rote Striche** (weniger Spieler), pro Änderung ein Strich, rechts angehängt, nach jedem 5. Strich ein Abstand; Anzeige-Dauer in den Optionen einstellbar (1–60 s). Die Kategoriezeile (Instanz/Raid/Tiefe) **bleibt sichtbar**, bis alle Striche abgelaufen sind.
- **Online-Hinweis:** Wenn mehr Gildenmitglieder online kommen: **blinkender oberer Balken** + **Countdown-Balken unten** (Dauer in Optionen, 1–60 s), optional Sound.
- **Detail-Liste:** Wird bei **Roster-Update** aktualisiert (Count und Liste bleiben konsistent). Spieler in den **ersten 5 Minuten** in Instanz/Raid/Tiefe **blinken** leicht.
- **Alt-zu-Main:** Die öffentliche Gildennotiz wird ausgewertet (z. B. „main, Mainname“, ein einzelner Name). Der Main-Name wird **nur angezeigt, wenn dieser Charakter in der Gilde existiert** (Verifikation gegen das Gildenroster); sonst erscheint der Twink-Name. Die **Klassenfarbe** in der Detail-Liste bleibt die des **aktuell eingeloggten Charakters**.
- **Detail-Tooltip:** Beim Überfahren einer Spielerzeile in der Detail-Liste erscheint ein Tooltip mit dem Spielernamen.

Die Versionsnummer findest du in `GuildZoneOverview.toc` und im Lua-Code (`ADDON_VERSION`).

---

## Installation

1. Ordner `GuildZoneOverview` nach  
   `World of Warcraft/_retail_/Interface/AddOns/GuildZoneOverview` kopieren.
2. Enthalten sein müssen: `GuildZoneOverview.toc`, `GuildZoneOverview_Data.lua`, `GuildZoneOverview_Core.lua`, `GuildZoneOverview_UI.lua`, `GuildZoneOverview_Options.lua`.
3. WoW neu starten oder `/reload`, Addon im Charakter-Auswahlbildschirm aktivieren.

---

## Funktionsweise

- Liest das **Gilden-Roster** (Zone/Instanz) der Online-Mitglieder aus.
- Ordnet jede Zone einer Kategorie zu:
  - **Instanz** und **Raid** werden **dynamisch** aus dem **Abenteuerführer (Encounter Journal)** beim Addon-Start geladen.
  - **Städte** (`CITY_ZONES`) und **Tiefen** (`DELVE_ZONES`) sind statisch. Zonennamen, die auch als offene Welt existieren (z. B. Zul'Aman), können in der **Blacklist** (`ZONE_AS_OTHER_BLACKLIST`) stehen und erscheinen dann als **Sonstiges**.
  - **Sonstiges** (alles andere)
- **Dauer-Tracking:** Pro Spieler wird die Zeit in der aktuellen Zone erfasst; Wechsel der Zone setzt die Anzeige zurück.
- **GUILD_ROSTER_UPDATE** wird um 0,75 s **gedebounced**, um bei großen Gilden Performance-Spitzen zu vermeiden.

### Alt-zu-Main

- Die öffentliche Gildennotiz wird pro Mitglied gelesen; erkannte Formate (z. B. „main, Mainname“, ein einzelnes Wort als Name) liefern den Main-Namen. Dieser wird **nur angezeigt, wenn der Charakter in der Gilde vorkommt** (Verifikation); sonst wird der Twink-Name angezeigt. Die Klassenfarbe bleibt die des aktuell online Charakters.

### UI

- **Hauptframe:** Fünf Zeilen mit Zählern (z. B. „Instanzen: 3“, „Raids: 1“, …), jede Kategorie in eigener Schriftfarbe.
- **Klick auf eine Zeile:** Detail-Liste darunter mit „Name – Zone“ (Klassenfarbe). Bei Instanz/Raid/Tiefe/Stadt ein **farbiger Punkt** links (Dauer: grün/orange/rot). Bei Sonstiges, Instanzen und Raids **Trennlinien** zwischen verschiedenen Zonen.
- **Verschieben:** Frame per Linksklick ziehen; Position wird in `GuildZoneOverviewDB` gespeichert.

---

## Optionen (Interface → AddOns → Gilden Zonenübersicht)

- **Allgemein:** **Fenster-Design** (Minimal/Talente/Berufe), Pulsierung wenn inaktiv, **Fenster auch in Gruppe anzeigen**.
- **Animation & Benachrichtigung:** Dauer (1–60 s) für Online-Blink und Countdown-Balken, Animationsfarbe, Klassenfarbe, Sound bei „jemand online“, Button „Online-Anzeige testen“.
- **Veränderungen tracken:** **Strich-Anzeige Dauer** (1–60 s), Checkboxen für Instanzen/Raids/Tiefen, Test-Buttons zum Simulieren (ein grüner bzw. roter Strich).

---

## Design

- **Blizzard Backdrop** (Tooltip-/Dialog-Stil) mit abgerundeten Ecken; **drei UI-Designs** wählbar in den Optionen: **Minimal** (Standard), **Talente**, **Berufe**.
- **Farbige Kategoriezeilen** (Blau, Lila, Grün, Rosa, Grau) mit vertikalem Verlauf und Hover-Aufhellung.
- Oben schmaler Rahmen; bei Online-Benachrichtigung **blinkender Balken** + **Countdown-Balken** unten.
- Schrift: Arial Narrow (`ARIALN.TTF`).

---

## Konfiguration / Erweiterung

- **RAID_ZONES** und **DUNGEON_ZONES** werden beim Addon-Start aus dem Abenteuerführer (EJ) befüllt und sind nicht manuell zu pflegen.
- **CITY_ZONES**, **DELVE_ZONES** und **ZONE_AS_OTHER_BLACKLIST** sind in `GuildZoneOverview.lua` editierbar (z. B. weitere Städte, weitere Blacklist-Einträge bei Zonen/Instanz-Namenskonflikten).
- **SavedVariables:** `GuildZoneOverviewDB` (Position, Breite, alle Optionen). Das Alt-zu-Main-Mapping wird nicht gespeichert (nur zur Laufzeit aus der Gildennotiz).
