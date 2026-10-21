# Grafana with this project's data sources and dashboards baked in. It keeps no state: every
# start provisions the same dashboards from these files, so they live in git like the code.
# `make grafana` builds and deploys it. See docs/monitoring/grafana.md.
FROM grafana/grafana:13.2.3

# Cloud Logging's data source is a plugin. Installed at build time, so starts don't download it.
# (The base image sets GF_PATHS_PLUGINS, which beats grafana.ini, so the path goes here.)
ENV GF_PATHS_PLUGINS=/opt/grafana/plugins
USER root
RUN mkdir -p "$GF_PATHS_PLUGINS" \
 && grafana cli --pluginsDir "$GF_PATHS_PLUGINS" plugins install googlecloud-logging-datasource 1.8.1 \
 && chown -R 472:0 "$GF_PATHS_PLUGINS"
USER 472

COPY grafana.ini /etc/grafana/grafana.ini
COPY provisioning /etc/grafana/provisioning
COPY dashboards /etc/grafana/dashboards
COPY start.sh /start.sh
ENTRYPOINT ["/start.sh"]
