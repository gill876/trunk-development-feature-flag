require "test_helper"

class StoreControllerTest < ActionDispatch::IntegrationTest
  test "shows the blue button and says which build answered" do
    get root_path, headers: { "X-Demo-User" => "beta-02" }

    assert_response :success
    assert_select "#buy[data-color=blue]", "Buy now"
    assert_select "#order[hidden]"
    assert_select ".store__debug", /beta-02 \(beta\)/
    assert_equal "local", response.headers["X-Revision"]
    assert_equal "dev", response.headers["X-App-Version"]
  end

  test "?as= picks a visitor and a cookie remembers it" do
    get root_path(as: "alpha-01")
    assert_select ".store__debug", /alpha-01 \(alpha\)/

    get root_path
    assert_select ".store__debug", /alpha-01 \(alpha\)/
  end

  test "strangers become guests" do
    get root_path
    assert_select ".store__debug", /guest-\h{8} \(user\)/
  end

  test "the flag turns the button orange for its segments only" do
    with_env("FEATURES__ORANGE_BUTTON_SEGMENTS" => "beta") do
      Rails.app.envs.reload

      get root_path, headers: { "X-Demo-User" => "beta-02" }
      assert_select "#buy[data-color=orange]"
      assert_select ".store__debug", /orange_button ON: segment beta/

      get root_path, headers: { "X-Demo-User" => "user-04" }
      assert_select "#buy[data-color=blue]"
      assert_select ".store__debug", /orange_button off: no rule matched/
    end
  ensure
    Rails.app.envs.reload
  end

  # The article wraps requests in FeatureFlags.with. On Rails 8.1 each request runs in its own
  # execution context with fresh Current attributes, so an override set outside never reaches it.
  # Integration tests set the flag through ENV instead, as the test above does.
  test "FeatureFlags.with outside a request doesn't reach inside it" do
    FeatureFlags.with(:orange_button, true) do
      get root_path, headers: { "X-Demo-User" => "user-01" }
      assert_select "#buy[data-color=blue]"
    end
  end

  test "BREAK_STORE makes the revision fail, but it still says which revision it is" do
    with_env("BREAK_STORE" => "1", "K_REVISION" => "flagship-00006-bad") do
      get root_path
    end

    assert_response :internal_server_error
    assert_equal "flagship-00006-bad", response.headers["X-Revision"]
  end
end
