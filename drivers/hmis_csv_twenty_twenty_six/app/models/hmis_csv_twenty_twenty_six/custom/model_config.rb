###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  module Custom
    # Provides common configuration methods for custom models
    module ModelConfig
      extend ActiveSupport::Concern

      class_methods do
        def custom_file_definition
          @custom_file_definition
        end

        def hud_csv_headers(version: '2026') # rubocop:disable Lint/UnusedMethodArgument
          custom_file_definition.real_columns.map { |col| col['name'] }
        end

        def hmis_structure(version: '2026') # rubocop:disable Lint/UnusedMethodArgument
          custom_file_definition.real_columns.each_with_object({}) do |col, hash|
            hash[col['name'].to_sym] = {
              type: col['type'] || 'string',
              required: col['required'] || false,
            }
          end
        end
      end
    end
  end
end
