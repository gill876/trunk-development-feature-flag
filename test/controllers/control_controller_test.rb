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

  test "speaks Japanese to a browser set to Japanese" do
    as_control { get root_path, headers: { "Accept-Language" => "ja,en-US;q=0.9" } }

    assert_select "html[lang=ja]"
    assert_select "h2", "まだ実行履歴がありません"
  end

  test "?locale=ja sticks for the 10 s refresh" do
    as_control do
      get root_path(locale: "ja")
      get board_path
    end

    assert_select "h2", "まだ実行履歴がありません"
  end

  test "languages we don't have get English" do
    as_control { get root_path(locale: "fr"), headers: { "Accept-Language" => "de-DE" } }

    assert_select "html[lang=en]"
    assert_select "h2", "No runs yet"
  end

  test "a full board in Japanese" do
    BoardStore.current.add_run(sample_run(overrides: { "user-02" => { "status" => 500, "color" => nil } }))

    as_control { get root_path(locale: "ja") }

    assert_select ".control__status", /最終実行：.+経過/
    assert_select ".tile__value", "12体中 0体"
    assert_select ".grid__latest", "青 · rev 1-abc"
    assert_select ".grid__latest", "エラー 500 · rev 1-abc"
  end

  private
    def as_control(&) = with_env("APP_ROLE" => "control", &)
end
