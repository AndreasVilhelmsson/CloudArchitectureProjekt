#!/bin/bash

echo "🔍 Kollar status för NGINX..."

if systemctl is-active --quiet nginx; then
  echo "✅ NGINX är igång."
else
  echo "❌ NGINX är INTE igång."
fi

echo "🌐 Testar HTTP-svar från localhost..."

if curl -s http://localhost | grep -q "<html"; then
  echo "✅ NGINX svarar korrekt."
else
  echo "❌ Ingen respons från NGINX lokalt."
fi

