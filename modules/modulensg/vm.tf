# resource "azurerm_windows_virtual_machine" "example" {

#     for_each = local.vm=="abc" ?var.networks:{}
#   name                = "example-machine"
#   resource_group_name = "ibo-rg"
#   location            = "uksouth"
#   size                = "Standard_F2"
#   admin_username      = "adminuser"
#   admin_password      = "P@$$w0rd1234!"
#   network_interface_ids = [
#     "/subscriptions/6e54aa79-9b0b-40ed-ae27-91fdffa0a565/resourceGroups/ibo-rg/providers/Microsoft.Network/networkInterfaces/est"
#   ]

#   os_disk {
#     caching              = "ReadWrite"
#     storage_account_type = "Standard_LRS"
#   }

#   source_image_reference {
#     publisher = "MicrosoftWindowsServer"
#     offer     = "WindowsServer"
#     sku       = "2016-Datacenter"
#     version   = "latest"
#   }
# }