require "test_helper"

class ControlControllerTest < ActionDispatch::IntegrationTest
  test "the dashboard is only served by the control role" do
    get root_path
    assert_select "#buy"

    as_control { get root_path }
    assert_select "h1", "Flagship Control"
  end

  test "shows the board" do
    BoardStore.current.add_run(sample_run)

    as_control { get root_path }

    assert_response :success
    assert_select ".grid tr", BotSquad::HANDLES.size
    assert_select ".tile__value", /0 of 12 bots/
  end

  test "the polling endpoint returns just the board" do
    as_control { get board_path }

    assert_response :success
    assert_select "h2", "No runs yet"
    assert_no_match(/<html/, response.body)
  end

  test "asks for the password when one is set" do
    with_env("CONTROL_PASSWORD" => "s3cret") do
      as_control { get root_path }
      assert_response :unauthorized

      credentials = ActionController::HttpAuthentication::Basic.encode_credentials("flagship", "s3cret")
      as_control { get root_path, headers: { "Authorization" => credentials } }
      assert_response :success
    end
  end

  private
    def as_control(&) = with_env("APP_ROLE" => "control", &)
end
