{
    "policy": {
        "description": "legal-hold-retain: defers deletion of indices already in cold storage. Not auto-attached; applied manually with change_policy (?type=_cold). See scripts/opensearch/README.md",
        "default_state": "cold",
        "states": [
            {
                "name": "cold",
                "actions": [],
                "transitions": [
                    {
                        "state_name": "delete",
                        "conditions": {
                            "min_index_age": "${delete_transition}"
                        }
                    }
                ]
            },
            {
                "name": "delete",
                "actions": [
                    {
                        "cold_delete": {},
                        "retry": {
                            "count": 3,
                            "delay": "1h",
                            "backoff": "exponential"
                        }
                    }
                ],
                "transitions": []
            }
        ]
    }
}
