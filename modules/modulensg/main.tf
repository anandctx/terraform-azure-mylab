# resource "azurerm_network_security_group" "example" {
#   for_each = { for k, v in local.subnets_by_vnet : k => v }
#   name     = "nsg-${each.value.subnet_name}"
#   # name = local.abc[each.value.vnet_name].tags!= null?"nsg-${local.abc[each.value.vnet_name].name}":each.value.vnet_name
#   location            = "uksouth"
#   resource_group_name = "ibo-rg"
# }

resource "azurerm_network_security_rule" "example_inbound" {
  # for_each                    = { for k, v in local.nsg_map : k => v }
  # for_each                    = { for k in local.nsg_map : k.nsg_name => k }
  for_each = local.nsg_rules_final_map_inbound
  # name                       = each.value.rules.rule_name

  name                         = "${each.value.access}_Inbound_${each.value.rule_name}"
  priority                     = each.value.priority
  direction                    = "Inbound"
  access                       = each.value.access
  protocol                     = each.value.protocol
  source_port_ranges           = try(each.value.source_port, null)
  source_port_range            = try(each.value.source_port1, null)
  destination_port_ranges      = each.value.destination_port
  source_address_prefixes      = each.value.source_address
  destination_address_prefixes = each.value.destination_address
  resource_group_name          = each.value.rgname
  # network_security_group_name = each.value.rules.network_security_group_name
  # network_security_group_name = each.key
  network_security_group_name = each.value.nsg_name
}

resource "azurerm_network_security_rule" "example_outbound" {
  # for_each                    = { for k, v in local.nsg_map : k => v }
  # for_each                    = { for k in local.nsg_map : k.nsg_name => k }
  for_each = local.nsg_rules_final_map_outbound
  # name                       = each.value.rules.rule_name

  name                         = "${each.value.rules.access}_${each.value.direction}_${each.value.rules.rule_name}"
  priority                     = each.value.rules.priority
  direction                    = each.value.direction
  access                       = each.value.rules.access
  protocol                     = each.value.rules.protocol
  source_port_ranges           = try(each.value.rules.source_port, null)
  source_port_range            = try(each.value.rules.source_port1, null)
  destination_port_ranges      = each.value.rules.destination_port
  source_address_prefixes      = each.value.rules.source_address
  destination_address_prefixes = each.value.rules.destination_address
  resource_group_name          = each.value.rgname
  # network_security_group_name = each.value.rules.network_security_group_name
  # network_security_group_name = each.key
  network_security_group_name = each.value.nsg_name
}



