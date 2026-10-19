# Cloud Run Admin API v2: read a service's traffic, start a job.
module Gcp::CloudRun
  extend self

  def service(name) = Gcp.get(url("services/#{name}"))

  # env: overrides for this one execution, like `gcloud run jobs execute --update-env-vars`.
  def run_job(name, env: {})
    overrides = env.any? ? { overrides: { containerOverrides: [ { env: env.map { |k, v| { name: k, value: v.to_s } } } ] } } : {}
    Gcp.post(url("jobs/#{name}:run"), overrides)
  end

  private
    def url(path) = "https://run.googleapis.com/v2/projects/#{Gcp.project}/locations/#{Gcp.region}/#{path}"
end
