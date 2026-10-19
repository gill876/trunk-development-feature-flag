# Where bot runs are kept: one Firestore document in production, a JSON file locally.
# Either way the dashboard reads a single document per refresh.
module BoardStore
  KEEP_RUNS = 15

  def self.current
    @current ||= ENV["BOARD_STORE"] == "firestore" ? Firestore.new : LocalFile.new(Rails.root.join("tmp/board.json"))
  end

  def self.current=(store)
    @current = store
  end
end
