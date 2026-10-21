# What this process is and which build it runs. Cloud Run sets K_REVISION;
# `make ship` sets APP_VERSION to the git commit it built.
module AppInfo
  extend self

  def role = ENV.fetch("APP_ROLE", "store")
  def control? = role == "control"
  def revision = ENV.fetch("K_REVISION", "local")
  def version = ENV.fetch("APP_VERSION", "dev")
  def release = "flagship@#{version}" # what Sentry calls a build; config/initializers/sentry.rb agrees
end
