# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, project, with_permission: [:can_view_project, :can_view_referrals]) }

  describe 'ce_referral query' do
    let(:query) do
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
              formDefinition {
                id
              }
            }
            swimlanes {
              id
              name
              participants {
                id
                name
              }
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

        expect(referral_data['opportunity']).to include(
          'id' => opportunity.id.to_s,
          'name' => opportunity.name,
          'status' => opportunity.status,
        )

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

      it 'returns no referral when user lacks permission' do
        # see additional permission logic testing in the Referral model spec
        remove_permissions(access_control, :can_view_referrals)

        response, result = post_graphql(**variables) { query }
        expect(response.status).to eq(200), result.inspect
        expect(result.dig('data', 'ceReferral')).to be_nil
      end

      context 'workflow with swimlanes' do
        # case_manager_swimlane is already set up in the CE spec helper
        let!(:provider_swimlane) { workflow_template.swimlanes.create!(name: 'Providers') }

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
            end.to make_database_queries(count: 15..20)
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
            :hmis_workflow_definition_task,
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
                }
              }
            }
          GRAPHQL
        end

        before do
          50.times do |i|
            conditional_task = create(
              :hmis_workflow_definition_task,
              template: workflow_template,
              name: "conditional task #{i}",
              swimlane: case_manager_swimlane,
            )
            gateway.connect_to!(conditional_task, condition: 'needs_provider_acceptance = 1')

            non_conditional_task = create(
              :hmis_workflow_definition_task,
              template: workflow_template,
              name: "nonconditional task #{i}",
              swimlane: case_manager_swimlane,
            )
            start_event.connect_to!(non_conditional_task)
          end
        end

        it 'does not result in n+1 query' do
          expect do
            response, result = post_graphql(**variables) { query }
            expect(response.status).to eq(200), result.inspect
            steps = result.dig('data', 'ceReferral', 'steps')
            expect(steps.length).to eq(51)
          end.to make_database_queries(count: 10..20)
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
