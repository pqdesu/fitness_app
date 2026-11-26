require "test_helper"

class PreferencesFlowTest < FlowTest
  test "the account page saves the two preferences without the password" do
    sign_in @user
    get edit_user_registration_path
    assert_select "form[action='/preferences'][data-controller=row-edit]" do
      assert_select "input[type=checkbox][name='user[auto_warm_up]'][data-action='change->row-edit#save']", 1
      assert_select "input[type=checkbox][name='user[timer_auto_start]'][data-action='change->row-edit#save']", 1
      assert_select "button[type=submit]", 1
    end
    assert_select "form[action='/users'] input[type=checkbox]", 0
    assert_select "input[name='user[auto_warm_up]'][type=checkbox]", 1
    assert_select "input[name='user[timer_auto_start]'][type=checkbox]", 1
    assert_select ".is-valid", 0

    %i[auto_warm_up timer_auto_start].each do |setting|
      patch preferences_path, params: { user: { setting => "1" } }
      assert_redirected_to edit_user_registration_path
      assert_equal "Saved.", flash[:notice]
      assert @user.reload.public_send(setting)

      patch preferences_path, params: { user: { setting => "0" } }
      assert_not @user.reload.public_send(setting)
    end
  end

  test "a failed sign-in shows no green check" do
    post user_session_path, params: { user: { email: @user.email, password: "wrong-password" } }
    follow_redirect! if response.redirect?
    assert_select ".is-valid", 0
  end

  test "preferences need a signed-in user" do
    patch preferences_path, params: { user: { auto_warm_up: "1" } }
    assert_response :redirect
    assert_not @user.reload.auto_warm_up?
  end
end
