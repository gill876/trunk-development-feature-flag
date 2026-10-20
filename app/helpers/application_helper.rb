module ApplicationHelper
  # The same release and environment the server reports, so Sentry puts browser and server
  # events of one build side by side.
  def sentry_browser_options
    { dsn: ENV["SENTRY_DSN"], release: AppInfo.release, environment: Rails.env }
  end
end
