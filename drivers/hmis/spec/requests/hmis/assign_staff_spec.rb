###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe 'Assign Staff Mutation', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    hmis_login(user)
    Hmis::ProjectStaffAssignmentConfig.new(project_id: p1.id).save!
  end

  subject(:mutation) do
    <<~GRAPHQL
      mutation AssignStaff($householdId: ID!, $assignmentTypeId: ID!, $userId: ID!) {
        assignStaff(householdId: $householdId, assignmentTypeId: $assignmentTypeId, userId: $userId) {
          staffAssignment {
            id
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:at) { create :hmis_staff_assignment_type }
  let!(:assignment) { create :hmis_staff_assignment, staff_assignment_type: at, data_source: ds1, enrollment: e1 }
  let!(:e2) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }

  let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1, user: u1 }
  let!(:e3) { create :hmis_hud_enrollment, data_source: ds1, project: p2 }
  let!(:p2_access_control) { create_access_control(hmis_user, p2) }

  context 'when the user has permission' do
    let!(:access_control) { create_access_control(hmis_user, p1) }

    it 'assigns staff' do
      input = {
        household_id: e2.household.household_id,
        assignment_type_id: at.id,
        user_id: hmis_user.id,
      }
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200)
      expect(result.dig('data', 'assignStaff', 'staffAssignment', 'id')).not_to be_nil
      expect(result.dig('data', 'assignStaff', 'errors')).to be_empty
    end

    it 'does not make duplicate assignment' do
      input = {
        household_id: assignment.household.household_id,
        assignment_type_id: assignment.staff_assignment_type.id,
        user_id: assignment.user.id,
      }
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(200)
      expect(result.dig('data', 'assignStaff', 'errors', 0, 'message')).to match(/is already assigned/)
    end

    it 'does not assign to project without staff assignment config' do
      input = {
        household_id: e3.household.household_id,
        assignment_type_id: at.id,
        user_id: hmis_user.id,
      }
      response, result = post_graphql(input) { mutation }
      expect(response.status).to eq(500)
      expect(result.dig('errors', 0, 'message')).to eq('Staff Assignment not enabled')
    end
  end

  context 'when the user lacks permission' do
    let!(:access_control) { create_access_control(hmis_user, p1, without_permission: :can_edit_enrollments) }

    it 'does not permit assignment' do
      input = {
        household_id: e2.household.household_id,
        assignment_type_id: at.id,
        user_id: hmis_user.id,
      }
      expect_access_denied post_graphql(input) { mutation }
    end
  end
end
