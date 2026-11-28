require "test_helper"

# application.scss compiles only the Font Awesome icons it lists; an icon a view names that is not
# on the list would show blank. This reads the list and every name the app uses.
class IconsTest < ActiveSupport::TestCase
  STYLE_CLASSES = %w[solid regular brands fw spin pulse lg xs sm 2x 3x].freeze

  def listed
    scss = Rails.root.join("app/assets/stylesheets/application.scss").read
    scss[/\$fa-used-icons:\s*\((.*?)\);/m, 1].scan(/"([a-z0-9-]+)"/).flatten
  end

  def used
    files = Dir[Rails.root.join("app/{views,helpers,javascript}/**/*.{erb,rb,js}")]
    files.flat_map do |file|
      text = File.read(file)
      text.scan(/\bfa-([a-z][a-z0-9-]*)/).flatten +
        text.scan(/icon_tag[ (]+"([a-z0-9-]+)"/).flatten +
        text.scan(/\bicon: "(?:fa-)?([a-z0-9-]+)"/).flatten
    end + nav_icons - STYLE_CLASSES
  end

  # nav_sections lists [label, path, icon, active] rows.
  def nav_icons
    Rails.root.join("app/helpers/application_helper.rb").read.scan(/\["[A-Za-z]+", \w+_path, "([a-z-]+)"/).flatten
  end

  test "every icon the app uses is in the compiled subset" do
    assert_operator used.uniq.size, :>, 20
    assert_empty used.uniq - listed
  end

  test "the subset has no icon the app does not use" do
    assert_empty listed - used.uniq
  end
end
