resource "elasticsearch_opensearch_destination" "cloud_platform_alerts" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
  "name" : "cloud-platform-alerts",
  "type" : "slack",
  "slack" : {
    "url" : "${jsondecode(data.aws_secretsmanager_secret_version.slack_webhook_url.secret_string)["url"]}"
  }
}
EOF
}

resource "elasticsearch_opensearch_monitor" "duplicate_grafana_uid_monitor" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
   "name": "Grafana duplcate UID",
   "type": "monitor",
   "enabled": false,
   "schedule": {
      "period": {
         "interval": 1,
         "unit": "MINUTES"
      }
   },
   "inputs": [
      {
         "search": {
            "indices": [
               "live_kubernetes_cluster*"
            ],
            "query": {
               "size": 0,
               "aggregations": {},
               "query": {
                  "bool": {
                     "must": [],
                     "filter": [
                     {
                        "bool": {
                           "filter": [
                           {
                              "multi_match": {
                                 "type": "phrase",
                                 "query": "the same UID is used more than once",
                                 "lenient": true
                              }
                           },
                           {
                              "bool": {
                                 "should": [
                                 {
                                    "match": {
                                       "kubernetes.container_name": "grafana"
                                    }
                                 }
                                 ],
                                 "minimum_should_match": 1
                              }
                           }
                           ]
                        }
                     },
                     {
                        "range": {
                           "@timestamp": {
                              "boost": 1,
                              "from": "{{period_end}}||-10m",
                              "to": "{{period_end}}",
                              "include_lower": true,
                              "include_upper": true,
                              "format": "epoch_millis"
                           }
                        }
                     }
                     ],
                     "should": [],
                     "must_not": []
                  }
               }
            }
         }
      }
   ],
   "triggers": [
      {
         "name": "Duplicate Grafana dashboard UIDs detected",
         "severity": "5",
         "condition": {
            "script": {
               "source": "ctx.results[0].hits.total.value > 1",
               "lang": "painless"
            }
         },
         "actions": [
            {
               "name": "Notify Cloud Platform lower-priority-alarms Slack Channel",
               "destination_id": "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
               "throttle_enabled": true,
               "throttle": {
                  "value": 60,
                  "unit": "MINUTES"
               },
               "message_template": {
                  "source": "Monitor {{ctx.monitor.name}} just entered alert status. Please investigate the issue.\n- Trigger: {{ctx.trigger.name}}\n- Severity: {{ctx.trigger.severity}}\n- Period start: {{ctx.periodStart}}\n- Period end: {{ctx.periodEnd}}\n- Runbook: https://runbooks.cloud-platform.service.justice.gov.uk/grafana-dashboards.html#dashboard-layout",
                  "lang": "mustache"
               },
               "subject_template": {
                  "source": "*Duplicate Grafana dashboard UID's found*",
                  "lang": "mustache"
               }
            }
         ]
      }
   ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}

resource "elasticsearch_opensearch_monitor" "psa_violations" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
   "name": "PodSecurity Violations",
   "type": "monitor",
   "enabled": false,
   "schedule": {
      "period": {
         "interval": 1,
         "unit": "MINUTES"
      }
   },
   "inputs": [
      {
         "search": {
            "indices": [
               "live_kubernetes_cluster*"
            ],
            "query": {
               "size": 0,
               "aggregations": {},
               "query": {
                  "bool": {
                     "adjust_pure_negative": true,
                     "boost": 1,
                     "filter": [
                        {
                           "range": {
                              "@timestamp": {
                                 "boost": 1,
                                 "from": "{{period_end}}||-10m",
                                 "to": "{{period_end}}",
                                 "include_lower": true,
                                 "include_upper": true,
                                 "format": "epoch_millis"
                              }
                           }
                        },
                        {
                            "multi_match": {
                              "type": "phrase",
                              "query": "violates PodSecurity",
                              "lenient": true
                            }
                          },
                          {
                            "bool": {
                              "filter": [
                                {
                                  "bool": {
                                    "must_not": {
                                      "multi_match": {
                                        "type": "phrase",
                                        "query": "smoketest-restricted",
                                        "lenient": true
                                      }
                                    }
                                  }
                                },
                                {
                                  "bool": {
                                    "must_not": {
                                      "multi_match": {
                                        "type": "phrase",
                                        "query": "smoketest-privileged",
                                        "lenient": true
                                      }
                                    }
                                  }
                                }
                              ]
                            }
                          }
                     ]
                  }
               }
            }
         }
      }
   ],
   "triggers": [
      {
         "name": "PodSecurity Violations",
         "severity": "5",
         "condition": {
            "script": {
               "source": "ctx.results[0].hits.total.value > 1",
               "lang": "painless"
            }
         },
         "actions": [
            {
               "name": "Notify Cloud Platform lower-priority-alarms Slack Channel",
               "destination_id": "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
               "throttle_enabled": true,
               "throttle": {
                  "value": 1440,
                  "unit": "MINUTES"
               },
               "message_template": {
                  "source": "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3h,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'%22violates%20PodSecurity%22%20AND%20NOT%20%22smoketest-restricted%22%20AND%20NOT%20%22smoketest-privileged%22'),sort:!())|this link> to check recent PodSecurity violation logs or search \"violates PodSecurity\" and investigate the affected namespaces. Contact the user to rectify.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk//kibana-podsecurity-violations-alert.html|Kibana PodSecurity Violations Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting#/monitors/jR-J3YsBP8PE0GofcRIF|PodSecurity Violations Monitor> on Kibana.",
                  "lang": "mustache"
               },
               "subject_template": {
                  "source": "*One or more namespaces have PodSecurity Violations*",
                  "lang": "mustache"
               }
            }
         ]
      }
   ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}

resource "elasticsearch_opensearch_monitor" "grafana_dashboard_fail" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
   "name": "Failed to load Grafana dashboard",
   "type": "monitor",
   "enabled": false,
   "schedule": {
      "period": {
         "interval": 1,
         "unit": "MINUTES"
      }
   },
   "inputs": [
      {
         "search": {
            "indices": [
               "live_kubernetes_cluster*"
            ],
            "query": {
               "size": 0,
               "aggregations": {},
               "query": {
                  "bool": {
                     "must": [],
                     "filter": [
                     {
                        "bool": {
                           "filter": [
                              {
                                 "bool": {
                                    "should": [
                                    {
                                       "multi_match": {
                                          "type": "phrase",
                                          "query": "failed to load dashboard",
                                          "lenient": true
                                       }
                                    },
                                    {
                                       "multi_match": {
                                          "type": "phrase",
                                          "query": "failed to save dashboard",
                                          "lenient": true
                                       }
                                    }
                                    ],
                                    "minimum_should_match": 1
                                 }
                              },
                              {
                                 "bool": {
                                    "should": [
                                    {
                                       "match": {
                                          "kubernetes.container_name": "grafana"
                                       }
                                    }
                                    ],
                                    "minimum_should_match": 1
                                 }
                              }
                           ]
                        }
                     },
                     {
                        "range": {
                           "@timestamp": {
                              "boost": 1,
                              "from": "{{period_end}}||-65m",
                              "to": "{{period_end}}",
                              "include_lower": true,
                              "include_upper": true,
                              "format": "epoch_millis"
                           }
                        }
                     }
                     ],
                     "should": [],
                     "must_not": []
                  }
               }
            }
         }
      }
   ],
   "triggers": [
      {
         "name": "Failed to load Grafana dashboard",
         "severity": "5",
         "condition": {
            "script": {
               "source": "ctx.results[0].hits.total.value > 1",
               "lang": "painless"
            }
         },
         "actions": [
            {
               "name": "Notify Cloud Platform lower-priority-alarms Slack Channel",
               "destination_id": "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
               "throttle_enabled": true,
               "throttle": {
                  "value": 360,
                  "unit": "MINUTES"
               },
               "message_template": {
                  "source": "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-3h,to:now))&_a=(columns:!(log),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'%22failed%20to%20load%20dashboard%22%20AND%20kubernetes.container_name:%20grafana'),sort:!())|this link> to see the offending logs on Kibana or refer to the troubleshooting section of the <https://runbooks.cloud-platform.service.justice.gov.uk/grafana-dashboards.html#troubleshooting|Grafana dashboards runbook> to help diagnose the issue. Contact the user to rectify.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting#/monitors/PvbYY4wBWxCz7Bq1729W|Failed to load Grafana dashboard monitor> on Kibana.",
                  "lang": "mustache"
               },
               "subject_template": {
                  "source": "*Grafana failed to load one or more dashboards* - This could prevent new dashboards from being created :sign-warning:",
                  "lang": "mustache"
               }
            }
         ]
      }
   ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}

resource "elasticsearch_opensearch_monitor" "external_dns_throttling" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
   "name": "Throttling Errors in External DNS",
   "type": "monitor",
   "enabled": false,
   "schedule": {
      "period": {
         "interval": 1,
         "unit": "MINUTES"
      }
   },
   "inputs": [
      {
         "search": {
            "indices": [
               "live_kubernetes_cluster*"
            ],
          "query": {
             "size": 0,
             "aggregations": {},
            "query": {
              "bool": {
                "must": [],
                "filter": [
                  {
                    "bool": {
                      "filter": [
                        {
                          "bool": {
                            "should": [
                              {
                                "match_phrase": {
                                  "kubernetes.namespace_name": "kube-system"
                                }
                              }
                            ],
                            "minimum_should_match": 1
                          }
                        },
                        {
                          "bool": {
                            "filter": [
                              {
                                "bool": {
                                  "should": [
                                    {
                                      "match_phrase": {
                                        "kubernetes.pod_name": "external-dns-*"
                                      }
                                    }
                                  ],
                                  "minimum_should_match": 1
                                }
                              },
                              {
                                "bool": {
                                  "filter": [
                                    {
                                      "bool": {
                                        "should": [
                                          {
                                            "match_phrase": {
                                              "log": "level=error"
                                            }
                                          }
                                        ],
                                        "minimum_should_match": 1
                                      }
                                    },
                                    {
                                      "bool": {
                                        "should": [
                                          {
                                            "match_phrase": {
                                              "log": "Throttling: Rate exceeded"
                                            }
                                          }
                                        ],
                                        "minimum_should_match": 1
                                      }
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  {
                    "range": {
                      "@timestamp": {
                         "boost": 1,
                         "from": "{{period_end}}||-1m",
                         "to": "{{period_end}}",
                         "include_lower": true,
                         "include_upper": true,
                         "format": "epoch_millis"
                      }
                    }
                  }
                ],
                "should": [],
                "must_not": []
              }
            }
         }
        }
      }
   ],
   "triggers": [
      {
         "name": "Throttling Errors in External DNS",
         "severity": "5",
         "condition": {
            "script": {
               "source": "ctx.results[0].hits.total.value > 2",
               "lang": "painless"
            }
         },
         "actions": [
            {
               "name": "Notify Cloud Platform lower-priority-alarms Slack Channel",
               "destination_id": "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
               "throttle_enabled": true,
               "throttle": {
                  "value": 1440,
                  "unit": "MINUTES"
               },
               "message_template": {
                  "source": "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30m,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'kubernetes.namespace_name:%20%22kube-system%22%20AND%20kubernetes.pod_name:%20%22external-dns-*%22%20AND%20log:%20%22level%3Derror%22%20AND%20log:%20%22Throttling:%20Rate%20exceeded%22'),sort:!())|this link> to check recent Throttling Errors in External DNS.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk/external-dns-error.html#invalid-change-batch|External DNS Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting|Throttling External DNS Errors Monitor> on Kibana.",
                  "lang": "mustache"
               },
               "subject_template": {
                  "source": "*Throttling Errors in External DNS*",
                  "lang": "mustache"
               }
            }
         ]
      }
   ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}

resource "elasticsearch_opensearch_monitor" "external_dns_invalid_batch_change" {
  provider = elasticsearch.app_logs
  body     = <<EOF
{
   "name": "Invalid Change Batch Errors in External DNS",
   "type": "monitor",
   "enabled": false,
   "schedule": {
      "period": {
         "interval": 1,
         "unit": "MINUTES"
      }
   },
   "inputs": [
      {
         "search": {
            "indices": [
               "live_kubernetes_cluster*"
            ],
            "query": {
               "size": 0,
               "aggregations": {},
            "query": {
              "bool": {
                "must": [],
                "filter": [
                  {
                    "bool": {
                      "filter": [
                        {
                          "bool": {
                            "should": [
                              {
                                "match_phrase": {
                                  "kubernetes.namespace_name": "kube-system"
                                }
                              }
                            ],
                            "minimum_should_match": 1
                          }
                        },
                        {
                          "bool": {
                            "filter": [
                              {
                                "bool": {
                                  "should": [
                                    {
                                      "match_phrase": {
                                        "kubernetes.pod_name": "external-dns-*"
                                      }
                                    }
                                  ],
                                  "minimum_should_match": 1
                                }
                              },
                              {
                                "bool": {
                                  "filter": [
                                    {
                                      "bool": {
                                        "should": [
                                          {
                                            "match_phrase": {
                                              "log": "level=error"
                                            }
                                          }
                                        ],
                                        "minimum_should_match": 1
                                      }
                                    },
                                    {
                                      "bool": {
                                        "should": [
                                          {
                                            "match_phrase": {
                                              "log": "InvalidChangeBatch"
                                            }
                                          }
                                        ],
                                        "minimum_should_match": 1
                                      }
                                    }
                                  ]
                                }
                              }
                            ]
                          }
                        }
                      ]
                    }
                  },
                  {
                    "range": {
                      "@timestamp": {
                         "boost": 1,
                         "from": "{{period_end}}||-10m",
                         "to": "{{period_end}}",
                         "include_lower": true,
                         "include_upper": true,
                         "format": "epoch_millis"
                      }
                    }
                  }
                ],
                "should": [],
                "must_not": []
              }
            }
         }
        }
      }
   ],
   "triggers": [
      {
         "name": "Invalid Change Batch Errors in External DNS",
         "severity": "5",
         "condition": {
            "script": {
               "source": "ctx.results[0].hits.total.value > 1",
               "lang": "painless"
            }
         },
         "actions": [
            {
               "name": "Notify Cloud Platform lower-priority-alarms Slack Channel",
               "destination_id": "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
               "throttle_enabled": true,
               "throttle": {
                  "value": 1440,
                  "unit": "MINUTES"
               },
               "message_template": {
                  "source": "Follow <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/discover#/?_g=(filters:!(),refreshInterval:(pause:!t,value:0),time:(from:now-30m,to:now))&_a=(columns:!(_source),filters:!(),index:'167701b0-f8c0-11ec-b95c-1d65c3682287',interval:auto,query:(language:kuery,query:'kubernetes.namespace_name:%20%22kube-system%22%20AND%20kubernetes.pod_name:%20%22external-dns-*%22%20AND%20log:%20%22level%3Derror%22%20AND%20log:%20%22InvalidChangeBatch%22'),sort:!())|this link> to check recent Invalid Change Batch Errors in External DNS.\n\nFurther guidance can be found on the <https://runbooks.cloud-platform.service.justice.gov.uk/external-dns-error.html#invalid-change-batch|External DNS Alert runbook>.\n\nThis has been triggered by the <https://kibana.cloud-platform.service.justice.gov.uk/_plugin/kibana/app/opendistro-alerting|Invalid Change Batch External DNS Errors Monitor> on Kibana.\n\n ```{{ctx.results[0].log}}```",
                  "lang": "mustache"
               },
               "subject_template": {
                  "source": "*Invalid Change Batch Errors in External DNS*",
                  "lang": "mustache"
               }
            }
         ]
      }
   ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}
