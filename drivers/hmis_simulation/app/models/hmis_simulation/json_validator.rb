###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisSimulation
  module JsonValidator
    SCHEMA_PATH = Rails.root.join(
      'drivers', 'hmis_simulation', 'public', 'schemas', 'simulation_config.json'
    ).freeze

    module_function

    # @param config [Hash] simulation config (string keys)
    # @return [Array<String>] schema validation error messages
    def perform(config)
      HmisExternalApis::JsonValidator.perform(config, SCHEMA_PATH.to_s)
    end
  end
end
