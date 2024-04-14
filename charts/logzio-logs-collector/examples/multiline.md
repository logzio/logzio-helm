Customizing Multiline Log Handling 
==================================

Handling multiline logs efficiently in the OpenTelemetry Collector deployed through `logzio-logs-collector` Helm chart requires understanding of the `filelog` receiver, particularly the `recombine` operator. This operator is crucial for parsing and recombining logs that span multiple lines into a single entry, such as stack traces or multiline application logs.

Key Configuration Options of the `recombine` Operator
-----------------------------------------------------

To tailor the `filelog` receiver for multiline logs, focus on these essential `recombine` operator configurations:

* **`combine_field`**: Specifies which field of the log entry should be combined into a single entry. Typically, this is the message body of the log (`body` or `body.message`).
    
* **`is_first_entry`** and **`is_last_entry`**: Logical expressions that evaluate to `true` if the log entry being processed is the beginning or the end of a multiline series, respectively. You need to specify at least one of these based on whether you can reliably identify the start or the end of a multiline log entry.
    
* **`combine_with`**: Defines the delimiter used to concatenate the log entries. For most logs, `"\n"` (newline) is a suitable delimiter, preserving the original log's structure.
    
* **`source_identifier`**: Helps differentiate between log sources when combining entries, ensuring logs from different sources are not mistakenly merged.
    

Creating Custom Formats for Multiline Logs
------------------------------------------

To configure custom formats, you must understand your logs' structure to accurately use `is_first_entry` or `is_last_entry` expressions. Regular expressions (regex) are powerful tools in matching specific log patterns, allowing you to identify the start or end of a multiline log entry effectively.

Custom multiline `recombine` operators should be added before `move from attributes.log to body`:
```yaml
  # Update body field after finishing all parsing
  - from: attributes.log
    to: body
    type: move
```
Here is an example `custom-values.yaml` that shows how where to add custom multiline `recombine` operators:
```yaml
secrets:
  enabled: true
  logzioLogsToken: "<<logzio-token>>"

config:
  receivers:
    filelog:
      operators:
      - id: get-format
        routes:
        - expr: body matches "^\\{"
          output: parser-docker
        - expr: body matches "^[^ Z]+ "
          output: parser-crio
        - expr: body matches "^[^ Z]+Z"
          output: parser-containerd
        type: router
      - id: parser-crio
        regex: ^(?P<time>[^ Z]+) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$
        timestamp:
          layout: 2006-01-02T15:04:05.999999999Z07:00
          layout_type: gotime
          parse_from: attributes.time
        type: regex_parser
      - combine_field: attributes.log
        combine_with: ""
        id: crio-recombine
        is_last_entry: attributes.logtag == 'F'
        max_log_size: 102400
        output: extract_metadata_from_filepath
        source_identifier: attributes["log.file.path"]
        type: recombine
      - id: parser-containerd
        regex: ^(?P<time>[^ ^Z]+Z) (?P<stream>stdout|stderr) (?P<logtag>[^ ]*) ?(?P<log>.*)$
        timestamp:
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
          parse_from: attributes.time
        type: regex_parser
      - combine_field: attributes.log
        combine_with: ""
        id: containerd-recombine
        is_last_entry: attributes.logtag == 'F'
        max_log_size: 102400
        output: extract_metadata_from_filepath
        source_identifier: attributes["log.file.path"]
        type: recombine
      - id: parser-docker
        output: extract_metadata_from_filepath
        timestamp:
          layout: '%Y-%m-%dT%H:%M:%S.%LZ'
          parse_from: attributes.time
        type: json_parser
      - id: extract_metadata_from_filepath
        parse_from: attributes["log.file.path"]
        regex: ^.*\/(?P<namespace>[^_]+)_(?P<pod_name>[^_]+)_(?P<uid>[a-f0-9\-]+)\/(?P<container_name>[^\._]+)\/(?P<restart_count>\d+)\.log$
        type: regex_parser
      - from: attributes.stream
        to: attributes["iostream"]
        type: move
      - from: attributes.container_name
        to: resource["k8s.container.name"]
        type: move
      - from: attributes.namespace
        to: resource["k8s.namespace.name"]
        type: move
      - from: attributes.pod_name
        to: resource["k8s.pod.name"]
        type: move
      - from: attributes.restart_count
        to: resource["k8s.container.restart_count"]
        type: move
      - from: attributes.uid
        to: resource["k8s.pod.uid"]
        type: move
      # Add custom multiline parsers here. Add more `type: recombine` operators for custom multiline formats
      # https://github.com/open-telemetry/opentelemetry-collector-contrib/blob/main/pkg/stanza/docs/operators/recombine.md
      - type: recombine
        id: stack-errors-recombine
        combine_field: body
        is_first_entry: body matches "^[^\\s]"
        source_identifier: attributes["log.file.path"]
      # Update body field after finishing all parsing
      - from: attributes.log
        to: body
        type: move
```
### Examples

#### Java Stack Trace Errors

Java exceptions span multiple lines, starting with an exception message followed by lines that detail the stack trace.

**Log Format:**

```java
Exception in thread "main" java.lang.NullPointerException
  at com.example.myproject.Book.getTitle(Book.java:16)
  at com.example.myproject.Author.getBookTitles(Author.java:25)
```
**Configuration:**

```yaml
config:
  receivers:
    filelog:
      operators:
        # previous operators
        - type: recombine
          id: Java-Stack-Trace-Errors
          combine_field: body
          is_first_entry: body matches "^[\\w]+(Exception|Error)"
          combine_with: "\n"
        # Update body field after finishing all parsing
        - from: attributes.log
          to: body
          type: move
```

#### Python Tracebacks

Python errors start with `Traceback` followed by file paths and the actual error message.

**Log Format:**

```python
Traceback (most recent call last):
  File "/path/to/script.py", line 1, in <module>
    raise Exception("An error occurred")
Exception: An error occurred
```
**Configuration:**

```yaml
config:
  receivers:
    filelog:
      operators:
        # previous operators
        - type: recombine
          id: Python-Tracebacks
          combine_field: body
          is_first_entry: body matches "^Traceback"
          combine_with: "\n"
        # Update body field after finishing all parsing
        - from: attributes.log
          to: body
          type: move
```

#### Custom Multiline Log Format

Suppose logs start with a timestamp and include continuation lines prefixed with a special character (e.g., `>`).

**Log Format:**

```shell
`2023-03-25 10:00:00 ERROR: An error occurred
> additional info
> more details
2023-03-25 10:05:00 INFO: A new entry starts` 
```
**Configuration:**
```yaml
config:
  receivers:
    filelog:
      operators:
        # previous operators
        - type: recombine
          id: custom-multiline
          combine_field: body
          is_first_entry: body matches "^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}"
          combine_with: "\n"
        # Update body field after finishing all parsing
        - from: attributes.log
          to: body
          type: move
```
