require "test_helper"

# Tests for lib/backport. They don't read the app's credentials: CI has no master key
# (this is a public repo), so the encrypted file can't be decrypted there.
class BackportTest < ActiveSupport::TestCase
  test "Rails 8.2 ships Rails.app.creds: when this fails, delete lib/backport/" do
    assert Rails.gem_version < Gem::Version.new("8.2.0.alpha"),
      "Rails #{Rails.version} has Rails.app.creds. Delete lib/backport/ and its require in config/application.rb."
  end

  test "Rails.app.creds asks the request override, then ENV, then credentials" do
    layers = Rails.app.creds.instance_variable_get(:@configurations).map(&:class)
    assert_equal [ FeatureOverrideConfiguration, ActiveSupport::EnvConfiguration, ActiveSupport::EncryptedConfiguration ], layers

    with_env("FEATURES__ORANGE_BUTTON" => "true") do
      Rails.app.envs.reload
      assert_equal "true", Rails.app.creds.option(:features, :orange_button), "ENV is asked before credentials"

      FeatureFlags.with(:orange_button, false) do
        assert_equal false, Rails.app.creds.option(:features, :orange_button), "the request override beats ENV"
      end
    end
  ensure
    Rails.app.envs.reload
  end

  test "encrypted credentials gained option and require" do
    Dir.mktmpdir do |dir|
      File.write("#{dir}/test.key", ActiveSupport::EncryptedConfiguration.generate_key)
      credentials = ActiveSupport::EncryptedConfiguration.new(config_path: "#{dir}/credentials.yml.enc",
        key_path: "#{dir}/test.key", env_key: "BACKPORT_TEST_KEY", raise_if_missing_key: true)
      credentials.write("features:\n  orange_button: false\n")

      assert_equal false, credentials.option(:features, :orange_button)
      assert_equal "fallback", credentials.option(:missing, default: "fallback")
      assert_equal "lazy", credentials.option(:missing, default: -> { "lazy" })
      assert_raises(KeyError) { credentials.require(:missing) }
    end
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
