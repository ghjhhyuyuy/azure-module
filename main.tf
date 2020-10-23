
# Configure the Microsoft Azure Provider
provider "azurerm" {
    # The "feature" block is required for AzureRM provider 2.x. 
    # If you're using version 1.x, the "features" block is not allowed.
    version = "~>2.0"
    features {}
}

module "example" {
  source = "./modules/example"
}
resource "azurerm_virtual_machine_extension" "example" {
  name                 = "var.extension_name"
  virtual_machine_id   = module.example.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
     "fileUris":["https://testzuowen.blob.core.windows.net/nginx/install_nginx.sh"], "commandToExecute": "sh install_nginx.sh" 
    }
SETTINGS


  tags = {
    environment = "Production"
  }
}