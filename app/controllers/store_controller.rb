# The one-page store. Bots check the color of its Buy now button.
class StoreController < ApplicationController
  # `make ship-broken` deploys a canary with BREAK_STORE=1 to stand in for a bad commit.
  class SimulatedBug < StandardError; end
  BROKEN_MESSAGE = "Simulated bug: this revision was deployed with BREAK_STORE=1."

  include BuildHeaders
  rescue_from(SimulatedBug) { |error| render plain: error.message, status: :internal_server_error }

  def show
    raise SimulatedBug, BROKEN_MESSAGE if ENV["BREAK_STORE"] == "1"

    @visitor = Visitor.from(request, cookies)
    @color = FeatureFlags.enabled_for?(:orange_button, @visitor) ? "orange" : "blue"
    @flag_reason = FeatureFlags.reason_for(:orange_button, @visitor)
  end
end
