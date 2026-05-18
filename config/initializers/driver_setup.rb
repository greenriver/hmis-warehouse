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

# Register driver view paths so drivers can provide their own views.
Dir[Rails.root.join('drivers', '*', 'app', 'views')].each do |view_path|
  ActionController::Base.prepend_view_path(view_path)
end

# Load driver extension files so model includes (e.g. include Hmis::UserExtension) resolve.
# Uses reloader.to_prepare (not config.to_prepare) because config.to_prepare blocks added
# during initializers are never forwarded to the reloader.
# Uses `load` so extensions are re-applied after Zeitwerk reloads in development.
#
# Extension files use compact module form (e.g. module DriverName::GrdaWarehouse::Hud),
# which requires all intermediate constants to exist. We create stub modules for each
# subdirectory level under extensions/ inside the driver's real namespace module.
Rails.application.reloader.to_prepare do
  Dir[Rails.root.join('drivers', '*', 'extensions')].each do |ext_root|
    driver_mod = File.basename(File.dirname(ext_root)).camelize.safe_constantize
    next unless driver_mod

    Dir.glob("#{ext_root}/*/").each do |level1_dir|
      l1_name = File.basename(level1_dir).camelize
      driver_mod.const_set(l1_name, Module.new) unless driver_mod.const_defined?(l1_name, false)
      l1_mod = driver_mod.const_get(l1_name, false)

      Dir.glob("#{level1_dir}/*/").each do |level2_dir|
        l2_name = File.basename(level2_dir).camelize
        l1_mod.const_set(l2_name, Module.new) unless l1_mod.const_defined?(l2_name, false)
      end
    end
  end

  Dir[Rails.root.join('drivers', '*', 'extensions', '**', '*_extension.rb')].sort.each do |path|
    load path
  end
end
