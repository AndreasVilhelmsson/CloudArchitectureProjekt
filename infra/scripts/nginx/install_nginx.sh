#!/bin/bash

echo "🧰 Uppdaterar system..."
sudo apt update && sudo apt upgrade -y

echo "📦 Installerar NGINX..."
sudo apt install -y nginx

echo "✅ Startar och aktiverar NGINX..."
sudo systemctl start nginx
sudo systemctl enable nginx

echo "🌍 Öppnar port 80 i brandväggen (om behövs)..."
sudo ufw allow 'Nginx Full' || true

echo "✅ Klart! Testa i webbläsaren:"
curl http://localhost
