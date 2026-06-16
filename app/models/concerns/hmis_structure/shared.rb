###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# frozen_string_literal: true

module HmisStructure::Shared
  extend ActiveSupport::Concern

  # Alias CamelCase HUD CSV column names to snake_case for Rails convention
  included do
    ['2022', '2024', '2026'].each do |version|
      configuration = hmis_configuration(version: version)
      next unless configuration.present? # Allow for adding new models

      configuration.keys.each do |col|
        alias_attribute col.to_s.underscore.to_sym, col
      end
    end
  end
end
