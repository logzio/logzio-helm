import unittest
import requests
import os
import json


class TestHelmIntegration(unittest.TestCase):
    api_token_logs = os.environ["TEST_LOGS_API_TOKEN"]
    logs_queries = []
    metrics_queries = []
    def test_integration_logs(self):
        for query in self.logs_queries:
            api_url = 'https://api.logz.io/v1/search'
            headers = {
                'X-API-TOKEN': self.api_token_logs,
                'Content-Type': 'application/json'
            }
            api_query = {
                "query": {
                    "bool": {
                        "must": [{
                            "query_string": {
                                "query": query
                            }
                        },
                            {
                                "range": {
                                    "@timestamp": {
                                        "gte": "now-10m",
                                        "lte": "now"
                                    }
                                }
                            }
                        ]
                    }
                },
                "size": 50,
                "from": 0
            }
            response = requests.post(url=api_url, json=api_query, headers=headers)
            log_count = int(json.loads(response.text)['hits']['total'])
            print(response.request.body)
            valid_count = 50
            self.assertTrue(log_count > 1, f"Should have at least one log!")
    


if __name__ == '__main__':
    TestHelmIntegration.logs_queries = [
        "kubernetes.host:aks-taintnp*", # Verify nodepool with taints
        "kubernetes.host:akswinnp*", # Verify windows nodepool
        "kubernetes.host:aks-default-*" # Regular node
    ]

unittest.main()