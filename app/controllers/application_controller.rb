class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  around_action :use_browser_time_zone

  private

  # Dates and times follow the clock of whoever is using the app: the browser reports its
  # time zone in a cookie (see app/javascript/time_zone.js), so "today" is the user's today.
  def use_browser_time_zone(&block)
    Time.use_zone(browser_time_zone, &block)
  end

  def browser_time_zone
    ActiveSupport::TimeZone[cookies[:time_zone].to_s] || Time.zone_default
  end

  def require_admin!
    return if current_user.admin?

    redirect_to exercises_path, alert: "Only an admin can manage the exercise catalogue."
  end
end
