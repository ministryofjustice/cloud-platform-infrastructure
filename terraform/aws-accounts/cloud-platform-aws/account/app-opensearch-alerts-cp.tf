provider "opensearch" {
  alias               = "app_logs"
  url                 = "https://${aws_opensearch_domain.live_app_logs.endpoint}"
  aws_assume_role_arn = aws_iam_role.os_access_role_app_logs.arn
  aws_profile         = "moj-cp"
  sign_aws_requests   = true
  healthcheck         = false
  sniff               = false
}


#############################################################################################
##      Create a channel configuration to replace elasticsearch_opensearch_destination     ##
#############################################################################################

# add config_id to prevent change in terraform plan

locals {
  cloud_platform_slack_alarm = jsonencode(
    {
      "config_id" : "notify-slack-lower-priority-alarms",
      "config" : {
        "name" : "cloud-platform-alerts",
        "description" : "notify-slack-lower-priority-alarms",
        "config_type" : "slack",
        "is_enabled" : true,
        "slack" : {
          "url" : jsondecode(data.aws_secretsmanager_secret_version.slack_webhook_url.secret_string)["url"]
        }
      }
    }
  )
}

resource "opensearch_channel_configuration" "cloud_platform_slack_alarm" {
  provider = opensearch.app_logs
  body     = local.cloud_platform_slack_alarm
}

#############################################
##      Alert for Grafana duplcate UID     ##
#############################################

## To be enabled

locals {
  duplicate_grafana_uid_monitor = jsonencode(
    {
      "owner" : "alerting",                   # to prevent change in terraform plan
      "monitor_type" : "query_level_monitor", # to prevent change in terraform plan
      "data_sources" : {                      # to prevent change in terraform plan
        "alerts_history_index" : ".opendistro-alerting-alert-history-write",
        "alerts_history_index_pattern" : "<.opendistro-alerting-alert-history-{now/d}-1>",
        "alerts_index" : ".opendistro-alerting-alerts",
        "findings_enabled" : false,
        "findings_index" : ".opensearch-alerting-finding-history-write",
        "findings_index_pattern" : "<.opensearch-alerting-finding-history-{now/d}-1>",
        "query_index" : ".opensearch-alerting-queries",
        "query_index_mappings_by_type" : {}
      },
      "name" : "Grafana duplcate UID",
      "type" : "monitor",
      "monitor_type" : "query_level_monitor",
      "enabled" : false, ## To be enabled
      "schedule" : {
        "period" : {
          "interval" : 1,
          "unit" : "MINUTES"
        }
      },
      "inputs" : [
        {
          "search" : {
            "indices" : [
              "live_kubernetes_cluster*"
            ],
            "query" : {
              "size" : 0,
              "query" : {
                "bool" : {
                  "filter" : [
                    {
                      "bool" : {
                        "filter" : [
                          {
                            "multi_match" : {
                              "query" : "the same UID is used more than once",
                              "fields" : [],
                              "type" : "phrase",
                              "operator" : "OR",
                              "slop" : 0,
                              "prefix_length" : 0,
                              "max_expansions" : 50,
                              "lenient" : true,
                              "zero_terms_query" : "NONE",
                              "auto_generate_synonyms_phrase_query" : true,
                              "fuzzy_transpositions" : true,
                              "boost" : 1
                            }
                          },
                          {
                            "bool" : {
                              "should" : [
                                {
                                  "match" : {
                                    "kubernetes.container_name" : {
                                      "query" : "grafana",
                                      "operator" : "OR",
                                      "prefix_length" : 0,
                                      "max_expansions" : 50,
                                      "fuzzy_transpositions" : true,
                                      "lenient" : false,
                                      "zero_terms_query" : "NONE",
                                      "auto_generate_synonyms_phrase_query" : true,
                                      "boost" : 1
                                    }
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "minimum_should_match" : "1",
                              "boost" : 1
                            }
                          }
                        ],
                        "adjust_pure_negative" : true,
                        "boost" : 1
                      }
                    },
                    {
                      "range" : {
                        "@timestamp" : {
                          "from" : "{{period_end}}||-10m",
                          "to" : "{{period_end}}",
                          "include_lower" : true,
                          "include_upper" : true,
                          "format" : "epoch_millis",
                          "boost" : 1
                        }
                      }
                    }
                  ],
                  "adjust_pure_negative" : true,
                  "boost" : 1
                }
              }
            }
          }
        }
      ],
      "triggers" : [
        {
          "query_level_trigger" : {
            "id" : "duplicate-grafana-dashboard-UIDs", # to prevent change in terraform plan
            "name" : "Duplicate Grafana dashboard UIDs detected",
            "severity" : "1",
            "condition" : {
              "script" : {
                "source" : "ctx.results[0].hits.total.value > 1",
                "lang" : "painless"
              }
            },
            "actions" : [
              {
                "id" : "duplicate-grafana-dashboard-UIDs", # to prevent change in terraform plan
                "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
                "destination_id" : opensearch_channel_configuration.cloud_platform_slack_alarm.id,
                "message_template" : {
                  "source" : "Monitor {{ctx.monitor.name}} just entered alert status. Please investigate the issue.\n- Trigger: {{ctx.trigger.name}}\n- Severity: {{ctx.trigger.severity}}\n- Period start: {{ctx.periodStart}}\n- Period end: {{ctx.periodEnd}}\n- Runbook: https://runbooks.cloud-platform.service.justice.gov.uk/grafana-dashboards.html#dashboard-layout",
                  "lang" : "mustache"
                },
                "throttle_enabled" : true,
                "subject_template" : {
                  "source" : "*Duplicate Grafana dashboard UID's found*",
                  "lang" : "mustache"
                },
                "throttle" : {
                  "value" : 60,
                  "unit" : "MINUTES"
                }
              }
            ]
          }
        }
      ]
    }
  )
}

resource "opensearch_monitor" "duplicate_grafana_uid_monitor" {
  provider   = opensearch.app_logs
  body       = local.duplicate_grafana_uid_monitor
  depends_on = [opensearch_channel_configuration.cloud_platform_slack_alarm]
}

#############################################
##      Alert for PodSecurity Violations   ##
#############################################

## To be enabled

locals {
  psa_violations = jsonencode(
    {
      "owner" : "alerting",                   # to prevent change in terraform plan
      "monitor_type" : "query_level_monitor", # to prevent change in terraform plan
      "data_sources" : {                      # to prevent change in terraform plan
        "alerts_history_index" : ".opendistro-alerting-alert-history-write",
        "alerts_history_index_pattern" : "<.opendistro-alerting-alert-history-{now/d}-1>",
        "alerts_index" : ".opendistro-alerting-alerts",
        "findings_enabled" : false,
        "findings_index" : ".opensearch-alerting-finding-history-write",
        "findings_index_pattern" : "<.opensearch-alerting-finding-history-{now/d}-1>",
        "query_index" : ".opensearch-alerting-queries",
        "query_index_mappings_by_type" : {}
      },
      "name" : "PodSecurity Violations",
      "type" : "monitor",
      "enabled" : false, ## To be enabled
      "schedule" : {
        "period" : {
          "interval" : 1,
          "unit" : "MINUTES"
        }
      },
      "inputs" : [
        {
          "search" : {
            "indices" : [
              "live_kubernetes_cluster*"
            ],
            "query" : {
              "size" : 0,
              "query" : {
                "bool" : {
                  "filter" : [
                    {
                      "range" : {
                        "@timestamp" : {
                          "from" : "{{period_end}}||-10m",
                          "to" : "{{period_end}}",
                          "include_lower" : true,
                          "include_upper" : true,
                          "format" : "epoch_millis",
                          "boost" : 1
                        }
                      }
                    },
                    {
                      "multi_match" : {
                        "query" : "violates PodSecurity",
                        "fields" : [],
                        "type" : "phrase",
                        "operator" : "OR",
                        "slop" : 0,
                        "prefix_length" : 0,
                        "max_expansions" : 50,
                        "lenient" : true,
                        "zero_terms_query" : "NONE",
                        "auto_generate_synonyms_phrase_query" : true,
                        "fuzzy_transpositions" : true,
                        "boost" : 1
                      }
                    },
                    {
                      "bool" : {
                        "filter" : [
                          {
                            "bool" : {
                              "must_not" : [
                                {
                                  "multi_match" : {
                                    "query" : "smoketest-restricted",
                                    "fields" : [],
                                    "type" : "phrase",
                                    "operator" : "OR",
                                    "slop" : 0,
                                    "prefix_length" : 0,
                                    "max_expansions" : 50,
                                    "lenient" : true,
                                    "zero_terms_query" : "NONE",
                                    "auto_generate_synonyms_phrase_query" : true,
                                    "fuzzy_transpositions" : true,
                                    "boost" : 1
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "boost" : 1
                            }
                          },
                          {
                            "bool" : {
                              "must_not" : [
                                {
                                  "multi_match" : {
                                    "query" : "smoketest-privileged",
                                    "fields" : [],
                                    "type" : "phrase",
                                    "operator" : "OR",
                                    "slop" : 0,
                                    "prefix_length" : 0,
                                    "max_expansions" : 50,
                                    "lenient" : true,
                                    "zero_terms_query" : "NONE",
                                    "auto_generate_synonyms_phrase_query" : true,
                                    "fuzzy_transpositions" : true,
                                    "boost" : 1
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "boost" : 1
                            }
                          }
                        ],
                        "adjust_pure_negative" : true,
                        "boost" : 1
                      }
                    }
                  ],
                  "adjust_pure_negative" : true,
                  "boost" : 1
                }
              }
            }
          }
        }
      ],
      "triggers" : [
        {
          "query_level_trigger" : {
            "id" : "pod-security-violations", # to prevent change in terraform plan
            "name" : "PodSecurity Violations",
            "severity" : "1",
            "condition" : {
              "script" : {
                "source" : "ctx.results[0].hits.total.value > 1",
                "lang" : "painless"
              }
            },
            "actions" : [
              {
                "id" : "pod-security-violations", # to prevent change in terraform plan
                "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
                "destination_id" : opensearch_channel_configuration.cloud_platform_slack_alarm.id,
                "message_template" : {
                  "source" : "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3h,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'%22violates%20PodSecurity%22%20AND%20NOT%20%22smoketest-restricted%22%20AND%20NOT%20%22smoketest-privileged%22'),sort:!())|this link> to check recent PodSecurity violation logs or search \"violates PodSecurity\" and investigate the affected namespaces. Contact the user to rectify.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk//kibana-podsecurity-violations-alert.html|Kibana PodSecurity Violations Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting#/monitors/jR-J3YsBP8PE0GofcRIF|PodSecurity Violations Monitor> on Kibana.",
                  "lang" : "mustache"
                },
                "throttle_enabled" : true,
                "subject_template" : {
                  "source" : "*One or more namespaces have PodSecurity Violations*",
                  "lang" : "mustache"
                },
                "throttle" : {
                  "value" : 1440,
                  "unit" : "MINUTES"
                }
              }
            ]
          }
        }
      ]
    }
  )
}

resource "opensearch_monitor" "psa_violations" {
  provider   = opensearch.app_logs
  body       = local.psa_violations
  depends_on = [opensearch_channel_configuration.cloud_platform_slack_alarm]
}

###################################################
##  Alert for Failed to load Grafana dashboard   ##
###################################################

## To be enabled

locals {
  grafana_dashboard_fail = jsonencode(
    {
      "owner" : "alerting",                   # to prevent change in terraform plan
      "monitor_type" : "query_level_monitor", # to prevent change in terraform plan
      "data_sources" : {                      # to prevent change in terraform plan
        "alerts_history_index" : ".opendistro-alerting-alert-history-write",
        "alerts_history_index_pattern" : "<.opendistro-alerting-alert-history-{now/d}-1>",
        "alerts_index" : ".opendistro-alerting-alerts",
        "findings_enabled" : false, ## To be enabled
        "findings_index" : ".opensearch-alerting-finding-history-write",
        "findings_index_pattern" : "<.opensearch-alerting-finding-history-{now/d}-1>",
        "query_index" : ".opensearch-alerting-queries",
        "query_index_mappings_by_type" : {}
      },
      "name" : "Failed to load Grafana dashboard",
      "type" : "monitor",
      "monitor_type" : "query_level_monitor",
      "enabled" : false,
      "schedule" : {
        "period" : {
          "interval" : 1,
          "unit" : "MINUTES"
        }
      },
      "inputs" : [
        {
          "search" : {
            "indices" : [
              "live_kubernetes_cluster*"
            ],
            "query" : {
              "size" : 0,
              "query" : {
                "bool" : {
                  "filter" : [
                    {
                      "bool" : {
                        "filter" : [
                          {
                            "bool" : {
                              "should" : [
                                {
                                  "multi_match" : {
                                    "query" : "failed to load dashboard",
                                    "fields" : [],
                                    "type" : "phrase",
                                    "operator" : "OR",
                                    "slop" : 0,
                                    "prefix_length" : 0,
                                    "max_expansions" : 50,
                                    "lenient" : true,
                                    "zero_terms_query" : "NONE",
                                    "auto_generate_synonyms_phrase_query" : true,
                                    "fuzzy_transpositions" : true,
                                    "boost" : 1
                                  }
                                },
                                {
                                  "multi_match" : {
                                    "query" : "failed to save dashboard",
                                    "fields" : [],
                                    "type" : "phrase",
                                    "operator" : "OR",
                                    "slop" : 0,
                                    "prefix_length" : 0,
                                    "max_expansions" : 50,
                                    "lenient" : true,
                                    "zero_terms_query" : "NONE",
                                    "auto_generate_synonyms_phrase_query" : true,
                                    "fuzzy_transpositions" : true,
                                    "boost" : 1
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "minimum_should_match" : "1",
                              "boost" : 1
                            }
                          },
                          {
                            "bool" : {
                              "should" : [
                                {
                                  "match" : {
                                    "kubernetes.container_name" : {
                                      "query" : "grafana",
                                      "operator" : "OR",
                                      "prefix_length" : 0,
                                      "max_expansions" : 50,
                                      "fuzzy_transpositions" : true,
                                      "lenient" : false,
                                      "zero_terms_query" : "NONE",
                                      "auto_generate_synonyms_phrase_query" : true,
                                      "boost" : 1
                                    }
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "minimum_should_match" : "1",
                              "boost" : 1
                            }
                          }
                        ],
                        "adjust_pure_negative" : true,
                        "boost" : 1
                      }
                    },
                    {
                      "range" : {
                        "@timestamp" : {
                          "from" : "{{period_end}}||-65m",
                          "to" : "{{period_end}}",
                          "include_lower" : true,
                          "include_upper" : true,
                          "format" : "epoch_millis",
                          "boost" : 1
                        }
                      }
                    }
                  ],
                  "adjust_pure_negative" : true,
                  "boost" : 1
                }
              }
            }
          }
        }
      ],
      "triggers" : [
        {
          "query_level_trigger" : {
            "id" : "grafana-dashboard-fail", # to prevent change in terraform plan
            "name" : "Failed to load Grafana dashboard",
            "severity" : "5",
            "condition" : {
              "script" : {
                "source" : "ctx.results[0].hits.total.value > 1",
                "lang" : "painless"
              }
            },
            "actions" : [
              {
                "id" : "grafana-dashboard-fail", # to prevent change in terraform plan
                "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
                "destination_id" : opensearch_channel_configuration.cloud_platform_slack_alarm.id,
                "message_template" : {
                  "source" : "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3h,to:now))&_a=(columns:!(log),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'%22failed%20to%20load%20dashboard%22%20OR%20%22failed%20to%20save%20dashboard%22%20AND%20kubernetes.container_name:%20grafana'),sort:!())|this link> to see the offending logs on Kibana or refer to the troubleshooting section of the <https://runbooks.cloud-platform.service.justice.gov.uk/grafana-dashboards.html#troubleshooting|Grafana dashboards runbook> to help diagnose the issue. Contact the user to rectify.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting#/monitors/PvbYY4wBWxCz7Bq1729W|Failed to load Grafana dashboard monitor> on Kibana.",
                  "lang" : "mustache"
                },
                "throttle_enabled" : true,
                "subject_template" : {
                  "source" : "*Grafana failed to load one or more dashboards* - This could prevent new dashboards from being created :sign-warning:",
                  "lang" : "mustache"
                },
                "throttle" : {
                  "value" : 360,
                  "unit" : "MINUTES"
                }
              }
            ]
          }
        }
      ]
    }
  )
}

resource "opensearch_monitor" "grafana_dashboard_fail" {
  provider   = opensearch.app_logs
  body       = local.grafana_dashboard_fail
  depends_on = [opensearch_channel_configuration.cloud_platform_slack_alarm]
}

###################################################
##  Alert for Throttling Errors in External DNS  ##
###################################################

## To be enabled

locals {
  external_dns_throttling = jsonencode(
    {
      "owner" : "alerting",                   # to prevent change in terraform plan
      "monitor_type" : "query_level_monitor", # to prevent change in terraform plan
      "data_sources" : {                      # to prevent change in terraform plan
        "alerts_history_index" : ".opendistro-alerting-alert-history-write",
        "alerts_history_index_pattern" : "<.opendistro-alerting-alert-history-{now/d}-1>",
        "alerts_index" : ".opendistro-alerting-alerts",
        "findings_enabled" : false, ## To be enabled
        "findings_index" : ".opensearch-alerting-finding-history-write",
        "findings_index_pattern" : "<.opensearch-alerting-finding-history-{now/d}-1>",
        "query_index" : ".opensearch-alerting-queries",
        "query_index_mappings_by_type" : {}
      },
      "name" : "Throttling Errors in External DNS",
      "type" : "monitor",
      "monitor_type" : "query_level_monitor",
      "enabled" : false,
      "schedule" : {
        "period" : {
          "interval" : 1,
          "unit" : "MINUTES"
        }
      },
      "inputs" : [
        {
          "search" : {
            "indices" : [
              "live_kubernetes_cluster*"
            ],
            "query" : {
              "size" : 0,
              "query" : {
                "bool" : {
                  "filter" : [
                    {
                      "bool" : {
                        "filter" : [
                          {
                            "bool" : {
                              "should" : [
                                {
                                  "match_phrase" : {
                                    "kubernetes.namespace_name" : {
                                      "query" : "kube-system",
                                      "slop" : 0,
                                      "zero_terms_query" : "NONE",
                                      "boost" : 1
                                    }
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "minimum_should_match" : "1",
                              "boost" : 1
                            }
                          },
                          {
                            "bool" : {
                              "filter" : [
                                {
                                  "bool" : {
                                    "should" : [
                                      {
                                        "match_phrase" : {
                                          "kubernetes.pod_name" : {
                                            "query" : "external-dns-*",
                                            "slop" : 0,
                                            "zero_terms_query" : "NONE",
                                            "boost" : 1
                                          }
                                        }
                                      }
                                    ],
                                    "adjust_pure_negative" : true,
                                    "minimum_should_match" : "1",
                                    "boost" : 1
                                  }
                                },
                                {
                                  "bool" : {
                                    "filter" : [
                                      {
                                        "bool" : {
                                          "should" : [
                                            {
                                              "match_phrase" : {
                                                "log" : {
                                                  "query" : "level=error",
                                                  "slop" : 0,
                                                  "zero_terms_query" : "NONE",
                                                  "boost" : 1
                                                }
                                              }
                                            }
                                          ],
                                          "adjust_pure_negative" : true,
                                          "minimum_should_match" : "1",
                                          "boost" : 1
                                        }
                                      },
                                      {
                                        "bool" : {
                                          "should" : [
                                            {
                                              "match_phrase" : {
                                                "log" : {
                                                  "query" : "Throttling: Rate exceeded",
                                                  "slop" : 0,
                                                  "zero_terms_query" : "NONE",
                                                  "boost" : 1
                                                }
                                              }
                                            }
                                          ],
                                          "adjust_pure_negative" : true,
                                          "minimum_should_match" : "1",
                                          "boost" : 1
                                        }
                                      }
                                    ],
                                    "adjust_pure_negative" : true,
                                    "boost" : 1
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "boost" : 1
                            }
                          }
                        ],
                        "adjust_pure_negative" : true,
                        "boost" : 1
                      }
                    },
                    {
                      "range" : {
                        "@timestamp" : {
                          "from" : "{{period_end}}||-1m",
                          "to" : "{{period_end}}",
                          "include_lower" : true,
                          "include_upper" : true,
                          "format" : "epoch_millis",
                          "boost" : 1
                        }
                      }
                    }
                  ],
                  "adjust_pure_negative" : true,
                  "boost" : 1
                }
              }
            }
          }
        }
      ],
      "triggers" : [
        {
          "query_level_trigger" : {
            "id" : "external-dns-throttling", # to prevent change in terraform plan
            "name" : "Throttling Errors in External DNS",
            "severity" : "5",
            "condition" : {
              "script" : {
                "source" : "ctx.results[0].hits.total.value > 2",
                "lang" : "painless"
              }
            },
            "actions" : [
              {
                "id" : "external-dns-throttling", # to prevent change in terraform plan
                "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
                "destination_id" : opensearch_channel_configuration.cloud_platform_slack_alarm.id,
                "message_template" : {
                  "source" : "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30m,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'kubernetes.namespace_name:%20%22kube-system%22%20AND%20kubernetes.pod_name:%20%22external-dns-*%22%20AND%20log:%20%22level%3Derror%22%20AND%20log:%20%22Throttling:%20Rate%20exceeded%22'),sort:!())|this link> to check recent Throttling Errors in External DNS.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk/external-dns-error.html#invalid-change-batch|External DNS Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting|Throttling External DNS Errors Monitor> on Kibana.",
                  "lang" : "mustache"
                },
                "throttle_enabled" : true,
                "subject_template" : {
                  "source" : "*Throttling Errors in External DNS*",
                  "lang" : "mustache"
                },
                "throttle" : {
                  "value" : 1440,
                  "unit" : "MINUTES"
                }
              }
            ]
          }
        }
      ]
    }
  )
}

resource "opensearch_monitor" "external_dns_throttling" {
  provider   = opensearch.app_logs
  body       = local.external_dns_throttling
  depends_on = [opensearch_channel_configuration.cloud_platform_slack_alarm]
}

#############################################################
##  Alert for Invalid Change Batch Errors in External DNS  ##
#############################################################

## To be enabled

locals {
  external_dns_invalid_batch_change = jsonencode(
    {
      "owner" : "alerting",                   # to prevent change in terraform plan
      "monitor_type" : "query_level_monitor", # to prevent change in terraform plan
      "data_sources" : {                      # to prevent change in terraform plan
        "alerts_history_index" : ".opendistro-alerting-alert-history-write",
        "alerts_history_index_pattern" : "<.opendistro-alerting-alert-history-{now/d}-1>",
        "alerts_index" : ".opendistro-alerting-alerts",
        "findings_enabled" : false, ## To be enabled
        "findings_index" : ".opensearch-alerting-finding-history-write",
        "findings_index_pattern" : "<.opensearch-alerting-finding-history-{now/d}-1>",
        "query_index" : ".opensearch-alerting-queries",
        "query_index_mappings_by_type" : {}
      },
      "name" : "Invalid Change Batch Errors in External DNS",
      "type" : "monitor",
      "monitor_type" : "query_level_monitor",
      "enabled" : false,
      "schedule" : {
        "period" : {
          "interval" : 1,
          "unit" : "MINUTES"
        }
      },
      "inputs" : [
        {
          "search" : {
            "indices" : [
              "live_kubernetes_cluster*"
            ],
            "query" : {
              "size" : 0,
              "query" : {
                "bool" : {
                  "filter" : [
                    {
                      "bool" : {
                        "filter" : [
                          {
                            "bool" : {
                              "should" : [
                                {
                                  "match_phrase" : {
                                    "kubernetes.namespace_name" : {
                                      "query" : "kube-system",
                                      "slop" : 0,
                                      "zero_terms_query" : "NONE",
                                      "boost" : 1
                                    }
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "minimum_should_match" : "1",
                              "boost" : 1
                            }
                          },
                          {
                            "bool" : {
                              "filter" : [
                                {
                                  "bool" : {
                                    "should" : [
                                      {
                                        "match_phrase" : {
                                          "kubernetes.pod_name" : {
                                            "query" : "external-dns-*",
                                            "slop" : 0,
                                            "zero_terms_query" : "NONE",
                                            "boost" : 1
                                          }
                                        }
                                      }
                                    ],
                                    "adjust_pure_negative" : true,
                                    "minimum_should_match" : "1",
                                    "boost" : 1
                                  }
                                },
                                {
                                  "bool" : {
                                    "filter" : [
                                      {
                                        "bool" : {
                                          "should" : [
                                            {
                                              "match_phrase" : {
                                                "log" : {
                                                  "query" : "level=error",
                                                  "slop" : 0,
                                                  "zero_terms_query" : "NONE",
                                                  "boost" : 1
                                                }
                                              }
                                            }
                                          ],
                                          "adjust_pure_negative" : true,
                                          "minimum_should_match" : "1",
                                          "boost" : 1
                                        }
                                      },
                                      {
                                        "bool" : {
                                          "should" : [
                                            {
                                              "match_phrase" : {
                                                "log" : {
                                                  "query" : "InvalidChangeBatch",
                                                  "slop" : 0,
                                                  "zero_terms_query" : "NONE",
                                                  "boost" : 1
                                                }
                                              }
                                            }
                                          ],
                                          "adjust_pure_negative" : true,
                                          "minimum_should_match" : "1",
                                          "boost" : 1
                                        }
                                      }
                                    ],
                                    "adjust_pure_negative" : true,
                                    "boost" : 1
                                  }
                                }
                              ],
                              "adjust_pure_negative" : true,
                              "boost" : 1
                            }
                          }
                        ],
                        "adjust_pure_negative" : true,
                        "boost" : 1
                      }
                    },
                    {
                      "range" : {
                        "@timestamp" : {
                          "from" : "{{period_end}}||-10m",
                          "to" : "{{period_end}}",
                          "include_lower" : true,
                          "include_upper" : true,
                          "format" : "epoch_millis",
                          "boost" : 1
                        }
                      }
                    }
                  ],
                  "adjust_pure_negative" : true,
                  "boost" : 1
                }
              }
            }
          }
        }
      ],
      "triggers" : [
        {
          "query_level_trigger" : {
            "id" : "external-dns-invalid-batch-change", # to prevent change in terraform plan
            "name" : "Invalid Change Batch Errors in External DNS",
            "severity" : "5",
            "condition" : {
              "script" : {
                "source" : "ctx.results[0].hits.total.value > 1",
                "lang" : "painless"
              }
            },
            "actions" : [
              {
                "id" : "external-dns-invalid-batch-change", # to prevent change in terraform plan
                "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
                "destination_id" : opensearch_channel_configuration.cloud_platform_slack_alarm.id,
                "message_template" : {
                  "source" : "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30m,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'kubernetes.namespace_name:%20%22kube-system%22%20AND%20kubernetes.pod_name:%20%22external-dns-*%22%20AND%20log:%20%22level%3Derror%22%20AND%20log:%20%22InvalidChangeBatch%22'),sort:!())|this link> to check recent Invalid Change Batch Errors in External DNS.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk/external-dns-error.html#invalid-change-batch|External DNS Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting|Invalid Change Batch External DNS Errors Monitor> on Kibana.\n\n ```{{ctx.results[0].log}}```",
                  "lang" : "mustache"
                },
                "throttle_enabled" : true,
                "subject_template" : {
                  "source" : "*Invalid Change Batch Errors in External DNS*",
                  "lang" : "mustache"
                },
                "throttle" : {
                  "value" : 1440,
                  "unit" : "MINUTES"
                }
              }
            ]
          }
        }
      ]
    }
  )
}

resource "opensearch_monitor" "external_dns_invalid_batch_change" {
  provider   = opensearch.app_logs
  body       = local.external_dns_invalid_batch_change
  depends_on = [opensearch_channel_configuration.cloud_platform_slack_alarm]
}