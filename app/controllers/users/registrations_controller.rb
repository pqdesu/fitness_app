module Users
  # Devise's account page, with one rule added: the only admin cannot cancel their account,
  # because nobody would be left to manage the catalogue and the users.
  class RegistrationsController < Devise::RegistrationsController
    before_action :permit_settings, only: [:update]

    def destroy
      return super unless current_user.last_admin?

      redirect_to edit_user_registration_path,
                  status: :see_other,
                  alert: "You are the only admin. Make someone else an admin before cancelling your account."
    end

    private

    # The account's one setting besides email and password: whether the workout timer starts on its own.
    def permit_settings
      devise_parameter_sanitizer.permit(:account_update, keys: [:timer_auto_start])
    end
  end
end
