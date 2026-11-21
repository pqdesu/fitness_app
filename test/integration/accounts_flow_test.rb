require "test_helper"

# Signing in, the account pages, what belongs to whom, and the admin's users page.
class AccountsFlowTest < FlowTest
  test "signed-out visitors see the landing page and are sent to login elsewhere" do
    get root_path
    assert_response :success
    assert_select "h1", /Plan your training/
    # the heading opens the page, with no icon tile above it
    assert_select ".hero .brand-mark", 0

    get splits_path
    assert_redirected_to new_user_session_path
  end

  test "devise pages render, each titled by its h1" do
    { new_user_session_path => "Log in", new_user_registration_path => "Sign up",
      new_user_password_path => "Forgot your password?" }.each do |path, title|
      get path
      assert_response :success
      assert_select "h1", title
    end
    sign_in @user
    get edit_user_registration_path
    assert_response :success
    assert_select "h1", "Account"
    assert_select "h2", "Cancel my account"
  end

  test "users cannot reach another user's records" do
    split = @admin.splits.create!(name: "Private")
    day = split.workout_days.create!(day: "Legs", weekday: 2)
    planned = day.workout_exercises.create!(exercise: @bench)
    log = day.workout_logs.create!(date: Date.current)
    entry = log.workout_log_exercises.create!(workout_exercise: planned)
    admins_own = Exercise.create!(name: "Secret lift", user: @admin)

    [split_path(split), workout_day_path(day), workout_exercise_path(planned), workout_log_path(log),
     edit_workout_log_exercise_path(entry), edit_exercise_path(admins_own), edit_exercise_path(@bench)].each do |path|
      sign_in @user # a 404 does not persist the test session, so sign in before each request
      get path
      assert_response :not_found, "#{path} was reachable"
    end

    requests = [
      -> { post workout_log_exercise_workout_sets_path(entry), params: { workout_set: { reps_completed: 8 } } },
      -> { post workout_exercise_workout_sets_path(planned), params: { workout_set: { reps_completed: 8 } } },
      -> { post workout_day_workout_exercises_path(day), params: { exercise_ids: [@bench.id] } },
      -> { post workout_log_workout_log_exercises_path(log), params: { exercise_ids: [@bench.id] } },
      -> { patch workout_exercise_path(planned), params: { workout_exercise: { equipment: "machine", machine_brand: "X" } } },
      -> { patch workout_log_exercise_path(entry), params: { workout_log_exercise: { equipment: "machine", machine_brand: "X" } } },
      -> { delete exercise_path(admins_own) }
    ]
    requests.each_with_index do |request, index|
      sign_in @user
      request.call
      assert_response :not_found, "request #{index} was allowed"
    end

    assert_equal 0, entry.workout_sets.count
    assert_equal 1, day.workout_exercises.count
    assert_equal 1, log.workout_log_exercises.count
    assert_equal "free_weights", planned.reload.equipment
    assert Exercise.exists?(admins_own.id)
  end

  test "an admin manages the users" do
    # only an admin reaches the page or its actions
    sign_in @user
    get root_path
    assert_select "a[href=?]", admin_users_path, count: 0
    get admin_users_path
    assert_redirected_to root_path
    assert_match "Only an admin can do that", flash[:alert]
    patch admin_user_path(@user), params: { admin: "true" }
    assert_not @user.reload.admin?
    delete admin_user_path(@admin)
    assert User.exists?(@admin.id)

    sign_in @admin
    get root_path
    assert_select ".dropdown-menu a[href=?]", admin_users_path, text: "Users"
    get admin_users_path
    assert_response :success
    assert_select "a.back-link", false
    assert_select "td", text: /lifter@example.com/
    assert_select "td", text: /admin@example.com.*Admin.*You/m
    # the admin's own row has no actions
    assert_select "form[action=?]", admin_user_path(@admin), count: 0
    assert_select "form[action=?]", admin_user_path(@user), count: 2

    patch admin_user_path(@user), params: { admin: "true" }
    assert_redirected_to admin_users_path
    assert @user.reload.admin?
    patch admin_user_path(@user), params: { admin: "false" }
    assert_not @user.reload.admin?

    # an admin cannot demote or delete themselves, so one admin always remains
    patch admin_user_path(@admin), params: { admin: "false" }
    assert_match "cannot change your own account", flash[:alert]
    assert @admin.reload.admin?
    delete admin_user_path(@admin)
    assert User.exists?(@admin.id)

    # deleting a user removes everything they recorded, and nothing of the shared catalogue
    day = @user.splits.create!(name: "PPL").workout_days.create!(day: "Push", weekday: 1)
    @user.update!(active_split: day.split)
    own = Exercise.create!(name: "Cable fly", user: @user)
    [@bench, own].each do |exercise|
      day.workout_exercises.create!(exercise: exercise).entry_on!(Date.current).workout_sets.create!(reps_completed: 8)
    end
    delete admin_user_path(@user)
    assert_redirected_to admin_users_path
    assert_not User.exists?(@user.id)
    assert_equal [0, 0, 0, 0], [Split.count, WorkoutLog.count, WorkoutSet.count, Exercise.where(name: "Cable fly").count]
    assert Exercise.exists?(@bench.id)
  end

  test "signing up cannot grant admin" do
    post user_registration_path, params: { user: { email: "new@example.com", password: "secret123", password_confirmation: "secret123", admin: true } }
    assert_not User.find_by!(email: "new@example.com").admin?
  end

  test "the only admin cannot cancel their account" do
    sign_in @admin
    get edit_user_registration_path
    assert_select "form[action=?] button", user_registration_path, text: "Cancel my account", count: 0
    assert_select "p", /You are the only admin/
    delete user_registration_path
    assert_redirected_to edit_user_registration_path
    assert_match "You are the only admin", flash[:alert]
    assert User.exists?(@admin.id)

    # with a second admin there is one left, so the account can go
    @user.update!(admin: true)
    get edit_user_registration_path
    assert_select "form[action=?] button", user_registration_path, text: "Cancel my account"
    delete user_registration_path
    assert_not User.exists?(@admin.id)
  end

  test "a regular user can cancel their account" do
    sign_in @user
    get edit_user_registration_path
    assert_select "form[action=?] button", user_registration_path, text: "Cancel my account"
    delete user_registration_path
    assert_not User.exists?(@user.id)
  end

  test "an account is locked after ten wrong passwords" do
    10.times { post user_session_path, params: { user: { email: @user.email, password: "wrong-password" } } }
    assert @user.reload.access_locked?

    # the right password does not get in while the account is locked
    post user_session_path, params: { user: { email: @user.email, password: "secret123" } }
    get splits_path
    assert_redirected_to new_user_session_path

    # the lock ends by itself
    travel 16.minutes do
      post user_session_path, params: { user: { email: @user.email, password: "secret123" } }
      get splits_path
      assert_response :success
    end
  end

  test "a password has at least eight characters, and a reset does not say whether the email exists" do
    post user_registration_path, params: { user: { email: "new@example.com", password: "short12", password_confirmation: "short12" } }
    assert_response :unprocessable_content
    assert_not User.exists?(email: "new@example.com")

    known = post(user_password_path, params: { user: { email: @user.email } }) && [response.location, flash[:notice]]
    unknown = post(user_password_path, params: { user: { email: "nobody@example.com" } }) && [response.location, flash[:notice]]
    assert_equal known, unknown
  end

  test "pages are sent with a content security policy" do
    get root_path
    policy = response.headers["Content-Security-Policy"]
    assert_match "default-src 'self'", policy
    assert_match(/script-src 'self' 'nonce-/, policy)
    assert_match "frame-ancestors 'self'", policy
  end
end
