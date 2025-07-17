# frozen_string_literal: true

require 'rails_helper'
require_relative '../login_and_permissions'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Mutations::Ce::SubmitCeReferralStep, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:ds_access_control) do
    create_access_control(
      hmis_user,
      ds1,
      with_permission: [:can_view_project, :can_view_referrals, :can_perform_any_referral_tasks],
    )
  end

  def build_input(contact_date: nil, client_accepted: nil)
    # form structure is defined in factory ce_referral_step_form_definition.
    # these are the same because the link_id and custom_field_key match.
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

  describe 'submit step mutation' do
    let!(:other_user) { create(:user, first_name: 'someone', last_name: 'else') }
    let!(:other_hmis_user) { other_user.related_hmis_user(ds1) }

    before(:each) do
      engine.start_workflow!(user: other_hmis_user)
      step = engine.active_steps.first
      engine.start_step!(step, user: other_hmis_user)
    end

    let(:mutation) do
      <<~GRAPHQL
        mutation SubmitCeReferralStep(
          $referralId: ID!
          $stepId: ID!
          $valuesByLinkId: JsonObject!
          $valuesByFieldName: JsonObject!
          $confirmed: Boolean
          $formDefinitionId: ID!
        ) {
          submitCeReferralStep(
            referralId: $referralId
            stepId: $stepId
            valuesByLinkId: $valuesByLinkId
            valuesByFieldName: $valuesByFieldName
            confirmed: $confirmed
            formDefinitionId: $formDefinitionId
          ) {
            step {
              id
              name
              status
              formDefinition {
                id
              }
              swimlane
            }
            referral {
              id
              status
            }
            #{error_fields}
          }
        }
      GRAPHQL
    end

    let(:step) { engine.active_steps.first }

    let(:base_variables) do
      {
        referralId: referral.id,
        stepId: step.id,
        formDefinitionId: ce_step_definition.id,
      }
    end

    context 'with valid input' do
      let(:contact_date) { 1.day.ago.to_date }
      let(:variables) do
        {
          **base_variables,
          **build_input(
            contact_date: contact_date.strftime('%Y-%m-%d'),
            client_accepted: 1,
          ),
        }
      end

      context 'with permission' do
        it 'submits the step' do
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result&.inspect
            step_data = result.dig('data', 'submitCeReferralStep', 'step')
            expect(step_data['name']).to eq('Client Acceptance')
            expect(step_data['status']).to eq('completed')
            expect(step_data['swimlane']).to eq(case_manager_swimlane.name)
            step.reload
            referral.reload
          end.to change(step, :status).to('completed').
            and change(step, :completed_at).from(nil)
        end

        it 'processes responses onto associated Custom Data Elements' do
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result&.inspect
          end.to change(step.custom_data_elements, :count).from(0).to(2)

          date_cded = step.custom_data_element_definitions.find_by(key: 'contact_date')
          acceptance_cded = step.custom_data_element_definitions.find_by(key: 'client_accepted')

          expect(step.form_processor).to be_present
          expect(step.custom_data_elements).to contain_exactly(
            have_attributes(value_date: contact_date.to_date, data_element_definition_id: date_cded.id),
            have_attributes(value_string: '1', data_element_definition_id: acceptance_cded.id),
          )
        end
      end

      context 'without permission' do
        let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_view_project]) }

        it 'raises an error' do
          expect do
            expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
          end.to not_change(step, :status)
        end
      end

      context 'with permission on own tasks' do
        let!(:ds_access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_referrals, :can_perform_own_referral_tasks, :can_view_project]) }

        it 'raises an error' do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end

        context 'and task assignment' do
          before do
            step.assignments.create!(user: hmis_user)
          end

          it 'submits the step' do
            expect do
              response, result = post_graphql(**variables) { mutation }
              expect(response.status).to eq(200), result.inspect
              step.reload
            end.to change(step, :status).to('completed')
          end
        end
      end
    end

    context 'with invalid input' do
      let(:variables) do
        {
          **base_variables,
          **build_input(
            contact_date: 1.day.ago,
            client_accepted: nil,
          ),
        }
      end

      it 'returns validation errors' do
        expect do
          response, result = post_graphql(**variables, confirmed: true) { mutation }
          expect(response.status).to eq(200), result&.inspect
          errors = result.dig('data', 'submitCeReferralStep', 'errors')
          expect(errors.count).to eq(1)
          expect(errors.first['severity']).to eq('error')
          expect(errors.first['linkId']).to eq('client_accepted')
          expect(errors.first['message']).to eq('must exist')
          step.reload
        end.to not_change(step, :status)
      end
    end
  end
end
