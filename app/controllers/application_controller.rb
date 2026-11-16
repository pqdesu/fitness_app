class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  around_action :use_browser_time_zone

  private

  # Dates and times follow the clock of whoever is using the app: the browser reports its
  # time zone in a cookie (see app/javascript/time_zone.js), so "today" is the user's today.
  def use_browser_time_zone(&)
    Time.use_zone(browser_time_zone, &)
  end

  # The zone in the cookie is also saved on the user. A browser that has not reported one yet
  # (a new session, or one without JavaScript or cookies) starts from that saved zone, not UTC.
  def browser_time_zone
    reported = cookies[:time_zone].to_s
    zone = ActiveSupport::TimeZone[reported] if reported.present?

    if zone
      current_user.update_column(:time_zone, reported) if current_user && current_user.time_zone != reported
      zone
    else
      (ActiveSupport::TimeZone[current_user.time_zone] if current_user&.time_zone.present?) || Time.zone_default
    end
  end

  def require_admin!
    return if current_user.admin?

    redirect_to root_path, alert: "Only an admin can do that."
  end
end
