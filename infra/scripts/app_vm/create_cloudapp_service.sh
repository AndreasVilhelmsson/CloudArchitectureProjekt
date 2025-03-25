#!/bin/bash

SERVICE_NAME="cloudapp"
APP_USER="azureuser"
APP_DIR="/home/$APP_USER/cloudapp"
APP_DLL="Cloudsoft.dll"  # Ändra detta till din faktiska DLL

echo "📝 Skapar systemd-tjänstfil..."

cat <<EOF | sudo tee /etc/systemd/system/$SERVICE_NAME.service
[Unit]
Description=.NET App Service
After=network.target

[Service]
WorkingDirectory=$APP_DIR
ExecStart=/usr/bin/env ASPNETCORE_URLS=http://0.0.0.0:5000 dotnet $APP_DLL
Restart=always
RestartSec=10
KillSignal=SIGINT
SyslogIdentifier=$SERVICE_NAME
User=$APP_USER
Environment=DOTNET_PRINT_TELEMETRY_MESSAGE=false

[Install]
WantedBy=multi-user.target
EOF

echo "🔁 Startar och aktiverar tjänsten..."
sudo systemctl daemon-reexec
sudo systemctl daemon-reload
sudo systemctl enable $SERVICE_NAME
sudo systemctl start $SERVICE_NAME

echo "✅ Klar! Tjänsten '$SERVICE_NAME' är nu aktiv."
