###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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

  describe 'with multiple names' do
    it 'should handle names correctly' do
      n1 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'First', primary: true)
      n2 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Second')
      n3 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Third')

      expect(c1.names).to contain_exactly(*[n1, n2, n3].map { |n| have_attributes(id: n.id) })
      expect(c1.names.primary_names).to contain_exactly(have_attributes(id: n1.id))
      expect(c1.primary_name).to have_attributes(id: n1.id)

      expect do
        create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Fourth', primary: true)
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'should update name when primary name is updated' do
      n1 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'First', primary: true)
      n2 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Second')

      expect(c1.first_name).to eq('First')

      n2.update(first: 'New Second Value')
      expect(c1.first_name).to eq('First')

      n1.update(first: 'New First Value')
      expect(c1.first_name).to eq('New First Value')
    end
  end

  describe 'with addresses' do
    it 'should handle addresses correctly' do
      expect(c1.addresses).to be_empty
      create(:hmis_hud_custom_client_address, user: u1, data_source: ds1, client: c1, line1: '999 Test Ave')
      expect(c1.addresses).to contain_exactly(have_attributes(line1: '999 Test Ave'))
    end
  end

  describe 'when destroying clients' do
    let!(:client) { create :hmis_hud_client }
    before(:each) do
      create(:hmis_hud_enrollment, client: client, user: client.user, data_source: client.data_source)
    end

    it 'preserves shared data' do
      client.destroy
      client.reload

      [
        :data_source,
        :user,
      ].each do |assoc|
        expect(client.send(assoc)).to be_present, "expected #{assoc} to be present"
      end
    end

    it 'destroys dependent data' do
      client.reload
      [
        :enrollments,
      ].each do |assoc|
        expect(client.send(assoc)).to be_present, "expected #{assoc} to be present"
      end

      client.destroy
      client.reload

      [
        :enrollments,
      ].each do |assoc|
        expect(client.send(assoc)).not_to be_present, "expected #{assoc} not to be present"
      end
    end
  end
end
