# frozen_string_literal: true

require_relative '../../../support/ce_spec_helper'

RSpec.describe Hmis::GraphqlController, type: :request do
  include_context 'ce spec helper'

  before(:each) do
    hmis_login(user)
  end

  before do
    referral.workflow_engine.start_workflow!(user: hmis_user)
  end

  describe 'ce_referral notes' do
    let(:mutation) do
      <<~GRAPHQL
        mutation CreateCeReferralNote($referralId: ID!, $note: String!) {
          createCeReferralNote(referralId: $referralId, note: $note) {
            referral {
              id
              notes {
                nodes {
                  id
                  note
                  user {
                    id
                    name
                  }
                }
              }
            }
          }
        }
      GRAPHQL
    end

    let(:variables) do
      { referralId: referral.id, note: 'Test note content' }
    end

    context 'when creating a referral note' do
      context 'with permission on full referral' do
        let!(:ds_access_control) do
          create_access_control(
            hmis_user,
            ds1,
            with_permission: [
              :can_view_project,
              :can_view_referrals,
              :can_perform_any_referral_tasks,
            ],
          )
        end
        it 'creates a note and resolves it on the referral response' do
          response, result = post_graphql(**variables) { mutation }

          expect(response.status).to eq(200), result.inspect
          expect(result.dig('data', 'createCeReferralNote', 'referral', 'notes', 'nodes')).to contain_exactly(
            a_hash_including(
              'note' => 'Test note content',
              'user' => a_hash_including('id' => hmis_user.id.to_s, 'name' => hmis_user.name),
            ),
          )
        end
      end
      context 'with permission on own tasks' do
        let!(:ds_access_control) do
          create_access_control(
            hmis_user,
            ds1,
            with_permission: [
              :can_view_project,
              :can_view_referrals,
              :can_perform_own_referral_tasks,
            ],
          )
        end
        it 'raises an access error' do
          expect_gql_error(post_graphql(**variables) { mutation }, message: 'access denied')
        end

        context 'and an available task assignment' do
          before do
            referral.workflow_engine.active_steps.first.assignments.create!(user: hmis_user)
          end

          it 'creates a note and resolves it on the referral response' do
            response, result = post_graphql(**variables) { mutation }

            expect(response.status).to eq(200), result.inspect
            expect(result.dig('data', 'createCeReferralNote', 'referral', 'notes', 'nodes')).to contain_exactly(
              a_hash_including(
                'note' => 'Test note content',
                'user' => a_hash_including('id' => hmis_user.id.to_s, 'name' => hmis_user.name),
              ),
            )
          end
        end
      end
    end
  end
end

RSpec.configure do |c|
  c.include GraphqlHelpers
end
