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
              participants {
                id
                swimlane {
                  id
                  name
                }
                user {
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

        participant_data = result.dig('data', 'assignReferralParticipants', 'referral', 'participants')
        expect(participant_data).to be_an(Array)

        expect(participant_data).to contain_exactly(
          a_hash_including(
            'user' => a_hash_including(
              'id' => hmis_user.id.to_s,
            ),
            'swimlane' => a_hash_including(
              'id' => case_manager_swimlane.id.to_s,
            ),
          ),
          a_hash_including(
            'user' => a_hash_including(
              'id' => hmis_user2.id.to_s,
            ),
            'swimlane' => a_hash_including(
              'id' => provider_swimlane.id.to_s,
            ),
          ),
        )
      end.to change(Hmis::Ce::ReferralParticipant, :count).by(2)
    end

    describe 'referral with existing participant' do
      let!(:existing_participant) { referral.participants.create(swimlane: case_manager_swimlane, user: hmis_user) }

      it 'does not create duplicate participants' do
        expect do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          participant_data = result.dig('data', 'assignReferralParticipants', 'referral', 'participants')
          expect(participant_data).to be_an(Array)
          expect(participant_data.size).to eq(2) # 1 new + 1 existing
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

            participant_data = result.dig('data', 'assignReferralParticipants', 'referral', 'participants')
            expect(participant_data).to be_an(Array)
            expect(participant_data.size).to eq(0)
          end.to change(Hmis::Ce::ReferralParticipant, :count).from(1).to(0)
        end
      end

      context 'with many existing records and input that both creates and destroys' do
        let!(:existing_participants) do
          10.times.map do |i|
            user = create(:hmis_user, data_source: ds1)
            swimlane = workflow_template.swimlanes.create(name: "Swimlane #{i}")
            referral.participants.create(swimlane: swimlane, user: user)
          end
        end

        let!(:new_users) do
          10.times.map do
            create(:hmis_user, data_source: ds1)
          end
        end

        let!(:new_swimlanes) do
          10.times.map do |i|
            workflow_template.swimlanes.create(name: "New Swimlane #{10 + i}")
          end
        end

        let(:variables) do
          {
            referralId: referral.id,
            participants: [
              *existing_participants.first(5).map do |participant| # keep the first 5 existing participants
                {
                  userId: participant.user.id,
                  swimlaneId: participant.swimlane.id,
                }
              end,
              *10.times.map do |i| # add 10 new participants
                {
                  userId: new_users[i].id,
                  swimlaneId: new_swimlanes[i].id,
                }
              end,
            ],
          }
        end

        it 'adds new participants and removes existing ones in the same mutation' do
          response, result = post_graphql(**variables) { mutation }
          expect(response.status).to eq(200), result.inspect

          participant_data = result.dig('data', 'assignReferralParticipants', 'referral', 'participants')
          expect(participant_data).to be_an(Array)
          expect(participant_data.size).to eq(15) # 5 existing and 10 new
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
