###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative 'login_and_permissions'
require_relative '../../support/hmis_base_setup'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'hmis base setup'

  let!(:access_control) { create_access_control(hmis_user, p1) }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1 }
  let!(:at) { create :hmis_staff_assignment_type }
  let!(:curr_assignment) { create :hmis_staff_assignment, staff_assignment_type: at, data_source: ds1, enrollment: e1 }
  let!(:prev_assignment) do
    create(
      :hmis_staff_assignment,
      staff_assignment_type: at,
      data_source: ds1,
      enrollment: e1,
      created_at: 2.weeks.ago,
      deleted_at: 1.week.ago,
    )
  end

  before(:each) do
    hmis_login(user)
    Hmis::ProjectStaffAssignmentConfig.new(project_id: p1.id).save!
  end

  describe 'household staff assignment query' do
    let(:query) do
      <<~GRAPHQL
        query GetHousehold($id: ID!, $isCurrentlyAssigned: Boolean) {
          household(id: $id) {
            staffAssignments(isCurrentlyAssigned: $isCurrentlyAssigned) {
              id
              user {
                id
              }
              staffAssignmentType
              assignedAt
              unassignedAt
            }
          }
        }
      GRAPHQL
    end

    it 'resolves currently assigned staff by default' do
      response, result = post_graphql(id: e1.household.household_id) { query }
      expect(response.status).to eq(200)
      assignment = result.dig('data', 'household', 'staffAssignments', 0)
      expect(assignment.dig('id')).to eq(curr_assignment.id.to_s)
      expect(assignment.dig('unassignedAt')).to be_nil
    end

    it 'resolves past assigned staff when isCurrentlyAssigned arg is set to false' do
      response, result = post_graphql(id: e1.household.household_id, is_currently_assigned: false) { query }
      expect(response.status).to eq(200)
      assignment = result.dig('data', 'household', 'staffAssignments', 0)
      expect(assignment.dig('id')).to eq(prev_assignment.id.to_s)
      expect(assignment.dig('unassignedAt')).not_to be_nil
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
