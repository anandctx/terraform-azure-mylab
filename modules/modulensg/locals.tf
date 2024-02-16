# locals {
#   subnet_list = flatten([
#     for network_name, network in var.networks : [
#       for subnet_name, subnet in network.subnets : merge(subnet, {
#         subnet_name = subnet_name
#         vnet_name   = network_name
#         rules       = subnet.rules
#         # pam_default   = subnet.pam_default
#         pexip = try(subnet.default_rules["pexip"], null)
#         # default_rules = subnet.default_rules
#       })
#     ]
#   ])



# }


locals {
  nsg_rules_map_inbound = flatten([
    for key, value in var.networks : [
      for rule in value.inbound : merge (rule, {
        # for  subvalue in value : {
        # for subkey, subvalue in lookup(value, "inbound", []) : {
        # merge (  for subkey, subvalue value.inbound,   for subkey, subvalue in value.outbound ) : {
        # rules     = subvalue
        nsg_name  = value.nsgname
        rgname    = value.rgname
        direction = "Inbound"
        # direction = value.direction
        # direction = subkey
    })]

  ])
  nsg_rules_map_outbound = flatten([
    for key, value in var.networks : [
      # for subkey, subvalue in concat (value.inbound,value.outbound) : {
      for subvalue in value.outbound : {
        # merge (  for subkey, subvalue value.inbound,   for subkey, subvalue in value.outbound ) : {
        rules     = subvalue
        nsg_name  = value.nsgname
        rgname    = value.rgname
        direction = "Outbound"
    }]

  ])

  # nsg_rules_final_map = {

  #   for nsg_rules in local.nsg_rules_map_inbound : "${nsg_rules.nsg_name}-${nsg_rules.rules.direction}-${nsg_rules.rules.priority}" => nsg_rules
  # }

  nsg_rules_final_map_inbound = {

    for nsg_rules in local.nsg_rules_map_inbound : "${nsg_rules.nsg_name}-${nsg_rules.direction}-${nsg_rules.priority}" => nsg_rules
  }

  nsg_rules_final_map_outbound = {

    for nsg_rules in local.nsg_rules_map_outbound : "${nsg_rules.nsg_name}-${nsg_rules.direction}-${nsg_rules.rules.priority}" => nsg_rules
  }

  nsg_rules_final_map = merge(local.nsg_rules_final_map_inbound, local.nsg_rules_final_map_outbound)
}


# output "nsg_new" {
#   value = {for a,b in local.nsg_rules_map_inbound : a=>b}
# }
