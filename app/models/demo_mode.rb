# Demo mode: Cloud Scheduler runs the bots every minute, and the bots switch it off again
# after 30 minutes, so a forgotten demo can't run all month.
module DemoMode
  extend self

  DURATION = 30.minutes

  # Called at the start of every bot run.
  def tick
    return unless Gcp.configured?

    if (minutes = ENV["START_DEMO"].to_i).positive?
      start(minutes.minutes)
    elsif Gcp::Scheduler.enabled?(job)
      ends_at = until_time
      if ends_at.nil?
        # Someone resumed the scheduler by hand: give it the usual 30 minutes.
        BoardStore.current.update("demo_until" => DURATION.from_now)
      elsif ends_at.past?
        stop
      end
    end
  end

  def start(duration = DURATION)
    BoardStore.current.update("demo_until" => duration.from_now)
    Gcp::Scheduler.resume(job)
  end

  def stop
    Gcp::Scheduler.pause(job)
    BoardStore.current.update("demo_until" => nil)
  end

  private
    def job = ENV.fetch("SCHEDULER_JOB", "flagship-bots-demo")

    def until_time
      value = BoardStore.current.read["demo_until"]
      Time.zone.parse(value) if value
    end
end
