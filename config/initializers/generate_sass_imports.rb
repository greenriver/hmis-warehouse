###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Regenerates the dart-sass glob-import partial once at boot, in
# development/test only.
#
# Sprockets compiles application.scss on demand in these environments, so
# without this, a fresh checkout would fail the first request that renders
# it, before anyone has run `yarn build:css`.
if Rails.env.development? || Rails.env.test?
  Rails.application.config.after_initialize do
    system('node', Rails.root.join('bin/generate_sass_imports.js').to_s, exception: false) ||
      Rails.logger.warn('[generate_sass_imports] failed to regenerate app/assets/stylesheets/application/_generated_imports.scss')
  end
end
