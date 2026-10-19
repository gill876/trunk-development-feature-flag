# The 12 bots. One run: every bot visits the store 3 times, then the run is saved to the board.
# On Cloud Run this is the flagship-bots job: `bin/rails runner BotSquad.run`.
class BotSquad
  COHORTS = { "dev" => 1, "alpha" => 2, "beta" => 3, "user" => 6 }.freeze
  HANDLES = COHORTS.flat_map { |cohort, count| (1..count).map { |n| format("%s-%02d", cohort, n) } }.freeze
  VISITS_PER_BOT = 3

  def self.run = new.run

  def run
    DemoMode.tick
    traffic = Traffic.current

    visits = HANDLES.map do |handle|
      Thread.new do
        url, target = destination(handle, traffic)
        bot = Bot.new(handle)
        Array.new(VISITS_PER_BOT) { bot.visit(url, target) }
      end
    end.flat_map(&:value)

    run = { "id" => SecureRandom.hex(4), "at" => Time.current.iso8601, "trigger" => trigger,
      "traffic" => traffic.to_a, "visits" => visits }
    BoardStore.current.add_run(run)
    puts summary(visits)
    run
  end

  private
    # dev-01 checks the canary through its own tag URL before any user traffic reaches it.
    # Everyone else uses the main URL, where Cloud Run decides which revision answers.
    def destination(handle, traffic)
      if handle.start_with?("dev-") && traffic.canary_url
        [ traffic.canary_url, "canary" ]
      else
        [ traffic.url, "main" ]
      end
    end

    def trigger
      if ENV["START_DEMO"].present? then "demo start"
      elsif ENV["CLOUD_RUN_EXECUTION"].present? then "job"
      else "local"
      end
    end

    def summary(visits)
      counts = visits.group_by { |v| v["status"] == 200 ? v["color"] : "error #{v['status']}" }.transform_values(&:size)
      "#{visits.size} visits: " + counts.map { |key, n| "#{n} #{key}" }.join(", ")
    end
end
