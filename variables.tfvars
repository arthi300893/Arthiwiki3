location="eastus"
resource_group_name="ArthiTestVM"
owner_tag="Arthi"
env_tag="TEST"
// VM Details
vm_name="ArthiWiki"
vnet_cidr="192.168.0.0/24"
subnet_cidr="192.168.0.0/28"
vmadmin_username="vmadmin"
vm_size="Standard_F2"
vm_source_image_offer="UbuntuServer"
vm_sku="16.04-LTS"
// Storage Account
storage_account_name="mmdevteststorageaccount"
account_tier="Standard"
account_replication_type="GRS"
// keyvault
key_vault_name="MM-Staging-Key-vault"
//recovery service vault
recovery_vault_name="mmstagingvmbkpvault"