module Admin
  # The admin's page of accounts: who is an admin, and removing an account.
  # An admin cannot change or delete their own account here, so there is always one admin left.
  class UsersController < ApplicationController
    include Paginated

    before_action :require_admin!
    before_action :set_user, only: [:update, :destroy]

    def index
      @users = paginate(User.order(:email), per: 30)
      @logs = WorkoutLog.where(user_id: @users.map(&:id)).group(:user_id).count
    end

    # Makes the user an admin, or a regular user again.
    def update
      @user.update!(admin: params[:admin] == "true")
      redirect_to admin_users_path, status: :see_other,
                                    notice: "#{@user.email} is #{@user.admin? ? 'now an admin' : 'no longer an admin'}."
    end

    def destroy
      @user.destroy!
      redirect_to admin_users_path, status: :see_other,
                                    notice: "#{@user.email} and everything they recorded were deleted."
    end

    private

    def set_user
      @user = User.find(params[:id])
      return unless @user == current_user

      redirect_to admin_users_path, status: :see_other,
                                    alert: "You cannot change your own account here. Use Account settings."
    end
  end
end
