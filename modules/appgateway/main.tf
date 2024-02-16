



resource "azurerm_public_ip" "pip" {
  for_each = {
    for item in local.public_frontend_pip_final_list : item.tfkey => item
  }
  name     = each.value.fullname
  location = each.value.location

  resource_group_name = each.value.rgfullname

  ## Default value to "Standard" SKU because "Basic" is not compatible with Application Gateway v2
  sku = each.value.sku

  ## Default value to "Static" as it is not possible to switch to "Dynamic" if the SKU is "Standard"
  allocation_method = each.value.ip_allocation_method

  domain_name_label = each.value.domain_name_label

  ddos_protection_mode    = each.value.ddos_protection_mode
  ddos_protection_plan_id = each.value.ddos_protection_plan_id
  zones                   = each.value.zones

  tags = each.value.tags
}

resource "azurerm_application_gateway" "appgw" {
  for_each = {
    # for rootitem in local.appgw_final_list : rootitem.root_tfkey => rootitem  #anand
    for rootitem in local.appgw_stage02_list : rootitem.root_tfkey => rootitem 

  }

  name                = each.value.fullname
  resource_group_name = each.value.rgfullname
  location            = each.value.location
  tags                = try(each.value.tags, null)


  zones        = each.value.zones
  enable_http2 = each.value.enable_http2

  sku {
    capacity = each.value.autoscale_configuration == null ? each.value.sku_capacity : null
    name     = each.value.sku
    tier     = each.value.sku
  }

  dynamic "autoscale_configuration" {
    for_each = each.value.autoscale_configuration != null ? ["Enabled"] : []
    content {
      min_capacity = each.value.autoscale_configuration.min_capacity
      max_capacity = each.value.autoscale_configuration.max_capacity

    }
  }

  dynamic "backend_address_pool" {
    for_each = local.appgw_backendpools_final_map[each.key].backendpools #each.value.backendpools
    iterator = bpool
    content {
      name         = bpool.value.fullname
      fqdns        = bpool.value.fqdns
      ip_addresses = bpool.value.ip_addresses
    }
  }
  frontend_ip_configuration {
    name = each.value.public_frontend_ip_configuration.fullname
    #public_ip_address_id = each.value.public_frontend_ip_configuration.public_ip_address_id
    public_ip_address_id = each.value.public_frontend_ip_configuration == null ? null : azurerm_public_ip.pip[each.key].id
  }
  dynamic "frontend_ip_configuration" {
    for_each = each.value.private_frontend_ip_configuration != null ? ["enabled"] : []
    #iterator = iter
    content {
      name                          = each.value.private_frontend_ip_configuration.fullname
      private_ip_address_allocation = each.value.private_frontend_ip_configuration.private_ip_address != null ? "Static" : null
      private_ip_address            = each.value.private_frontend_ip_configuration.private_ip_address
      subnet_id                     = each.value.private_frontend_ip_configuration.snet_id #format("%s%s%s", iter.vnet_rgname, iter.vnet_name, iter.snet_name)
    }
  }

  dynamic "frontend_port" {
    # 
    for_each = local.appgw_frontendports_final_map[each.key].ports #each.value.http_listeners #TOFIX
    iterator = iter
    content {
      name = format("port_%s", iter.value)
      port = tonumber(iter.value)
    }
  }
  dynamic "http_listener" {
    for_each = local.appgw_http_listeners_final_map[each.key].http_listeners #each.value.http_listeners
    iterator = iter
    content {
      name                           = iter.value.fullname #join("-", ["lstnr", iter.value.name])
      frontend_ip_configuration_name = each.value.private_frontend_ip_configuration != null ? each.value.private_frontend_ip_configuration.fullname : each.value.public_frontend_ip_configuration.fullname
      frontend_port_name             = format("port_%s", iter.value.frontend_port)
      host_name                      = iter.value.host_name
      host_names                     = iter.value.host_names
      protocol                       = iter.value.protocol
      require_sni                    = iter.value.require_sni
      ssl_certificate_name           = iter.value.ssl_certificate_name
      ssl_profile_name               = iter.value.ssl_profile_name
      firewall_policy_id             = iter.value.firewall_policy_id
      dynamic "custom_error_configuration" {
        for_each = iter.value.custom_error_configuration
        iterator = err_conf
        content {
          status_code           = err_conf.value.status_code
          custom_error_page_url = err_conf.value.custom_error_page_url
        }
      }
    }
  }

  dynamic "redirect_configuration" {
    for_each = [
      for v in local.appgw_rules_final_map[each.key].rules : v if v.redirect_configuration != null #each.value.request_routing_rules
    ]
    iterator = config
    content {
      include_path         = config.value.redirect_configuration.include_path
      include_query_string = config.value.redirect_configuration.include_query_string
      name                 = config.value.fullname
      redirect_type        = config.value.redirect_configuration.redirect_type            #optional(string) #Permanenet Temporary Found See other
      target_url           = config.value.redirect_configuration.target_url               #optional(string) #(Optional) The URL to redirect the request to. Cannot be set if target_listener_name is set.
      target_listener_name = config.value.redirect_configuration.target_listener_fullname #(Optional) The name of the listener to redirect to. Cannot be set if target_url is set.
    }
  }

  dynamic "request_routing_rule" {
    for_each = local.appgw_rules_final_map[each.key].rules #each.value.request_routing_rules
    iterator = routing
    content {
      name      = routing.value.fullname
      rule_type = routing.value.rule_type

      http_listener_name         = routing.value.http_listener_fullname
      backend_address_pool_name  = routing.value.backend_address_pool_fullname
      backend_http_settings_name = routing.value.backend_http_settings_fullname
      url_path_map_name          = routing.value.url_path_map_name
      # redirect_configuration_name = routing.value.redirect_configuration_name
      redirect_configuration_name = routing.value.redirect_configuration == null ? null : routing.value.fullname
      rewrite_rule_set_name       = routing.value.rewrite_rule_set_name
      priority                    = coalesce(routing.value.priority, routing.key + 1)
    }
  }


  dynamic "probe" {
    for_each = local.appgw_probes_final_map[each.key].probes #each.value.request_routing_rules
    #iterator = probe
    content {
      name     = probe.value.fullname
      host     = probe.value.host
      port     = probe.value.port
      interval = probe.value.interval

      path     = probe.value.path
      protocol = probe.value.protocol
      timeout  = probe.value.timeout

      pick_host_name_from_backend_http_settings = probe.value.pick_host_name_from_backend_http_settings
      unhealthy_threshold                       = probe.value.unhealthy_threshold
      minimum_servers                           = probe.value.minimum_servers
      dynamic "match" {
        for_each = probe.value.match != null ? ["Deploy"] : []
        content {
          body        = probe.value.match.body
          status_code = probe.value.match.status_code
        }
      }

    }
  }

  gateway_ip_configuration {
    name      = "appGatewayIpConfig"
    subnet_id = each.value.private_frontend_ip_configuration == null ? null : each.value.private_frontend_ip_configuration.snet_id #format("%s%s%s", each.value.private_frontend_ip_configurations[0].vnet_rgname, each.value.private_frontend_ip_configurations[0].vnet_name, each.value.private_frontend_ip_configurations[0].snet_name)
  }

  dynamic "waf_configuration" {
    for_each = each.value.sku == "WAF_v2" && each.value.waf_configuration != null ? [each.value.waf_configuration] : []
    content {
      enabled                  = waf_configuration.value.enabled
      file_upload_limit_mb     = waf_configuration.value.file_upload_limit_mb
      firewall_mode            = waf_configuration.value.firewall_mode
      max_request_body_size_kb = waf_configuration.value.max_request_body_size_kb
      request_body_check       = waf_configuration.value.request_body_check
      rule_set_type            = waf_configuration.value.rule_set_type
      rule_set_version         = waf_configuration.value.rule_set_version

      # dynamic "disabled_rule_group" {
      #   for_each = local.disabled_rule_group_settings != null ? local.disabled_rule_group_settings : []
      #   content {
      #     rule_group_name = disabled_rule_group.value.rule_group_name
      #     rules           = disabled_rule_group.value.rules
      #   }
      # }

      dynamic "exclusion" {
        for_each = waf_configuration.value.exclusion != null ? waf_configuration.value.exclusion : []
        content {
          match_variable          = exclusion.value.match_variable
          selector                = exclusion.value.selector
          selector_match_operator = exclusion.value.selector_match_operator
        }
      }
    }
  }


  dynamic "backend_http_settings" {
    for_each = local.appgw_backend_http_settings_final_map[each.key].backend_http_settings #each.value.backend_http_settings
    iterator = iter
    content {
      name     = iter.value.fullname
      port     = iter.value.port
      protocol = iter.value.protocol

      path       = iter.value.path
      probe_name = iter.value.probe_fullname

      cookie_based_affinity               = iter.value.cookie_based_affinity_enabled ? "Enabled" : "Disabled"
      affinity_cookie_name                = iter.value.affinity_cookie_name
      request_timeout                     = iter.value.request_timeout
      host_name                           = iter.value.host_name
      pick_host_name_from_backend_address = iter.value.pick_host_name_from_backend_address
      trusted_root_certificate_names      = iter.value.trusted_root_certificate_names

      # dynamic "authentication_certificate" {
      # }

      dynamic "connection_draining" {
        for_each = iter.value.connection_draining_timeout_sec != null ? ["enabled"] : []
        content {
          enabled           = true
          drain_timeout_sec = iter.value.connection_draining_timeout_sec
        }
      }
    }
  }

 
}


# resource "azurerm_tplpropertymap_resource" "tplsubresource" {
#   for_each = {
#     for item in local.tplproperty_list : item.tfkey => item
#   }
#   name               = each.value.name
#   tplproperty1       = each.value.tplsubpropertymap
#   tplsubpropertymap2 = each.value.tplsubpropertymap2

#   depends_on = [
#     azurerm_application_gateway.appgw
#   ]
# }

#############################
# diagnostic settings
resource "azurerm_monitor_diagnostic_setting" "main" {
  for_each = {
    for item in local.diagnosticsettings_final_list : item.tfkey => item
  }
  name               = each.value.name
  target_resource_id = azurerm_application_gateway.appgw[each.value.root_tfkey].id

  storage_account_id             = each.value.storage_account_id
  log_analytics_workspace_id     = each.value.log_analytics_workspace_id
  log_analytics_destination_type = each.value.log_analytics_destination_type
  #   eventhub_authorization_rule_id = <not yet supported>
  #   eventhub_name                  = <not yet supported>

  dynamic "enabled_log" {
    for_each = each.value.log_categories
    content {
      category = enabled_log.value
    }
  }

  dynamic "metric" {
    for_each = each.value.metric_categories
    content {
      category = metric.value
      enabled  = true
    }
  }

  lifecycle {
    ignore_changes = [log_analytics_destination_type]
  }
}
#############################
# role assignment
resource "azurerm_role_assignment" "rbacs" {
  for_each = {
    for item in local.rbac_role_assignments_list : item.tfkey => item
  }
  scope                = azurerm_application_gateway.appgw[each.value.root_tfkey].id
  role_definition_name = each.value.role_definition_name
  principal_id         = each.value.principal_id

}