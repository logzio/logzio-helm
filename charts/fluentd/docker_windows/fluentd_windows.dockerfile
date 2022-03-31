FROM fluent/fluentd:v1.14.5-windows-ltsc2019-1.0
RUN gem install fluent-plugin-detect-exceptions \
&& gem install fluent-plugin-logzio \
&& gem install fluent-plugin-concat \
&& gem install fluent-plugin-record-modifier \
&& gem install fluent-plugin-kubernetes_metadata_filter \
&& gem install fluent-plugin-kubernetes \
&& gem install fluent-plugin-systemd -v 1.0.3 \
&& gem install fluent-plugin-multi-format-parser \
&& gem install fluent-plugin-windows-eventlog
COPY plugins /fluent/plugins

ENTRYPOINT ["cmd", "/k" ,"fluentd", "--config", "C:\\fluent\\conf\\fluent.conf","-p","C:\\fluent\\plugins"]