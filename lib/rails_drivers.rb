# frozen_string_literal: true

# Thin compatibility shim replacing the rails_drivers gem registry.
# Feature initializers push driver symbols here; application code checks
# RailsDrivers.loaded.include?(:driver_name) to test availability.
# Cleanup of these 170+ call sites is deferred to a follow-up task per ADR 0007.
module RailsDrivers
  def self.loaded
    @loaded ||= []
  end
end
