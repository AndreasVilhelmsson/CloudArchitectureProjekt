#!/bin/bash

# ==========================
# 🌍 Global konfiguration
# ==========================
RESOURCE_GROUP="Cloudexercise-north-rg"
LOCATION="northeurope"
USERNAME="azureuser"
VM_IMAGE="Ubuntu2204"
VM_SIZE="Standard_B1s"

# ==========================
# 🌐 Nätverksinställningar
# ==========================
VNET_NAME="cloudexercise-vnet"

APP_SUBNET_NAME="app-subnet"
APP_SUBNET_PREFIX="10.0.1.0/24"
APP_VM_NAME="myAppVm"

NGINX_SUBNET_NAME="nginx-subnet"
NGINX_SUBNET_PREFIX="10.0.2.0/24"
NGINX_VM_NAME="nginxVm"

# ==========================
# 🧠 Funktion för dynamisk portöppning
# ==========================
open_port_if_needed() {
  local PORT=$1
  local VM_NAME=$2

  echo "🔐 Kollar om port $PORT är öppen på $VM_NAME..."

  NIC_ID=$(az vm show -g $RESOURCE_GROUP -n $VM_NAME --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  NSG_ID=$(az network nic show --ids $NIC_ID --query 'networkSecurityGroup.id' -o tsv)
  NSG_NAME=$(basename $NSG_ID)

  PORT_OPEN=$(az network nsg rule list -g $RESOURCE_GROUP --nsg-name $NSG_NAME \
    --query "[?destinationPortRange=='$PORT'].name" -o tsv)

  if [[ -z "$PORT_OPEN" ]]; then
    USED_PRIORITIES=$(az network nsg rule list -g $RESOURCE_GROUP --nsg-name $NSG_NAME --query "[].priority" -o tsv)
    NEXT_PRIORITY=1001
    while echo "$USED_PRIORITIES" | grep -q "$NEXT_PRIORITY"; do
      ((NEXT_PRIORITY++))
    done

    echo "🔓 Öppnar port $PORT på $VM_NAME (priority $NEXT_PRIORITY)..."
    az vm open-port \
      --resource-group $RESOURCE_GROUP \
      --name $VM_NAME \
      --port $PORT \
      --priority $NEXT_PRIORITY
  else
    echo "✅ Port $PORT är redan öppen på $VM_NAME"
  fi
}

# ==========================
# 🛠 Skapa Resource Group
# ==========================
echo "📦 Kollar om resource group finns..."
if az group show --name $RESOURCE_GROUP &> /dev/null; then
  echo "✅ Resource group '$RESOURCE_GROUP' finns redan."
else
  echo "🌀 Skapar resource group..."
  az group create --name $RESOURCE_GROUP --location $LOCATION
fi

# ==========================
# 🛠 Skapa VNet
# ==========================
echo "🌐 Kollar om vNet finns..."
if az network vnet show --name $VNET_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ vNet '$VNET_NAME' finns redan."
else
  echo "🌐 Skapar vNet..."
  az network vnet create \
    --resource-group $RESOURCE_GROUP \
    --name $VNET_NAME \
    --address-prefix 10.0.0.0/16 \
    --subnet-name $APP_SUBNET_NAME \
    --subnet-prefix $APP_SUBNET_PREFIX
fi

# ==========================
# 🛠 Skapa NGINX-subnet
# ==========================
echo "🌐 Kollar om NGINX-subnet finns..."
if az network vnet subnet show \
  --vnet-name $VNET_NAME \
  --name $NGINX_SUBNET_NAME \
  --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ Subnet '$NGINX_SUBNET_NAME' finns redan."
else
  echo "📦 Skapar subnet för NGINX..."
  az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $NGINX_SUBNET_NAME \
    --address-prefixes $NGINX_SUBNET_PREFIX
fi

# ==========================
# 💻 Skapa App VM
# ==========================
echo "💻 Kollar om app-VM '$APP_VM_NAME' finns..."
if az vm show --name $APP_VM_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ App VM '$APP_VM_NAME' finns redan."
else
  echo "🚀 Skapar App VM..."
  az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $APP_VM_NAME \
    --image $VM_IMAGE \
    --size $VM_SIZE \
    --admin-username $USERNAME \
    --generate-ssh-keys \
    --vnet-name $VNET_NAME \
    --subnet $APP_SUBNET_NAME \
    --public-ip-sku Standard
fi

# ==========================
# 💻 Skapa NGINX VM
# ==========================
echo "💻 Kollar om NGINX-VM '$NGINX_VM_NAME' finns..."
if az vm show --name $NGINX_VM_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ NGINX VM '$NGINX_VM_NAME' finns redan."
else
  echo "🚀 Skapar NGINX VM..."
  az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $NGINX_VM_NAME \
    --image $VM_IMAGE \
    --size $VM_SIZE \
    --admin-username $USERNAME \
    --generate-ssh-keys \
    --vnet-name $VNET_NAME \
    --subnet $NGINX_SUBNET_NAME \
    --public-ip-sku Standard
fi

# ==========================
# 🌐 Öppna portar automatiskt
# ==========================
open_port_if_needed 80 $APP_VM_NAME
open_port_if_needed 5000 $APP_VM_NAME
open_port_if_needed 80 $NGINX_VM_NAME

# ==========================
# 🔗 Visa IP-adresser
# ==========================
APP_IP=$(az vm show -d -g $RESOURCE_GROUP -n $APP_VM_NAME --query publicIps -o tsv)
NGINX_IP=$(az vm show -d -g $RESOURCE_GROUP -n $NGINX_VM_NAME --query publicIps -o tsv)

echo ""
echo "✅ Klart!"
echo "🌍 App-VM IP:     $APP_IP"
echo "🌍 NGINX-VM IP:   $NGINX_IP"
echo ""
echo "🔐 SSH in till VMs:"
echo "   ssh $USERNAME@$APP_IP"
echo "   ssh $USERNAME@$NGINX_IP"

# ==========================
# 🛡 Bastion-inställningar
# ==========================
BASTION_SUBNET_NAME="bastion-subnet"
BASTION_SUBNET_PREFIX="10.0.3.0/24"
BASTION_VM_NAME="bastionVm"

# ==========================
# 📡 Skapa Bastion Subnet
# ==========================
echo "🌐 Kollar om Bastion-subnet finns..."
if az network vnet subnet show \
  --vnet-name $VNET_NAME \
  --name $BASTION_SUBNET_NAME \
  --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ Subnet '$BASTION_SUBNET_NAME' finns redan."
else
  echo "📦 Skapar subnet för Bastion..."
  az network vnet subnet create \
    --resource-group $RESOURCE_GROUP \
    --vnet-name $VNET_NAME \
    --name $BASTION_SUBNET_NAME \
    --address-prefixes $BASTION_SUBNET_PREFIX
fi

# ==========================
# 🛡 Skapa Bastion VM
# ==========================
echo "💻 Kollar om Bastion VM '$BASTION_VM_NAME' finns..."
if az vm show --name $BASTION_VM_NAME --resource-group $RESOURCE_GROUP &> /dev/null; then
  echo "✅ Bastion VM '$BASTION_VM_NAME' finns redan."
else
  echo "🚀 Skapar Bastion VM..."
  az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $BASTION_VM_NAME \
    --image $VM_IMAGE \
    --size $VM_SIZE \
    --admin-username $USERNAME \
    --generate-ssh-keys \
    --vnet-name $VNET_NAME \
    --subnet $BASTION_SUBNET_NAME \
    --public-ip-sku Standard
fi

# ==========================
# 🔓 Öppna SSH till Bastion
# ==========================
open_port_if_needed 22 $BASTION_VM_NAME

# ==========================
# 📡 Visa Bastion IP
# ==========================
BASTION_IP=$(az vm show -d -g $RESOURCE_GROUP -n $BASTION_VM_NAME --query publicIps -o tsv)

echo ""
echo "🛡 Bastion-VM IP: $BASTION_IP"
echo "🔐 SSH in med:"
echo "   ssh $USERNAME@$BASTION_IP"

# ==========================
# 🔐 Tillåt intern SSH från Bastion till andra VM:ar
# ==========================

allow_internal_ssh() {
  local TARGET_VM=$1
  local SOURCE_SUBNET=$2
  local PORT=22

  echo "🔐 Kollar intern SSH-regel för $TARGET_VM från $SOURCE_SUBNET..."

  NIC_ID=$(az vm show -g $RESOURCE_GROUP -n $TARGET_VM --query 'networkProfile.networkInterfaces[0].id' -o tsv)
  NSG_ID=$(az network nic show --ids $NIC_ID --query 'networkSecurityGroup.id' -o tsv)
  NSG_NAME=$(basename $NSG_ID)

  RULE_EXISTS=$(az network nsg rule list -g $RESOURCE_GROUP --nsg-name $NSG_NAME \
    --query "[?name=='allow-ssh-from-bastion'].name" -o tsv)

  if [[ -z "$RULE_EXISTS" ]]; then
    echo "🔓 Skapar NSG-regel på $TARGET_VM som tillåter SSH från $SOURCE_SUBNET..."
    az network nsg rule create \
      --resource-group $RESOURCE_GROUP \
      --nsg-name $NSG_NAME \
      --name allow-ssh-from-bastion \
      --priority 1050 \
      --source-address-prefixes $SOURCE_SUBNET \
      --destination-port-ranges $PORT \
      --direction Inbound \
      --access Allow \
      --protocol Tcp
  else
    echo "✅ SSH-regel från $SOURCE_SUBNET finns redan på $TARGET_VM"
  fi
}

# Kör för båda VM:ar
allow_internal_ssh $APP_VM_NAME $BASTION_SUBNET_PREFIX
allow_internal_ssh $NGINX_VM_NAME $BASTION_SUBNET_PREFIX

