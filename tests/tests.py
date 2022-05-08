import unittest
import requests
import os
import json
import datetime


class TestHelmIntegration(unittest.TestCase):
    api_token_logs = os.environ["TEST_LOGS_API_TOKEN"]
    api_token_metrics = os.environ["TEST_METRICS_API_TOKEN"]
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
            valid_count = 50
            self.assertTrue(log_count > 1, f"Should have at least one log!")

    def test_integration_metrics(self):
        end_datetime = datetime.datetime.now().replace(microsecond=0, second=0, minute=0)
        end = int(end_datetime.timestamp())
        start_datetime = (end_datetime - datetime.timedelta(minutes=15)).replace(microsecond=0, second=0, minute=0).timestamp()
        start = int(start_datetime)
        for query in self.metrics_queries:
            api_url = f'https://api.logz.io/v1/metrics/prometheus/api/v1/query_range?query=kube_node_info{query}&start={start}&end={end}&step=15'
            headers = {
                'X-API-TOKEN': self.api_token_metrics,
                'Content-Type': 'application/json'
            }
            response = requests.get(url=api_url, headers=headers)
            response_body = json.loads(response.text)
            self.assertTrue(response_body['status'] == 'success', f"Status should be success")
            metrics_count = len(response_body['data']['result'])
            self.assertTrue(metrics_count > 1, f"Should have at least one metric!")


if __name__ == '__main__':
    TestHelmIntegration.logs_queries = [
        "kubernetes.host:aks-taintnp*",  # Verify nodepool with taints
        "kubernetes.host:akswinnp*",  # Verify windows nodepool
        "kubernetes.host:aks-default-*"  # Regular node
    ]

    TestHelmIntegration.metrics_queries = [
        "kube_node_info%7Bp8s_logzio_name%3D%22integration-tf-helm-test%22%2C+node%3D%7E%22aks-default-.%2B%22%7D",
        "kube_node_info%7Bp8s_logzio_name%3D%22integration-tf-helm-test%22%2C+node%3D%7E%22aks-taintnp-.%2B%22%7D",
        "kube_node_info%7Bp8s_logzio_name%3D%22integration-tf-helm-test%22%2C+node%3D%7E%22akswinnp.%2B%22%7D"
    ]

unittest.main()