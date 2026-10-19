# The dashboard. It runs as its own Cloud Run service (APP_ROLE=control) and is never
# canaried, so a broken store revision can't take down the thing you're watching it with.
class ControlController < ApplicationController
  layout "control"
  before_action :require_password

  def show
    @board = Board.load
  end

  # The page polls this every 10 s while its tab is visible: one Firestore read each time.
  def board
    render partial: "board", locals: { board: Board.load }
  end

  def run_bots
    start_bots
    redirect_to root_path, notice: "Bots sent. Their results land here in about 30 seconds."
  end

  def start_demo
    start_bots("START_DEMO" => DemoMode::DURATION.in_minutes.to_i)
    redirect_to root_path, notice: "Demo mode is on: the bots run every minute for the next 30 minutes."
  end

  private
    def start_bots(env = {})
      if Gcp.configured?
        Gcp::CloudRun.run_job(ENV.fetch("BOTS_JOB", "flagship-bots"), env: env)
      else
        # Locally there is no job to start, so the bots run in a background thread.
        Thread.new { Rails.application.executor.wrap { BotSquad.run } }
      end
    end

    # The dashboard can start paid work, so production always asks for the password.
    def require_password
      password = ENV["CONTROL_PASSWORD"]
      return if password.blank? && !Rails.env.production?

      authenticate_or_request_with_http_basic("Flagship Control") do |_name, given|
        password.present? && ActiveSupport::SecurityUtils.secure_compare(given, password)
      end
    end
end
