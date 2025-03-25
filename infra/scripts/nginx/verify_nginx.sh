#!/bin/bash

echo "🧪 Verifierar NGINX-status på denna VM..."

# 1. Är nginx installerat?
if ! command -v nginx &> /dev/null; then
  echo "❌ NGINX är inte installerat!"
  exit 1
else
  echo "✅ NGINX är installerat."
fi

# 2. Är nginx igång?
echo "🔎 Kollar tjänstestatus..."
STATUS=$(systemctl is-active nginx)
if [[ "$STATUS" == "active" ]]; then
  echo "✅ NGINX körs just nu."
else
  echo "❌ NGINX är inte igång. Försöker starta..."
  sudo systemctl start nginx
  sleep 2
fi

# 3. Lyssnar nginx på port 80?
echo "🔎 Kollar om port 80 är öppen lokalt..."
if sudo ss -tuln | grep ':80' &> /dev/null; then
  echo "✅ NGINX lyssnar på port 80."
else
  echo "❌ NGINX lyssnar inte på port 80."
fi

# 4. Fungerar en lokal förfrågan?
echo "🔎 Testar curl till localhost..."
if curl -s --max-time 3 http://localhost | grep -q "nginx"; then
  echo "✅ NGINX svarar korrekt lokalt!"
else
  echo "❌ Ingen respons från NGINX lokalt."
fi

# 5. Extern IP
echo "🌍 Din publika IP är:"
curl -s ifconfig.me || curl -s http://icanhazip.com
