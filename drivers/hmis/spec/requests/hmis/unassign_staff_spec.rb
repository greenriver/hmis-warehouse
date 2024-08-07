###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Unassign Staff Mutation', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
  end

  subject(:mutation) do
    <<~GRAPHQL
      mutation UnassignStaff($id: ID!) {
        unassignStaff(id: $id) {
          staffAssignment {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:ar) { create :hmis_staff_assignment_relationship }
  let!(:assignment) { create :hmis_staff_assignment, staff_assignment_relationship: ar, data_source: ds1, enrollment: e1 }

  context 'when the user has permission' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'unassigns staff' do
      expect(Hmis::StaffAssignment.count).to eq(1)
      response, result = post_graphql({ id: assignment.id }) { mutation }
      expect(response.status).to eq(200)
      expect(result.dig('data', 'unassignStaff', 'staffAssignment', 'id')).not_to be_nil
      expect(result.dig('data', 'unassignStaff', 'errors')).to be_empty
      expect(Hmis::StaffAssignment.count).to eq(0)
    end

    it 'returns an error when the ID is not found' do
      response, result = post_graphql({ id: 555 }) { mutation }
      expect(response.status).to eq(500)
      expect(result.dig('errors', 0, 'message')).to match("Couldn't find Hmis::StaffAssignment")
    end
  end

  context 'when the user lacks permission' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_edit_enrollments) }

    it 'does not unassign' do
      expect_access_denied(post_graphql({ id: assignment.id }) { mutation })
      expect(Hmis::StaffAssignment.count).to eq(1)
    end
  end
end
