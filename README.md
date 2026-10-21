# Flagship

[![CI](https://img.shields.io/github/actions/workflow/status/gill876/trunk-development-feature-flag/ci.yml?branch=main&style=flat&logo=githubactions&logoColor=white&label=CI&labelColor=6d597a)](https://github.com/gill876/trunk-development-feature-flag/actions/workflows/ci.yml)
![Ruby 3.4.9](https://img.shields.io/badge/Ruby-3.4.9-ffb3c6?style=flat&logo=ruby&logoColor=white&labelColor=6d597a)
![Rails 8.1](https://img.shields.io/badge/Rails-8.1-ff9aa2?style=flat&logo=rubyonrails&logoColor=white&labelColor=6d597a)
![Cloud Run, Tokyo](https://img.shields.io/badge/Cloud_Run-Tokyo-a0c4ff?style=flat&logo=googlecloud&logoColor=white&labelColor=6d597a)
[![OpenAPI 3.0](https://img.shields.io/badge/OpenAPI-3.0-b5ead7?style=flat&logo=openapiinitiative&logoColor=white&labelColor=6d597a)](openapi/openapi.yaml)
[![Sentry: errors and replays](https://img.shields.io/badge/Sentry-errors_%26_replays-c3aed6?style=flat&logo=sentry&logoColor=white&labelColor=6d597a)](docs/monitoring/sentry.md)
[![Grafana: 4 dashboards](https://img.shields.io/badge/Grafana-4_dashboards-ffc8a2?style=flat&logo=grafana&logoColor=white&labelColor=6d597a)](docs/monitoring/grafana.md)
<br>
[![Feature flags: no gem needed](https://img.shields.io/badge/%F0%9F%9A%A9_feature_flags-no_gem_needed-ffdac1?style=flat&labelColor=6d597a)](GUIDE.md#3-feature-flags-the-rails-way-without-a-gem)
[![Canaries: 0% to 10% to 100%](https://img.shields.io/badge/%F0%9F%90%A4_canaries-0%25_%E2%86%92_10%25_%E2%86%92_100%25-fdfd96?style=flat&labelColor=6d597a)](GUIDE.md#7-rollout-playbook)
[![Bots: 12 tiny robots](https://img.shields.io/badge/%F0%9F%A4%96_bots-12_tiny_robots-e2f0cb?style=flat&labelColor=6d597a)](GUIDE.md#the-bot-squad)
[![Budget: about 0 yen a month](https://img.shields.io/badge/%F0%9F%92%B4_budget-~%C2%A50%2Fmonth-caffbf?style=flat&labelColor=6d597a)](GUIDE.md#costs-and-guardrails)
![Made with love and uwu](https://img.shields.io/badge/made_with-%F0%9F%92%96_and_uwu-ffc6ff?style=flat&labelColor=6d597a)

A small demo of **trunk-based development**, **feature flags** and **canary deploys**: a one-button Rails store on Cloud Run, 12 bots that check the button's color as dev, alpha, beta and regular users, and a dashboard that shows what each bot saw and which revision served it.

The write-up, with diagrams and every step explained, is in **[GUIDE.md](GUIDE.md)**.

## What's in here

| Piece | Where | Runs as |
| --- | --- | --- |
| The store | `app/controllers/store_controller.rb` | Cloud Run service `flagship`, the one that gets canaries |
| The dashboard | `app/controllers/control_controller.rb` | Cloud Run service `flagship-control` (`APP_ROLE=control`) |
| The bots | `app/bots/` | Cloud Run job `flagship-bots` (`bin/rails runner BotSquad.run`) |
| Every GCP step | `Makefile`, `script/` | your terminal, and CI on each merge to main |

One image runs all three.

## Watching it

| | Where | Docs |
| --- | --- | --- |
| What each bot saw | Flagship Control (`make urls`) | [GUIDE.md](GUIDE.md#the-dashboard) |
| Traffic, errors, latency, the SLO, the free tier | Grafana, at `make urls` (same login) | [docs/monitoring/grafana.md](docs/monitoring/grafana.md) |
| Errors with stack traces, traces and replays | Sentry, project [`flagship`](https://cargill-seiveright.sentry.io/projects/flagship/) | [docs/monitoring/sentry.md](docs/monitoring/sentry.md) |
| The API and its contract | `/api/docs` on any store URL | [docs/api.md](docs/api.md) |

New to this? Start with [docs/monitoring/README.md](docs/monitoring/README.md): what each tool is for, the SRE words (SLO, error budget, golden signals), and what to watch during a canary.

## On your laptop

Needs Ruby 3.4.9 (`.ruby-version`).

```sh
bundle install
make test       # the test suite
make dev        # store on :3000, dashboard on :3001
make dev-bots   # in another terminal: run the 12 bots against the local store
```

Open http://localhost:3001 for the dashboard and http://localhost:3000/?as=beta-02 to see the store as a bot does.

## On Google Cloud

```sh
make setup BILLING_ACCOUNT=XXXXXX-XXXXXX-XXXXXX GITHUB_REPO=owner/name   # once
make launch                                                              # step 0
make help                                                                # everything else
```

Monitoring, once the store is up: `make grafana` deploys Grafana (CI redeploys it on every merge), and `make sentry DSN=…` turns on Sentry.

`make setup` creates a project of its own (so `make teardown` removes everything), budget alerts, Firestore, the secrets, and keyless deploys from GitHub Actions. Expect roughly ¥0–100 a month while you experiment; [GUIDE.md](GUIDE.md#costs-and-guardrails) explains why.
