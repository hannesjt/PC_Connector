# PC Connector – App (Vue / Nuxt)

Eine einzige Vue-/Nuxt-Codebasis für **Web**, **Mobil** (Capacitor → Android/iOS)
und **Desktop** (Electron → Windows/macOS/Linux). Sie ersetzt die frühere
Angular-Web-App **und** die Flutter-Handy-App.

## Architektur

Ein Browser kann zwei Dinge nicht, die die App braucht: **Wake-on-LAN**
(rohe UDP-Pakete) und **direkte Aufrufe an den PC-Agent** (der schickt keine
CORS-Header). Beides übernimmt der in Nuxt integrierte **Nitro-Server** (die
`server/`-Routen):

```
Client (Vue/Nuxt SPA)
   ├─ /proxy/**    → leitet an den PC-Agent weiter (umgeht CORS,
   │                 schleust Bearer-Token für <img>/Download ein)
   ├─ /api/wol      → sendet das Wake-on-LAN Magic Packet
   └─ /api/discover → findet PC-Agents im LAN (UDP-Broadcast :8421)
```

| Ziel        | Technik                                   |
| ----------- | ----------------------------------------- |
| Web         | Nuxt 3 (SPA) + Nitro-Server (Node)        |
| Android/iOS | Capacitor (verpackt die generierte SPA)   |
| Desktop     | Electron (startet den Nitro-Server lokal) |

| Ordner         | Inhalt                                          |
| -------------- | ----------------------------------------------- |
| `pages/`       | Seiten (Geräteliste, Setup, Steuerung, …)       |
| `composables/` | `useApi`, `useProfiles`, `useTheme`, `useToast` |
| `server/`      | Nitro-Routen: Proxy, WOL, Discovery             |
| `electron/`    | Electron-Hauptprozess + Preload                 |

Der PC-Agent (`pc_agent/`) bleibt **unverändert**.

## Enthaltene Features

Wake-on-LAN · Netzwerk-Discovery · sicheres Pairing (Code) · mehrere PC-Profile ·
Skripte & Kategorien · Abläufe (Chains) · Maus-Touchpad & Tastatur · Lautstärke ·
Zwischenablage senden/holen · Datei-Explorer (Download/Upload/Öffnen) ·
Live-Bildschirm · Skript-Verlauf · Dark/Light-Mode.

> Alles ist freigeschaltet (self-hosted, keine Paywall).

---

## Lokale Entwicklung

```bash
cd web_app
npm install
npm run dev          # Nuxt-Dev-Server auf http://localhost:3000
```

Der Dev-Server stellt sowohl das Frontend als auch die `/proxy`-, `/api/wol`-
und `/api/discover`-Routen bereit.

---

## Web-Deployment auf Proxmox (Docker)

> **Wichtig:** Der Container läuft mit `network_mode: host`, damit die
> Wake-on-LAN- und Discovery-Broadcasts das LAN erreichen (gleiches Layer-2-Netz
> wie der PC).

```bash
cd web_app
docker compose up -d --build
```

Danach im Browser: `http://<proxmox-ip>:8080`. Anderen Port setzen:

```yaml
# docker-compose.yml
environment:
  - PORT=9000
```

### Produktions-Build ohne Docker

```bash
cd web_app
npm install
npm run build                 # erzeugt .output (Nitro node-server)
node .output/server/index.mjs # serviert alles auf $PORT (Standard 3000)
```

---

## Desktop (Electron)

```bash
cd web_app
npm install
npm run build          # Nitro-Server-Bundle erzeugen
npm run electron:dev   # App im Entwicklungsmodus starten

npm run electron:build # installierbares Paket (release/) via electron-builder
```

Electron startet im Produktionsmodus den gebündelten Nitro-Server lokal, sodass
Proxy, Wake-on-LAN und Discovery direkt vom PC aus funktionieren.

---

## Mobil (Capacitor – Android / iOS)

Eine mobile WebView kann keine Broadcast-Pakete senden und der PC-Agent hat
keine CORS-Header. Für WOL/Discovery/Proxy zeigt die App daher auf eine
laufende Web-App-Instanz (`NUXT_PUBLIC_BACKEND_BASE`):

```bash
cd web_app
npm install
npm i -D @capacitor/cli

# Plattformen einmalig anlegen
npx cap add android
npx cap add ios

# generieren + synchronisieren (Backend-Adresse einbetten)
NUXT_PUBLIC_BACKEND_BASE=http://192.168.1.10:8080 npm run cap:android
NUXT_PUBLIC_BACKEND_BASE=http://192.168.1.10:8080 npm run cap:ios
```

`cap:android` / `cap:ios` führen `nuxt generate`, `cap sync` und `cap open` aus.
Der eigentliche APK-/IPA-Build erfolgt anschließend in Android Studio bzw. Xcode.

---

## Hinweise & Sicherheit

- Das Backend proxyt an eine vom Client angegebene Agent-Adresse. In einem
  vertrauenswürdigen Heimnetz ist das ok; exponiere den Dienst **nicht**
  ungeschützt ins Internet (SSRF-Risiko). Nutze bei Bedarf einen Reverse-Proxy
  mit Authentifizierung.
- Wake-on-LAN funktioniert nur, wenn der Host per Broadcast den PC erreicht
  (gleiches Subnetz, WOL im BIOS/NIC aktiviert – siehe Haupt-README).
- Der Live-Bildschirm ist reines Polling von JPEG-Screenshots des Agents.
