# The board as one Firestore document, flagship/board:
#   runs:       the newest KEEP_RUNS bot runs, newest first
#   demo_until: when demo mode switches itself off
class BoardStore::Firestore
  def initialize(project: ENV.fetch("GOOGLE_CLOUD_PROJECT"))
    @client = Google::Cloud::Firestore.new(project_id: project)
    @doc = @client.doc("flagship/board")
  end

  def read
    snapshot = @doc.get
    snapshot.exists? ? JSON.parse(snapshot.data.to_json) : {}
  end

  # A transaction, so two runs finishing at once can't drop each other.
  def add_run(run)
    @client.transaction do |tx|
      runs = tx.get(@doc).data&.dig(:runs) || []
      tx.set(@doc, { runs: [ run, *runs ].first(BoardStore::KEEP_RUNS), updated_at: Time.current }, merge: true)
    end
  end

  def update(fields)
    @doc.set(fields, merge: true)
  end
end
