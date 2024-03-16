###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::BulkAssignServiceInput < Types::BaseInputObject
    description 'Input for BulkAssignService mutation'
    argument :project_id, ID, required: true
    argument :client_ids, [ID], required: true, description: 'Clients that should receive service. Clients that are unenrolled in the project will be enrolled in the project.'
    argument :service_type_id, ID, required: true
    argument :coc_code, String, required: false, description: 'CoC code to store as EnrollmentCoC when enrolling a new client. Only needed if Project operaties in multiple CoCs.'
    argument :date_provided, GraphQL::Types::ISO8601Date, required: true
  end
end
