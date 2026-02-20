# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Mutations::Ce::CreateDirectCeReferral, type: :request do
  include_context 'ce spec helper'

  let!(:ds_access_control) { create_access_control(hmis_user, ds1) }

  before(:each) do
    hmis_login(user)
  end

  let!(:source_project) { create(:hmis_hud_project, data_source: ds1) }
  let!(:source_enrollment) { create(:hmis_hud_enrollment, data_source: ds1, project: source_project, client: client) }

  # Override the referral from ce_spec_helper.rb to prevent it from being created in the database
  # This test creates its own referral via the mutation instead
  let!(:referral) { nil }

  let!(:target_project_ce_config) { create(:hmis_project_ce_config, project: project, receives_direct_referrals: true) }

  def build_input(contact_date: nil, client_accepted: nil)
    # form structure similar to ce_referral_step_form_definition factory
    {
      values_by_link_id: {
        'contact_date' => contact_date,
        'client_accepted' => client_accepted,
      },
      values_by_field_name: {
        'contact_date' => contact_date,
        'client_accepted' => client_accepted,
      },
    }
  end

  # perform mutation and return the referral id
  def perform_mutation(variables)
    response, result = post_graphql(**variables) { mutation }
    expect(response.status).to eq(200), result.inspect
    result.dig('data', 'createDirectCeReferral', 'referral', 'id')
  end

  describe 'create direct CE referral mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation CreateDirectCeReferral(
          $targetUnitGroupId: ID!
          $sourceEnrollmentId: ID!
          $valuesByLinkId: JsonObject!
          $valuesByFieldName: JsonObject!
          $formDefinitionId: ID!
          $confirmed: Boolean
        ) {
          createDirectCeReferral(
            targetUnitGroupId: $targetUnitGroupId
            sourceEnrollmentId: $sourceEnrollmentId
            valuesByLinkId: $valuesByLinkId
            valuesByFieldName: $valuesByFieldName
            formDefinitionId: $formDefinitionId
            confirmed: $confirmed
          ) {
            referral {
              id
              status
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    let(:contact_date) { 1.day.ago.to_date }
    let(:variables) do
      {
        targetUnitGroupId: unit_group.id,
        sourceEnrollmentId: source_enrollment.id,
        formDefinitionId: ce_step_definition.id,
        **build_input(
          contact_date: contact_date.strftime('%Y-%m-%d'),
          client_accepted: 1,
        ),
      }
    end

    context 'with valid input' do
      it 'creates a new direct CE referral' do
        referral_id = nil
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          referral_data = result.dig('data', 'createDirectCeReferral', 'referral')
          expect(referral_data['status']).to eq('in_progress')
          referral_id = referral_data['id']
        end.to change(Hmis::Ce::Referral, :count).by(1)

        referral = Hmis::Ce::Referral.find(referral_id)
        # referral is ready for the next step
        expect(referral.workflow_engine.active_steps.map(&:node)).to contain_exactly(provider_acceptance_task)

        # values were saved to CDEs
        step = referral.steps.where(status: 'completed').sole
        expect(step.custom_data_elements.count).to eq(2)
      end

      context 'with assignment rules on unit_group' do
        let!(:eligibility_rule) { create(:hmis_ce_eligibility_requirement, owner: unit_group, expression: 'current_age >= 18') }
        let!(:priority_rule) { create(:hmis_ce_priority_scheme, owner: unit_group, expression: 'days_homeless') }

        it 'captures assignment rules on the referral at creation time' do
          referral_id = perform_mutation(variables)
          referral = Hmis::Ce::Referral.find(referral_id)
          expect(referral.assignment_rules).to be_an(Array)
          expect(referral.assignment_rules.length).to eq(2)
          rule_ids = referral.assignment_rules.map { |r| r['id'] }
          expect(rule_ids).to contain_exactly(eligibility_rule.id, priority_rule.id)
        end
      end
    end

    context 'when user lacks can_manage_outgoing_referrals permission' do
      before do
        remove_permissions(ds_access_control, :can_manage_outgoing_referrals)
      end

      it 'raises access denied error' do
        expect do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end.not_to change(Hmis::Ce::Referral, :count)
      end
    end

    context 'when target project does not accept direct CE referrals' do
      before do
        target_project_ce_config.update!(receives_direct_referrals: false)
      end

      it 'raises access denied error' do
        expect do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end.not_to change(Hmis::Ce::Referral, :count)
      end
    end

    context 'when no units are available for CE referrals' do
      before do
        unit.latest_opportunity.update!(status: 'locked')
      end

      it 'returns an error about unavailability' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          errors = result.dig('data', 'createDirectCeReferral', 'errors')
          expect(errors).to be_present
          expect(errors.first['fullMessage']).to include('no longer has availability')

          referral_data = result.dig('data', 'createDirectCeReferral', 'referral')
          expect(referral_data).to be_nil
        end.not_to change(Hmis::Ce::Referral, :count)
      end
    end

    context 'when form validation fails' do
      before do
        fake_errors = HmisErrors::Errors.new
        fake_errors.add(:base, :invalid, full_message: 'fake error')
        allow_any_instance_of(Hmis::WorkflowExecution::Engine).to receive(:validate_step).and_return(fake_errors.errors)
      end

      it 'does not create a referral and returns errors' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          errors = result.dig('data', 'createDirectCeReferral', 'errors')
          expect(errors).to be_present
          expect(errors.first['fullMessage']).to include('fake error')

          referral_data = result.dig('data', 'createDirectCeReferral', 'referral')
          expect(referral_data).to be_nil
        end.to not_change(Hmis::Ce::Referral, :count).
          and not_change(Hmis::WorkflowExecution::Instance, :count)
      end
    end

    context 'when the unit group has a direct referral workflow template' do
      let!(:direct_referral_workflow_template) { create(:hmis_workflow_definition_template, :with_basic_tasks, data_source: ds1) }
      let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: workflow_template, direct_referral_workflow_template: direct_referral_workflow_template) }

      it 'creates the referral with the correct template' do
        referral_id = nil
        expect do
          referral_id = perform_mutation(variables)
        end.to change(Hmis::Ce::Referral, :count).by(1)

        referral = Hmis::Ce::Referral.find(referral_id)
        expect(referral.workflow_template).to eq(direct_referral_workflow_template)
      end
    end

    # More comprehensive specs for default participant assignment are in the model spec
    # (see spec/models/hmis/ce/referral_spec.rb #create_default_participants!)
    context 'with default swimlane assignments' do
      let!(:case_manager) { create :hmis_user }
      let!(:swimlane) { workflow_template.swimlanes.create!(name: 'Case Managers') }
      let!(:default_assignment) do
        create(:hmis_ce_default_swimlane_assignment, user: case_manager, swimlane: swimlane, owner: project)
      end

      it 'creates referral participants from default assignments' do
        referral_id = nil
        expect do
          referral_id = perform_mutation(variables)
        end.to change(Hmis::Ce::ReferralParticipant, :count).by(1)

        referral = Hmis::Ce::Referral.find(referral_id)
        participant = referral.participants.first
        expect(participant.user).to eq(case_manager)
        expect(participant.swimlane).to eq(swimlane)
      end
    end
  end
end
