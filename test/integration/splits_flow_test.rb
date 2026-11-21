require "test_helper"

# Splits: the week of a split and the active split.
class SplitsFlowTest < FlowTest
  test "a split is a week, Sunday to Saturday" do
    sign_in @user
    get new_split_path
    assert_response :success
    post splits_path, params: { split: { name: "" } }
    assert_response :unprocessable_content
    post splits_path, params: { split: { name: "PPL" } }
    # Not @user.splits.last: the signed-in user is this same object, and the rejected
    # split above is still sitting unsaved in its association.
    split = Split.order(:id).last
    assert_equal @user, split.user
    assert_redirected_to split

    # an empty week: seven blank circles, each starting a workout day on its weekday
    get split_path(split)
    assert_select ".week .week-day", 7
    assert_select ".week .week-day.is-set", 0
    assert_equal %w[S M T W T F S], css_select(".week .week-circle").map(&:text)
    assert_select ".week a[href=?]", new_split_workout_day_path(split, weekday: 1)

    get new_split_workout_day_path(split, weekday: 1)
    assert_select "select[name='workout_day[weekday]'] option[selected]", text: "Monday"
    # the workout is chosen from the list, not typed
    assert_equal ["Choose a workout", *WorkoutDay::NAMES], css_select("select[name='workout_day[day]'] option").map(&:text)
    post split_workout_days_path(split), params: { workout_day: { day: "Chest day", weekday: 1 } }
    assert_response :unprocessable_content
    post split_workout_days_path(split), params: { workout_day: { day: "Push", weekday: 1 } }
    day = split.workout_days.last
    assert_redirected_to split_path(split, anchor: "day-#{day.id}")
    assert_equal "Monday", day.weekday_name

    # one workout per weekday
    post split_workout_days_path(split), params: { workout_day: { day: "Pull", weekday: 1 } }
    assert_response :unprocessable_content
    post split_workout_days_path(split), params: { workout_day: { day: "Pull" } }
    assert_response :unprocessable_content
    assert_equal 1, split.workout_days.count

    # Monday is now coloured and goes to that day's plan; the next free weekday is offered for a new day
    get split_path(split)
    assert_select ".week .week-day.is-set", 1
    assert_select ".week a.is-set[href=?]", split_path(split, anchor: "day-#{day.id}")
    assert_select "#day-#{day.id} h2", "Push"
    # the split's and each day's edit and delete are in a ⋯ menu; deleting is an × and asks first
    assert_select ".page-header .actions-menu a[href=?]", edit_split_path(split), text: /Rename/
    assert_select ".page-header .actions-menu form.button_to[action=?][data-turbo-confirm] .fa-xmark", split_path(split)
    assert_select "#day-#{day.id} .actions-menu a[href=?]", edit_workout_day_path(day), text: /Edit/
    assert_select "#day-#{day.id} .actions-menu form.button_to[action=?][data-turbo-confirm] .fa-xmark", workout_day_path(day)
    assert_select ".week a.is-set .week-label", "Push"
    get new_split_workout_day_path(split)
    assert_select "select[name='workout_day[weekday]'] option[selected]", text: "Sunday"

    get edit_workout_day_path(day)
    assert_response :success
    patch workout_day_path(day), params: { workout_day: { weekday: 5 } }
    assert_equal "Friday", day.reload.weekday_name
    get edit_split_path(split)
    assert_response :success

    [splits_path, root_path].each do |path|
      get path
      assert_response :success, "#{path} failed"
    end

    delete workout_day_path(day)
    assert_redirected_to split
    delete split_path(split)
    assert_equal 0, @user.splits.count
  end

  test "one split is active, is ringed on the splits page and shown on the dashboard" do
    sign_in @user
    get dashboard_path
    assert_select ".split-card .empty-state a[href=?]", new_split_path

    ppl = @user.splits.create!(name: "PPL")
    upper_lower = @user.splits.create!(name: "Upper lower")
    upper_lower.workout_days.create!(day: "Upper", weekday: 2)

    # until one is chosen, the oldest split is the active one
    get splits_path
    assert_select ".split-card", 2
    assert_select ".split-card.is-active", 1
    assert_select ".split-card.is-active h2", "PPL"
    assert_select ".split-card.is-active .split-active-badge", /Active/
    assert_select ".split-card.is-active form", 0
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(upper_lower)

    # changed on the splits page: the user stays there
    patch activate_split_path(upper_lower), headers: { "HTTP_REFERER" => splits_url }
    assert_redirected_to splits_url
    assert_equal upper_lower, @user.reload.active_split
    follow_redirect!
    assert_select ".split-card.is-active h2", "Upper lower"
    assert_select ".back-link", 0
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(ppl)

    # the split page says whether it is active, and offers the change if not
    get split_path(upper_lower)
    assert_select ".header-actions .split-active-badge", /Active split/
    get split_path(ppl)
    assert_select ".header-actions form[action=?]", activate_split_path(ppl)

    # the dashboard shows the active split and its week
    get dashboard_path
    assert_select ".split-card.is-active h2", "Upper lower"
    assert_select ".split-card.is-active .week a.is-set .week-label", "Upper"
    assert_select ".split-card.is-active a[href=?]", splits_path(from: "dashboard"), text: "Change"

    # changed from the dashboard: "Change" opens the splits, and choosing one returns to the dashboard
    get splits_path(from: "dashboard")
    assert_select ".back-link[href=?]", dashboard_path
    assert_select ".split-card:not(.is-active) form[action=?]", activate_split_path(ppl, from: "dashboard")
    patch activate_split_path(ppl, from: "dashboard"), headers: { "HTTP_REFERER" => splits_url(from: "dashboard") }
    assert_redirected_to dashboard_path
    follow_redirect!
    assert_select ".split-card.is-active h2", "PPL"
    patch activate_split_path(upper_lower)

    # someone else's split cannot be activated
    others = @admin.splits.create!(name: "Not mine")
    patch activate_split_path(others)
    assert_response :not_found
    assert_equal upper_lower, @user.reload.active_split
  end
end
