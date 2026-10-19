# The one-page store. Bots check the color of its Buy now button.
class StoreController < ApplicationController
  # `make ship-broken` deploys a canary with BREAK_STORE=1 to stand in for a bad commit.
  class SimulatedBug < StandardError; end

  before_action :set_build_headers
  rescue_from(SimulatedBug) { |error| render plain: error.message, status: :internal_server_error }

  def show
    raise SimulatedBug, "Simulated bug: this revision was deployed with BREAK_STORE=1." if ENV["BREAK_STORE"] == "1"

    @visitor = Visitor.from(request, cookies)
    @color = FeatureFlags.enabled_for?(:orange_button, @visitor) ? "orange" : "blue"
    @flag_reason = FeatureFlags.reason_for(:orange_button, @visitor)
  end

  private
    # The bots read these to tell which revision and which build answered.
    def set_build_headers
      response.set_header "X-Revision", AppInfo.revision
      response.set_header "X-App-Version", AppInfo.version
    end
end
