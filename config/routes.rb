Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check

  # One codebase, two Cloud Run services: the store, and the dashboard (APP_ROLE=control).
  constraints(->(_request) { AppInfo.control? }) do
    root "control#show", as: :control_root
    get "board" => "control#board"
    post "runs" => "control#run_bots"
    post "demo" => "control#start_demo"
  end

  # The store's JSON API. openapi/openapi.yaml describes it; /api/docs shows it.
  constraints(->(_request) { !AppInfo.control? }) do
    namespace :api do
      namespace :v1 do
        resources :flags, only: :index
        resources :purchases, only: :create
      end
      get "docs" => "docs#show"
    end
    get "openapi.yaml" => "api/docs#spec", as: :openapi
  end

  root "store#show"
end
