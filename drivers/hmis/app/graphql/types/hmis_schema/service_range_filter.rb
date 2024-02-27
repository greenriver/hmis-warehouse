###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::ServiceRangeFilter < Types::BaseInputObject
    description 'Object to capture input for filtering by date range served'
    argument :start_date, GraphQL::Types::ISO8601Date, required: true
    argument :end_date, GraphQL::Types::ISO8601Date, required: false
    argument :service_type, ID, required: false, description: 'Service type that was rendered during date range'
    argument :project_id, ID, required: false, description: 'Project where the service was rendered'
  end
end
