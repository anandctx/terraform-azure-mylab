# data "azapi_resource_action" "ds" {
#   type                   = "Microsoft.Resources/resourceGroups@2022-09-01"
#   resource_id            = "/subscriptions/6e54aa79-9b0b-40ed-ae27-91fdffa0a565/resourceGroups/ibo-rg"
#   action                 = "resources"
#   method                 = "GET"
#   response_export_values = ["*"]
# }