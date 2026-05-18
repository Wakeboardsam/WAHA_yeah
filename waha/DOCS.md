# WAHA WhatsApp Add-on — Full Documentation

## Overview

WAHA (WhatsApp HTTP API) is a self-hosted REST API for WhatsApp. This add-on runs WAHA as a Home Assistant add-on, giving you full WhatsApp integration without any external services.

---

## First-Time Setup

After installing and starting the add-on:

1. Open the **Web UI** — click "Open Web UI" on the add-on page, or go to `http://<your-ha-ip>:3000/dashboard`
2. Log in with:
   - Username: `admin`
   - Password: `waha_fixed_password_2026`
3. The `default` session is pre-configured — click **Start** to start it
4. A QR code will appear — scan it with WhatsApp on your phone:
   - Open WhatsApp → **Settings → Linked Devices → Link a Device**
5. Wait for status to show **WORKING**

Session data is persisted — you only need to scan the QR code once. After HA or add-on restarts, start the session again (or use the auto-start automation below).

---

## Docker Image

This add-on uses the official WAHA Docker image:

| Architecture | Image Tag |
|---|---|
| `aarch64` (Raspberry Pi 4/5) | `devlikeapro/waha:arm-2026.4.3` |
| `amd64` (x86/NUC/VM) | `devlikeapro/waha:2026.4.3` |

The correct image is selected automatically. Home Assistant builds the add-on locally and injects the right base image for your device's architecture via the `BUILD_FROM` build argument (defined in `build.yaml`).

WAHA CORE (free tier) is used. No paid subscription required.

---

## Environment Variables

### Security

| Variable | Default | Description |
|---|---|---|
| `WAHA_API_KEY` | `waha_fixed_key_2026` | API key — include as `X-Api-Key` header in all REST requests |
| `WAHA_DASHBOARD_USERNAME` | `admin` | Dashboard UI login username |
| `WAHA_DASHBOARD_PASSWORD` | `waha_fixed_password_2026` | Dashboard UI login password |
| `WAHA_NO_API_KEY` | `false` | Set `true` to disable API key requirement |

### Sessions

| Variable | Default | Description |
|---|---|---|
| `WAHA_DEFAULT_SESSION` | `default` | Default session name |
| `WHATSAPP_RESTART_ALL_SESSIONS` | `false` | Auto-restart all sessions on startup |
| `WAHA_AUTO_START_DELAY_SECONDS` | `0` | Delay before auto-starting sessions |
| `WAHA_CLIENT_DEVICE_NAME` | — | Name shown in WhatsApp Linked Devices list |
| `WAHA_CLIENT_BROWSER_NAME` | — | Browser name shown in WhatsApp |

### Storage

| Variable | Default | Description |
|---|---|---|
| `WAHA_LOCAL_STORE_BASE_DIR` | `/data/.sessions` | Base directory for session persistence |
| `WHATSAPP_FILES_FOLDER` | `/tmp/whatsapp-files` | Directory for received media files |
| `WHATSAPP_FILES_LIFETIME` | `180` | Media file lifetime in seconds (`0` = permanent) |
| `WHATSAPP_DOWNLOAD_MEDIA` | `true` | Whether to download incoming media |

### Engine

| Variable | Default | Description |
|---|---|---|
| `WHATSAPP_DEFAULT_ENGINE` | `WEBJS` | Engine: `WEBJS`, `NOWEB`, or `GOWS` |

### Logging

| Variable | Default | Description |
|---|---|---|
| `WAHA_LOG_LEVEL` | `info` | Log level: `error`, `warn`, `info`, `debug`, `trace` |
| `WAHA_LOG_FORMAT` | `PRETTY` | Log format: `PRETTY` or `JSON` |
| `TZ` | — | Timezone e.g. `Europe/Berlin` |

### Webhooks (receive messages in HA)

| Variable | Default | Description |
|---|---|---|
| `WHATSAPP_HOOK_URL` | — | URL to POST incoming events to |
| `WHATSAPP_HOOK_EVENTS` | — | Events to forward: `message`, `session.status`, or `*` for all |
| `WHATSAPP_HOOK_HMAC_KEY` | — | Secret key for webhook HMAC signature verification |
| `WHATSAPP_HOOK_RETRIES_POLICY` | — | Retry policy: `linear` or `exponential` |
| `WHATSAPP_HOOK_RETRIES_DELAY_SECONDS` | `2` | Delay between retries |

### Proxy

| Variable | Default | Description |
|---|---|---|
| `WHATSAPP_PROXY_SERVER` | — | Proxy server (e.g. `localhost:3128`) |
| `WHATSAPP_PROXY_SERVER_USERNAME` | — | Proxy username |
| `WHATSAPP_PROXY_SERVER_PASSWORD` | — | Proxy password |

---

## Session Management API

All requests require the `X-Api-Key` header.

### Create a session

```bash
curl -X POST http://<ha-ip>:3000/api/sessions \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: waha_fixed_key_2026' \
  -d '{"name": "default"}'
```

### Start a session

```bash
curl -X POST http://<ha-ip>:3000/api/sessions/default/start \
  -H 'X-Api-Key: waha_fixed_key_2026'
```

### Check session status

```bash
curl http://<ha-ip>:3000/api/sessions/default \
  -H 'X-Api-Key: waha_fixed_key_2026'
```

Response:
```json
{
  "name": "default",
  "status": "WORKING",
  "me": {
    "id": "491234567890@c.us",
    "pushName": "Your Name"
  }
}
```

### Get QR code for authentication

```bash
curl http://<ha-ip>:3000/api/default/auth/qr?format=image \
  -H 'X-Api-Key: waha_fixed_key_2026' \
  --output qr.png
```

### Stop a session

```bash
curl -X POST http://<ha-ip>:3000/api/sessions/default/stop \
  -H 'X-Api-Key: waha_fixed_key_2026'
```

### Logout (clears WhatsApp auth — requires new QR scan)

```bash
curl -X POST http://<ha-ip>:3000/api/sessions/default/logout \
  -H 'X-Api-Key: waha_fixed_key_2026'
```

### Session status states

| Status | Meaning |
|---|---|
| `STOPPED` | Not running |
| `STARTING` | Initializing |
| `SCAN_QR_CODE` | Waiting for QR scan (expires in 60–120s) |
| `WORKING` | Connected and ready |
| `FAILED` | Error — restart or re-authenticate |

---

## Sending Messages API

### Send a text message

```bash
curl -X POST http://<ha-ip>:3000/api/sendText \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: waha_fixed_key_2026' \
  -d '{
    "chatId": "491234567890@c.us",
    "text": "Hello from Home Assistant!",
    "session": "default"
  }'
```

### Send an image

```bash
curl -X POST http://<ha-ip>:3000/api/sendImage \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: waha_fixed_key_2026' \
  -d '{
    "chatId": "491234567890@c.us",
    "file": {"url": "https://example.com/image.jpg"},
    "caption": "Look at this!",
    "session": "default"
  }'
```

### Send a file

```bash
curl -X POST http://<ha-ip>:3000/api/sendFile \
  -H 'Content-Type: application/json' \
  -H 'X-Api-Key: waha_fixed_key_2026' \
  -d '{
    "chatId": "491234567890@c.us",
    "file": {"url": "https://example.com/document.pdf"},
    "caption": "Your document",
    "session": "default"
  }'
```

> **Note:** Phone numbers must be in international format without `+` (e.g. `491234567890` not `+491234567890`)

---

## Home Assistant Integration

### REST commands (`configuration.yaml`)

```yaml
rest_command:
  send_whatsapp:
    url: "http://localhost:3000/api/sendText"
    method: POST
    headers:
      Content-Type: application/json
      X-Api-Key: "waha_fixed_key_2026"
    payload: '{"chatId": "{{ phone }}@c.us", "text": "{{ message }}", "session": "default"}'

  waha_start_session:
    url: "http://localhost:3000/api/sessions/default/start"
    method: POST
    headers:
      X-Api-Key: "waha_fixed_key_2026"

  waha_stop_session:
    url: "http://localhost:3000/api/sessions/default/stop"
    method: POST
    headers:
      X-Api-Key: "waha_fixed_key_2026"
```

### Auto-start session on HA boot (`automations.yaml`)

```yaml
- alias: "Start WAHA session on startup"
  trigger:
    - platform: homeassistant
      event: start
  action:
    - delay: "00:00:30"
    - service: rest_command.waha_start_session
```

### Send a message from an automation

```yaml
- alias: "Notify on motion"
  trigger:
    - platform: state
      entity_id: binary_sensor.garden_motion
      to: "on"
  action:
    - service: rest_command.send_whatsapp
      data:
        phone: "491234567890"
        message: "Motion detected in the garden!"
```

### Receive messages via webhook

To trigger HA automations when a WhatsApp message arrives, set the webhook URL environment variable to your HA webhook:

```
WHATSAPP_HOOK_URL=http://homeassistant:8123/api/webhook/whatsapp_incoming
WHATSAPP_HOOK_EVENTS=message
```

Then in HA create an automation with a webhook trigger:

```yaml
- alias: "Handle incoming WhatsApp message"
  trigger:
    - platform: webhook
      webhook_id: whatsapp_incoming
  action:
    - service: notify.notify
      data:
        message: "WhatsApp message received: {{ trigger.json.payload.body }}"
```

---

## Storage

Session authentication data is stored at `/data/.sessions` inside the container, which maps to HA's persistent add-on storage. This survives:
- Add-on restarts
- HA reboots
- HA OS updates

You only need to scan the QR code once. If you **logout** (not stop) the session, WhatsApp auth is cleared and a new QR scan is required.

---

## Troubleshooting

**QR code keeps appearing after restart**
- The session was logged out, not just stopped. Start the session — if it goes to `WORKING` directly, data is persisted. If it goes to `SCAN_QR_CODE`, scan once and it will persist going forward.

**401 Unauthorized**
- Add the `X-Api-Key: waha_fixed_key_2026` header to all requests.

**Message not delivered**
- Check session status is `WORKING` before sending.
- Phone number must be in international format without `+`.

**Add-on won't start**
- Check the add-on logs for errors.
- Make sure port 3000 is not used by another add-on.

**Web UI not accessible**
- Try `http://<your-ha-ip>:3000/dashboard` directly in your browser.
