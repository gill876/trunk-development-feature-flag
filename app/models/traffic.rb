# How Cloud Run splits the store's traffic right now, as the Admin API reports it.
# Locally there is no split: everything goes to STORE_URL.
class Traffic
  Target = Data.define(:revision, :percent, :tag, :uri)

  attr_reader :url, :targets

  def self.current
    return new(url: ENV.fetch("STORE_URL", "http://localhost:3000"), targets: []) unless Gcp.configured?

    service = Gcp::CloudRun.service(ENV.fetch("STORE_SERVICE", "flagship"))
    latest = service["latestReadyRevision"].to_s.split("/").last
    targets = service.fetch("trafficStatuses", []).map do |status|
      Target.new(revision: status["revision"].presence || latest, percent: status["percent"].to_i,
        tag: status["tag"], uri: status["uri"])
    end
    new(url: service["uri"], targets: targets)
  end

  def self.from_h(list)
    targets = Array(list).map do |target|
      Target.new(revision: target["revision"], percent: target["percent"].to_i, tag: target["tag"], uri: target["uri"])
    end
    new(url: nil, targets: targets)
  end

  def initialize(url:, targets:)
    @url, @targets = url, targets
  end

  def canary_url = targets.find { |t| t.tag == "canary" }&.uri

  # The revision with the biggest share. Anything else that answers is a canary.
  def main_revision = targets.select { |t| t.percent.positive? }.max_by(&:percent)&.revision

  def serving = targets.select { |t| t.percent.positive? }.sort_by { |t| -t.percent }

  def tag_for(revision) = targets.find { |t| t.revision == revision && t.tag }&.tag

  def to_a = targets.map { |t| t.to_h.stringify_keys }
end
