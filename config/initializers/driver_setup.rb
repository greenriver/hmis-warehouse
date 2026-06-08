# frozen_string_literal: true

# Replaces the rails_drivers gem's Railtie setup for Zeitwerk and view paths.

# Collapse top-level concerns directories under each driver's app/models, app/controllers,
# and app/graphql. This mirrors exactly what the rails_drivers gem Railtie did:
#   loader.collapse('drivers/*/app/models/concerns')
#   loader.collapse('drivers/*/app/controllers/concerns')
#   loader.collapse('drivers/*/app/graphql/concerns')
# Only the immediate concerns/ child is collapsed — deeper nested concerns/ directories
# (e.g. drivers/hmis/app/models/hmis/concerns/) retain their namespace.
['models', 'controllers', 'graphql'].each do |component|
  Dir[Rails.root.join('drivers', '*', 'app', component, 'concerns')].each do |concerns_dir|
    Rails.autoloaders.main.collapse(concerns_dir)
  end
end

# Driver model extensions live under each driver's app/models/<driver>/extensions/ directory and
# are namespaced as <Driver>::...Extension. Collapsing the `extensions` segment makes the main
# autoloader map e.g. app/models/cas_access/extensions/user_extension.rb -> CasAccess::UserExtension,
# so extensions autoload on demand and reload in lockstep with the app (this is what makes `reload!`
# work — the previous to_prepare/load approach could not survive a console reload).
# See docs/developer/drivers.md for details.
Dir[Rails.root.join('drivers', '*', 'app', 'models', '*', 'extensions')].each do |ext_dir|
  Rails.autoloaders.main.collapse(ext_dir)
end

# Register driver view paths so drivers can provide their own views.
Dir[Rails.root.join('drivers', '*', 'app', 'views')].each do |view_path|
  ActionController::Base.prepend_view_path(view_path)
end
