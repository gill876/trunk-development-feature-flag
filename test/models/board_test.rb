require "test_helper"

class BoardTest < ActiveSupport::TestCase
  CANARY_SPLIT = [
    { "revision" => "flagship-00004-old", "percent" => 90, "tag" => "stable" },
    { "revision" => "flagship-00005-new", "percent" => 10, "tag" => "canary", "uri" => "https://canary---flagship.example" }
  ].freeze

  test "an empty board" do
    board = Board.new({})
    assert board.empty?
    assert_equal "none", board.canary_summary
  end

  test "rows list every bot with up to 3 runs of visits" do
    store = BoardStore.current
    4.times { store.add_run(sample_run) }
    board = Board.load

    assert_equal 4, board.runs.size
    assert_equal BotSquad::HANDLES, board.rows.map(&:handle)
    assert_equal 9, board.rows.first.cells.size
    assert_equal "blue · rev 1", board.rows.first.latest
  end

  test "visits answered by anything but the biggest revision are marked as canary" do
    run = sample_run(revision: "flagship-00004-old", traffic: CANARY_SPLIT,
      overrides: { "dev-01" => { "revision" => "flagship-00005-new", "target" => "canary" } })
    board = Board.new("runs" => [ run ])

    dev, alpha = board.rows.first(2)
    assert dev.cells.all?(&:canary)
    assert alpha.cells.none?(&:canary)
    assert_equal "90% rev 4 (stable) · 10% rev 5 (canary)", board.traffic_summary
    assert_equal "rev 5", board.canary_summary
  end

  test "counts orange buttons and errors" do
    run = sample_run(overrides: { "beta-01" => { "color" => "orange" }, "user-02" => { "status" => 500, "color" => nil } })
    board = Board.new("runs" => [ run ])

    assert_equal 1, board.orange_count
    assert_equal 3, board.error_count
    assert_equal [ 0, 0, 1, 0 ], board.cohorts.map(&:orange)
    assert_equal "error 500 · rev 1", board.rows.find { |row| row.handle == "user-02" }.latest
  end

  test "demo mode shows only while it hasn't ended" do
    assert Board.new("demo_until" => 10.minutes.from_now.iso8601).demo_until
    assert_nil Board.new("demo_until" => 1.minute.ago.iso8601).demo_until
  end
end
