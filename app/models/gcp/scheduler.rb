# Cloud Scheduler API: the demo-mode job that runs the bots every minute.
module Gcp::Scheduler
  extend self

  def enabled?(name) = Gcp.get(url(name))["state"] == "ENABLED"
  def resume(name) = Gcp.post(url("#{name}:resume"))
  def pause(name) = Gcp.post(url("#{name}:pause"))

  private
    def url(path) = "https://cloudscheduler.googleapis.com/v1/projects/#{Gcp.project}/locations/#{Gcp.region}/jobs/#{path}"
end
