<p align="center">
  <img src="assets/icon/icon.png" width="120" alt="PC Connector Icon">
</p>

<h1 align="center">PC Connector</h1>

<p align="center">
  Steuere und wecke deinen PC vom Handy aus – per Wake-on-LAN, Skripte und Abläufe.
</p>

<p align="center">
  <a href="../../releases/latest">
    <img src="https://img.shields.io/github/v/release/DEIN-USERNAME/PC_Connector?label=Download&style=for-the-badge&logo=github" alt="Letzter Release">
  </a>
</p>

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
