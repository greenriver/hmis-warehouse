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

RSpec.configure do |c|
  c.include GraphqlHelpers
end
