# Reads `gcloud run services describe flagship --format=json` from stdin and answers one question.
# Ruby instead of jq, because Ruby is already here.
#
#   serving       the one revision taking all traffic (fails if traffic is split)
#   split?        exits 0 if more than one revision is taking traffic
#   on-latest?    exits 0 if traffic follows the latest revision (needed before a flag change)
#   tag NAME      the revision a tag points at
#   url [TAG]     the service URL, or a tag's URL
#   table         a readable summary for `make status`
require "json"

service = JSON.parse($stdin.read)
traffic = service.dig("status", "traffic") || []
serving = traffic.select { |t| t["percent"].to_i.positive? }

case ARGV[0]
when "serving"
  abort "Traffic is split between revisions; finish the canary first (make promote or make rollback)." if serving.size != 1
  puts serving.first["revisionName"]
when "split?"
  exit(serving.map { |t| t["revisionName"] }.uniq.size > 1 ? 0 : 1)
when "on-latest?"
  exit(serving.size == 1 && serving.first["latestRevision"] ? 0 : 1)
when "tag"
  target = traffic.find { |t| t["tag"] == ARGV[1] } or abort "No revision is tagged #{ARGV[1]}."
  puts target["revisionName"]
when "url"
  puts ARGV[1] ? traffic.find { |t| t["tag"] == ARGV[1] }&.dig("url") : service.dig("status", "url")
when "table"
  latest = service.dig("status", "latestCreatedRevisionName")
  puts "Traffic"
  traffic.group_by { |t| t["revisionName"] }.each do |revision, targets|
    percent = targets.sum { |t| t["percent"].to_i }
    tags = targets.filter_map { |t| t["tag"] }
    notes = [ ("latest" if revision == latest), ("follows latest" if targets.any? { |t| t["latestRevision"] }) ].compact
    puts format("  %-28s %4d%%  %-14s %s", revision, percent, tags.join(","), notes.join(", "))
  end
  env = service.dig("spec", "template", "spec", "containers", 0, "env") || []
  flags = env.select { |e| e["name"].start_with?("FEATURES__") }
  puts "\nFlags on the latest revision (ENV overrides credentials)"
  puts flags.empty? ? "  none set" : flags.map { |e| "  #{e['name']}=#{e['value']}" }
  version = env.find { |e| e["name"] == "APP_VERSION" }&.dig("value")
  puts "\nLatest build: #{version || 'unknown'}"
else
  abort "usage: traffic.rb serving|split?|on-latest?|tag NAME|url [TAG]|table"
end
