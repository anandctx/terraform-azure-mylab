# output "local_appgw_final" {
#   value = local.appgw_final_list
# }
# output "resource_appgw" {
#   value = azurerm_application_gateway.appgw
# }

output "final_map" {
  value = local.appgw_stage02_list
}


output "final_map_2" {
  value = local.appgw_final_list
}

output "backendpool" {
  value = local.appgw_backendpools_final_map
}


output "mapofmap" {
  value = {for rootitem in local.appgw_final_list : rootitem.root_tfkey => rootitem}
}

