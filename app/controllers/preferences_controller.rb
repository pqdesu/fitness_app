# The two account settings that need no password: saved straight from the Account page.
class PreferencesController < ApplicationController
  def update
    current_user.update!(params.expect(user: [:timer_auto_start, :auto_warm_up]))
    redirect_to edit_user_registration_path, notice: "Saved."
  end
end
