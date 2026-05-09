<p align="center">
  <img src="assets/icon/icon.png" width="140" alt="PC Connector Icon">
</p>

<h1 align="center">PC Connector</h1>

<p align="center">
  Steuere und wecke deinen PC vom Handy aus – per Wake-on-LAN, Skripte und Abläufe.
</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/DEIN-USERNAME/PC_Connector?label=Letzter%20Release&style=for-the-badge&logo=github&color=1976D2" alt="Letzter Release">
  </a>
  &nbsp;
  <img src="https://img.shields.io/badge/Plattform-Android%20%7C%20Windows-brightgreen?style=for-the-badge&logo=android" alt="Plattform">
  &nbsp;
  <img src="https://img.shields.io/badge/Lizenz-MIT-blue?style=for-the-badge" alt="Lizenz">
</p>

---

## Was ist PC Connector?

PC Connector ermöglicht es, einen Windows-PC bequem vom Smartphone aus zu steuern – ohne Cloud, ohne Konto, vollständig im eigenen Heimnetzwerk.

Ein kleiner Server (`PC_Connector_Agent.exe`) läuft auf dem PC im Hintergrund. Die Android-App verbindet sich per einmaligem Pairing-Code sicher damit und erlaubt anschließend das Ausführen von Skripten, das Steuern des PCs über vorgefertigte Abläufe und das Aufwecken aus dem Ruhezustand per Wake-on-LAN.

### Komponenten

| Komponente | Technologie | Beschreibung |
|---|---|---|
| **PC Agent** | Python + FastAPI | Server-Prozess auf dem PC, stellt REST-API + Weboberfläche bereit |
| **Android App** | Flutter | Smartphone-App zur Steuerung |

---

## Features

| Feature | Beschreibung |
|---|---|
| ⚡ **Wake-on-LAN** | PC aus dem Schlaf aufwecken, auch wenn er ausgeschaltet ist |
| ▶ **Skripte ausführen** | Beliebige Windows-Befehle per Knopfdruck starten |
| 🔗 **Abläufe** | Mehrere Skripte nacheinander ausführen, optional mit Verzögerung |
| 📁 **Gruppen** | Skripte in Kategorien organisieren und sortieren |
| 🌐 **Weboberfläche** | Vollständige Konfiguration im Browser, kein App-Update nötig |
| 🔒 **Sicheres Pairing** | Einmaliger 6-stelliger Code – kein Passwort im Klartext |
| 📡 **Automatische Erkennung** | App findet den PC automatisch im lokalen Netzwerk (UDP-Broadcast) |
| 🖱️ **Drag & Drop** | Reihenfolge von Skripten, Abläufen und Gruppen per Drag & Drop ändern |

---

## Screenshots

> *Screenshots folgen in einer späteren Version.*

---

## Download

Den neuesten Release findest du unter [**Releases**](../../releases/latest):

| Datei | Für wen | Größe ca. |
|---|---|---|
| `PC_Connector_Agent.exe` | PC (Windows 10/11) – kein Python nötig | ~17 MB |
| `app-arm64-v8a-release.apk` | Android (moderne Geräte, z.B. Pixel, Samsung S-Serie) | ~17 MB |

---

## Installation

### PC Agent (Windows)

**Schritt 1 – Wake-on-LAN im BIOS aktivieren**  
Im BIOS/UEFI unter „Power Management" → „Wake on LAN" oder „PCI-E Power On" aktivieren.

**Schritt 2 – Netzwerkkarte konfigurieren**  
Geräte-Manager → Netzwerkkarte → Eigenschaften → Energieverwaltung → „Gerät kann den Computer aus dem Ruhezustand aktivieren" ankreuzen.

**Schritt 3 – PC Agent einrichten**

1. `PC_Connector_Agent.exe` herunterladen und z.B. nach `C:\Tools\PC_Connector\` legen
2. Beim ersten Start wird `config.yaml` automatisch angelegt
3. `config.yaml` anpassen (Vorlage: `config.yaml.example`):

```yaml
pc:
  name: Mein-PC            # Anzeigename in der App
  mac: AA:BB:CC:DD:EE:FF   # MAC-Adresse der Netzwerkkarte (ipconfig /all)
  ip: 192.168.1.100        # Feste lokale IP-Adresse des PCs

api:
  port: 8420
```

> **Tipp – MAC-Adresse finden:** Eingabeaufforderung → `ipconfig /all` → „Physikalische Adresse" der aktiven Netzwerkkarte.

> **Tipp – Feste IP:** Im Router für den PC eine feste IP-Adresse per DHCP-Reservierung vergeben (über die MAC-Adresse).

4. EXE starten – Weboberfläche erreichbar unter: `http://localhost:8420`

**Optional – Autostart mit Windows**  
Win + R → `shell:startup` → Verknüpfung der EXE in den geöffneten Ordner ziehen. Der PC Agent startet dann automatisch beim Windows-Login.

---

### Android App

1. `app-arm64-v8a-release.apk` auf das Handy übertragen (USB-Kabel oder im Browser öffnen)
2. Vor der Installation: **Einstellungen → Sicherheit → Aus unbekannten Quellen installieren** aktivieren
3. APK antippen und installieren
4. App starten → PC wird automatisch im Netzwerk gefunden
5. Auf „Koppeln" tippen → Pairing-Code in der Weboberfläche des PCs generieren (`http://PC-IP:8420`) und in der App eingeben

---

## Weboberfläche

Erreichbar unter `http://PC-IP:8420` im lokalen Netzwerk (auch direkt am PC via `localhost`).

| Bereich | Funktion |
|---|---|
| **Gerätekopplung** | Pairing-Codes generieren, verbundene Geräte anzeigen und entfernen |
| **Skripte** | Skripte anlegen, bearbeiten, Gruppe zuweisen, per Drag & Drop sortieren |
| **Abläufe** | Mehrschrittige Abläufe mit Verzögerungen konfigurieren |
| **Gruppen** | Kategorien anlegen und Skripte zuweisen |

---

## Skript-Beispiele

```yaml
# Herunterfahren
command: shutdown /s /t 0

# Neu starten
command: shutdown /r /t 0

# PC sperren
command: rundll32.exe user32.dll,LockWorkStation

# Steam starten
command: start steam://open/main

# Lautstärke stummschalten
command: powershell -c "(New-Object -ComObject WScript.Shell).SendKeys([char]173)"
```

---

## Selbst bauen

### Voraussetzungen

- Python 3.12+
- Flutter 3.x (SDK)
- Android SDK + JDK 17

### PC Agent EXE

```bat
build_agent.bat
```

Ausgabe: `pc_agent\dist\PC_Connector_Agent.exe`

### Android APK

```bat
build_apk.bat
```

Ausgabe: `mobile_app\build\app\outputs\flutter-apk\`

---

## Entwicklung

### Projektstruktur

```
PC_Connector/
├── pc_agent/               # Python FastAPI Server
│   ├── main.py             # Einstiegspunkt
│   ├── routers/            # API-Endpunkte (scripts, web, pairing, status)
│   ├── services/           # Geschäftslogik (auth, config, script runner, WoL)
│   ├── models/             # Pydantic-Schemas
│   ├── templates/          # Weboberfläche (index.html)
│   ├── tests/              # pytest-Tests (76 Tests)
│   └── config.yaml.example # Konfigurationsvorlage
├── mobile_app/             # Flutter Android App
│   ├── lib/
│   │   ├── main.dart
│   │   ├── screens/        # Bildschirme (Home, Setup, Geräteliste, Ergebnis)
│   │   ├── services/       # API, Storage, Discovery, WoL
│   │   ├── models/         # Datenmodelle
│   │   └── widgets/        # UI-Komponenten
│   └── test/               # Flutter-Tests (31 Tests)
├── assets/icon/            # App-Icon (PNG + ICO)
├── .github/workflows/      # CI/CD (Tests + Release-Build)
├── build_agent.bat         # EXE bauen
└── build_apk.bat           # APK bauen
```

### Backend-Tests

```bash
cd pc_agent
pip install -r requirements.txt pytest pytest-asyncio httpx
pytest tests/ -v
```

### Flutter-Tests

```bash
cd mobile_app
flutter test
```

---

## Sicherheitshinweis

PC Connector ist für den Einsatz im **lokalen Heimnetzwerk** ausgelegt.

- Port `8420` **nicht** über das Internet freigeben (keine Port-Weiterleitung im Router)
- Das Pairing-System stellt sicher, dass nur explizit gekoppelte Geräte Befehle senden dürfen
- Tokens werden lokal gespeichert und sind ohne Netzwerkzugang wertlos

---

## Lizenz

MIT License – Copyright (c) 2026 Hannes Jütting – siehe [LICENSE](LICENSE)


---

## Übersicht

PC Connector besteht aus zwei Teilen:

| Komponente | Beschreibung |
|---|---|
| **PC Agent** | Python-Server (als `.exe`) der auf dem PC läuft |
| **Android App** | Flutter-App die den PC steuert |

---

## Features

- **Wake-on-LAN** – PC aus dem Tiefschlaf aufwecken
- **Skripte ausführen** – beliebige Befehle per Knopfdruck starten
- **Abläufe** – mehrere Skripte nacheinander mit Verzögerung
- **Gruppen** – Skripte nach Kategorien organisieren
- **Weboberfläche** – Konfiguration bequem im Browser
- **Gerätekopplung** – sicherer Pairing-Code ohne Passwort im Klartext
- **Automatische Erkennung** – App findet den PC im lokalen Netzwerk

---

## Download

Den neuesten Release findest du unter [**Releases**](../../releases/latest):

| Datei | Beschreibung |
|---|---|
| `PC_Connector_Agent.exe` | PC-Server für Windows |
| `app-arm64-v8a-release.apk` | Android App (moderne Geräte) |

---

## Installation

### PC Agent (Windows)

1. `PC_Connector_Agent.exe` herunterladen und irgendwo ablegen (z.B. `C:\Tools\`)
2. Beim ersten Start wird `config.yaml` automatisch angelegt – Vorlage: `config.yaml.example`
3. `config.yaml` anpassen:

```yaml
pc:
  name: Mein-PC          # Anzeigename in der App
  mac: AA:BB:CC:DD:EE:FF # MAC-Adresse der Netzwerkkarte
  ip: 192.168.1.100      # Lokale IP-Adresse

api:
  port: 8420
```

4. EXE starten – Weboberfläche: `http://localhost:8420`

**Optional – Autostart mit Windows:**  
Win + R → `shell:startup` → Verknüpfung der EXE dort ablegen.

---

### Android App

1. APK auf das Handy übertragen (USB oder Webbrowser)
2. Vor der Installation: **Einstellungen → Sicherheit → Unbekannte Quellen** aktivieren
3. APK antippen und installieren
4. App starten → PC im Netzwerk wird automatisch gefunden oder manuell per IP eingeben
5. Kopplung: Pairing-Code in der Weboberfläche (`http://PC-IP:8420`) generieren und in der App eingeben

---

## Weboberfläche

Erreichbar unter `http://PC-IP:8420` im lokalen Netzwerk.

| Bereich | Funktion |
|---|---|
| **Gerätekopplung** | Pairing-Codes generieren, verbundene Geräte verwalten |
| **Skripte** | Skripte anlegen, bearbeiten, per Drag & Drop sortieren |
| **Abläufe** | Mehrschrittige Abläufe konfigurieren |
| **Gruppen** | Skripte in Kategorien einteilen |

---

## Selbst bauen

### Voraussetzungen

- Python 3.12+
- Flutter 3.x
- Android SDK + JDK 17

### PC Agent EXE

```bat
build_agent.bat
```

Ausgabe: `pc_agent/dist/PC_Connector_Agent.exe`

### Android APK

```bat
build_apk.bat
```

Ausgabe: `mobile_app/build/app/outputs/flutter-apk/`

---

## Entwicklung

### Backend-Tests

```bash
cd pc_agent
pip install -r requirements.txt pytest pytest-asyncio httpx
pytest tests/ -v
```

### Flutter-Tests

```bash
cd mobile_app
flutter test
```

---

## Sicherheitshinweis

PC Connector ist für den Einsatz im **lokalen Heimnetzwerk** ausgelegt.  
Stelle sicher, dass Port `8420` **nicht** über das Internet erreichbar ist.

---

## Lizenz

MIT License – siehe [LICENSE](LICENSE)
