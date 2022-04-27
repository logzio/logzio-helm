import unittest
import requests
import os
import json


class TestHelmLogsIntegration(unittest.TestCase):
    api_token = os.environ["TEST_LOGS_API_TOKEN"]
    query = None
    def test_integration(self):
        api_url = 'https://api.logz.io/v1/search'
        api_token = self.api_token
        headers = {
            'X-API-TOKEN': api_token,
            'Content-Type': 'application/json'
        }
        api_query = {
            "query": {
                "bool": {
                    "must": [{
                        "query_string": {
                            "query": self.query
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
        print(f'api_token: {api_token}')
        print(f'Query: {query}')
        print(response.request.body)
        valid_count = 50
        self.assertTrue(log_count > 1, f"Should have at least one log!")


if __name__ == '__main__':
    queries = [
        "kubernetes.host:aks-taintnp*", # Verify nodepool with taints
        "kubernetes.host:akswinnp*", # Verify windows nodepool
        "kubernetes.host:aks-default-*" # Regular node
    ]

    for host_query in queries:
        TestHelmLogsIntegration.query = host_query
unittest.main()