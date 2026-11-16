# The time zone the user's browser last reported, kept so a new browser session (or a browser
# without JavaScript or cookies) starts in the user's own zone instead of UTC.
class AddTimeZoneToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :time_zone, :string
  end
end
