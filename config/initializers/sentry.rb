# Errors, traces and request logs go to Sentry when SENTRY_DSN is set (`make sentry DSN=...`).
# Without it nothing is sent, so tests and laptops stay quiet. See docs/monitoring/sentry.md.
# Initializers can't use app/ classes yet, so this reads AppInfo's variables itself.
Sentry.init do |config|
  config.dsn = ENV["SENTRY_DSN"]
  config.release = "flagship@#{ENV.fetch("APP_VERSION", "dev")}"
  config.environment = Rails.env

  # Breadcrumbs: the controller actions and outgoing HTTP calls that led up to an error.
  config.breadcrumbs_logger = [ :active_support_logger, :http_logger ]

  # Every request a person makes is traced. The bots and the contract tests make hundreds,
  # so only 1 in 10 of theirs is. Free plan: 5M spans a month.
  config.traces_sampler = lambda do |context|
    next context[:parent_sampled] unless context[:parent_sampled].nil?

    agent = context.dig(:env, "HTTP_USER_AGENT").to_s
    agent.match?(/FlagshipBot|schemathesis/i) ? 0.1 : 1.0
  end

  # Logs are on by default since sentry-ruby 7: each request's controller, status and duration
  # shows up in Sentry next to its errors and traces. Free plan: 5 GB a month.

  # Rails.error.report (used where the app rescues an error itself) reaches Sentry too.
  config.rails.register_error_subscriber = true
end

# Which Cloud Run service or job sent an event, and which revision. Every event gets these.
Sentry.set_tags(service: ENV["K_SERVICE"] || ENV["CLOUD_RUN_JOB"] || "local", revision: ENV.fetch("K_REVISION", "local"))
