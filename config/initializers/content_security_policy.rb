# Be sure to restart your server when you modify this file.

# What the browser may load on the app's pages: the app's own files, the two Google Fonts hosts
# the stylesheet imports its fonts from (config/_fonts.scss), and nothing else. Scripts run only
# from the app, with a nonce for the inline import map. Bootstrap's icons (the close button, the
# navbar toggler, the select arrow) are data: images in its CSS.
# See https://guides.rubyonrails.org/security.html#content-security-policy-header

Rails.application.configure do
  config.content_security_policy do |policy|
    policy.default_src :self
    policy.font_src    :self, :data, "https://fonts.gstatic.com"
    policy.style_src   :self, "https://fonts.googleapis.com"
    policy.img_src     :self, :data
    policy.script_src  :self
    policy.object_src  :none
    policy.base_uri    :self
    policy.form_action :self
    # Only the app may show its own pages in a frame; no other site can.
    policy.frame_ancestors :self
  end

  # A nonce for the inline import map (javascript_importmap_tags) and for the style Turbo adds for
  # its progress bar. It follows the session, so pages Turbo keeps in its cache stay valid.
  config.content_security_policy_nonce_generator = ->(request) { request.session.id.to_s.presence || SecureRandom.base64(16) }
  config.content_security_policy_nonce_directives = %w[script-src style-src]
end
