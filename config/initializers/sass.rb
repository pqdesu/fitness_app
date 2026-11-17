# Bootstrap 5.3 and Font Awesome are written in the Sass syntax Dart Sass now warns about
# (@import, global functions). The warnings are theirs to fix, so they are kept out of the logs.
Rails.application.config.sass.quiet_deps = true
Rails.application.config.sass.silence_deprecations = %w[import global-builtin color-functions if-function]
