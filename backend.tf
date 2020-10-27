# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

# Create a resource group if it doesn't exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = var.group_name
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

module "apigateway"{
    source = "./apigateway"
}
# Create Network Security Group and rule
resource "azurerm_network_security_group" "backend" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = azurerm_resource_group.myterraformgroup.name

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges     = ["22","80"]
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "backend" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = azurerm_resource_group.myterraformgroup.name

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = var.backend_net.id
        private_ip_address_allocation = "Dynamic"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "backend" {
    network_interface_id      = azurerm_network_interface.backend.id
    network_security_group_id = azurerm_network_security_group.backend.id
}
# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = azurerm_resource_group.myterraformgroup.name
    }

    byte_length = 8
}

resource "azurerm_storage_container" "backend" {
  name                  = "vhds"
  storage_account_name  = azurerm_storage_account.mystorageaccount.name
  container_access_type = "private"
}
# Create storage account for boot diagnostics
resource "azurerm_storage_account" "backend" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = azurerm_resource_group.myterraformgroup.name
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}
# Create (and display) an SSH key
resource "tls_private_key" "example_ssh" {
  algorithm = "RSA"
  rsa_bits = 4096
}
output "tls_private_key" { value = tls_private_key.example_ssh.private_key_pem }
# Create virtual machine
resource "azurerm_virtual_machine" "backend" {
    name                  = "myVM"
    location              = "eastus"
    resource_group_name   = azurerm_resource_group.myterraformgroup.name
    network_interface_ids = [azurerm_network_interface.backend.id]
    vm_size                  = "Standard_DS1_v2"

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "18.04-LTS"
        version   = "latest"
    }
storage_os_disk {
    name          = "myosdisk1"
    vhd_uri       = "${azurerm_storage_account.backend.primary_blob_endpoint}${azurerm_storage_container.example.name}/myosdisk1.vhd"
    caching       = "ReadWrite"
    create_option = "FromImage"
  }

  os_profile {
    computer_name  = "hostname"
    admin_username = "testadmin"
    admin_password = "Password1234!"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

    tags = {
        environment = "Terraform Demo"
    }
}
resource "azurerm_virtual_machine_extension" "backend" {
  name                 = "var.extension_name"
  virtual_machine_id   = azurerm_virtual_machine.backend.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
     "fileUris":["https://testzuowen.blob.core.windows.net/nginx/install_nginx.sh"], "commandToExecute": "sh install_backend.sh" 
    }
SETTINGS


  tags = {
    environment = "Production"
  }
}