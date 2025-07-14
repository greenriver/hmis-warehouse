###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisCsvTwentyTwentySix
  # Provides common configuration methods for custom models
  #
  # This concern simplifies access to the YAML configuration by providing
  # standard methods for things like headers, structure, and keys.
  module CustomModelConfig
    extend ActiveSupport::Concern

    class_methods do
      # @return [Hash] The YAML configuration for this specific custom file
      def custom_file_config
        @custom_file_config
      end

      # @return [Array<String>] A list of all column names from the CSV file
      def hud_csv_headers
        custom_file_config['columns'].map { |col| col['name'] }
      end

      # @return [Hash] A hash describing the structure of the file (types, requirements)
      def hmis_structure
        custom_file_config['columns'].each_with_object({}) do |col, hash|
          hash[col['name'].to_sym] = {
            type: col['type'] || 'string',
            required: col['required'] || false,
          }
        end
      end
    end
  end
end
