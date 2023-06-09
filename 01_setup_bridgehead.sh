#!/usr/bin/env bash

TEMP=$(getopt -o '' --long client_id:,client_secret:,tenant_id:,subscription_id: -- "$@")
eval set -- "$TEMP"

while true; do
  case "$1" in
    --client_id)
      ARM_CLIENT_ID="$2"
      shift 2;;
    --client_secret)
      ARM_CLIENT_SECRET="$2"
      shift 2;;
    --tenant_id)
      ARM_TENANT_ID="$2"
      shift 2;;
    --subscription_id)
      ARM_SUBSCRIPTION_ID="$2"
      shift 2;;

    --)
      shift
      break;;
    *)
      echo "Invalid option: $1" >&2
      exit 1;;
  esac
done


if [[ -z "${ARM_CLIENT_ID}" || -z "${ARM_CLIENT_SECRET}" || -z "${ARM_TENANT_ID}" || -z "${ARM_SUBSCRIPTION_ID}" ]]; then
  echo "Error running shell script. Following input is required: --client_id <Service Principal Client ID> --client_secret <Service Principal Client Secret> --tenant_id <AAD Tenant ID --subscription_id <Azure Subscription ID>" >&2
  exit 1
fi

FILE_VARIABLES="variables.tf"
FILE_SETTINGS="bootstrap.yaml"
FILE_BACKEND="backend.tf"
FILE_OUTPUTS="outputs.tf"
FILE_PROVIDERS="terraform.tf"
FILE_MAIN="main.tf"

DIRECTORY_BRIDGEHEAD="01_bridgehead"

BASENAME="azure-bridgehead"
RANDOM_LENGTH=5
LOCATION=$(yq '.settings.bridgehead.location' $FILE_SETTINGS)
ACCOUNT_TIER=$(yq '.settings.bridgehead.account_tier' $FILE_SETTINGS)
ACCOUNT_REPLICATION_TYPE=$(yq '.settings.bridgehead.account_replication_type' $FILE_SETTINGS)

###########################################
# Functions
###########################################

function print_empty_lines() {
  for (( i=1; i<=$1; i++ ))
  do
    echo ""
  done
}

function handle_interrupt () {
  print_empty_lines 1
  echo "Finished. Exiting ..."    
  exit 1
}

function handle_error () {
  print_empty_lines 1
  echo "An error occurred. Exiting ..."  
  exit 1
}

trap 'handle_interrupt' INT
trap 'handle_error' ERR

print_empty_lines 1

###########################################
# Verify if Input exists
###########################################

if [ -z "$BASENAME" ]; then
  print_empty_lines 1
  echo "BASENAME not specified."
  exit 1
fi

if [ -z "$RANDOM_LENGTH" ]; then
  print_empty_lines 1
  echo "RANDOM_LENGTH not specified."
  exit 1
fi

if [ -z "$LOCATION" ]; then
  print_empty_lines 1
  echo "LOCATION not specified."
  exit 1
fi

if [ -z "$ACCOUNT_TIER" ]; then
  print_empty_lines 1
  echo "ACCOUNT_TIER not specified."
  exit 1
fi

if [ -z "$ACCOUNT_REPLICATION_TYPE" ]; then
  print_empty_lines 1
  echo "ACCOUNT_REPLICATION_TYPE not specified."
  exit 1
fi

if [ -z "$ARM_CLIENT_ID" ]; then
  print_empty_lines 1
  echo "ARM_CLIENT_ID not specified. Please run the script with option flags: -i <Service Principal Client ID> -s <Service Principal Secret>"
  exit 1
fi

if [ -z "$ARM_CLIENT_SECRET" ]; then
  print_empty_lines 1
  echo "ARM_CLIENT_SECRET not specified. Please run the script with option flags: -i <Service Principal Client ID> -s <Service Principal Secret>"
  exit 1
fi

###########################################
# Bridgehead Directory
###########################################

mkdir -p ./$DIRECTORY_BRIDGEHEAD

###########################################
# Bridgehead Outputs File
###########################################

echo "Creating $FILE_OUTPUTS."
cat <<EOF > $DIRECTORY_BRIDGEHEAD/$FILE_OUTPUTS
output "resource_group_name" {
  value = azurerm_resource_group.bridgehead.name
}

output "storage_account_name" {
  value = azurerm_storage_account.bridgehead.name
}

output "container_name" {
  value = azurerm_storage_container.tfcafes.name
}
EOF

###########################################
# Bridgehead Providers File
###########################################

echo "Creating $FILE_PROVIDERS."
cat <<EOF > $DIRECTORY_BRIDGEHEAD/$FILE_PROVIDERS
terraform {
  required_version = "~> 1.3"
  required_providers {
    azurerm = "~> 3.52" # https://registry.terraform.io/providers/hashicorp/azurerm/latest
    azurecaf = {
      source  = "aztfmod/azurecaf" # https://registry.terraform.io/providers/aztfmod/azurecaf/latest/docs
      version = "~> 1.2"
    }
  }
}

provider "azurerm" {
  features {}
}
EOF

###########################################
# Bridgehead Variables File
###########################################

echo "Creating $FILE_VARIABLES."
cat <<EOF > $DIRECTORY_BRIDGEHEAD/$FILE_VARIABLES
variable "basename" {
  description = "The string for naming all Azure resources."
  type        = string
  default     = "$BASENAME"
}

variable "random_length" {
  description = "A random suffix string added to each resource name."
  type        = number
  default     = $RANDOM_LENGTH
}

variable "location" {
  description = "Defines the region in which the resources will be deployed, e.g. westeurope."
  type        = string
  default     = "$LOCATION"

  validation {
    condition     = can(regex("^((east|west|central|north|south|switzerland)?(us|europe|asia|australia|north))$", var.location))
    error_message = "Invalid Azure region."
  }
}

variable "account_tier" {
  description = "Defines the tier of this storage account. Valid options are Standard and Premium. For BlockBlobStorage and FileStorage accounts only Premium is valid. Changing this forces a new resource to be created."
  type        = string
  default     = "$ACCOUNT_TIER"

  validation {
    condition     = can(regex("^((Standard|Premium))$", var.account_tier))
    error_message = "Invalid Azure storage account tier."
  }
}

variable "account_replication_type" {
  description = "Defines the type of replication to use for this storage account. Valid options are LRS, GRS, RAGRS, ZRS, GZRS and RAGZRS."
  type        = string
  default     = "$ACCOUNT_REPLICATION_TYPE"

  validation {
    condition     = can(regex("^((LRS|GRS|RAGRS|ZRS|GZRS|RAGZRS))$", var.account_replication_type))
    error_message = "Invalid Azure storage account replication type."
  }
}
EOF

###########################################
# Bridgehead Main File
###########################################

echo "Creating $FILE_MAIN."
cat <<EOF > $DIRECTORY_BRIDGEHEAD/$FILE_MAIN
###############################################################
# Local Variables
###############################################################

locals {
  tags = {
    environment = "terraform bridgehead"
    managedby   = "terraform"
  }
}

##################################
# Resource Group for BRIDGEHEAD
##################################

# https://registry.terraform.io/providers/aztfmod/azurecaf/latest
resource "azurecaf_name" "rg" {
  name          = var.basename
  resource_type = "azurerm_resource_group"
  random_length = 0
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group
resource "azurerm_resource_group" "bridgehead" {
  name     = azurecaf_name.rg.result
  location = var.location
  tags     = local.tags
}

##################################
# Storage Account for Terraform State files
##################################

# https://registry.terraform.io/providers/aztfmod/azurecaf/latest
resource "azurecaf_name" "stracc" {
  name          = var.basename
  resource_type = "azurerm_storage_account"
  random_length = var.random_length
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account
resource "azurerm_storage_account" "bridgehead" {
  name                     = azurecaf_name.stracc.result
  resource_group_name      = azurerm_resource_group.bridgehead.name
  location                 = azurerm_resource_group.bridgehead.location
  account_tier             = var.account_tier
  account_replication_type = var.account_replication_type
  tags                     = local.tags
}

##################################
# Blob Container for Bridgehead and Terraform CAF Enterprise Scale (tfcafes) state file
##################################

# https://registry.terraform.io/providers/aztfmod/azurecaf/latest
resource "azurecaf_name" "tfcafes" {
  name          = "terraform-backend-enterprise-scale"
  resource_type = "azurerm_storage_blob"
  random_length = 0
}

# https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_container
resource "azurerm_storage_container" "tfcafes" {
  name                  = azurecaf_name.tfcafes.result
  storage_account_name  = azurerm_storage_account.bridgehead.name
  container_access_type = "private"

  lifecycle { prevent_destroy = true }
}
EOF

###########################################
# Export Bash Environment Variables
###########################################

export ARM_CLIENT_ID=$ARM_CLIENT_ID
export ARM_CLIENT_SECRET=$ARM_CLIENT_SECRET
export ARM_TENANT_ID=$ARM_TENANT_ID
export ARM_SUBSCRIPTION_ID=$ARM_SUBSCRIPTION_ID

###########################################
# Terraform Init
###########################################

print_empty_lines 1
echo "Executing terraform init."
if terraform -chdir=$DIRECTORY_BRIDGEHEAD init
then
  print_empty_lines 1
  echo -e "\e[1;32m"Terraform init executed successfully."\e[0m"
else
  print_empty_lines 1
  echo -e "\e[1;31m"Terraform init failed."\e[0m"
  exit 1
fi

###########################################
# Terraform Validate
###########################################

print_empty_lines 1
echo "Executing terraform validate."
if terraform -chdir=$DIRECTORY_BRIDGEHEAD validate
then
  print_empty_lines 1
  echo -e "\e[1;32m"Terraform validate executed successfully."\e[0m"
else
  print_empty_lines 1
  echo -e "\e[1;31m"Terraform validate failed."\e[0m"
  exit 1
fi

###########################################
# Terraform Apply
###########################################

print_empty_lines 1
echo "Executing terraform apply."
print_empty_lines 1
if terraform -chdir=$DIRECTORY_BRIDGEHEAD apply -auto-approve
then
  print_empty_lines 1
  echo -e "\e[1;32m"Terraform apply executed successfully."\e[0m"
else
  print_empty_lines 1
  echo -e "\e[1;31m"Terraform apply failed."\e[0m"
  exit 1
fi

####################################
# Configure Azure backend
####################################

RESOURCE_GROUP_NAME=$(terraform -chdir=$DIRECTORY_BRIDGEHEAD output resource_group_name)
STORAGE_ACCOUNT_NAME=$(terraform -chdir=$DIRECTORY_BRIDGEHEAD output storage_account_name)
CONTAINER_NAME=$(terraform -chdir=$DIRECTORY_BRIDGEHEAD output container_name)

cat <<EOF > $DIRECTORY_BRIDGEHEAD/$FILE_BACKEND
terraform {
  backend "azurerm" {
    resource_group_name = $RESOURCE_GROUP_NAME
    storage_account_name = $STORAGE_ACCOUNT_NAME
    container_name = $CONTAINER_NAME
    key = "terraform-bridgehead.tfstate"
  }
}
EOF

if terraform -chdir=$DIRECTORY_BRIDGEHEAD init <<EOF
yes
EOF
then
  print_empty_lines 1
  echo -e "\e[1;32m"Bridgehead successfully installed."\e[0m"
else
  echo -e "\e[1;31m"Initializing Azure Backend failed."\e[0m"
  exit 1
fi

####################################
# Some post steps
####################################

print_empty_lines 2
echo "Post Steps: Formatting all Terraform files."
terraform -chdir=$DIRECTORY_BRIDGEHEAD fmt >/dev/null 2>&1

echo "Post Steps: Removing local state file."
print_empty_lines 2
rm -f $DIRECTORY_BRIDGEHEAD/terraform.tfstate* >/dev/null 2>&1