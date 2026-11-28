class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  around_action :use_browser_time_zone

  # Two requests at the same moment (a double tap) can both pass a "once only" check; the
  # database's unique index then refuses the second one.
  rescue_from ActiveRecord::RecordNotUnique do
    redirect_back fallback_location: root_path, alert: "That was already saved, so nothing was added twice.", status: :see_other
  end

  helper_method :from_dashboard?, :errors_of

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

  def require_admin!(back: root_path, message: "Only an admin can do that.")
    return if current_user.admin?

    redirect_to back, alert: message
  end

  # The page was opened from the Home page (its links add from=dashboard), so it goes back there.
  def from_dashboard?
    params[:from] == "dashboard"
  end

  # A logged workout's page after a change made on it. Its forms post without from=, so the page they
  # came from (the referer) tells whether it was opened from Home; keeping from=dashboard keeps its
  # back button and Delete returning Home.
  def workout_log_page(log, **)
    workout_log_path(log, from: ("dashboard" if from_dashboard? || referer_from_dashboard?), **)
  end

  def referer_from_dashboard?
    Rack::Utils.parse_query(URI(request.referer.to_s).query)["from"] == "dashboard"
  rescue URI::InvalidURIError
    false
  end

  # A query parameter read as text. A client can send page[]=1 or page[a]=1, which Rails turns
  # into an Array or a Hash; those are treated as if the parameter was not sent.
  def text_param(key)
    value = params[key]
    value if value.is_a?(String)
  end

  # One message per field, so a blank field is not also called too short: "Name can't be blank".
  def errors_of(record)
    record.errors.group_by(&:attribute).values.map { |errors| errors.first.full_message }.to_sentence
  end
end
