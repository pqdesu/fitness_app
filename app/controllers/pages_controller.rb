class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # Signed out it is the landing page; signed in, the dashboard (see Dashboard).
  def home
    @dashboard = Dashboard.new(current_user, Date.current) if user_signed_in?
  end
end
