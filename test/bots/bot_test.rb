require "test_helper"

class BotTest < ActiveSupport::TestCase
  test "reads the button color from the page" do
    html = %(<main><button id="buy" data-color="orange">Buy now</button></main>)
    assert_equal "orange", Bot.button_color(html)
  end

  test "no button, no color" do
    assert_nil Bot.button_color("Simulated bug")
    assert_nil Bot.button_color(nil)
  end

  test "a failed connection is recorded, not raised" do
    visit = Bot.new("beta-02").visit("http://127.0.0.1:9/", "main")
    assert_equal 0, visit["status"]
    assert_equal "beta", visit["cohort"]
    assert visit["error"].present?
  end

  test "the squad is 12 bots in 4 cohorts" do
    assert_equal 12, BotSquad::HANDLES.size
    assert_equal %w[dev-01 alpha-01 alpha-02 beta-01], BotSquad::HANDLES.first(4)
  end
end
