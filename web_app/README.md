# PC Connector – Web-App (Angular)

Web-Version der PC-Connector-Handy-App. Steuere deinen PC bequem aus dem Browser –
gehostet auf deinem Proxmox-Server (oder jedem Docker-Host im selben Netzwerk).

## Architektur

Ein Browser kann zwei Dinge nicht, die die Handy-App macht: **Wake-on-LAN**
(rohe UDP-Pakete) und **direkte Aufrufe an den PC-Agent** (der schickt keine
CORS-Header). Beides löst ein schlankes Node-Backend, das immer mitläuft:

```
Browser ──► Angular SPA (statisch)
        └─► Node-Backend (BFF)
              ├─ /proxy/**   → leitet an den PC-Agent weiter (umgeht CORS,
              │                schleust Bearer-Token für <img>/Download ein)
              ├─ /api/wol     → sendet das Wake-on-LAN Magic Packet
              └─ /api/discover→ findet PC-Agents im LAN (UDP-Broadcast :8421)
```

| Komponente  | Technik                                     |
| ----------- | ------------------------------------------- |
| `frontend/` | Angular 18 (Standalone-Components, Signals) |
| `backend/`  | Node.js + Express + `http-proxy`            |

Der PC-Agent (`pc_agent/`) bleibt **unverändert**.

## Enthaltene Features

Wake-on-LAN · Netzwerk-Discovery · sicheres Pairing (Code) · mehrere PC-Profile ·
Skripte & Kategorien · Abläufe (Chains) · Maus-Touchpad & Tastatur · Lautstärke ·
Zwischenablage senden/holen · Datei-Explorer (Download/Upload/Öffnen) ·
Live-Bildschirm · Skript-Verlauf · Dark/Light-Mode.

> Alles ist freigeschaltet (self-hosted, keine Paywall). Die App-PIN-Sperre wurde
> weggelassen – sichere den Zugriff stattdessen über dein Netzwerk bzw. einen
> Reverse-Proxy mit Auth.

---

## Deployment auf Proxmox (Docker)

Voraussetzung: Docker + Docker Compose in einer LXC/VM oder direkt auf dem Host.

> **Wichtig:** Der Container läuft mit `network_mode: host`, damit die
> Wake-on-LAN- und Discovery-Broadcasts das LAN erreichen. Er muss dafür im
> **selben Layer-2-Netz** wie dein PC hängen (bei LXC eine Bridge, kein NAT).

```bash
cd web_app
docker compose up -d --build
```

Danach im Browser öffnen:

```
http://<proxmox-ip>:8080
```

Anderen Port setzen:

```yaml
# docker-compose.yml
environment:
  - PORT=9000
```

### Erste Schritte in der Web-App

1. **„PC hinzufügen“** oder **„PCs im Netzwerk suchen“**.
2. Auf dem PC die Agent-Weboberfläche öffnen (`http://<pc-ip>:8420`) und
   **„Code generieren“**.
3. Code in der Web-App eingeben → **Verbinden**. Das Profil (inkl. Token & MAC)
   wird im Browser (localStorage) gespeichert.

---

## Lokale Entwicklung

Zwei Terminals:

```bash
# 1) Backend (Proxy + WOL + Discovery) auf :8080
cd web_app/backend
npm install
npm start

# 2) Angular Dev-Server auf :4200 (proxyt /proxy und /api an :8080)
cd web_app/frontend
npm install
npm start
```

Aufrufen: `http://localhost:4200`

## Produktions-Build (ohne Docker)

```bash
cd web_app/frontend
npm install && npm run build     # erzeugt dist/pc-connector-web/browser
cd ../backend
npm install --omit=dev
cp -r ../frontend/dist/pc-connector-web/browser ./public
node server.js                   # serviert alles auf $PORT (Standard 8080)
```

---

## Hinweise & Sicherheit

- Das Backend proxyt an eine vom Client angegebene Agent-Adresse. In einem
  vertrauenswürdigen Heimnetz ist das ok; exponiere den Dienst **nicht**
  ungeschützt ins Internet (SSRF-Risiko). Nutze bei Bedarf einen Reverse-Proxy
  mit Authentifizierung.
- Wake-on-LAN funktioniert nur, wenn der Docker-Host per Broadcast den PC
  erreicht (gleiches Subnetz, WOL im BIOS/NIC aktiviert – siehe Haupt-README).
- Der Live-Bildschirm ist reines Polling von JPEG-Screenshots des Agents.
