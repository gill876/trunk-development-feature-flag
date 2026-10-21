# Shared by script/setup and script/flagship. Works with macOS's bash 3.2.

PROJECT_ID="${PROJECT_ID:-$(cat .gcp-project 2>/dev/null || true)}"
REGION="${REGION:-asia-northeast1}"

SERVICE=flagship            # the store: the only service that gets canaries
CONTROL=flagship-control    # the dashboard
JOB=flagship-bots           # the 12 bots, as a Cloud Run job
SCHEDULE=flagship-bots-demo # Cloud Scheduler job behind demo mode (paused unless a demo is on)
GRAFANA=flagship-grafana    # Grafana, with the dashboards in grafana/
REPO=flagship               # Artifact Registry repository

# Print a command, then run it. Everything that changes something in GCP goes through here,
# so you can see (and copy) the real gcloud command. Read-only lookups run quietly.
run() {
  printf '\033[36m$ %s\033[0m\n' "$*" >&2
  "$@"
}

say() { printf '\033[1m%s\033[0m\n' "$*" >&2; }
die() { printf '\033[31m%s\033[0m\n' "$*" >&2; exit 1; }

need_project() {
  [ -n "$PROJECT_ID" ] || die "No GCP project yet. Run: make setup BILLING_ACCOUNT=..."
  P=(--project="$PROJECT_ID")
  R=(--project="$PROJECT_ID" --region="$REGION")
  REGISTRY="$REGION-docker.pkg.dev/$PROJECT_ID/$REPO"
}

sa() { echo "$1@$PROJECT_ID.iam.gserviceaccount.com"; }
