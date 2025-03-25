#!/bin/bash

# ==========================================================
# 🛡 sync_ssh_to_bastion.sh
#
# Det här skriptet:
# ✅ Hämtar Bastion-VM:ens publika IP från Azure
# ✅ Kopierar din privata SSH-nyckel (~/.ssh/id_rsa) till Bastion-VM (om den inte redan finns)
# ✅ Sätter rätt filrättigheter (chmod 600) på nyckeln i Bastion
# ✅ Gör det möjligt att SSH:a från Bastion till interna VM:ar
# ==========================================================

# === 🔧 Konfiguration ===
RESOURCE_GROUP="Cloudexercise-north-rg"
BASTION_VM_NAME="bastionVm"
BASTION_USER="azureuser"
SSH_KEY="$HOME/.ssh/id_rsa"
REMOTE_KEY_PATH="/home/$BASTION_USER/.ssh/id_rsa"

# === 🌍 Hämta Bastion IP från Azure ===
echo "🌍 Hämtar Bastion-VM:s publika IP från Azure..."
BASTION_IP=$(az vm show -d -g $RESOURCE_GROUP -n $BASTION_VM_NAME --query publicIps -o tsv)

# === ❌ Kontroll om IP inte hittas ===
if [[ -z "$BASTION_IP" ]]; then
  echo "❌ Kunde inte hitta Bastion-VM:s IP. Kontrollera att:"
  echo "- VM '$BASTION_VM_NAME' finns i resource group '$RESOURCE_GROUP'"
  echo "- Du är inloggad med Azure CLI (az login)"
  echo "- Du har rätt prenumeration vald (az account show)"
  exit 1
fi

echo "✅ Bastion IP hittad: $BASTION_IP"

# === 🔍 Kontrollera om nyckeln redan finns ===
echo "🔍 Kollar om nyckel redan finns på Bastion..."
EXISTS=$(ssh -o StrictHostKeyChecking=no $BASTION_USER@$BASTION_IP "test -f $REMOTE_KEY_PATH && echo 'yes' || echo 'no'")

if [[ "$EXISTS" == "yes" ]]; then
  echo "✅ Nyckeln finns redan på Bastion. Inget att göra."
else
  echo "🔐 Kopierar privat nyckel till Bastion..."
  scp $SSH_KEY $BASTION_USER@$BASTION_IP:$REMOTE_KEY_PATH || {
    echo "❌ Fel vid överföring av nyckel med SCP. Avbryter."
    exit 1
  }

  echo "🔒 Sätter behörigheter på Bastion..."
  ssh $BASTION_USER@$BASTION_IP "chmod 600 $REMOTE_KEY_PATH"
fi

# === ✅ Klart ===
echo ""
echo "✅ Klar! Du kan nu SSH:a från Bastion till dina interna VM:ar:"
echo "   ssh $BASTION_USER@10.0.1.X   # App-VM"
echo "   ssh $BASTION_USER@10.0.2.X   # NGINX-VM"




