# PC Connector – Projektplan

## Übersicht

Eine Mobile-App, mit der ein PC per **Wake-on-LAN (WOL)** gestartet und über **konfigurierbare Buttons** Skripte auf dem PC remote ausgeführt werden können.

---

## Architektur

```
┌─────────────┐         HTTP/WebSocket         ┌──────────────────┐
│  Mobile App  │  ◄──────────────────────────►  │  PC-Agent (API)  │
│  (Flutter)   │                                │  (Python/FastAPI) │
└──────┬───────┘                                └────────┬─────────┘
       │                                                 │
       │  UDP Magic Packet (WOL)                         │  Führt lokale
       │  (direkt ins LAN / über Broadcast)              │  Skripte aus
       ▼                                                 ▼
   ┌────────┐                                    ┌──────────────┐
   │  PC NIC │◄──── Wake-on-LAN ────────────────│  OS (Scripts) │
   └────────┘                                    └──────────────┘
```

### Komponenten

| Komponente | Technologie | Zweck |
|---|---|---|
| **Mobile App** | Flutter (Dart) | UI, WOL senden, Skript-Buttons, Status-Anzeige |
| **PC-Agent** | Python + FastAPI | REST-API auf dem PC, führt Skripte aus, liefert Status |
| **Konfiguration** | JSON/YAML-Datei | Definiert verfügbare Skripte, PC-Daten (MAC, IP) |

---

## Funktionale Anforderungen

### 1. Wake-on-LAN

- [ ] MAC-Adresse des Ziel-PCs konfigurierbar
- [ ] Magic Packet (UDP) an Broadcast-Adresse senden
- [ ] Unterstützung für LAN & WLAN (gleiches Subnetz)
- [ ] Optional: WOL über Internet via Port-Forwarding oder VPN
- [ ] Visuelles Feedback: "Paket gesendet" / "PC antwortet" (Ping)

### 2. PC-Status prüfen

- [ ] Ping/Health-Check an den PC-Agent
- [ ] Status-Anzeige: Online / Offline / Startend
- [ ] Automatisches Polling (konfigurierbares Intervall)

### 3. Skript-Ausführung per Button

- [ ] Dynamische Button-Liste aus Konfiguration laden
- [ ] Jeder Button löst ein definiertes Skript auf dem PC aus
- [ ] Unterstützte Skript-Typen: `.ps1`, `.bat`, `.sh`, `.py`, beliebige Executables
- [ ] Ausgabe/Ergebnis des Skripts an die App zurückliefern
- [ ] Fehlerbehandlung: Timeout, Exit-Code, stderr

### 4. Konfiguration

- [ ] Skripte werden auf dem PC in einer Konfig-Datei definiert
- [ ] Jedes Skript hat: `id`, `name`, `icon`, `command`, `timeout`, `confirm` (Bestätigung nötig?)
- [ ] PC-Profil: `name`, `mac_address`, `ip`, `port`
- [ ] Mehrere PCs unterstützbar (Zukunft)

---

## Technischer Plan

### Phase 1: PC-Agent (Backend)

**Ziel:** REST-API auf dem PC, die Skripte ausführen kann.

#### Struktur

```
pc_agent/
├── main.py              # FastAPI-Einstiegspunkt
├── config.yaml          # Skript- und PC-Konfiguration
├── routers/
│   ├── scripts.py       # Endpunkte: Liste, Ausführen
│   └── status.py        # Health-Check / System-Info
├── services/
│   ├── script_runner.py # Skript-Ausführung (subprocess)
│   └── config_loader.py # YAML-Konfiguration laden
├── models/
│   └── schemas.py       # Pydantic-Modelle
└── requirements.txt
```

#### API-Endpunkte

| Methode | Pfad | Beschreibung |
|---|---|---|
| `GET` | `/api/status` | Health-Check, Hostname, Uptime |
| `GET` | `/api/scripts` | Liste aller konfigurierten Skripte |
| `POST` | `/api/scripts/{id}/run` | Skript ausführen, Ergebnis zurückgeben |

#### Beispiel `config.yaml`

```yaml
pc:
  name: "Gaming-PC"
  mac_address: "AA:BB:CC:DD:EE:FF"

scripts:
  - id: "shutdown"
    name: "PC Herunterfahren"
    icon: "power_off"
    command: "shutdown /s /t 0"
    confirm: true
    timeout: 10

  - id: "steam"
    name: "Steam starten"
    icon: "games"
    command: "start steam://open/main"
    confirm: false
    timeout: 5

  - id: "backup"
    name: "Backup ausführen"
    icon: "backup"
    command: "powershell -File C:\\Scripts\\backup.ps1"
    confirm: true
    timeout: 300
```

#### Sicherheit

- **API-Key** als Bearer-Token für alle Endpunkte (konfigurierbar)
- **Allowlist** für erlaubte Skript-IDs (nur vorkonfigurierte Skripte ausführbar)
- Keine arbiträren Befehle von der App – nur registrierte Skripte
- HTTPS empfohlen (Self-Signed-Cert oder Reverse Proxy)
- Rate-Limiting auf Skript-Ausführung

---

### Phase 2: Mobile App (Flutter)

**Ziel:** App mit WOL-Funktion und Skript-Buttons.

#### Struktur

```
lib/
├── main.dart
├── models/
│   ├── pc_profile.dart      # PC-Daten (MAC, IP, Port, API-Key)
│   └── script_config.dart   # Skript-Modell
├── services/
│   ├── wol_service.dart     # Wake-on-LAN Magic Packet senden
│   ├── api_service.dart     # HTTP-Client für PC-Agent API
│   └── storage_service.dart # Lokale Speicherung (SharedPreferences)
├── screens/
│   ├── home_screen.dart     # Hauptbildschirm: Status + Buttons
│   ├── setup_screen.dart    # PC-Konfiguration (MAC, IP eingeben)
│   └── script_result_screen.dart # Skript-Ergebnis anzeigen
├── widgets/
│   ├── status_indicator.dart # Online/Offline-Anzeige
│   ├── script_button.dart    # Einzelner Skript-Button
│   └── wol_button.dart       # Wake-on-LAN Button
```

#### UI-Konzept

```
┌─────────────────────────────┐
│  PC Connector               │
│                             │
│  ┌───────────────────────┐  │
│  │  Gaming-PC             │  │
│  │  ● Online              │  │
│  │  192.168.1.100         │  │
│  └───────────────────────┘  │
│                             │
│  ┌─────────┐ ┌───────────┐ │
│  │  ⏻ WOL  │ │ ⏻ Shutdown│ │
│  └─────────┘ └───────────┘ │
│                             │
│  ┌─────────┐ ┌───────────┐ │
│  │ 🎮 Steam│ │ 💾 Backup │ │
│  └─────────┘ └───────────┘ │
│                             │
│  ┌─────────┐ ┌───────────┐ │
│  │ 🖥 RDP   │ │ 📁 Explorer│ │
│  └─────────┘ └───────────┘ │
│                             │
│            ⚙ Einstellungen  │
└─────────────────────────────┘
```

#### Wake-on-LAN Implementierung

```dart
// Magic Packet: 6x 0xFF + 16x MAC-Adresse (6 Bytes)
// Senden per UDP an Broadcast-Adresse (255.255.255.255), Port 9
```

---

### Phase 3: Integration & Feinschliff

- [ ] Bestätigungsdialog bei kritischen Aktionen (Shutdown etc.)
- [ ] Skript-Ergebnis (stdout/stderr) in der App anzeigen
- [ ] Auto-Discovery: PC-Agent im LAN finden (mDNS/Broadcast)
- [ ] Darkmode / Theming
- [ ] Mehrere PC-Profile verwalten
- [ ] Widget für Android-Homescreen (Quick-WOL)

---

## Umsetzungsreihenfolge

| # | Schritt | Aufwand |
|---|---|---|
| 1 | PC-Agent: Grundgerüst (FastAPI + Config laden) | Klein |
| 2 | PC-Agent: `/api/status` Endpunkt | Klein |
| 3 | PC-Agent: `/api/scripts` + `/api/scripts/{id}/run` | Mittel |
| 4 | PC-Agent: API-Key-Authentifizierung | Klein |
| 5 | Flutter: Projekt-Setup + PC-Konfiguration (Setup-Screen) | Klein |
| 6 | Flutter: WOL-Service implementieren | Klein |
| 7 | Flutter: API-Service (HTTP-Client) | Klein |
| 8 | Flutter: Home-Screen mit Status + Skript-Buttons | Mittel |
| 9 | Flutter: Skript-Ergebnis-Anzeige | Klein |
| 10 | PC-Agent: Als Windows-Dienst / Autostart einrichten | Klein |
| 11 | Testen im LAN | Klein |
| 12 | Feinschliff: Fehlerbehandlung, UI-Polish | Mittel |

---

## Technologie-Entscheidungen

| Entscheidung | Wahl | Begründung |
|---|---|---|
| Mobile Framework | **Flutter** | Cross-Platform (Android + iOS), schnelle Entwicklung, gute UDP-Unterstützung |
| Backend Framework | **Python + FastAPI** | Einfach, async, gute subprocess-Unterstützung, schnell aufgesetzt |
| Konfigurationsformat | **YAML** | Gut lesbar, einfach editierbar |
| Authentifizierung | **API-Key (Bearer)** | Einfach, ausreichend für LAN-Nutzung |
| Lokale Speicherung (App) | **SharedPreferences** | Leichtgewichtig für PC-Profile |

---

## Voraussetzungen

### PC-Seite
- Wake-on-LAN im BIOS/UEFI aktiviert
- WOL in den Netzwerkadapter-Einstellungen aktiviert
- Python 3.10+ installiert
- Firewall: Port des PC-Agents freigeben (z.B. 8420)

### Handy-Seite
- Im gleichen WLAN/LAN wie der PC (oder VPN)
- Flutter SDK für Entwicklung

---

## Offene Fragen / Entscheidungen

- [ ] Soll die App auch über das Internet (außerhalb des LANs) funktionieren? → VPN oder Cloud-Relay nötig
- [ ] Soll der PC-Agent als Windows-Dienst oder als Tray-App laufen?
- [ ] Soll es eine Web-Oberfläche zusätzlich zur App geben?
- [ ] Braucht es WebSocket für Live-Output bei lang laufenden Skripten?
