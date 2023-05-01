###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::Enums::ValidationSeverity < Types::BaseEnum
    graphql_name 'ValidationSeverity'

    value 'error'
    value 'warning'
  end
end
