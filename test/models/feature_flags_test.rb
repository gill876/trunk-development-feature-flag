require "test_helper"

class FeatureFlagsTest < ActiveSupport::TestCase
  USERS = (1..6).map { |n| Visitor.for(format("user-%02d", n)) }

  test "off by default: credentials say orange_button: false" do
    assert_not FeatureFlags.enabled_for?(:orange_button, Visitor.for("dev-01"))
    assert_equal "no rule matched", FeatureFlags.reason_for(:orange_button, Visitor.for("dev-01"))
  end

  test "segments from ENV arrive as a comma-separated string" do
    with_flags("FEATURES__ORANGE_BUTTON_SEGMENTS" => "dev, alpha") do
      assert FeatureFlags.enabled_for?(:orange_button, Visitor.for("dev-01"))
      assert FeatureFlags.enabled_for?(:orange_button, Visitor.for("alpha-02"))
      assert_not FeatureFlags.enabled_for?(:orange_button, Visitor.for("beta-01"))
      assert_equal "segment alpha", FeatureFlags.reason_for(:orange_button, Visitor.for("alpha-02"))
    end
  end

  test "a percentage rollout picks the same users every time" do
    with_flags("FEATURES__ORANGE_BUTTON_PERCENTAGE" => "25") do
      first = USERS.map { |user| FeatureFlags.enabled_for?(:orange_button, user) }
      assert_equal first, USERS.map { |user| FeatureFlags.enabled_for?(:orange_button, user) }
      assert_equal USERS.map { |user| FeatureFlags.bucket(:orange_button, user) < 25 }, first
    end
  end

  test "0% is nobody and 100% is everyone" do
    with_flags("FEATURES__ORANGE_BUTTON_PERCENTAGE" => "0") do
      assert USERS.none? { |user| FeatureFlags.enabled_for?(:orange_button, user) }
    end
    with_flags("FEATURES__ORANGE_BUTTON_PERCENTAGE" => "100") do
      assert USERS.all? { |user| FeatureFlags.enabled_for?(:orange_button, user) }
    end
  end

  test "once a percentage is set, the on/off switch is ignored" do
    with_flags("FEATURES__ORANGE_BUTTON" => "true", "FEATURES__ORANGE_BUTTON_PERCENTAGE" => "0") do
      assert FeatureFlags.enabled?(:orange_button)
      assert_not FeatureFlags.enabled_for?(:orange_button, USERS.first)
    end
  end

  test "segments are checked before the percentage" do
    with_flags("FEATURES__ORANGE_BUTTON_SEGMENTS" => "beta", "FEATURES__ORANGE_BUTTON_PERCENTAGE" => "0") do
      assert FeatureFlags.enabled_for?(:orange_button, Visitor.for("beta-03"))
    end
  end

  test "the allowlist matches a user id" do
    with_flags("FEATURES__ORANGE_BUTTON_USERS" => "user-03") do
      assert FeatureFlags.enabled_for?(:orange_button, Visitor.for("user-03"))
      assert_not FeatureFlags.enabled_for?(:orange_button, Visitor.for("user-04"))
      assert_equal "allowlisted", FeatureFlags.reason_for(:orange_button, Visitor.for("user-03"))
    end
  end

  test "the kill switch: false for everyone once the targeting vars are gone" do
    with_flags("FEATURES__ORANGE_BUTTON" => "false") do
      assert_not FeatureFlags.enabled_for?(:orange_button, Visitor.for("dev-01"))
    end
  end

  test "with overrides a flag for a block, above ENV, then restores it" do
    with_flags("FEATURES__ORANGE_BUTTON" => "false") do
      FeatureFlags.with(:orange_button, true) do
        assert FeatureFlags.enabled?(:orange_button)
      end
      assert_not FeatureFlags.enabled?(:orange_button)
    end
  end

  test "buckets run from 0 to 99" do
    buckets = (1..300).map { |n| FeatureFlags.bucket(:orange_button, Visitor.for("guest-#{format('%08x', n)}")) }
    assert buckets.all? { |b| (0..99).cover?(b) }
    assert buckets.uniq.size > 50
  end

  private
    # Rails.app.envs reads ENV once and caches it, like a process that has already booted.
    # Reload it so the test sees the change, the way a new Cloud Run revision would.
    def with_flags(vars)
      with_env(vars) do
        Rails.app.envs.reload
        yield
      end
    ensure
      Rails.app.envs.reload
    end
end
