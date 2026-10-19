require "test_helper"

class BoardStoreTest < ActiveSupport::TestCase
  test "keeps the newest runs first and drops the oldest" do
    store = BoardStore.current
    ids = Array.new(BoardStore::KEEP_RUNS + 2) { sample_run.tap { |run| store.add_run(run) }["id"] }

    runs = store.read["runs"]
    assert_equal BoardStore::KEEP_RUNS, runs.size
    assert_equal ids.last, runs.first["id"]
  end

  # Production uses Firestore; the tests don't, so check the client library is at least loaded.
  test "the Firestore client is loaded" do
    assert defined?(Google::Cloud::Firestore), "Gemfile must require google/cloud/firestore"
  end

  test "update merges fields without touching runs" do
    store = BoardStore.current
    store.add_run(sample_run)
    store.update("demo_until" => 30.minutes.from_now)

    data = store.read
    assert_equal 1, data["runs"].size
    assert data["demo_until"]
  end
end
