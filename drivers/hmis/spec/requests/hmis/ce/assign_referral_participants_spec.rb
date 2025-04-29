# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/ce_spec_helper'

RSpec.describe Mutations::Ce::AssignReferralParticipants, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  let!(:provider_swimlane) { workflow_template.swimlanes.create!(name: 'Providers') }
  let!(:provider_acceptance_task) do
    create(
      :hmis_workflow_definition_task,
      template: workflow_template,
      name: 'Provider Acceptance',
      swimlane: provider_swimlane,
      form_definition: create(:hmis_form_definition),
    )
  end

  let!(:hmis_user2) { create(:hmis_user, data_source: ds1) }

  describe 'assign participants mutation' do
    let(:mutation) do
      <<~GRAPHQL
        mutation AssignParticipants($referralId: ID!, $participants: [CeReferralParticipantInput!]!) {
          assignReferralParticipants(referralId: $referralId, participants: $participants) {
            referral {
              id
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
        }
      GRAPHQL
    end

    let(:variables) do
      {
        referralId: referral.id,
        participants: [
          {
            userId: hmis_user.id,
            swimlaneId: case_manager_swimlane.id,
          },
          {
            userId: hmis_user2.id,
            swimlaneId: provider_swimlane.id,
          },
        ],
      }
    end

    it 'creates referral participants' do
      expect do
        response, result = post_graphql(**variables) { mutation }
        expect(response.status).to eq(200), result.inspect

        referral_swimlanes = result.dig('data', 'assignReferralParticipants', 'referral', 'swimlanes')
        expect(referral_swimlanes).to contain_exactly(
          a_hash_including(
            'id' => case_manager_swimlane.id.to_s,
            'name' => case_manager_swimlane.name,
            'participants' => [
              a_hash_including(
                'id' => hmis_user.id.to_s,
                'name' => hmis_user.name,
              ),
            ],
          ),
          a_hash_including(
            'id' => provider_swimlane.id.to_s,
            'name' => provider_swimlane.name,
            'participants' => [
              a_hash_including(
                'id' => hmis_user2.id.to_s,
                'name' => hmis_user2.name,
              ),
            ],
          ),
        )
      end.to change(Hmis::Ce::ReferralParticipant, :count).by(2)
    end

    describe 'referral with available task' do
      before do
        referral.workflow_engine.start_workflow!(user: hmis_user)
      end

      it 'creates assignees as well as participants' do
        step = referral.workflow_engine.active_steps.sole
        expect do
          post_graphql(**variables) { mutation }
          step.reload
        end.to change(step.assignments, :count).from(0).to(1)
        expect(step.assignments.sole.user).to eq(hmis_user)
      end
    end

    describe 'referral with existing participant' do
      let!(:existing_participant) { referral.participants.create(swimlane: case_manager_swimlane, user: hmis_user) }

      it 'does not create duplicate participants' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect
          existing_participant.reload
        end.to change(Hmis::Ce::ReferralParticipant, :count).from(1).to(2).
          and not_change(existing_participant, :updated_at)
      end

      context 'with input that indicates deletion of a participant' do
        let(:variables) do
          {
            referralId: referral.id,
            participants: [],
          }
        end

        it 'deletes removed participants' do
          expect do
            response, result = post_graphql(**variables) { mutation }
            expect(response.status).to eq(200), result.inspect
          end.to change(Hmis::Ce::ReferralParticipant, :count).from(1).to(0)
        end
      end
    end

    context 'with invalid user' do
      let(:variables) do
        {
          referralId: referral.id,
          participants: [
            {
              userId: 'abc',
              swimlaneId: case_manager_swimlane.id,
            },
          ],
        }
      end

      it 'raises an error' do
        expect_gql_error(post_graphql(**variables) { mutation }, message: 'Not found')
      end
    end

    context 'with invalid swimlane' do
      let(:variables) do
        {
          referralId: referral.id,
          participants: [
            {
              userId: hmis_user.id,
              swimlaneId: 'xyz',
            },
          ],
        }
      end

      it 'raises an error' do
        expect_gql_error(post_graphql(**variables) { mutation }, message: 'Not found')
      end
    end
  end
end
