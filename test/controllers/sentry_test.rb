require "test_helper"
require "sentry/test_helper"

# What Sentry receives when something breaks. Sentry::TestHelper swaps in a transport that
# keeps events in memory instead of sending them.
class SentryTest < ActionDispatch::IntegrationTest
  include Sentry::TestHelper

  setup { setup_sentry_test }
  teardown { teardown_sentry_test }

  test "a broken page tells Sentry who hit it and what their flags said" do
    with_env("BREAK_STORE" => "1") { get root_path, headers: { "X-Demo-User" => "beta-02" } }

    assert_response :internal_server_error
    event = sentry_errors.last
    assert_equal "StoreController::SimulatedBug", event.exception.values.last.type
    assert_equal({ id: "beta-02", segment: "beta" }, event.user.symbolize_keys)
    assert_equal({ cohort: "beta", "flag.orange_button": "off" }, event.tags.symbolize_keys.slice(:cohort, :"flag.orange_button"))
    assert_equal "no rule matched", event.contexts.dig("feature_flags", :orange_button, :reason)
  end

  # The checkout drill: only visitors with the orange button hit the bug.
  test "the checkout bug reaches Sentry with the flag that caused it" do
    with_env("BREAK_STORE" => "checkout", "FEATURES__ORANGE_BUTTON_SEGMENTS" => "beta") do
      Rails.app.envs.reload

      post api_v1_purchases_path, headers: { "X-Demo-User" => "user-01" }, as: :json
      assert_response :created
      assert_empty sentry_errors

      assert_raises(KeyError) { post api_v1_purchases_path, headers: { "X-Demo-User" => "beta-02" }, as: :json }
    end

    event = sentry_errors.last
    assert_equal "KeyError", event.exception.values.last.type
    assert_equal "on", event.tags[:"flag.orange_button"]
    assert_equal "segment beta", event.contexts.dig("feature_flags", :orange_button, :reason)
  ensure
    Rails.app.envs.reload
  end

  test "the store page loads the browser SDK only when there's a DSN" do
    get root_path
    assert_select "script[src*='sentry-cdn.com']", 0

    with_env("SENTRY_DSN" => Sentry::TestHelper::DUMMY_DSN) { get root_path }
    assert_select "script[src*='sentry-cdn.com'][integrity]", 1
    assert_match "flagship@dev", response.body
  end

  private
    # Every request also sends a trace (a transaction event); these are just the errors.
    def sentry_errors = sentry_events.grep(Sentry::ErrorEvent)
end
