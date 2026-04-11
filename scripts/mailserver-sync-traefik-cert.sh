#!/bin/bash
set -euo pipefail

ACME_JSON_PATH="${1:-/var/data/config/traefik/acme.json}"
MAIL_DOMAIN="${2:-mail.furyhawk.lol}"
TARGET_DIR="/var/data/docker-mailserver/ssl"

if [ ! -f "$ACME_JSON_PATH" ]; then
  echo "ACME file not found: $ACME_JSON_PATH"
  exit 1
fi

mkdir -p "$TARGET_DIR"

python3 - "$ACME_JSON_PATH" "$MAIL_DOMAIN" "$TARGET_DIR" <<'PY'
import base64
import json
import os
import sys

acme_path, mail_domain, target_dir = sys.argv[1], sys.argv[2], sys.argv[3]

with open(acme_path, "r", encoding="utf-8") as f:
    data = json.load(f)

cert_entries = data.get("letsencrypt", {}).get("Certificates", [])
if not cert_entries:
    raise SystemExit("No certificates found in acme.json")

selected = None
for entry in cert_entries:
    domain = entry.get("domain", {})
    main = domain.get("main", "")
    sans = domain.get("sans", []) or []
    if main == mail_domain or mail_domain in sans:
        selected = entry
        break

if selected is None:
    raise SystemExit(f"No certificate found for domain: {mail_domain}")

cert_b64 = selected.get("certificate")
key_b64 = selected.get("key")
if not cert_b64 or not key_b64:
    raise SystemExit("Selected certificate entry is missing certificate/key data")

cert_pem = base64.b64decode(cert_b64)
key_pem = base64.b64decode(key_b64)

cert_path = os.path.join(target_dir, "fullchain.pem")
key_path = os.path.join(target_dir, "privkey.pem")

with open(cert_path, "wb") as f:
    f.write(cert_pem)
with open(key_path, "wb") as f:
    f.write(key_pem)

os.chmod(cert_path, 0o600)
os.chmod(key_path, 0o600)

print(f"Wrote {cert_path}")
print(f"Wrote {key_path}")
PY

echo "Certificate sync complete for $MAIL_DOMAIN"
