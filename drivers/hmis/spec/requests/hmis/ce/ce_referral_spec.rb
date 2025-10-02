# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  describe 'ce_referral query' do
    let(:query) do
      <<~GRAPHQL
        query GetCeReferral($id: ID!) {
          ceReferral(id: $id) {
            id
            status
            clientId
            client {
              id
              firstName
            }
            targetProjectName
            access {
              canViewTargetProject
              canCreateReferralNote
            }
            targetEnrollment {
              id
            }
            sourceEnrollment {
              id
              projectName
              projectType
              entryDate
              exitDate
              householdSize
              householdMembers {
                id
                clientId
                clientName
                relationshipToHoH
                access {
                  canViewClients
                }
              }
            }
            opportunity {
              id
              name
              status
            }
            steps {
              id
              name
              status
              formDefinition {
                id
              }
            }
            currentSteps {
              id
            }
            swimlanes {
              id
              name
              participants {
                id
                name
              }
            }
            updatedBy {
              id
              name
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      {
        id: referral.id,
      }
    end

    context 'when workflow is initialized' do
      it 'returns expected structure with correct steps' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        referral_data = result.dig('data', 'ceReferral')

        expect(referral_data['id']).to eq(referral.id.to_s)
        expect(referral_data['status']).to eq('initialized')
        expect(referral_data['client']['firstName']).to eq(referral.client.first_name)

        expect(referral_data['opportunity']).to include(
          'id' => opportunity.id.to_s,
          'name' => opportunity.name,
          'status' => opportunity.status,
        )

        # Verify that step and currentStep scopes don't mess with each other
        expect(referral_data['currentSteps'].count).to eq(0)

        steps = referral_data['steps']
        expect(steps).to be_an(Array)
        expect(steps.length).to eq(2) # Should only include task nodes

        # Verify first step (Client Acceptance)
        expect(steps[0]).to include(
          'name' => 'Client Acceptance',
          'status' => 'unavailable',
          'formDefinition' => { 'id' => client_acceptance_task.form_definitions.sole.id.to_s },
        )

        # Verify second step (Provider Acceptance)
        expect(steps[1]).to include(
          'name' => 'Provider Acceptance',
          'status' => 'unavailable',
          'formDefinition' => { 'id' => provider_acceptance_task.form_definitions.sole.id.to_s },
        )
      end

      context 'with source enrollment and household members' do
        let!(:source_project) { create(:hmis_hud_project, data_source: ds1, user: u1, project_name: 'Source Project') }
        let!(:household_id) { 'referred_household_id' }

        # Create additional clients for household members
        let!(:household_client_2) { create(:hmis_hud_client, data_source: ds1, first_name: 'Jane', last_name: 'Doe') }

        # Create source enrollment for the main client (Head of Household)
        let!(:source_enrollment) do
          create(
            :hmis_hud_enrollment,
            client: client,
            project: source_project,
            data_source: ds1,
            household_id: household_id,
            relationship_to_hoh: 1, # Head of Household
          )
        end

        # Create household member enrollments
        let!(:household_enrollment_2) do
          create(
            :hmis_hud_enrollment,
            client: household_client_2,
            project: source_project,
            data_source: ds1,
            household_id: household_id,
            relationship_to_hoh: 2, # Child
          )
        end

        # Update referral to have source enrollment
        before do
          referral.update!(source_enrollment: source_enrollment)
        end

        it 'returns source enrollment with correct household members' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          referral_data = result.dig('data', 'ceReferral')

          source_enrollment_data = referral_data['sourceEnrollment']
          expect(source_enrollment_data).to be_present
          expect(source_enrollment_data['id']).to eq(source_enrollment.id.to_s)
          expect(source_enrollment_data['projectName']).to eq('Source Project')
          expect(source_enrollment_data['householdSize']).to eq(2)

          # Verify household members are returned correctly
          household_members = source_enrollment_data['householdMembers']
          expect(household_members).to be_an(Array)
          expect(household_members.length).to eq(2)

          expect(household_members).to contain_exactly(
            a_hash_including(
              'id' => source_enrollment.id.to_s,
              'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
              'clientName' => client.brief_name,
              'access' => { 'canViewClients' => true },
              'clientId' => client.id.to_s,
            ),
            a_hash_including(
              'id' => household_enrollment_2.id.to_s,
              'relationshipToHoH' => 'CHILD',
              'clientName' => household_client_2.brief_name,
              'access' => { 'canViewClients' => true },
              'clientId' => household_client_2.id.to_s,
            ),
          )
        end

        context 'when user lacks permission to view clients' do
          before do
            remove_permissions(ds_access_control, :can_view_clients)
          end

          it 'returns masked client names for household members' do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            referral_data = result.dig('data', 'ceReferral')

            source_enrollment_data = referral_data['sourceEnrollment']
            household_members = source_enrollment_data['householdMembers']

            # All household members should have masked names and no client access
            household_members.each do |member|
              expect(member['clientName']).to match(/Client \d+/)
              expect(member['access']['canViewClients']).to eq(false)
            end
          end
        end

        context 'when user lacks permission to view client names' do
          before do
            remove_permissions(ds_access_control, :can_view_client_name)
          end

          it 'returns masked client names but allows viewing clients' do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            referral_data = result.dig('data', 'ceReferral')

            source_enrollment_data = referral_data['sourceEnrollment']
            household_members = source_enrollment_data['householdMembers']

            # All household members should have masked names but can view clients
            household_members.each do |member|
              expect(member['clientName']).to match(/Client \d+/)
              expect(member['access']['canViewClients']).to eq(true)
            end
          end
        end
      end

      it 'returns no referral when user lacks permission' do
        # see additional permission logic testing in the model spec referral_permission_spec
        remove_permissions(ds_access_control, :can_view_referrals)

        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceReferral')).to be_nil
      end

      it 'returns the referral with anonymized client when user cannot view clients' do
        remove_permissions(ds_access_control, :can_view_clients)

        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceReferral', 'client')).to be_nil
        expect(result.dig('data', 'ceReferral', 'clientId')).to eq(referral.client.id.to_s) # Client ID is still returned so the UI can display an anonymized client
      end

      context 'workflow with swimlanes' do
        it 'returns swimlanes' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          swimlanes = result.dig('data', 'ceReferral', 'swimlanes')
          expect(swimlanes).to contain_exactly(
            a_hash_including('id' => case_manager_swimlane.id.to_s, 'name' => case_manager_swimlane.name, 'participants' => []),
            a_hash_including('id' => provider_swimlane.id.to_s, 'name' => provider_swimlane.name, 'participants' => []),
          )
        end

        context 'and participants' do
          let!(:cm1) { create(:hmis_user, data_source: ds1) }
          let!(:cm_participant1) { referral.participants.create(swimlane: case_manager_swimlane, user: cm1) }
          let!(:cm2) { create(:hmis_user, data_source: ds1) }
          let!(:cm_participant2) { referral.participants.create(swimlane: case_manager_swimlane, user: cm2) }
          let!(:provider) { create(:hmis_user, data_source: ds1) }
          let!(:provider_participant) { referral.participants.create(swimlane: provider_swimlane, user: provider) }

          it 'returns participants' do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            swimlanes = result.dig('data', 'ceReferral', 'swimlanes')
            expect(swimlanes).to contain_exactly(
              a_hash_including(
                'id' => case_manager_swimlane.id.to_s,
                'name' => case_manager_swimlane.name,
                'participants' => [
                  a_hash_including('id' => cm1.id.to_s, 'name' => cm1.name),
                  a_hash_including('id' => cm2.id.to_s, 'name' => cm2.name),
                ],
              ),
              a_hash_including(
                'id' => provider_swimlane.id.to_s,
                'name' => provider_swimlane.name,
                'participants' => [
                  a_hash_including('id' => provider.id.to_s, 'name' => provider.name),
                ],
              ),
            )
          end
        end

        context 'with many swimlanes and participants' do
          before do
            50.times do |i|
              swimlane = workflow_template.swimlanes.create!(name: "Swimlane #{i}")
              user = create(:hmis_user, data_source: ds1)
              referral.participants.create(swimlane: swimlane, user: user)
            end
          end

          it 'does not result in n+1 query' do
            expect do
              response, result = post_graphql(**variables) { query }
              expect(response.status).to eq(200), result.inspect
            end.to make_database_queries(count: 40..50)
          end
        end
      end
    end

    context 'when workflow is started' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
      end

      it 'shows first step as available' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        steps = result.dig('data', 'ceReferral', 'steps')

        expect(steps[0]['status']).to eq('available')
        expect(steps[1]['status']).to eq('unavailable')
      end

      context 'when the user can view the referral but not the project' do
        before do
          remove_permissions(ds_access_control, :can_view_project)
          add_permissions(ds_access_control, :can_view_own_referrals)

          step = referral.workflow_engine.active_steps.first
          step.assignments.create!(user: hmis_user)
        end

        it 'returns the referral with project name, but not canViewTargetProject access' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceReferral', 'targetProjectName')).to eq(referral.target_project.project_name)
          expect(result.dig('data', 'ceReferral', 'access', 'canViewTargetProject')).to eq(false)
        end
      end

      context 'when the workflow has a target enrollment' do
        let!(:enrollment) { create(:hmis_hud_enrollment, project: referral.target_project, client: referral.client) }
        before do
          referral.update!(target_enrollment: enrollment)
        end

        it 'returns the referral with enrollment' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'ceReferral', 'targetEnrollment', 'id')).to eq(enrollment.id.to_s)
        end

        context 'when the user does not have permission to see the enrollment' do
          before do
            remove_permissions(ds_access_control, :can_view_enrollment_details)
          end

          it 'does not return the enrollment' do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'ceReferral', 'targetEnrollment')).to be_nil
          end
        end
      end

      describe 'note creation permission' do
        shared_examples 'checks canCreateReferralNote permission' do |expected_value|
          it "returns #{expected_value} for canCreateReferralNote" do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect

            access = result.dig('data', 'ceReferral', 'access')
            expect(access['canCreateReferralNote']).to eq(expected_value)
          end
        end

        context 'when user can perform any referral tasks' do
          let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_any_referral_tasks, :can_view_project]) }

          include_examples 'checks canCreateReferralNote permission', true
        end

        context 'when user can perform own referral tasks' do
          let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project]) }

          context 'and user is not assigned' do
            include_examples 'checks canCreateReferralNote permission', false
          end

          context 'and user is assigned' do
            before do
              referral.participants.create!(swimlane: case_manager_swimlane, user: hmis_user)
              referral.workflow_engine.assign_task!(referral.workflow_engine.active_steps.first)
            end

            include_examples 'checks canCreateReferralNote permission', true
          end
        end

        context 'when user can only view referrals but cannot perform tasks' do
          let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project]) }

          include_examples 'checks canCreateReferralNote permission', false
        end
      end
    end

    context 'when first step is completed' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
        step = referral.workflow_engine.active_steps.first
        referral.workflow_engine.start_step!(step, user: hmis_user)
        referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { accepted: true })
      end

      it 'shows second step as available' do
        _, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        steps = result.dig('data', 'ceReferral', 'steps')

        expect(steps[0]['status']).to eq('completed')
        expect(steps[1]['status']).to eq('available')
      end
    end

    context 'when workflow includes a conditional step' do
      let(:gateway) do
        create(
          :hmis_workflow_definition_gateway,
          template: workflow_template,
          gateway_type: 'exclusive',
          name: 'conditional gw',
        )
      end

      before do
        client_acceptance_task.outflows.destroy_all
        client_acceptance_task.connect_to!(gateway)
        gateway.connect_to!(provider_acceptance_task, condition: 'needs_provider_acceptance = 1')
        gateway.connect_to!(accept_referral, condition: 'needs_provider_acceptance = 0')
      end

      it 'does not return the conditional step' do
        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        steps = result.dig('data', 'ceReferral', 'steps')
        expect(steps.length).to eq(1) # Should only include the task that is definitely happening, not the conditional task

        expect(steps[0]).to include('name' => 'Client Acceptance')
      end

      context 'when the condition is met and the step is enabled' do
        before do
          referral.workflow_engine.start_workflow!(user: hmis_user)
          step = referral.workflow_engine.active_steps.first
          referral.workflow_engine.start_step!(step, user: hmis_user)
          referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { needs_provider_acceptance: 1 })
        end

        it 'returns the conditional step' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          steps = result.dig('data', 'ceReferral', 'steps')
          expect(steps.length).to eq(2)

          expect(steps[0]).to include('name' => 'Client Acceptance')
          expect(steps[1]).to include('name' => 'Provider Acceptance')
        end
      end

      context 'when there is another step after the conditional step' do
        let!(:post_provider_acceptance) do
          create(
            :hmis_workflow_definition_user_task,
            template: workflow_template,
            name: 'Post Provider Acceptance',
            swimlane: case_manager_swimlane,
          )
        end

        before do
          provider_acceptance_task.outflows.destroy_all
          provider_acceptance_task.connect_to!(post_provider_acceptance)
          post_provider_acceptance.connect_to!(accept_referral)
        end

        it 'does not return the conditional step OR the step after it' do
          response, result = post_graphql(**variables) { query }
          expect(response.status).to eq(200), result.inspect
          steps = result.dig('data', 'ceReferral', 'steps')
          expect(steps.length).to eq(1) # Should only include the task that is definitely happening, not the conditional task

          expect(steps[0]).to include('name' => 'Client Acceptance')
        end

        context 'when the condition is met and the step is enabled' do
          before do
            referral.workflow_engine.start_workflow!(user: hmis_user)
            step = referral.workflow_engine.active_steps.first
            referral.workflow_engine.start_step!(step, user: hmis_user)
            referral.workflow_engine.complete_step!(step, user: hmis_user, submitted_values: { needs_provider_acceptance: 1 })
          end

          it 'returns the conditional step AND the step after' do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            steps = result.dig('data', 'ceReferral', 'steps')
            expect(steps.length).to eq(3)

            expect(steps[0]).to include('name' => 'Client Acceptance')
            expect(steps[1]).to include('name' => 'Provider Acceptance')
            expect(steps[2]).to include('name' => 'Post Provider Acceptance')
          end
        end
      end

      context 'when there are many steps' do
        let(:query) do # this query leaves out formDefinition, which does cause n+1 and isn't resolved in batch on the frontend.
          <<~GRAPHQL
            query GetCeReferral($id: ID!) {
              ceReferral(id: $id) {
                id
                status
                opportunity {
                  id
                  name
                  status
                }
                steps {
                  id
                  name
                  status
                  access {
                    canPerformStep
                  }
                }
              }
            }
          GRAPHQL
        end

        before do
          50.times do |i|
            conditional_task = create(
              :hmis_workflow_definition_user_task,
              template: workflow_template,
              name: "conditional task #{i}",
              swimlane: case_manager_swimlane,
            )
            gateway.connect_to!(conditional_task, condition: 'needs_provider_acceptance = 1')

            non_conditional_task = create(
              :hmis_workflow_definition_user_task,
              template: workflow_template,
              name: "nonconditional task #{i}",
              swimlane: case_manager_swimlane,
            )
            start_event.connect_to!(non_conditional_task)
          end
        end

        it 'does not result in n+1 query' do
          referral.workflow_engine.start_workflow!(user: hmis_user)

          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            steps = result.dig('data', 'ceReferral', 'steps')
            expect(steps.length).to eq(51)
          end.to make_database_queries(count: 25..35)
        end

        context 'when current user has can_perform_own_referral_tasks' do
          before do
            remove_permissions(ds_access_control, :can_perform_any_referral_tasks)
            add_permissions(ds_access_control, :can_perform_own_referral_tasks)
            referral.participants.create(swimlane: case_manager_swimlane, user: hmis_user)

            referral.workflow_engine.start_workflow!(user: hmis_user)
          end

          it 'still does not cause n+1' do
            expect do
              _, result = post_graphql(**variables) { query }
              steps = result.dig('data', 'ceReferral', 'steps')
              expect(steps.map { |step| step.dig('access', 'canPerformStep') }).to all(be true)
            end.to make_database_queries(count: 30..40)
          end
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
