require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  test "short_date is the weekday, day and month, with the year only when it is not this year" do
    travel_to Time.zone.local(2026, 11, 26, 12) do
      assert_equal "Wed 18 Nov", short_date(Date.new(2026, 11, 18))
      assert_equal "Mon 5 Jan", short_date(Date.new(2026, 1, 5))
      assert_equal "Thu 25 Dec 2025", short_date(Date.new(2025, 12, 25))
    end
  end
end
