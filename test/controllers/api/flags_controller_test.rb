require "test_helper"

class Api::FlagsControllerTest < ActionDispatch::IntegrationTest
  include OpenApiContract

  test "a guest's flags match the spec" do
    get api_v1_flags_path

    assert_schema_conform(200)
    assert_match Visitor::GUEST, response.parsed_body.dig("visitor", "id")
    assert_equal "local", response.headers["X-Revision"]
  end

  test "says which rule turned a flag on" do
    with_env("FEATURES__ORANGE_BUTTON_SEGMENTS" => "beta") do
      Rails.app.envs.reload
      get api_v1_flags_path, headers: { "X-Demo-User" => "beta-02" }
    end

    assert_schema_conform(200)
    assert_equal [ { "name" => "orange_button", "enabled" => true, "reason" => "segment beta" } ], response.parsed_body["flags"]
  ensure
    Rails.app.envs.reload
  end

  test "a broken revision answers in JSON too" do
    with_env("BREAK_STORE" => "1") { get api_v1_flags_path }

    assert_schema_conform(500)
  end

  test "the dashboard service doesn't serve the API" do
    with_env("APP_ROLE" => "control") { get api_v1_flags_path }

    assert_response :not_found
  end
end
