require "test_helper"

class LiftsHelperTest < ActionView::TestCase
  test "a heavy weight is read with thousands separated, fields keep it plain" do
    assert_equal "1,234.125 kg", format_weight(1234.125, plain: true)
    assert_includes format_weight(1234.125), "1,234.125"
    assert_equal "80 kg", format_weight(80, plain: true)
    assert_equal "1.125 kg", format_weight(1.125, plain: true)
    assert_equal "1234.125", weight_number(1234.125)
    assert_equal "1,234", weight_text(1234)
    assert_equal "-1,234.5", weight_text(-1234.5) # the sign stays (an assisted bodyweight set)
    assert_equal "99,999.125", weight_text(99_999.125)
  end
end
