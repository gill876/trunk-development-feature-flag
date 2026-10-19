# The board as a JSON file, for running everything on your laptop and in tests.
class BoardStore::LocalFile
  def initialize(path)
    @path = Pathname(path)
  end

  def read
    @path.exist? ? JSON.parse(@path.read) : {}
  end

  def add_run(run)
    change { |data| data.merge("runs" => [ run.as_json, *data["runs"] ].first(BoardStore::KEEP_RUNS)) }
  end

  def update(fields)
    change { |data| data.merge(fields.as_json) }
  end

  private
    def change
      @path.dirname.mkpath
      File.open(@path, File::RDWR | File::CREAT) do |file|
        file.flock(File::LOCK_EX)
        data = file.size.zero? ? {} : JSON.parse(file.read)
        file.rewind
        file.write(JSON.pretty_generate(yield(data)))
        file.flush
        file.truncate(file.pos)
      end
    end
end
