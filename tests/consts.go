package tests

const (
	BaseLogzioApiUrl = "https://api.logz.io/v1"
	LogsQuery        = `{
  "query": {
    "query_string": {
      "query": "env_id:multi-env-test AND type:agent-k8s"
    }
  },
  "from": 0,
  "size": 100,
  "sort": [
    {
      "@timestamp": {
        "order": "desc"
      }
    }
  ],
  "_source": true,
  "docvalue_fields": [
    "@timestamp"
  ],
  "version": true,
  "stored_fields": [
    "*"
  ],
  "highlight": {},
  "aggregations": {
    "byType": {
      "terms": {
        "field": "type",
        "size": 5
      }
    }
  }
}`

	TracesQuery = `{
  "query": {
    "query_string": {
      "query": "JaegerTag.env_id:multi-env-test AND type:jaegerSpan"
    }
  },
  "from": 0,
  "size": 100,
  "sort": [
    {
      "@timestamp": {
        "order": "desc"
      }
    }
  ],
  "_source": true,
  "docvalue_fields": [
    "@timestamp"
  ],
  "version": true,
  "stored_fields": [
    "*"
  ],
  "highlight": {},
  "aggregations": {
    "byType": {
      "terms": {
        "field": "type",
        "size": 5
      }
    }
  }
}`
)
