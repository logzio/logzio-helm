package tests

import (
	"go.uber.org/zap"
	"strings"
)

const (
	BaseLogzioApiUrl = "https://api.logz.io/v1"
	QueryTemplate    = `{
  "query": {
    "query_string": {
      "query": "{{QUERY}}"
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

func formatQuery(query string) string {
	return strings.Replace(QueryTemplate, "{{QUERY}}", query, 1)
}

var (
	logger, _ = zap.NewProduction()
)
