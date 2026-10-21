# The one-page store. Bots check the color of its Buy now button.
class StoreController < ApplicationController
  # `make ship-broken` deploys a canary with BREAK_STORE=1 to stand in for a bad commit.
  class SimulatedBug < StandardError; end
  BROKEN_MESSAGE = "Simulated bug: this revision was deployed with BREAK_STORE=1."

  include BuildHeaders
  include SentryVisitorContext

  rescue_from(SimulatedBug) do |error|
    Rails.error.report(error, handled: false)
    render plain: error.message, status: :internal_server_error
  end

  def show
    @visitor = Visitor.from(request, cookies)
    tell_sentry_about(@visitor)
    raise SimulatedBug, BROKEN_MESSAGE if ENV["BREAK_STORE"] == "1"

    @color = FeatureFlags.enabled_for?(:orange_button, @visitor) ? "orange" : "blue"
    @flag_reason = FeatureFlags.reason_for(:orange_button, @visitor)
  end
end
