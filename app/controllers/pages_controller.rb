class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home]

  # Signed out it is the landing page; signed in, the Home page (see Dashboard): today's workout,
  # this week, the month and recent workouts. Opening the app opens it.
  def home
    return unless user_signed_in?

    @dashboard = Dashboard.new(current_user, Date.current)
    render :dashboard
  end

  # What was done this month: the totals, each split's and each exercise's share.
  def month
    @dashboard = Dashboard.new(current_user, Date.current)
  end
end
