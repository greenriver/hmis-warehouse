###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'BulkAssignService', type: :request do
  include_context 'hmis base setup'
  include_context 'hmis service setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation BulkAssignService(
        $clientIds: [ID!]!
        $projectId: ID!
        $serviceTypeId: ID!
        $dateProvided: ISO8601Date!
      ) {
        bulkAssignService(
          clientIds: $clientIds
          projectId: $projectId
          serviceTypeId: $serviceTypeId
          dateProvided: $dateProvided
        ) {
          success
          errors {
            message
          }
        }
      }
    GRAPHQL
  end

  # fails if lacking can_edit_enrollments for project
  # fails if clients not found
  # fails if lacking can_enroll_clients for unenrolled clients
  # assigns to enrolled clients
  # enrolls and assigns to unenrolled clients
  # chooses open
  # does not choose closed
  # chooses deterministically for multiple open enrollments
  # works for HUD Service
  # works for Custom Service
  # validates Date Provided
  # validates uniqueness for Bed Nights
end
