variable "location" {
  type        = string
  description = "The location(Region) of the resource"
}
variable "landing_zone_environment" {
  description = "The environment of the landing zone. It must be the same as the environment in the sub name"
  type        = string
}

variable "opgroup" {
  type        = string
  description = "The OpGroup name of this resource"
}
variable "opco" {
  type        = string
  description = "The OpCo name of this resource"
}
variable "subscription_id" {
  type        = string
  description = "SubscriptionId where the resource should be deployed"
}

variable "app_gateways" {
  description = "A map of resources to be deployed into the subscription"
  type = map(object({
    basename       = string
    instancenumber = optional(string)
    rgname         = string
    tags           = optional(map(string), {})
    enable_http2   = optional(bool, true)

    sku          = optional(string, "WAF_v2")
    sku_capacity = optional(number, 2) #value must be between 1 and 10, optional if autoscale_configuration is set
    autoscale_configuration = optional(object({
      min_capacity = number
      max_capacity = optional(number, 5)
    }))
    zones = optional(list(number), [1, 2, 3])

    waf_configuration = object({
      enabled                  = optional(bool, true)
      file_upload_limit_mb     = optional(number, 100)
      firewall_mode            = optional(string, "Prevention")
      max_request_body_size_kb = optional(number, 128)
      request_body_check       = optional(bool, true)
      rule_set_type            = optional(string, "OWASP")
      rule_set_version         = optional(string, 3.1)
      disabled_rule_group = optional(list(object({
        rule_group_name = string
        rules           = optional(list(string))
      })), [])
      exclusion = optional(list(object({
        match_variable          = string
        selector                = optional(string)
        selector_match_operator = optional(string)
      })), [])
    })

    public_frontend_ip_configuration = object({
      #fullname = string
      #public_ip_address_id = string
      sku                     = optional(string, "Standard")
      ip_allocation_method    = optional(string, "Static")
      ddos_protection_mode    = optional(string, null)
      ddos_protection_plan_id = optional(string, null)
      domain_name_label       = optional(string)
    })

    private_frontend_ip_configuration = optional(object({
      #fullname           = string
      private_ip_address = string #if this is null it will be dynamically allocated
      vnet_rgname        = string
      vnet_name          = string
      snet_name          = string
    }))

    applications = map(object({
      backendpools = list(object({
        name         = string
        fqdns        = optional(list(string)) # anand
        # fqdns = string #anand
       
        ip_addresses = optional(list(string))
      }))


      backend_http_settings = list(object({
        name       = string
        port       = optional(number, 443)
        protocol   = optional(string, "Https")
        path       = optional(string)
        probe_name = optional(string)

        # cookie_based_affinity           = optional(string, "Disabled")
        cookie_based_affinity_enabled   = optional(bool, false)
        affinity_cookie_name            = optional(string, "ApplicationGatewayAffinity")
        connection_draining_timeout_sec = optional(number)
        request_timeout                 = optional(number, 20)

        host_name                           = optional(string)
        pick_host_name_from_backend_address = optional(bool, false)
        trusted_root_certificate_names      = optional(list(string), [])
        #authentication_certificate          = optional(string)


      }))

      http_listeners = list(object({
        name = string

        #frontend_ip_configuration_name = optional(string)
        #frontend_port_name             = optional(string)
        frontend_port = string
        host_name     = optional(string)
        host_names    = optional(list(string))
        #protocol             = optional(string, "Https")
        protocol             = optional(string, "Http")
        require_sni          = optional(bool, false)
        ssl_certificate_name = optional(string)
        ssl_profile_name     = optional(string)
        firewall_policy_id   = optional(string)

        custom_error_configuration = optional(list(object({
          status_code           = string
          custom_error_page_url = string
        })), [])
      }))

      request_routing_rules = list(object({
        name                       = string
        priority                   = optional(number)
        rule_type                  = optional(string, "Basic")
        http_listener_name         = string
        backend_address_pool_name  = optional(string)
        backend_http_settings_name = optional(string)
        url_path_map_name          = optional(string)
        #redirect_configuration_name = optional(string) #OCR to be removed
        redirect_configuration = optional(object({ #OCR to be implemented
          include_path         = optional(bool, false)
          include_query_string = optional(bool, false)
          #name= rule_name
          redirect_type        = optional(string) #Permanenet Temporary Found See other
          target_url           = optional(string) #(Optional) The URL to redirect the request to. Cannot be set if target_listener_name is set.
          target_listener_name = optional(string) #(Optional) The name of the listener to redirect to. Cannot be set if target_url is set.

        }))
        rewrite_rule_set_name = optional(string)
      }))

      probes = optional(list(object({
        name                                      = string
        pick_host_name_from_backend_http_settings = optional(bool, false)
        host                                      = optional(string)       # (Optional) The Hostname used for this Probe. If the Application Gateway is configured for a single site, by default the Host name should be specified as 127.0.0.1, unless otherwise configured in custom probe. Cannot be set if pick_host_name_from_backend_http_settings is set to true.
        port                                      = optional(number, null) #(Optional) Custom port which will be used for probing the backend servers. The valid value ranges from 1 to 65535. In case not set, port from HTTP settings will be used. This property is valid for Standard_v2 and WAF_v2 only.
        interval                                  = optional(number, 30)
        path                                      = optional(string, "/")
        protocol                                  = optional(string, "Https")
        timeout                                   = optional(number, 30)

        unhealthy_threshold = optional(number, 3)
        minimum_servers     = optional(number, 0)

        match = optional(object({
          body        = optional(string, "")
          status_code = optional(list(string), ["200-399"])
        }), {})
      })), [])

    }))

    diagnosticsettings = optional(map(object({
      storage_account_id             = optional(string)
      log_analytics_workspace_id     = optional(string)
      log_analytics_destination_type = optional(string, "Dedicated") #"AzureDiagnostics" # When set to 'Dedicated' logs sent to a Log Analytics workspace will go into resource specific tables, instead of the legacy AzureDiagnostics table.
      log_categories                 = list(string)
      metric_categories              = optional(list(string), [])
    })))
    rbac_role_assignments = optional(
      list(
        object({
          role_definition_name = string
          #role_definition_id=optional(string) #required for custom roles
          principal_ids = list(string)
          #skip_service_principal_aad_check =optional(bool,false)
        })
      ),
    [])
  }))

  validation {
    condition = length(flatten([for k, v in var.app_gateways : v.basename if can(regex("^[a-z]+$", v.basename)) == false])) == 0
    error_message = "Basename  supports only lower case letters. Values: ${
      join(";", flatten([for k, v in var.app_gateways : v.basename if can(regex("^[a-z]+$", v.basename)) == false]))
    }"
  }
  validation {
    condition = length(
      flatten([for k, v in var.app_gateways : v.instancenumber if can(regex("^[0-9]{2}$", v.instancenumber)) == false])
    ) == 0
    error_message = "Instancenumbers should be made out of a two digit number.. Values: ${
      join(
        ";",
        flatten([for k, v in var.app_gateways : v.instancenumber if can(regex("^[0-9]{2}$", v.instancenumber)) == false])
      )
    }"
  }
  #validate application names
  validation {
    condition = length(
      #start
      flatten([for k, v in var.app_gateways : [
        for appname in keys(v.applications) : [
          appname
        ] if can(regex("^[a-z]+$", appname)) == false
      ]])
      #end
    ) == 0
    error_message = "Application names should be made out lowercase letters only. Values: ${
      join(
        ";",
        #start
        flatten([for k, v in var.app_gateways : [
          for appname in keys(v.applications) : [
            appname
          ] if can(regex("^[a-z]+$", appname)) == false
        ]])
        #end
      )
    }"
  }

  #validate backend pool names
  validation {
    condition = length(
      #start
      flatten([for k, v in var.app_gateways : [
        for appname, appitem in v.applications : [
          for bpoolitem in appitem.backendpools : [
            bpoolitem.name
          ] if can(regex("^[a-z_]+-[0-9]{2}$", bpoolitem.name)) == false
        ]
      ]])
      #end
    ) == 0
    error_message = "Backendpool names should match the following regex '^[a-z_]+-[0-9]{2}$'. Values: ${
      join(
        ";",
        #start
        flatten([for k, v in var.app_gateways : [
          for appname, appitem in v.applications : [
            for bpoolitem in appitem.backendpools : [
              bpoolitem.name
            ] if can(regex("^[a-z_]+-[0-9]{2}$", bpoolitem.name)) == false
          ]
        ]])
        #end
      )
    }"
  }
  #validate backend_http_settings names
  validation {
    condition = length(
      #start
      flatten([for k, v in var.app_gateways : [
        for appname, appitem in v.applications : [
          for item in appitem.backend_http_settings : [
            item.name
          ] if can(regex("^[a-z_]+-[0-9]{2}$", item.name)) == false
        ]
      ]])
      #end
    ) == 0
    error_message = "Backend_Http_settings names should match the following regex '^[a-z_]+-[0-9]{2}$'. Values: ${
      join(
        ";",
        #start
        flatten([for k, v in var.app_gateways : [
          for appname, appitem in v.applications : [
            for item in appitem.backend_http_settings : [
              item.name
            ] if can(regex("^[a-z_]+-[0-9]{2}$", item.name)) == false
          ]
        ]])
        #end
      )
    }"
  }
  #validate http_listeners names
  validation {
    condition = length(
      #start
      flatten([for k, v in var.app_gateways : [
        for appname, appitem in v.applications : [
          for item in appitem.http_listeners : [
            item.name
          ] if can(regex("^[a-z_0-9]+-[0-9]{2}$", item.name)) == false
        ]
      ]])
      #end
    ) == 0
    error_message = "http_listeners names should match the following regex '^[a-z_]+-[0-9]{2}$'. Values: ${
      join(
        ";",
        #start
        flatten([for k, v in var.app_gateways : [
          for appname, appitem in v.applications : [
            for item in appitem.http_listeners : [
              item.name
            ] if can(regex("^[a-z_0-9]+-[0-9]{2}$", item.name)) == false
          ]
        ]])
        #end
      )
    }"
  }
  #validate request_routing_rules names
  validation {
    condition = length(
      #start
      flatten([for k, v in var.app_gateways : [
        for appname, appitem in v.applications : [
          for item in appitem.request_routing_rules : [
            item.name
          ] if can(regex("^[a-z_]+-[0-9]{2}$", item.name)) == false
        ]
      ]])
      #end
    ) == 0
    error_message = "request_routing_rules names should match the following regex '^[a-z_]+-[0-9]{2}$'. Values: ${
      join(
        ";",
        #start
        flatten([for k, v in var.app_gateways : [
          for appname, appitem in v.applications : [
            for item in appitem.request_routing_rules : [
              item.name
            ] if can(regex("^[a-z_]+-[0-9]{2}$", item.name)) == false
          ]
        ]])
        #end
      )
    }"
  }
}





