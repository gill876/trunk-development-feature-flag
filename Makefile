# Flagship: every step of the demo, in the order GUIDE.md walks through them.
# Each target prints the gcloud commands it runs, so you can see what's really happening.
#
#   make help          list everything
#   make setup         once: project, budgets, Firestore, secrets, keyless CI
#   make launch        step 0: first deploy
#   make ship          step 1: deploy the current commit at 0% (CI does this on every merge)
#   make canary PCT=10 step 2
#   make promote       step 3
#   make flag FLAG=orange_button SEGMENTS=dev   steps 4-7

.DEFAULT_GOAL := help
.PHONY: help setup launch tools ship ship-broken canary promote rollback flag flag-off \
        bots demo bots-off status urls password teardown dev dev-bots test lint openapi contract

FLAGSHIP = script/flagship

help: ## List every target
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*## "} {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'

## ---- GCP, once
setup: ## Create the project, budgets, Firestore, secrets and CI access (BILLING_ACCOUNT=... GITHUB_REPO=owner/name)
	@BILLING_ACCOUNT='$(BILLING_ACCOUNT)' GITHUB_REPO='$(GITHUB_REPO)' script/setup

launch: ## Step 0: build and deploy everything, the store at 100%
	@$(FLAGSHIP) launch

tools: ## Redeploy the dashboard and the bots job from the current commit
	@$(FLAGSHIP) tools

## ---- Shipping code (canary)
ship: ## Step 1: deploy the current commit at 0%, with a canary tag URL
	@$(FLAGSHIP) ship

canary: ## Step 2: send PCT% of requests to the canary (PCT=10)
	@PCT='$(PCT)' $(FLAGSHIP) canary

promote: ## Step 3: the canary takes 100%
	@$(FLAGSHIP) promote

rollback: ## All traffic back to the stable revision, in seconds
	@$(FLAGSHIP) rollback

ship-broken: ## Drill: deploy a canary that fails every request
	@$(FLAGSHIP) ship-broken

## ---- Releasing features (flags)
flag: ## Steps 4-7: FLAG=orange_button with SEGMENTS=dev,alpha,beta and/or PERCENT=25 and/or USERS=user-03
	@FLAG='$(FLAG)' SEGMENTS='$(SEGMENTS)' PERCENT='$(PERCENT)' USERS='$(USERS)' $(FLAGSHIP) flag

flag-off: ## Kill switch: FLAG=orange_button off for everyone
	@FLAG='$(FLAG)' $(FLAGSHIP) flag-off

## ---- API contract (openapi/openapi.yaml)
openapi: ## Lint the OpenAPI spec, as CI does
	npx --yes @redocly/cli@2.58.0 lint

contract: ## Check a running store against the spec: the canary, or URL=http://localhost:3000
	@URL='$(URL)' $(FLAGSHIP) contract

## ---- Bots
bots: ## Run the 12 bots once and wait for them
	@$(FLAGSHIP) bots

demo: ## Demo mode: bots every minute for 30 minutes, then off by themselves
	@$(FLAGSHIP) demo

bots-off: ## Stop demo mode now
	@$(FLAGSHIP) bots-off

## ---- Looking around
status: ## Revisions, traffic split and flags right now
	@$(FLAGSHIP) status

urls: ## The store, canary and dashboard URLs
	@$(FLAGSHIP) urls

password: ## The dashboard password (user: flagship)
	@$(FLAGSHIP) password

teardown: ## Delete the whole GCP project
	@$(FLAGSHIP) teardown

## ---- On your laptop
dev: ## Run the store (:3000) and the dashboard (:3001)
	@trap 'kill 0' EXIT; bin/rails server -p 3000 -P tmp/pids/store.pid & APP_ROLE=control bin/rails server -p 3001 -P tmp/pids/control.pid & wait

dev-bots: ## Run the bots against the local store
	STORE_URL=http://localhost:3000 bin/rails runner BotSquad.run

test: ## Run the tests
	bin/rails test

lint: ## RuboCop and Brakeman, as CI runs them
	bin/rubocop
	bin/brakeman --no-pager -q
