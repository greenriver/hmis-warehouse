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

  let!(:unit_group) { create(:hmis_unit_group, project: project, workflow_template: workflow_template, direct_referral_entrypoint: client_acceptance_task) }
  let!(:unit) { create(:hmis_unit, unit_group: unit_group) }
  let!(:target_opportunity) { create(:hmis_ce_opportunity, project: project, workflow_template: workflow_template, unit: unit) }

  let!(:target_project_ce_config) { create(:hmis_project_ce_config, project: project, accepts_direct_referrals: true) }

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
        target_project_ce_config.update!(accepts_direct_referrals: false)
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
  end
end
