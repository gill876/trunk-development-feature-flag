# Flagship

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

`make setup` creates a project of its own (so `make teardown` removes everything), budget alerts, Firestore, the secrets, and keyless deploys from GitHub Actions. Expect roughly ¥0–100 a month while you experiment; [GUIDE.md](GUIDE.md#costs-and-guardrails) explains why.
