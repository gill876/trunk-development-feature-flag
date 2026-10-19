require "test_helper"

class BackportTest < ActiveSupport::TestCase
  test "Rails 8.2 ships Rails.app.creds: when this fails, delete lib/backport/" do
    assert Rails.gem_version < Gem::Version.new("8.2.0.alpha"),
      "Rails #{Rails.version} has Rails.app.creds. Delete lib/backport/ and its require in config/application.rb."
  end

  test "Rails.app.creds asks the request override, then ENV, then credentials" do
    creds = Rails.app.creds
    assert_kind_of ActiveSupport::CombinedConfiguration, creds
    assert_equal false, creds.option(:features, :orange_button)

    with_env("FEATURES__ORANGE_BUTTON" => "true") do
      Rails.app.envs.reload
      assert_equal "true", creds.option(:features, :orange_button), "ENV beats credentials"

      FeatureFlags.with(:orange_button, false) do
        assert_equal false, creds.option(:features, :orange_button), "the request override beats ENV"
      end
    end
  ensure
    Rails.app.envs.reload
  end

  test "credentials gained option and require" do
    assert_equal false, Rails.app.credentials.option(:features, :orange_button)
    assert_equal "fallback", Rails.app.credentials.option(:missing, default: "fallback")
    assert_raises(KeyError) { Rails.app.credentials.require(:missing) }
  end

  test "ENV keys are upcased and joined with double underscores" do
    with_env("FEATURES__SOME_FLAG" => "on") do
      Rails.app.envs.reload
      assert_equal "on", Rails.app.envs.option(:features, :some_flag)
    end
  ensure
    Rails.app.envs.reload
  end
end
