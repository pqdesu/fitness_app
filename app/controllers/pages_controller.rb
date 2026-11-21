class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # Signed out it is the landing page; signed in, the Today page: the dashboard's Today box and
  # this week's moves, on their own. Opening the app opens it.
  def home
    return unless user_signed_in?

    @dashboard = Dashboard.new(current_user, Date.current)
    render :today
  end

  # The dashboard (see Dashboard): the month, this week, today's workout and recent workouts.
  def dashboard
    @dashboard = Dashboard.new(current_user, Date.current)
  end
end
