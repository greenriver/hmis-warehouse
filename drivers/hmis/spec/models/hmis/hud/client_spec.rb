require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Hud::Client, type: :model do
  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  include_context 'hmis base setup'

  describe 'matching_search_term scope' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, FirstName: 'Jelly', LastName: 'Bean' }
    let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, FirstName: 'Zoo', LastName: 'Jelly' }

    # Note: client_search_spec covers more cases. This is only for the scope.
    it 'should return correct results' do
      [
        ['foo', []],
        ['jelly', [c2, c3]],
        ['bean, jelly', [c2]],
        ['jelly bean', [c2]],
        [c3.id.to_s, [c3]],
        [c3.personal_id, [c3]],
      ].each do |query, expected_result|
        scope = Hmis::Hud::Client.matching_search_term(query)
        expect(scope.count).to eq(expected_result.length)
        expect(scope.pluck(:id)).to eq(expected_result.map(&:id)) if expected_result.any?
      end
    end
  end
end
