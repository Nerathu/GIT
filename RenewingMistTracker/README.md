# Renewing Mist Tracker

Ein schlankes WoW-Addon für **Mistweaver-Mönche** (Retail, Patch 12.0.x), das live anzeigt, wie viele Gruppen-/Raidmitglieder deinen **Renewing Mist**-HoT (SpellID 119611) aktiv haben.

---

## Features

- **Live-Zähler** `X/Y`: Anzahl aktiver ReMs (`X`) und maximale Ziele (`Y`) je nach Gruppe/Raid.
- **Icon**: Renewing-Mist-Symbol, schwarzer Rahmen, verschiebbar (Position wird gespeichert).
- **Textfarben**:
  - 0 ReMs → Rot  
  - 1–2 ReMs → Gelb/Orange  
  - ≥3 ReMs → Grün  
- **Leuchtrahmen**: Türkiser Rahmen bei Maximum oder ab Schwellenwert (M+ bzw. Raid getrennt einstellbar).
- **Nur Mistweaver**: Das Fenster erscheint nur in der Mistweaver-Spezialisierung; als Brewmaster oder Windwalker bleibt es ausgeblendet.
- **Optionen** (Interface → AddOns → RenewingMistTracker):
  - Rahmen sperren (nicht verschiebbar)
  - Leuchten nur bei Maximum (alle haben Buff)
  - Nicht im Kampf anzeigen
  - Nicht in Instanzen anzeigen

---

## Installation

1. Ordner `RenewingMistTracker` nach  
   `World of Warcraft/_retail_/Interface/AddOns/` kopieren.
2. Addon im Charakterauswahlbildschirm aktivieren (nur für Mönche sichtbar via X-Class: MONK).
3. Ingame: Fenster nur sichtbar als **Mistweaver**; Position durch Ziehen anpassen.

---

## Technik

- **Aura-Erkennung**: `C_UnitAuras.GetAuraDataBySpellName` (Spellname „Erneuernder Nebel“, HELPFUL) für Spieler und Gruppen-/Raid-Einheiten.
- **Spec-Prüfung**: Nur bei Spezialisierung Mistweaver (specID 270) wird das Fenster angezeigt; bei Spec-Wechsel sofortige Anpassung.
- **Events**: `ADDON_LOADED`, `PLAYER_ENTERING_WORLD`, `GROUP_ROSTER_UPDATE`, `UNIT_AURA` (gedrosselt), `PLAYER_REGEN_*`, `ZONE_CHANGED_NEW_AREA`, `PLAYER_SPECIALIZATION_CHANGED`.
- **SavedVariables**: `RenewingMistTrackerDB` (Position, Optionen).

---

## Bekannte Einschränkungen

- Aura-APIs unterliegen Blizzards Regeln zu privaten/geheimen Auren; bei API-Änderungen kann eine Anpassung nötig werden.
- Spellname ist deutsch („Erneuernder Nebel“); bei anderen Lokalen müsste der Name angepasst werden.
