resource "azurerm_virtual_network" "example" {
  name                = "example-network"
  location            = "uksouth"
  resource_group_name = "ibo-rg"
  address_space       = ["10.0.0.0/16"]


  subnet {
    name           = "subnet1"
    address_prefix = "10.0.1.0/24"
  }


 
}