require "test_helper"

class UserTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "lifter@example.com", password: "secret123")
  end

  test "the current split is the active one, or the oldest split until one is chosen" do
    assert_nil @user.current_split

    ppl = @user.splits.create!(name: "PPL")
    upper_lower = @user.splits.create!(name: "Upper lower")
    assert_equal ppl, @user.current_split
    assert ppl.active?
    assert_not upper_lower.active?

    @user.update!(active_split: upper_lower)
    assert_equal upper_lower, @user.current_split
    assert upper_lower.reload.active?
    assert_not ppl.reload.active?
  end

  test "deleting the active split clears the choice" do
    ppl = @user.splits.create!(name: "PPL")
    upper_lower = @user.splits.create!(name: "Upper lower")
    @user.update!(active_split: upper_lower)

    upper_lower.destroy
    assert_nil @user.reload.active_split
    assert_equal ppl, @user.current_split
  end

  test "the active split must be one of the user's own" do
    other = User.create!(email: "other@example.com", password: "secret123")
    @user.active_split = other.splits.create!(name: "Not mine")
    assert_not @user.valid?
    assert_includes @user.errors[:active_split], "must be one of your splits"
  end
end
