# Logz.io API Fetcher Helm Chart

This Helm chart deploys the Logz.io API Fetcher to collect data from Auth/OAuth Api's data to Logz.io

## Prerequisites

- Kubernetes cluster
- Helm installed

## Installation

1. Add the Logz.io Helm repository:

  ```bash
  helm repo add logzio https://logzio.github.io/logzio-helm
  ```

2. Update the Helm repositories:

  ```bash
  helm repo update
  ```

3. Install the Logz.io API Fetcher chart with custom values file:

  ```bash
  helm install logzio-api-fetcher -f custom-values.yaml logzio-helm/logzio-api-fetcher
  ```

## Configuration

Edit the configuration in `values.config`. There are 2 sections of the configuration:

#### logzio

| Parameter Name | Description | Required/Optional | Default |
| --- | --- | ---| ---|
| url | The Logz.io Listener URL for your region with port 8071. For example: https://listener.logz.io:8071 | Optional | `https://listener.logz.io:8071` |
| token | Your Logz.io log shipping token securely directs the data to your Logz.io account. | Required | - |

#### apis

<details>
  <summary>
    <span><a href="./src/apis/general/README.md">General API</a></span>
  </summary>

For structuring custom API calls use type `general` API with the parameters below.

## Configuration Options
| Parameter Name     | Description                                                                                                                       | Required/Optional | Default                     |
|--------------------|-----------------------------------------------------------------------------------------------------------------------------------|-------------------|-----------------------------|
| name               | Name of the API (custom name)                                                                                                     | Optional          | the defined `url`           |
| url                | The request URL                                                                                                                   | Required          | -                           |
| headers            | The request Headers                                                                                                               | Optional          | `{}`                        |
| body               | The request body                                                                                                                  | Optional          | -                           |
| method             | The request method (`GET` or `POST`)                                                                                              | Optional          | `GET`                       |
| pagination         | Pagination settings if needed (see [options below](#pagination-configuration-options))                                            | Optional          | -                           |
| next_url           | If needed to update the URL in next requests based on the last response. Supports using variables ([see below](#using-variables)) | Optional          | -                           |
| response_data_path | The path to the data inside the response                                                                                          | Optional          | response root               |
| additional_fields  | Additional custom fields to add to the logs before sending to logzio                                                              | Optional          | Add `type` as `api-fetcher` |
| scrape_interval    | Time interval to wait between runs (unit: `minutes`)                                                                              | Optional          | 1 (minute)                  |

## Pagination Configuration Options
If needed, you can configure pagination.

| Parameter Name   | Description                                                                                                                                      | Required/Optional                                  | Default |
|------------------|--------------------------------------------------------------------------------------------------------------------------------------------------|----------------------------------------------------|---------|
| type             | The pagination type (`url`, `body` or `headers`)                                                                                                 | Required                                           | -       |
| url_format       | If pagination type is `url`, configure the URL format used for the pagination. Supports using variables ([see below](#using-variables)).         | Required if pagination type is `url`               | -       |
| update_first_url | `True` or `False`; If pagination type is `url`, and it's required to append new params to the first request URL and not reset it completely.     | Optional if pagination type is `url`               | False   |
| headers_format   | If pagination type is `headers`, configure the headers format used for the pagination. Supports using variables ([see below](#using-variables)). | Required if pagination type is `headers`           | -       |
| body_format      | If pagination type is `body`, configure the body format used for the pagination. Supports using variables ([see below](#using-variables)).       | Required if pagination type is `body`              | -       |
| stop_indication  | When should the pagination end based on the response. (see [options below](#pagination-stop-indication-configuration)).                          | Optional (if not defined will stop on `max_calls`) | -       |
| max_calls        | Max calls that the pagination can make. (Supports up to 1000)                                                                                    | Optional                                           | 1000    |

## Pagination Stop Indication Configuration
| Parameter Name | Description                                                                             | Required/Optional                               | Default |
|----------------|-----------------------------------------------------------------------------------------|-------------------------------------------------|---------|
| field          | The name of the field in the response body, to search the stop indication at            | Required                                        | -       |
| condition      | The stop condition (`empty`, `equals` or `contains`)                                    | Required                                        | -       |
| value          | If condition is `equals` or `contains`, the value of the `field` that we should stop at | Required if condition is `equals` or `contains` | -       |

## Using Variables
Using variables allows taking values from the response of the first request, to structure the request after it.  
Mathematical operations `+` and `-` are supported, in order to add or reduce a number from the variable value.  

Use case examples for variable usage:
1. Update a date filter at every call
2. Update a page number in pagination

To use variables:
- Wrap the variable name in curly brackets
- Provide the full path to that variable in the response
- Add `res.` prefix to the path.

Example: Say this is my response:
```json
{
  "field": "value",
  "another_field": {
    "nested": 123
  },
  "num_arr": [1, 2, 3],
  "obj_arr": [
    {
      "field2": 345
    },
    {
      "field2": 567
    }
  ]
}
```
Paths to fields values are structured like so:
- `{res.field}` = `"value"`
- `{res.another_field.nested}` = `123`
- `{res.num_arr.[2]}` = `3`
- `{res.obj_arr.[0].field2}` = `345`

Using the fields values in the `next_url` for example like so:
```Yaml
next_url: https://logz.io/{res.field}/{res.obj_arr[0].field2}
```
Would update the URL at every call to have the value of the given fields from the response, in our example the url for the next call would be:
```
https://logz.io/value/345
```
And in the call after it, it would update again according to the response and the `next_url` structure, and so on.


</details>
<details>
  <summary>
    <span><a href="./src/apis/oauth/README.md">OAuth API</a></span>
  </summary>

For structuring custom OAuth calls use type `oauth` API with the parameters below.

## Configuration Options
| Parameter Name    | Description                                                                                                                           | Required/Optional | Default                     |
|-------------------|---------------------------------------------------------------------------------------------------------------------------------------|-------------------|-----------------------------|
| name              | Name of the API (custom name)                                                                                                         | Optional          | the defined `url`           |
| token_request     | Nest here any detail relevant to the request to get the bearer access token. (Options in [General API](./src/apis/general/README.md)) | Required          | -                           |
| data_request      | Nest here any detail relevant to the data request. (Options in [General API](./src/apis/general/README.md))                           | Required          | -                           |
| scrape_interval   | Time interval to wait between runs (unit: `minutes`)                                                                                  | Optional          | 1 (minute)                  |
| additional_fields | Additional custom fields to add to the logs before sending to logzio                                                                  | Optional          | Add `type` as `api-fetcher` |

</details>
<details>
  <summary>
    <span><a href="./src/apis/azure/README.MD/#azure-graph">Azure Graph</a></span>
  </summary>

For Azure Graph, use type `azure_graph` with the below parameters.

## Configuration Options
| Parameter Name                 | Description                                                          | Required/Optional | Default           |
|--------------------------------|----------------------------------------------------------------------|-------------------|-------------------|
| name                           | Name of the API (custom name)                                        | Optional          | `azure api`       |
| azure_ad_tenant_id             | The Azure AD Tenant id                                               | Required          | -                 |
| azure_ad_client_id             | The Azure AD Client id                                               | Required          | -                 |
| azure_ad_secret_value          | The Azure AD Secret value                                            | Required          | -                 |
| date_filter_key                | The name of key to use for the date filter in the request URL params | Optional          | `createdDateTime` |
| data_request.url               | The request URL                                                      | Required          | -                 |
| data_request.additional_fields | Additional custom fields to add to the logs before sending to logzio | Optional          | -                 |
| days_back_fetch                | The amount of days to fetch back in the first request                | Optional          | 1 (day)           |
| scrape_interval                | Time interval to wait between runs (unit: `minutes`)                 | Optional          | 1 (minute)        |

</details>

<details>
  <summary>
    <span><a href="./src/apis/azure/README.MD/#azure-mail-reports">Azure Mail Reports</a></span>
  </summary>

For Azure Mail Reports, use type `azure_mail_reports` with the below parameters.

## Configuration Options
| Parameter Name                 | Description                                                                 | Required/Optional | Default     |
|--------------------------------|-----------------------------------------------------------------------------|-------------------|-------------|
| name                           | Name of the API (custom name)                                               | Optional          | `azure api` |
| azure_ad_tenant_id             | The Azure AD Tenant id                                                      | Required          | -           |
| azure_ad_client_id             | The Azure AD Client id                                                      | Required          | -           |
| azure_ad_secret_value          | The Azure AD Secret value                                                   | Required          | -           |
| start_date_filter_key          | The name of key to use for the start date filter in the request URL params. | Optional          | `startDate` |
| end_date_filter_key            | The name of key to use for the end date filter in the request URL params.   | Optional          | `EndDate`   |
| data_request.url               | The request URL                                                             | Required          | -           |
| data_request.additional_fields | Additional custom fields to add to the logs before sending to logzio        | Optional          | -           |
| days_back_fetch                | The amount of days to fetch back in the first request                       | Optional          | 1 (day)     |
| scrape_interval                | Time interval to wait between runs (unit: `minutes`)                        | Optional          | 1 (minute)  |


</details>
<details>
  <summary>
    <span><a href="./src/apis/azure/README.MD/#azure-general">Azure General API</a></span>
  </summary>

For structuring custom general Azure API calls use type `azure_general` API with the parameters below.

## Configuration Options
| Parameter Name        | Description                                                                                                 | Required/Optional | Default     |
|-----------------------|-------------------------------------------------------------------------------------------------------------|-------------------|-------------|
| name                  | Name of the API (custom name)                                                                               | Optional          | `azure api` |
| azure_ad_tenant_id    | The Azure AD Tenant id                                                                                      | Required          | -           |
| azure_ad_client_id    | The Azure AD Client id                                                                                      | Required          | -           |
| azure_ad_secret_value | The Azure AD Secret value                                                                                   | Required          | -           |
| data_request          | Nest here any detail relevant to the data request. (Options in [General API](./src/apis/general/README.md)) | Required          | -           |
| days_back_fetch       | The amount of days to fetch back in the first request                                                       | Optional          | 1 (day)     |
| scrape_interval       | Time interval to wait between runs (unit: `minutes`)                                                        | Optional          | 1 (minute)  |

</details>
<details>
  <summary>
    <span><a href="./src/apis/cloudflare/README.md">Cloudflare</a></span>
  </summary>

For Cloudflare API, use type as `cloudflare`.  
By default `cloudflare` API type:

- has built in pagination settings
- sets the `response_data_path` to `result` field.

## Configuration Options
| Parameter Name          | Description                                                                                                                                | Required/Optional | Default           |
|-------------------------|--------------------------------------------------------------------------------------------------------------------------------------------|-------------------|-------------------|
| name                    | Name of the API (custom name)                                                                                                              | Optional          | the defined `url` |
| cloudflare_account_id   | The CloudFlare Account ID                                                                                                                  | Required          | -                 |
| cloudflare_bearer_token | The Cloudflare Bearer token                                                                                                                | Required          | -                 |
| url                     | The request URL                                                                                                                            | Required          | -                 |
| next_url                | If needed to update the URL in next requests based on the last response. Supports using variables (see [General API](./general/README.md)) | Optional          | -                 |
| additional_fields       | Additional custom fields to add to the logs before sending to logzio                                                                       | Optional          | -                 |
| scrape_interval         | Time interval to wait between runs (unit: `minutes`)                                                                                       | Optional          | 1 (minute)        |
| pagination_off          | True if builtin pagination should be off, False otherwise                                                                                  | Optional          | `False`           |

</details>

### Example

#### Auth api config:

```yaml
logzio:
  url: https://listener.logz.io:8071
  token: 123456789a

apis:
  - name: cloudflare test
    type: cloudflare
    cloudflare_account_id: <<CLOUDFLARE_ACCOUNT_ID>>
    cloudflare_bearer_token: <<CLOUDFLARE_BEARER_TOKEN>>
    url: https://api.cloudflare.com/client/v4/accounts/{account_id}/alerting/v3/history
    next_url: https://api.cloudflare.com/client/v4/accounts/{account_id}/alerting/v3/history?since={res.result.[0].sent}
    days_back_fetch: 7
    scrape_interval: 5
    additional_fields:
      type: cloudflare

  - name: azure general example
    type: azure_general
    azure_ad_tenant_id: <<AZURE_AD_TENANT_ID>>
    azure_ad_client_id: <<AZURE_AD_CLIENT_ID>>
    azure_ad_secret_value: <<AZURE_AD_SECRET_VALUE>>
    data_request:
      url: ...
    scrape_interval: 30
    days_back_fetch: 30

  - name: mail reports example
    type: azure_mail_reports
    azure_ad_tenant_id: <<AZURE_AD_TENANT_ID>>
    azure_ad_client_id: <<AZURE_AD_CLIENT_ID>>
    azure_ad_secret_value: <<AZURE_AD_SECRET_VALUE>>
    data_request:
      url: https://login.microsoftonline.com/<<AZURE_AD_TENANT_ID>>/oauth2/v2.0/token
      additional_fields:
        type: azure_mail_reports
    scrape_interval: 60  # for mail reports we suggest no less than 60 minutes
    days_back_fetch: 8  # for mail reports we suggest up to 8 days

```

#### OAuth Api config:

```yaml
logzio:
  url: https://listener.logz.io:8071
  token: 123456789a

oauth_apis:
  - type: azure_graph
    name: azure_test
    credentials:
      id: <<AZURE_AD_SECRET_ID>>
      key: <<AZURE_AD_SECRET_VALUE>>
    token_http_request:
      url: https://login.microsoftonline.com/<<AZURE_AD_TENANT_ID>>/oauth2/v2.0/token
      body: client_id=<<AZURE_AD_CLIENT_ID>>
        &scope=https://graph.microsoft.com/.default
        &client_secret=<<AZURE_AD_SECRET_VALUE>>
        &grant_type=client_credentials
      headers:
      method: POST
    data_http_request:
      url: https://graph.microsoft.com/v1.0/auditLogs/signIns
      method: GET
      headers:
    json_paths:
      data_date: createdDateTime
      next_url:
      data:
    settings:
      time_interval: 1
      days_back_fetch: 30
  - type: general
    name: general_test
    credentials:
      id: aaaa-bbbb-cccc
      key: abcabcabc
    token_http_request:
      url: https://login.microsoftonline.com/abcd-efgh-abcd-efgh/oauth2/v2.0/token
      body: client_id=aaaa-bbbb-cccc
            &scope=https://graph.microsoft.com/.default
            &client_secret=abcabcabc
            &grant_type=client_credentials
      headers:
      method: POST
    data_http_request:
      url: https://graph.microsoft.com/v1.0/auditLogs/directoryAudits
      headers:
    json_paths:
      data_date: activityDateTime
      data: value
      next_url: '@odata.nextLink'
    settings:
      time_interval: 1
    start_date_name: activityDateTime
  - type: azure_mail_reports
    name: mail_reports
    credentials:
      id: <<AZURE_AD_SECRET_ID>>
      key: <<AZURE_AD_SECRET_VALUE>>
    token_http_request:
      url: https://login.microsoftonline.com/abcd-efgh-abcd-efgh/oauth2/v2.0/token
      body: client_id=<<AZURE_AD_CLIENT_ID>>
        &scope=https://outlook.office365.com/.default
        &client_secret=<<AZURE_AD_SECRET_VALUE>>
        &grant_type=client_credentials
      headers:
      method: POST
    data_http_request:
      url: https://reports.office365.com/ecp/reportingwebservice/reporting.svc/MessageTrace
      method: GET
      headers:
    json_paths:
      data_date: EndDate
      next_url:
      data:
    filters:
      format: Json
    settings:
      time_interval: 60 # for mail reports we suggest no less than 60 minutes
      days_back_fetch: 8 # for mail reports we suggest up to 8 days
    start_date_name: StartDate
    end_date_name: EndDate

```

## Changelog:

- **1.0.1**:
  - Update api fetcher version to 0.2.0
- **1.0.0**:
  - Helm chart for deploying the Logz.io API Fetcher.