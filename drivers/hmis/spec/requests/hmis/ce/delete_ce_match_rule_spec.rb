# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'deleteCeMatchRule mutation', type: :request do
  include_context 'hmis base setup'

  before(:each) do
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
    allow(Hmis::Ce::Match::CandidatePoolBuilder).to receive(:call)
    hmis_login(user)
  end

  let!(:access_control) { create_access_control(hmis_user, ds1, with_permission: [:can_view_project, :can_administrate_coordinated_entry]) }

  let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: ds1, name: 'Delete me') }
  let(:other_data_source) { create(:hmis_data_source) }

  let(:mutation) do
    <<~GRAPHQL
      mutation DeleteCeMatchRule($id: ID!) {
        deleteCeMatchRule(id: $id) {
          rule {
            id
            name
          }
          #{error_fields}
        }
      }
    GRAPHQL
  end

  it 'deletes a rule' do
    response, result = post_graphql(id: rule.id) { mutation }
    expect(response.status).to eq(200), result.inspect

    expect(result.dig('data', 'deleteCeMatchRule', 'rule')).to include('id' => rule.id.to_s, 'name' => 'Delete me')
    expect(Hmis::Ce::Match::Rule.with_deleted.find(rule.id)).to be_deleted
  end

  context 'when the rule is in another data source' do
    let!(:rule) { create(:hmis_ce_eligibility_requirement, owner: other_data_source, name: 'Other DS') }

    it 'denies access' do
      expect_access_denied post_graphql(id: rule.id) { mutation }
    end
  end
end
