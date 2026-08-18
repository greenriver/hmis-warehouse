###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# app/assets/stylesheets/application.scss imports a generated file
# (bin/generate_sass_imports.js) that stands in for the glob imports dart-sass
# can't do natively. In production, `assets:precompile` regenerates it via the
# `css:build` prerequisite before Sprockets ever compiles application.scss. In
# development/test, Sprockets compiles on demand (config.assets.compile =
# true), so without this, a fresh checkout or a CI run that never ran
# `yarn build:css` would fail the first time any page renders
# `stylesheet_link_tag 'application'`. Regenerate once at boot as a safety net
# — a running `yarn build:css --watch` process keeps it fresh after that.
if Rails.env.development? || Rails.env.test?
  Rails.application.config.after_initialize do
    system('node', Rails.root.join('bin/generate_sass_imports.js').to_s, exception: false) ||
      Rails.logger.warn('[generate_sass_imports] failed to regenerate app/assets/stylesheets/application/_generated_imports.scss')
  end
end
