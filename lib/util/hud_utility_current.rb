###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HudUtilityCurrent
  class << self
    # Delegate all method calls to the appropriate HUD utility based on current version
    def method_missing(method_name, *args, **kwargs, &block)
      current_utility = current_hud_utility

      if current_utility.respond_to?(method_name)
        current_utility.public_send(method_name, *args, **kwargs, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      current_hud_utility.respond_to?(method_name, include_private) || super
    end

    def current_hud_utility
      # Use the same logic as HmisStructure::Base#current_hud_utility
      case hud_csv_version
      when '2024'
        HudUtility2024
      else
        HudUtility2026
      end
    end

    def hud_csv_version
      # Move to 2026 in production after 2025-10-01
      # Move to 2026 in staging after 2025-09-01
      # Move to 2026 in test and development now
      cutoff_date = if Rails.env.production?
        Date.new(2025, 10, 1)
      elsif Rails.env.staging?
        Date.new(2025, 9, 1)
      else
        Date.current
      end
      return '2024' if Date.current < cutoff_date

      '2026'
    end
  end
end
