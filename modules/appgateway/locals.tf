
locals {
  # This environment short mapping is for future use where we want to use a proper environment name for tags
  environment_short = {
    Development = "d"
    Production  = "p"
    Sandbox     = "x"
    Staging     = "s"
    Test        = "t"
  }
  environment                     = var.landing_zone_environment
  opgroup                         = var.opgroup
  location_short                  = "uks"
  genericprefix                   = format("%s-%s-%s-%s", local.opgroup, var.opco, "uks", local.environment_short[local.environment])
  rgprefix                        = format("%s-%s", "rg", local.genericprefix)
  subscription_id                 = var.subscription_id
  instancenumber_min_digits_count = 2

  appgw_stage01_list = flatten([for rootitem_key, rootitem in var.app_gateways : merge(rootitem, {
    rootitem_key = rootitem_key

    root_tfkey = can(regex("^agw-", rootitem.basename)) ? rootitem.basename : join("-", [rootitem.basename, rootitem.instancenumber])
    fullname   = can(regex("^agw-", rootitem.basename)) ? rootitem.basename : format("%s-%s-%s-%s", "agw", local.genericprefix, rootitem.basename, rootitem.instancenumber)
    rgfullname = can(regex("^rg-", rootitem.rgname)) ? rootitem.rgname : "${local.rgprefix}-${rootitem.rgname}"
    location   = var.location
    #contains the full name of the applicaiton gateway without the resource prefix
    #this is used for the subresource naming
    agwsuffix = join("-", [local.genericprefix, rootitem.basename, rootitem.instancenumber])

    private_frontend_ip_configuration = rootitem.private_frontend_ip_configuration == null ? null : merge(rootitem.private_frontend_ip_configuration, {
      vnet_fullname   = can(regex("^vnet-", rootitem.private_frontend_ip_configuration.vnet_name)) ? rootitem.private_frontend_ip_configuration.vnet_name : format("%s-%s-%s", "vnet", local.genericprefix, rootitem.private_frontend_ip_configuration.vnet_name)
      vnet_rgfullname = can(regex("^rg-", rootitem.private_frontend_ip_configuration.vnet_rgname)) ? rootitem.private_frontend_ip_configuration.vnet_rgname : format("%s-%s", local.rgprefix, rootitem.private_frontend_ip_configuration.vnet_rgname)
      snet_fullname   = can(regex("^snet-", rootitem.private_frontend_ip_configuration.snet_name)) ? rootitem.private_frontend_ip_configuration.snet_name : format("%s-%s-%s", "snet", local.genericprefix, rootitem.private_frontend_ip_configuration.snet_name)
    })
    })
  ])



  appgw_stage02_list = flatten([for rootitem in local.appgw_stage01_list : merge(rootitem, {
    #root_tfkey = rootitem.fullname #this will be the TF index key

    public_frontend_ip_configuration = rootitem.public_frontend_ip_configuration == null ? null : merge(rootitem.public_frontend_ip_configuration, {
      fullname = join("-", ["feip", rootitem.agwsuffix, "ipv4-public"])
    })

    private_frontend_ip_configuration = rootitem.private_frontend_ip_configuration == null ? null : merge(rootitem.private_frontend_ip_configuration, {
      fullname = join("-", ["feip", rootitem.agwsuffix, "ipv4-private"])
      snet_id  = format("/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/virtualNetworks/%s/subnets/%s", local.subscription_id, rootitem.private_frontend_ip_configuration.vnet_rgfullname, rootitem.private_frontend_ip_configuration.vnet_fullname, rootitem.private_frontend_ip_configuration.snet_fullname)
    })
    })
  ])
  appgw_final_list = flatten([for rootitem in local.appgw_stage02_list : merge(rootitem, {
    #add new  properties here
    applications = { for itemkey, item in rootitem.applications : itemkey => merge(item, {
      prefix = {
        listener              = join("-", ["lstnr", local.genericprefix, itemkey])
        rule                  = join("-", ["rule", local.genericprefix, itemkey])
        backendpool           = join("-", ["bep", local.genericprefix, itemkey])
        probe                 = join("-", ["hp", local.genericprefix, itemkey])
        backend_http_settings = join("-", ["bckhttp", local.genericprefix, itemkey])
      }
      })

    }
    })
  ])

  #locals for creating public ip resources
  public_frontend_pip_final_list = flatten([
    for rootitem in local.appgw_final_list : merge(rootitem.public_frontend_ip_configuration, {
      root_tfkey = rootitem.root_tfkey
      tfkey      = rootitem.root_tfkey
      fullname   = join("-", ["pip", rootitem.agwsuffix]) #replace(rootitem.agwsuffix, "/^agw-/", "pip-")
      location   = rootitem.location
      tags       = rootitem.tags
      rgfullname = rootitem.rgfullname
      zones      = rootitem.zones
      }
    ) if lookup(rootitem, "public_frontend_ip_configuration", null) != null #specify this "if" condition if variable is not mandatory or can be empty
  ])


  appgw_backendpools_final_map = {
    for rootitem in local.appgw_final_list : rootitem.root_tfkey => {
      backendpools = flatten([
        for appname, appitem in rootitem.applications : [
          for item in appitem.backendpools : merge(item, {
            fullname = join("-", [appitem.prefix.backendpool, item.name])
            }
          )
        ]
      ])
    }
  }
  appgw_backend_http_settings_final_map = {
    for rootitem in local.appgw_final_list : rootitem.root_tfkey => {
      backend_http_settings = flatten([
        for appname, appitem in rootitem.applications : [
          for item in appitem.backend_http_settings : merge(item, {
            fullname       = join("-", [appitem.prefix.backend_http_settings, item.name])
            probe_fullname = item.probe_name == null ? null : join("-", [appitem.prefix.probe, item.probe_name])
            }
          )
        ]
      ])
    }
  }
  appgw_http_listeners_final_map = {
    for rootitem in local.appgw_final_list : rootitem.root_tfkey => {
      http_listeners = flatten([
        for appname, appitem in rootitem.applications : [
          for item in appitem.http_listeners : merge(item, {
            fullname = join("-", [appitem.prefix.listener, item.name])
            }
          )
        ]
      ])
    }
  }


  appgw_rules_final_map = {
    for rootitem in local.appgw_final_list : rootitem.root_tfkey => {
      rules = flatten([
        for appname, appitem in rootitem.applications : [
          for item in appitem.request_routing_rules : merge(item, {
            fullname                       = join("-", [appitem.prefix.rule, item.name])
            http_listener_fullname         = join("-", [appitem.prefix.listener, item.http_listener_name])
            backend_address_pool_fullname  = item.backend_address_pool_name == null ? null : join("-", [appitem.prefix.backendpool, item.backend_address_pool_name])
            backend_http_settings_fullname = item.backend_http_settings_name == null ? null : join("-", [appitem.prefix.backend_http_settings, item.backend_http_settings_name])
            ##add listenerfullname to redirect_configuration param 
            redirect_configuration = item.redirect_configuration == null ? null : merge(item.redirect_configuration, {
              target_listener_fullname = item.redirect_configuration.target_listener_name == null ? null : join("-", [appitem.prefix.listener, item.redirect_configuration.target_listener_name])
            })
            }
          )
        ]
      ])
    }
  }

  appgw_frontendports_final_map = {
    for itemkey, item in local.appgw_http_listeners_final_map : itemkey => {
      ports = distinct(flatten([
        for listener in item.http_listeners : [
          listener.frontend_port
        ]
      ]))

    }

  }


  appgw_probes_final_map = {
    for rootitem in local.appgw_final_list : rootitem.root_tfkey => {
      probes = flatten([
        for appname, appitem in rootitem.applications : [
          for item in appitem.probes : merge(item, {
            fullname = join("-", [appitem.prefix.probe, item.name])
            }
          )
        ]
      ])
    }
  }
  #diagnostic settings
  diagnosticsettings_stage01_list = flatten([
    for rootitem in local.appgw_final_list : [
      for itemkey, item in rootitem.diagnosticsettings : merge(item, {
        root_tfkey                     = rootitem.root_tfkey
        name                           = itemkey
        tfkey                          = format("%s_%s", rootitem.root_tfkey, itemkey)
        log_analytics_destination_type = item.log_analytics_workspace_id == null ? null : item.log_analytics_destination_type
        }
      ) if item.storage_account_id != null || item.log_analytics_workspace_id != null
    ] if rootitem.diagnosticsettings != null
  ])
  diagnosticsettings_final_list = local.diagnosticsettings_stage01_list



  #role assignment
  rbac_role_assignments_list = distinct(flatten([
    for rootitem in local.appgw_final_list : [
      for item in rootitem.rbac_role_assignments : [
        for principal_id in item.principal_ids : {
          tfkey                = format("%s_%s_%s", rootitem.root_tfkey, item.role_definition_name, principal_id)
          root_tfkey           = rootitem.root_tfkey
          role_definition_name = item.role_definition_name
          principal_id         = principal_id
        }
      ]
    ]
    ]
  ))
}