module Users
  # Devise's account page, with one rule added: the only admin cannot cancel their account,
  # because nobody would be left to manage the catalogue and the users.
  class RegistrationsController < Devise::RegistrationsController
    def destroy
      return super unless current_user.last_admin?

      redirect_to edit_user_registration_path,
                  status: :see_other,
                  alert: "You are the only admin. Make someone else an admin before cancelling your account."
    end
  end
end
