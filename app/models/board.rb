# What the dashboard shows: every bot's visits from the last 3 runs, plus a summary of the newest run.
class Board
  RUNS_SHOWN = 3

  Cell = Data.define(:state, :canary, :title)
  Row = Data.define(:handle, :cohort, :cells, :latest)
  CohortCount = Data.define(:cohort, :orange, :total)

  attr_reader :runs

  def self.load = new(BoardStore.current.read)

  def initialize(data)
    @runs = Array(data["runs"])
    @demo_until = Time.zone.parse(data["demo_until"]) if data["demo_until"]
  end

  def empty? = runs.empty?
  def latest_run = runs.first
  def last_run_at
    Time.zone.parse(latest_run["at"]) if latest_run
  end

  def demo_until
    @demo_until if @demo_until&.future?
  end

  def traffic = Traffic.from_h(latest_run&.dig("traffic"))

  # "90% rev 4 (stable) · 10% rev 5 (canary)"
  def traffic_summary
    return "no split (local)" if traffic.serving.empty?

    traffic.serving.map do |target|
      tag = traffic.tag_for(target.revision)
      "#{target.percent}% #{self.class.revision_label(target.revision)}#{" (#{tag})" if tag}"
    end.join(" · ")
  end

  def canary_summary
    canary = traffic.targets.find { |target| target.tag == "canary" }
    canary ? self.class.revision_label(canary.revision) : "none"
  end

  def rows
    shown = runs.first(RUNS_SHOWN).reverse
    BotSquad::HANDLES.map do |handle|
      cells = shown.flat_map { |run| visits_for(run, handle).map { |visit| cell(visit, Traffic.from_h(run["traffic"])) } }
      Row.new(handle: handle, cohort: Visitor.for(handle).cohort, cells: cells, latest: describe(latest_visit(handle)))
    end
  end

  def orange_count = latest_visits.count { |visit| visit["color"] == "orange" }
  def bot_count = BotSquad::HANDLES.size

  def error_count = recent_visits.count { |visit| visit["status"] != 200 }
  def recent_visit_count = recent_visits.size

  def cohorts
    BotSquad::COHORTS.map do |cohort, total|
      CohortCount.new(cohort: cohort, orange: latest_visits.count { |v| v["cohort"] == cohort && v["color"] == "orange" }, total: total)
    end
  end

  # "flagship-00004-kzn" → "rev 4-kzn". The number alone isn't unique: two revisions can share it.
  def self.revision_label(name)
    number, suffix = name.to_s.match(/-(\d{5})-(\w+)\z/)&.captures
    number ? "rev #{number.to_i}-#{suffix}" : name.to_s
  end

  private
    def visits_for(run, handle) = run["visits"].select { |visit| visit["bot"] == handle }
    def recent_visits = runs.first(RUNS_SHOWN).flat_map { |run| run["visits"] }

    # Each bot's last visit in the newest run.
    def latest_visits
      return [] unless latest_run
      latest_run["visits"].group_by { |visit| visit["bot"] }.map { |_bot, visits| visits.last }
    end

    def latest_visit(handle) = latest_run && visits_for(latest_run, handle).last

    def cell(visit, traffic)
      state = visit["status"] == 200 ? (visit["color"] || "missing") : "error"
      canary = traffic.main_revision.present? && visit["revision"].present? && visit["revision"] != traffic.main_revision
      title = [ visit["status"] == 200 ? visit["color"] : "status #{visit['status']}", self.class.revision_label(visit["revision"]),
        visit["version"], ("#{visit['ms']} ms" if visit["ms"]) ].compact.join(" · ")
      Cell.new(state: state, canary: canary, title: title)
    end

    def describe(visit)
      return "no visits yet" unless visit
      what = visit["status"] == 200 ? visit["color"] : (visit["status"].zero? ? visit["error"] : "error #{visit['status']}")
      [ what, (self.class.revision_label(visit["revision"]) if visit["revision"]) ].compact.join(" · ")
    end
end
