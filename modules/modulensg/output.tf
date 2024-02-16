# # output "nsg_rules" {
# #   value = local.subnets_by_vnet
# # }

# output "data" {
#   value = jsondecode(data.azapi_resource_action.ds.output).value
# }

# locals {
#   ab = jsondecode(data.azapi_resource_action.ds.output).value
# }

# locals {
#   abc = {for item in local.ab:item.name =>item if item.type == "Microsoft.Network/virtualNetworks"}
# }

# output "abc" {
#     value = local.subnets_by_vnet 
# }

# output "combine" {
#     value = local.combine
# }


# # locals {
# #   vm = {for item in local.ab:replace(item.managedBy, "/.*virtualMachines//","") =>item if item.type == "Microsoft.Compute/disks"  }
# # }

# locals {
#   vm = {for item in local.ab:replace(item.name, "/.OsDisk.*/","") =>item if item.type == "Microsoft.Compute/disks" && item.sku["name"] !="abc"  }
# }

# # locals {
# #   vm = {for item in local.ab:item.name =>item if item.type == "Microsoft.Compute/disks"  }
# # }

# # locals {
# #   vm = {for item in local.ab:item.name =>item if lookup(item.tags, "a", "abcd") != "abcd"}
# # }



# # output "vm" {
# #     value = local.vm
# # }

# output "vm" {
#     value = local.vm["test1"]
# }
