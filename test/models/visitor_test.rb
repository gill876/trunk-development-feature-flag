require "test_helper"

class VisitorTest < ActiveSupport::TestCase
  test "the cohort comes from the handle's prefix" do
    assert_equal "dev", Visitor.for("dev-01").cohort
    assert_equal "beta", Visitor.for("beta-03").cohort
    assert_equal "user", Visitor.for("user-06").cohort
    assert Visitor.for("alpha-02").alpha?
    assert_not Visitor.for("user-01").beta?
  end

  test "guests are regular users" do
    guest = Visitor.for("guest-0a1b2c3d")
    assert_equal "user", guest.cohort
    assert_not guest.dev?
  end

  test "only known handle shapes are accepted" do
    assert Visitor.valid?("beta-02")
    assert Visitor.valid?("guest-0a1b2c3d")
    assert_not Visitor.valid?("admin-01")
    assert_not Visitor.valid?("beta-2")
    assert_not Visitor.valid?(nil)
  end
end
