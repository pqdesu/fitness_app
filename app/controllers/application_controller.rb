class ApplicationController < ActionController::Base
  before_action :authenticate_user!

  private

  def require_admin!
    return if current_user.admin?

    redirect_to exercises_path, alert: "Only an admin can manage the exercise catalogue."
  end
end
