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
  let!(:ar) { create :hmis_staff_assignment_relationship }
  let!(:curr_assignment) { create :hmis_staff_assignment, staff_assignment_relationship: ar, data_source: ds1, enrollment: e1 }
  let!(:prev_assignment) do
    create(
      :hmis_staff_assignment,
      staff_assignment_relationship: ar,
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
              nodes {
                id
                user {
                  id
                }
                staffAssignmentRelationship
                assignedAt
                unassignedAt
              }
            }
          }
        }
      GRAPHQL
    end

    it 'resolves currently assigned staff by default' do
      response, result = post_graphql(id: e1.household.household_id) { query }
      expect(response.status).to eq(200), result.inspect
      assignment = result.dig('data', 'household', 'staffAssignments', 'nodes', 0)
      expect(assignment.dig('id')).to eq(curr_assignment.id.to_s)
      expect(assignment.dig('unassignedAt')).to be_nil
    end

    it 'resolves past assigned staff when isCurrentlyAssigned arg is set to false' do
      response, result = post_graphql(id: e1.household.household_id, is_currently_assigned: false) { query }
      expect(response.status).to eq(200), result.inspect
      assignment = result.dig('data', 'household', 'staffAssignments', 'nodes', 0)
      expect(assignment.dig('id')).to eq(prev_assignment.id.to_s)
      expect(assignment.dig('unassignedAt')).not_to be_nil
    end
  end

  describe 'user staff assignment query' do
    let(:query) do
      <<~GRAPHQL
        query GetUserStaffAssignments($id: ID!) {
          user(id: $id) {
            staffAssignments {
              nodesCount
              nodes {
                id
                staffAssignmentRelationship
              }
            }
          }
        }
      GRAPHQL
    end

    let!(:ds1_assignment) { create :hmis_staff_assignment, staff_assignment_relationship: ar, data_source: ds1, enrollment: e1, user: hmis_user }

    # Set up a second HMIS where this user also has assignees
    let!(:ds2) { create :hmis_data_source }
    let!(:p2) { create :hmis_hud_project, data_source: ds2 }
    let!(:e2) { create :hmis_hud_enrollment, data_source: ds2, project: p2 }
    let!(:ds2_assignment) { create :hmis_staff_assignment, staff_assignment_relationship: ar, data_source: ds2, enrollment: e2, user: hmis_user }

    it 'resolves assignees for the user, resolving only those in the current data source' do
      response, result = post_graphql(id: hmis_user.id) { query }
      expect(response.status).to eq(200), result.inspect
      expect(result.dig('data', 'user', 'staffAssignments', 'nodesCount')).to eq(1)
      expect(result.dig('data', 'user', 'staffAssignments', 'nodes', 0, 'id')).to eq(ds1_assignment.id.to_s)
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
