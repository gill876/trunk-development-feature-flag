ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

# API tests include this: assert_schema_conform(status) checks the request and the response
# against openapi/openapi.yaml, so the spec and the code can't drift apart.
module OpenApiContract
  include Committee::Rails::Test::Methods

  def committee_options
    @committee_options ||= { schema_path: Rails.root.join("openapi/openapi.yaml").to_s, strict_reference_validation: true }
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Each test gets its own board file, so tests never see each other's runs.
    setup do
      @board_path = Rails.root.join("tmp/test-boards/#{SecureRandom.hex(6)}.json")
      BoardStore.current = BoardStore::LocalFile.new(@board_path)
    end

    teardown { FileUtils.rm_f(@board_path) }

    def with_env(vars)
      previous = vars.keys.index_with { |key| ENV[key] }
      vars.each { |key, value| ENV[key] = value }
      yield
    ensure
      previous.each { |key, value| ENV[key] = value }
    end

    # A finished bot run, shaped like the ones BotSquad saves.
    def sample_run(color: "blue", revision: "flagship-00001-abc", traffic: [ { "revision" => "flagship-00001-abc", "percent" => 100 } ], overrides: {})
      visits = BotSquad::HANDLES.flat_map do |handle|
        Array.new(BotSquad::VISITS_PER_BOT) do
          { "bot" => handle, "cohort" => Visitor.for(handle).cohort, "target" => "main", "status" => 200,
            "color" => color, "revision" => revision, "version" => "abc1234", "ms" => 40 }.merge(overrides.fetch(handle, {}))
        end
      end
      { "id" => SecureRandom.hex(4), "at" => Time.current.iso8601, "trigger" => "test", "traffic" => traffic, "visits" => visits }
    end
  end
end
