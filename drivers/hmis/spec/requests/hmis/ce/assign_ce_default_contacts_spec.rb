###
# Copyright 2016 - 2026 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'AssignCeDefaultContacts Mutation', type: :request do
  include_context 'hmis base setup'

  subject(:mutation) do
    <<~GRAPHQL
      mutation AssignCeDefaultContacts($input: CeDefaultContactsInput!) {
        assignCeDefaultContacts(input: $input) {
          defaultContacts {
            id
            user {
              id
            }
            swimlane {
              id
              name
            }
            projectId
            organizationId
            unitGroupId
            global
          }
        }
      }
    GRAPHQL
  end

  let!(:workflow_template) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral') }
  let!(:swimlane1) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Case Managers') }
  let!(:swimlane2) { create(:hmis_workflow_definition_swimlane, template: workflow_template, name: 'Housing Navigators') }
  let!(:user1) { create(:hmis_user, data_source: ds1) }
  let!(:user2) { create(:hmis_user, data_source: ds1) }
  let!(:user3) { create(:hmis_user, data_source: ds1) }

  # Grant users permission to perform referral tasks
  let!(:user1_access) { create_access_control(user1, ds1, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }
  let!(:user2_access) { create_access_control(user2, ds1, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }
  let!(:user3_access) { create_access_control(user3, ds1, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }

  # Set up project to use the workflow template
  let!(:unit_group) { create(:hmis_unit_group, project: p1, workflow_template: workflow_template) }

  # Setup access control at data source level (covers both global and project-level operations)
  let!(:access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_clients, :can_view_project, :can_administrate_coordinated_entry],
    )
  end

  before(:each) do
    hmis_login(user)
  end

  # Shared input for global operations
  let(:global_contacts_input) do
    {
      input: {
        contacts: [
          {
            swimlaneId: swimlane1.id,
            userIds: [user1.id, user2.id],
          },
          {
            swimlaneId: swimlane2.id,
            userIds: [user3.id],
          },
        ],
      },
    }
  end

  # Shared input for project operations
  let(:project_contacts_input) do
    {
      input: {
        projectId: p1.id,
        contacts: [
          {
            swimlaneId: swimlane1.id,
            userIds: [user1.id, user2.id],
          },
        ],
      },
    }
  end

  describe 'global contacts' do
    let(:input) { global_contacts_input }

    it 'creates global default contacts' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        contacts = result.dig('data', 'assignCeDefaultContacts', 'defaultContacts')
        expect(contacts.size).to eq(3)

        # Check that all contacts are marked as global
        expect(contacts.all? { |c| c['global'] == true }).to be true
        expect(contacts.all? { |c| c['projectId'].nil? }).to be true

        # Verify the assignments are returned grouped by swimlane
        swimlane1_contacts = contacts.select { |c| c['swimlane']['id'] == swimlane1.id.to_s }
        expect(swimlane1_contacts.size).to eq(2)
        expect(swimlane1_contacts.map { |c| c['user']['id'] }).to contain_exactly(user1.id.to_s, user2.id.to_s)
        swimlane2_contacts = contacts.select { |c| c['swimlane']['id'] == swimlane2.id.to_s }
        expect(swimlane2_contacts.size).to eq(1)
        expect(swimlane2_contacts.first['user']['id']).to eq(user3.id.to_s)
      end.to change(Hmis::Ce::DefaultSwimlaneAssignment, :count).by(3)

      # Verify the assignments were created with the data source as owner
      assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: ds1)
      expect(assignments.pluck(:user_id, :swimlane_id)).to contain_exactly(
        [user1.id, swimlane1.id],
        [user2.id, swimlane1.id],
        [user3.id, swimlane2.id],
      )
    end

    context 'with existing assignments' do
      let!(:existing_assignment1) do
        create(:hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: ds1)
      end
      let!(:existing_assignment2) do
        create(:hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane1, owner: ds1)
      end
      let!(:existing_assignment3) do
        create(:hmis_ce_default_swimlane_assignment, user: user3, swimlane: swimlane2, owner: ds1)
      end

      context 'when removing all users from a swimlane' do
        let(:input) do
          {
            input: {
              contacts: [
                { swimlaneId: swimlane1.id, userIds: [] },
                { swimlaneId: swimlane2.id, userIds: [user3.id] },
              ],
            },
          }
        end

        it 'removes assignments for the specified swimlane' do
          expect do
            response, result = post_graphql(input) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change { Hmis::Ce::DefaultSwimlaneAssignment.where(owner: ds1, swimlane: swimlane1).count }.from(2).to(0)

          expect(Hmis::Ce::DefaultSwimlaneAssignment.where(owner: ds1, swimlane: swimlane2).count).to eq(1)
        end
      end

      context 'when updating users' do
        let(:input) do
          {
            input: {
              contacts: [
                { swimlaneId: swimlane1.id, userIds: [user1.id] },
                { swimlaneId: swimlane2.id, userIds: [user3.id] },
              ],
            },
          }
        end

        it 'removes unspecified users and keeps specified users without creating duplicates' do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect

          expect(Hmis::Ce::DefaultSwimlaneAssignment.exists?(id: existing_assignment1.id)).to be true
          expect(Hmis::Ce::DefaultSwimlaneAssignment.exists?(id: existing_assignment2.id)).to be false
          expect(Hmis::Ce::DefaultSwimlaneAssignment.exists?(id: existing_assignment3.id)).to be true

          contacts = result.dig('data', 'assignCeDefaultContacts', 'defaultContacts')
          expect(contacts.size).to eq(2)
        end
      end
    end
  end

  describe 'project contacts' do
    let(:input) { project_contacts_input }

    it 'creates project-specific default contacts' do
      expect do
        response, result = post_graphql(input) { mutation }
        expect(response.status).to eq(200), result.inspect

        contacts = result.dig('data', 'assignCeDefaultContacts', 'defaultContacts')
        expect(contacts.size).to eq(2)

        expect(contacts.all? { |c| c['global'] == false }).to be true
        expect(contacts.all? { |c| c['projectId'] == p1.id.to_s }).to be true
      end.to change(Hmis::Ce::DefaultSwimlaneAssignment, :count).by(2)

      assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: p1)
      expect(assignments.pluck(:user_id, :swimlane_id)).to contain_exactly(
        [user1.id, swimlane1.id],
        [user2.id, swimlane1.id],
      )
    end

    context 'with existing assignments' do
      let!(:existing_assignment1) do
        create(:hmis_ce_default_swimlane_assignment, user: user1, swimlane: swimlane1, owner: p1)
      end
      let!(:existing_assignment2) do
        create(:hmis_ce_default_swimlane_assignment, user: user2, swimlane: swimlane1, owner: p1)
      end

      context 'when updating users' do
        let(:input) do
          {
            input: {
              projectId: p1.id,
              contacts: [{ swimlaneId: swimlane1.id, userIds: [user1.id, user3.id] }],
            },
          }
        end

        it 'removes user2, adds user3, and does not recreate duplicates' do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect

          expect(Hmis::Ce::DefaultSwimlaneAssignment.where(owner: p1).count).to eq(2)
          expect(Hmis::Ce::DefaultSwimlaneAssignment.exists?(id: existing_assignment1.id)).to be true
          expect(Hmis::Ce::DefaultSwimlaneAssignment.exists?(id: existing_assignment2.id)).to be false

          assignments = Hmis::Ce::DefaultSwimlaneAssignment.where(owner: p1)
          expect(assignments.pluck(:user_id)).to contain_exactly(user1.id, user3.id)
        end
      end
    end
  end

  describe 'permissions' do
    # Shared examples for permission testing
    shared_examples 'requires can_administrate_coordinated_entry permission' do
      context 'when user has can_administrate_coordinated_entry permission' do
        it 'allows the operation' do
          response, result = post_graphql(input) { mutation }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'assignCeDefaultContacts', 'defaultContacts')).to be_present
        end
      end

      context 'when user lacks can_administrate_coordinated_entry permission' do
        before do
          remove_permissions(access_control, :can_administrate_coordinated_entry)
        end

        it 'denies access' do
          expect_access_denied post_graphql(input) { mutation }
        end
      end
    end

    context 'for global contacts' do
      let(:input) { global_contacts_input }
      it_behaves_like 'requires can_administrate_coordinated_entry permission'
    end

    context 'for project contacts' do
      let(:input) { project_contacts_input }
      let!(:access_control) do # even if access is granted at the project, not data source level
        create_access_control(
          hmis_user,
          p1,
          with_permission: [:can_view_clients, :can_view_project, :can_administrate_coordinated_entry],
        )
      end
      it_behaves_like 'requires can_administrate_coordinated_entry permission'
    end
  end

  describe 'validation' do
    shared_examples 'raises an error and does not create default contacts' do |expected_error: nil|
      it 'raises an error and does not create default contacts' do
        expect do
          expect_gql_error(post_graphql(input) { mutation }, message: expected_error)
        end.not_to change(Hmis::Ce::DefaultSwimlaneAssignment, :count)
      end
    end

    context 'when user lacks permission to perform referral tasks in the project' do
      let!(:user_without_permission) { create(:hmis_user, data_source: ds1) }
      # cruft: user has permission in a different project
      let!(:p2) { create(:hmis_hud_project, data_source: ds1) }
      let!(:user_access_control) { create_access_control(user_without_permission, p2, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }

      let(:input) do
        {
          input: {
            projectId: p1.id,
            contacts: [
              {
                swimlaneId: swimlane1.id,
                userIds: [user_without_permission.id],
              },
            ],
          },
        }
      end

      it_behaves_like 'raises an error and does not create default contacts', expected_error: /not authorized/
    end

    context 'when user lacks permission to perform referral tasks in the data source' do
      let!(:user_without_permission) { create(:hmis_user, data_source: ds1) }
      # cruft: user has permission in a different data source
      let!(:ds2) { create(:hmis_data_source) }
      let!(:user_access_control) { create_access_control(user_without_permission, ds2, with_permission: [:can_view_project, :can_perform_any_referral_tasks]) }

      let(:input) do
        {
          input: {
            contacts: [
              {
                swimlaneId: swimlane1.id,
                userIds: [user_without_permission.id],
              },
            ],
          },
        }
      end

      it_behaves_like 'raises an error and does not create default contacts', expected_error: /not authorized/
    end

    context 'when non-existent swimlane is passed' do
      let(:input) do
        {
          input: {
            projectId: p1.id,
            contacts: [
              {
                swimlaneId: 999999,
                userIds: [user1.id],
              },
            ],
          },
        }
      end

      it_behaves_like 'raises an error and does not create default contacts', expected_error: /Swimlane\(s\) not found/
    end

    context 'when swimlane exists but is not applicable to the project' do
      let!(:other_template) { create(:hmis_workflow_definition_template, data_source: ds1, status: 'published', template_type: 'ce_referral') }
      let!(:other_swimlane) { create(:hmis_workflow_definition_swimlane, template: other_template, name: 'Other') }

      let(:input) do
        {
          input: {
            projectId: p1.id,
            contacts: [
              {
                swimlaneId: other_swimlane.id,
                userIds: [user1.id],
              },
            ],
          },
        }
      end

      it_behaves_like 'raises an error and does not create default contacts', expected_error: /Swimlane\(s\) not found/
    end

    context 'when non-existent user is passed' do
      let(:input) do
        {
          input: {
            projectId: p1.id,
            contacts: [
              {
                swimlaneId: swimlane1.id,
                userIds: [999999],
              },
            ],
          },
        }
      end

      it_behaves_like 'raises an error and does not create default contacts', expected_error: /User\(s\) not found/
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
