#!/bin/sh
# Log panels need the project ID, and a dashboard file can't read it from the environment.
# So fill it in, then start Grafana the way the image normally does.
set -eu
mkdir -p /tmp/dashboards
for file in /etc/grafana/dashboards/*.json; do
  sed "s/__GOOGLE_CLOUD_PROJECT__/$GOOGLE_CLOUD_PROJECT/g" "$file" > "/tmp/dashboards/$(basename "$file")"
done
exec /run.sh "$@"
