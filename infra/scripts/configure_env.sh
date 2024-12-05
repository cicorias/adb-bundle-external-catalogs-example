#!/bin/bash
set -x
# Set paths
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENV_FILE="$ROOT_DIR/infra/.env"

echo -e "\e[32mROOT_DIR: $ROOT_DIR\e[0m"
echo -e "\e[32mENV_FILE: $ENV_FILE\e[0m"
echo -e "\e[32mSCRIPT_DIR: $SCRIPT_DIR\e[0m"

# Ensure the infra directory exists
mkdir -p "$(dirname "$ENV_FILE")"

# Backup existing .env file if it exists
if [[ -f "$ENV_FILE" ]]; then
  cp "$ENV_FILE" "$ENV_FILE.bak"
fi


# Function to check if the az cli is installed and NOT for Windows
check_az_cli() {
    # call the `az --version1` and ensure the string "Python (Windows)" does Not appear
    if az --version | grep -q "Python (Windows)"; then
        echo -e "\e[31mAzure CLI is not version for Linux/Darwin/WSL. Please install a proper native version.\e[0m"
        exit 1
    fi
}

# Function to update or add a variable in the .env file
update_env_var() {
  local key=$1
  local value=$2
  if grep -q "^${key}=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s/^${key}=.*/${key}=${value}/" "$ENV_FILE"
  else
    echo "${key}=${value}" >> "$ENV_FILE"
  fi
}

# Preflight checks

check_az_cli

# Step 1: Get Azure Subscription
echo "Fetching the current Azure subscription..."
SUBSCRIPTION=$(az account show --query "id" -o tsv)

if [[ -z "$SUBSCRIPTION" ]]; then
  echo -e "\e[31mFailed to fetch Azure subscription. Ensure you're logged into Azure CLI.\e[0m"
  exit 1
fi

update_env_var "ARM_SUBSCRIPTION_ID" "$SUBSCRIPTION"
echo "Azure subscription '$SUBSCRIPTION' has been saved as ARM_SUBSCRIPTION_ID in $ENV_FILE."

# Step 2: Select Azure Region
echo "Fetching the list of available Azure regions..."
REGIONS=$(az account list-locations --query "[].{Name:name}" -o tsv)

if [[ -z "$REGIONS" ]]; then
  echo -e "\e[31mFailed to fetch Azure regions. Ensure you're logged into Azure CLI and have the correct subscription selected.\e[0m"
  exit 1
fi

echo "Available Azure regions:"
echo "$REGIONS" | nl -w 3 -s '. '

echo ""
read -p "Enter the number of the Azure region to select: " REGION_NUMBER

if ! [[ "$REGION_NUMBER" =~ ^[0-9]+$ ]]; then
  echo -e "\e[31mInvalid input. Please enter a valid number.\e[0m"
  exit 1
fi

SELECTED_REGION=$(echo "$REGIONS" | sed -n "${REGION_NUMBER}p")
if [[ -z "$SELECTED_REGION" ]]; then
  echo -e "\e[31mInvalid selection. Please try again.\e[0m"
  exit 1
fi

update_env_var "TF_VAR_location" "$SELECTED_REGION"
echo "Region '$SELECTED_REGION' has been saved as TF_VAR_location in $ENV_FILE."

# Step 3: Select Databricks Workspace
if [[ -f "$ENV_FILE" ]]; then
  source "$ENV_FILE"
fi

if [[ -z "$TF_VAR_location" ]]; then
  echo -e "\e[31mError: TF_VAR_location is not set. Please ensure the region is selected.\e[0m"
  exit 1
fi

echo "Fetching Databricks workspaces in the region: $TF_VAR_location..."
WORKSPACES=$(az databricks workspace list --query "[?location=='$TF_VAR_location'].{Name:name,ResourceGroup:resourceGroup,Region:location}" -o json)

if [[ -z "$WORKSPACES" ]]; then
  echo -e "\e[31mNo Databricks workspaces found in the region: $TF_VAR_location.\e[0m"
  exit 1
fi

# Parse workspace names, resource groups, and regions
WORKSPACE_NAMES=$(echo "$WORKSPACES" | jq -r '.[].Name')
WORKSPACE_RGS=$(echo "$WORKSPACES" | jq -r '.[].ResourceGroup')
WORKSPACE_REGIONS=$(echo "$WORKSPACES" | jq -r '.[].Region')

echo "Available Databricks workspaces in $TF_VAR_location:"
echo "$WORKSPACE_NAMES" | nl -w 3 -s '. '
if [[ -z "$WORKSPACE_NAMES" ]]; then
    echo -e "\e[31mError: No Databricks workspaces found in the region: $TF_VAR_location. Please rerun the script.\e[0m"
    exit 1
fi

echo ""
read -p "Enter the number of the Databricks workspace to select: " WORKSPACE_NUMBER

if ! [[ "$WORKSPACE_NUMBER" =~ ^[0-9]+$ ]]; then
  echo -e "\e[31mInvalid input. Please enter a valid number.\e[0m"
  exit 1
fi

SELECTED_WORKSPACE=$(echo "$WORKSPACE_NAMES" | sed -n "${WORKSPACE_NUMBER}p")
SELECTED_RG=$(echo "$WORKSPACE_RGS" | sed -n "${WORKSPACE_NUMBER}p")
SELECTED_REGION=$(echo "$WORKSPACE_REGIONS" | sed -n "${WORKSPACE_NUMBER}p")

if [[ -z "$SELECTED_WORKSPACE" || -z "$SELECTED_RG" || -z "$SELECTED_REGION" ]]; then
  echo -e "\e[31mInvalid selection. Please try again.\e[0m"
  exit 1
fi

update_env_var "TF_VAR_adb_workspace_name" "$SELECTED_WORKSPACE"
update_env_var "TF_VAR_adb_resource_group" "$SELECTED_RG"
update_env_var "TF_VAR_environment_name" "dev"
echo -e "\e[32mDatabricks workspace '$SELECTED_WORKSPACE' and resource group '$SELECTED_RG' have been saved to $ENV_FILE.\e[0m"

# Confirm the updated .env file
echo -e "\e[32mCurrent contents of $ENV_FILE:\e[0m"
cat "$ENV_FILE"
