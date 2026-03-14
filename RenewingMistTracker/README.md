# Renewing Mist Tracker

Ein schlankes WoW-Addon für Mistweaver-Mönche (Patch 12.0.x), das live anzeigt, wie viele Gruppen-/Raidmitglieder aktuell deinen **Renewing Mist** (HoT, SpellID 119611) aktiv haben.

## Features

- **Live-Zähler**: Zeigt `X/Y`, wobei:
  - `X` = Anzahl der Einheiten mit deinem aktiven Renewing Mist
  - `Y` = maximale mögliche Anzahl (Gruppen-/Raidgröße)
- **Grafisches Icon**: Verwendet das Renewing-Mist-Symbol als Hintergrund.
- **Visuelles Feedback**:
  - Dynamische Textfarbe:
    - `0` ReMs → Rot (kritisch)
    - `1–2` ReMs → Gelb/Orange (aufbauen)
    - `>=3` ReMs → Grün (gut abgedeckt)
  - Schwarzer Pixelrahmen + farbiger Innenrahmen je nach Auslastung (0 %, ≥ 50 %, 100 %).
- **Frei verschiebbar**:
  - Frame mit linker Maustaste ziehen, Position wird dauerhaft gespeichert.
- **Option: nur im Kampf anzeigen**:
  - Optional kannst du wählen, ob der Tracker **nur im Kampf** oder **immer** sichtbar sein soll.
- **Optionen im Interface-Menü**:
  - Unter `Interface -> AddOns -> Renewing Mist Tracker`:
    - Rahmenfarbe bei **0 %**, **≥ 50 %**, **100 %** über Color-Picker anpassbar.
- **Debug-Modus** (optional):
  - Schreibt zusätzliche Infos in den Chat, um Zählung und Gruppenerkennung zu prüfen.

## Installation

1. Kopiere den Ordner `RenewingMistTracker` in:
   - `.../_retail_/Interface/AddOns/`
2. Stelle sicher, dass die `RenewingMistTracker.toc` geladen ist (Addon-Liste im Charakterauswahlbildschirm).

## Slash-Commands

- ` /rem help`  
  Zeigt eine kurze Übersicht und die aktuelle Addon-Version.

- ` /rem debug`  
  Zeigt den aktuellen Debug-Status (aktiv / inaktiv).

- ` /rem debug on`  
  Aktiviert Debug-Ausgaben im Chat.

- ` /rem debug off`  
  Deaktiviert Debug-Ausgaben.

- ` /rem combat on`  
  Tracker wird **nur im Kampf** angezeigt.

- ` /rem combat off`  
  Tracker wird **immer** angezeigt (Standard).

- ` /rmt`  
  Gibt eine Statuszeile im Chat aus, z.B.  
  `"[RMT] v0.0.7 ReM: 4/6, Debug: true"`.

## Funktionsweise (Technik)

- Das Addon lauscht auf:
  - `UNIT_AURA`
  - `GROUP_ROSTER_UPDATE`
  - `PLAYER_ENTERING_WORLD`
  - `PLAYER_SPECIALIZATION_CHANGED`, `ACTIVE_TALENT_GROUP_CHANGED`
  - `PLAYER_REGEN_DISABLED`, `PLAYER_REGEN_ENABLED` (Kampfstatus)
- Für jede relevante Einheit (`player`, `partyX`, `raidX`) wird versucht, Renewing Mist über die moderne Aura-API zu erkennen.
- Die Anzeige wird über einen kurzen Timer (`C_Timer.After`) gedrosselt, um Event-Spam zu glätten.

## Bekannte Einschränkungen

- Die Aura-APIs in 12.0.x unterliegen Blizzards Private-/Secret-Aura-Regeln. Bei zukünftigen API-Änderungen kann eine Anpassung nötig werden.
- Der Tracker ist auf **Renewing Mist (HoT)** ausgelegt.
- Auf **nicht-Monk-Chars** blendet das Addon das Frame aus (sofern die Spec-Prüfung aktiv ist).

