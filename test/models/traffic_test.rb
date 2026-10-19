require "test_helper"

class TrafficTest < ActiveSupport::TestCase
  def traffic(targets, latest_created: nil)
    Traffic.new(url: "https://flagship.example", latest_created: latest_created,
      targets: targets.map { |t| Traffic::Target.new(revision: t[0], percent: t[1], tag: t[2], uri: t[3]) })
  end

  test "the canary URL is offered while the canary waits or runs" do
    waiting = traffic([ [ "flagship-00001-aaa", 100, "stable", nil ], [ "flagship-00002-bbb", 0, "canary", "https://canary---x" ] ],
      latest_created: "flagship-00002-bbb")
    assert_equal "https://canary---x", waiting.canary_url
    assert_equal "flagship-00001-aaa", waiting.main_revision
  end

  test "no canary URL once the canary is the main revision" do
    promoted = traffic([ [ "flagship-00002-bbb", 100, "canary", "https://canary---x" ] ], latest_created: "flagship-00002-bbb")
    assert_nil promoted.canary_url
  end

  test "no canary URL when the tag was left on an older revision" do
    # After a promote, a flag change made a newer revision; the old canary tag would show stale code.
    stale = traffic([ [ "flagship-00004-new", 100, nil, nil ], [ "flagship-00004-old", 0, "canary", "https://canary---x" ] ],
      latest_created: "flagship-00004-new")
    assert_nil stale.canary_url
  end

  test "revision labels keep the suffix, since numbers can repeat" do
    assert_equal "rev 4-kzn", Board.revision_label("flagship-00004-kzn")
    assert_equal "local", Board.revision_label("local")
  end
end
