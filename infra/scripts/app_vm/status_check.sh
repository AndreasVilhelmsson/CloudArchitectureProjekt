#!/bin/bash

echo "🔍 Kollar status för .NET-appen (cloudapp.service)..."

if systemctl is-active --quiet cloudapp; then
  echo "✅ App-tjänsten 'cloudapp' är igång."
else
  echo "❌ App-tjänsten är INTE igång."
fi

echo "🌐 Testar HTTP-svar på port 5000..."

if curl -s http://localhost:5000 | grep -q "<html"; then
  echo "✅ Appen svarar korrekt på port 5000."
else
  echo "❌ Ingen respons från appen på port 5000."
fi
