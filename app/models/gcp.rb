# A small REST client for the Google APIs the demo calls (Cloud Run Admin, Cloud Scheduler).
# On Cloud Run the token comes from the service's own service account; locally it comes
# from `gcloud auth application-default login`.
module Gcp
  extend self

  class Error < StandardError; end

  SCOPE = "https://www.googleapis.com/auth/cloud-platform".freeze

  def configured? = project.present?
  def project = ENV["GOOGLE_CLOUD_PROJECT"]
  def region = ENV.fetch("REGION", "asia-northeast1")

  def get(url) = request(Net::HTTP::Get, url)
  def post(url, body = {}) = request(Net::HTTP::Post, url, body)

  private
    def request(verb, url, body = nil)
      uri = URI(url)
      req = verb.new(uri)
      req["Authorization"] = "Bearer #{access_token}"
      req["Content-Type"] = "application/json"
      req.body = body.to_json if body

      res = Net::HTTP.start(uri.host, uri.port, use_ssl: true, open_timeout: 10, read_timeout: 30) { |http| http.request(req) }
      raise Error, "#{req.method} #{uri.path} → #{res.code}: #{res.body.to_s.first(300)}" unless res.is_a?(Net::HTTPSuccess)

      res.body.present? ? JSON.parse(res.body) : {}
    end

    def access_token
      @credentials ||= Google::Auth.get_application_default([ SCOPE ])
      @credentials.fetch_access_token! if @credentials.access_token.nil? || @credentials.expires_within?(60)
      @credentials.access_token
    end
end
