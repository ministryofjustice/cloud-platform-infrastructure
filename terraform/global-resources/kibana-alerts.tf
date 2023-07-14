resource "elasticsearch_opensearch_monitor" "duplicate_grafana_uid_in_logs" {
  provider = elasticsearch
  body     = <<EOF
{
  "name": "Grafana UID",
  "type": "monitor",
  "enabled": false,
  "schedule": {
    "period": {
      "interval": 10,
      "unit": "MINUTES"
    }
  },
  "input" : {
    "search" : {
      "request" : {
        "indices" : ["live-kubernetes-*"],
     "body" : {
         "size": 0,
         "query": {
             "bool": {
               "filter": [{
                 "range": {
                   "@timestamp": {
                       "from": "{{period_end}}||-1m",
                       "to": "{{period_end}}",
                       "include_lower": true,
                       "include_upper": true,
                       "format": "epoch_millis",
                       "boost": 1
                     }
                   }
                 },
                 {
                 "match_phrase": {
                     "log": {
                         "query": "\"the same UID is used more than once\"",
                         "slop": 0,
                         "zero_terms_query": "NONE",
                         "boost": 1
                       }
                     }
                   }
                  ],
               "adjust_pure_negative": true,
               "boost": 1
             }
           },
           "aggregations": {}
         }
       }
     }
   },
   "triggers": [
    {
      "name" : "Duplicate Grafana UID in logs",
      "severity" : "5",
      "condition" : {
        "script" : {
          "source" : "ctx.results[0].hits.total.value > 1",
          "lang" : "painless"
        }
      },
      "actions" : [
        {
          "name" : "Notify Cloud Platform lower-priority-alarms Slack Channel",
          "destination_id" : "${elasticsearch_opensearch_destination.cloud_platform_alerts.id}",
          "throttle_enabled" : true,
          "throttle" : {
            "value" : 60,
            "unit" : "MINUTES"
          },
          "message_template" : {
            "source" : "Monitor {{ctx.monitor.name}} just entered alert status. Please investigate the issue.\n- Trigger: {{ctx.trigger.name}}\n- Severity: {{ctx.trigger.severity}}\n- Period start: {{ctx.periodStart}}\n- Period end: {{ctx.periodEnd}}",
            "lang" : "painless"
          },
          "subject_template" : {
            "source" : "duplicate grafana uid's found",
            "lang" : "mustache"
          }
        }
      ]
    }
  ]
}
EOF

  depends_on = [elasticsearch_opensearch_destination.cloud_platform_alerts]

}

resource "elasticsearch_opensearch_destination" "cloud_platform_alerts" {
  provider = elasticsearch
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