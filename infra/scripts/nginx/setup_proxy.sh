cat > setup_proxy.sh <<EOF
#!/bin/bash

APP_VM_IP="40.69.207.116"  # <-- Ersätt med din riktiga app-IP!

echo "📝 Skapar NGINX proxy-konfiguration..."

cat <<NGINX | sudo tee /etc/nginx/sites-available/cloudapp
server {
    listen 80;

    location / {
        proxy_pass http://$APP_VM_IP:5000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection keep-alive;
        proxy_set_header Host \$host;
        proxy_cache_bypass \$http_upgrade;
    }
}
NGINX

echo "🔗 Aktiverar konfiguration..."
sudo ln -sf /etc/nginx/sites-available/cloudapp /etc/nginx/sites-enabled/default

echo "🧪 Testar NGINX-konfig..."
sudo nginx -t

echo "🔄 Startar om NGINX..."
sudo systemctl reload nginx

echo "✅ Proxy är nu aktiv!"
EOF
