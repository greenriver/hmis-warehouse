###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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

  describe 'source_hash checks' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, FirstName: 'Jelly', LastName: 'Bean' }
    it 'should exist when a new record is created, and change when updated' do
      initial_source_hash = c2.source_hash
      expect(initial_source_hash).to be_present
      c2.update!(FirstName: 'Jelly2')
      expect(initial_source_hash).not_to eq(c2.reload.source_hash)
    end
  end

  describe 'matching_search_term scope' do
    let!(:c2) { create :hmis_hud_client, data_source: ds1, user: u1, FirstName: 'Jelly', LastName: 'Bean' }
    let!(:c3) { create :hmis_hud_client, data_source: ds1, user: u1, FirstName: 'Zoo', LastName: 'Jelly' }

    # Note: client_search_spec covers more cases. This is only for the scope.
    it 'should return correct results' do
      [
        ['foo', []],
        ['jelly', [c3, c2]],
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
    let!(:c1) { create :hmis_hud_client_complete, data_source: ds1, user: u1, FirstName: 'Jelly', LastName: 'Bean' }

    it 'should handle names correctly' do
      n1 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'First', primary: true)
      n2 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Second')
      n3 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Third')
      c1.update(names: [n1, n2, n3])
      expect(c1.names).to contain_exactly(*[n1, n2, n3].map { |n| have_attributes(id: n.id) })
      expect(c1.names.primary_names).to contain_exactly(have_attributes(id: n1.id))
      expect(c1.primary_name).to have_attributes(id: n1.id)
      expect(c1.valid?(:client_form)).to be true

      n4 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Fourth', primary: true)
      c1.update(names: [n1, n2, n3, n4])
      expect(c1.valid?(:client_form)).to be false
    end

    it 'should update name when primary name is updated' do
      n1 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'First', primary: true)
      n2 = create(:hmis_hud_custom_client_name, user: u1, data_source: ds1, client: c1, first: 'Second')

      c1.update_name_from_primary_name!
      expect(c1.first_name).to eq('First')

      n2.update!(first: 'New Second Value')
      c1.update_name_from_primary_name!
      expect(c1.first_name).to eq('First')

      n1.update!(first: 'New First Value')
      c1.reload.update_name_from_primary_name!
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
      expect do
        client.destroy!
        client.reload
      end.
        to not_change(client, :data_source).
        and not_change(client, :user)
    end

    it 'destroys dependent data' do
      referral = create(:hmis_external_api_ac_hmis_referral)
      referral.household_members.create!(
        relationship_to_hoh: 'self_head_of_household',
        client: client,
      )

      expect do
        client.destroy!
        client.reload
      end.
        to change(client, :enrollments).to([]).
        and change(client, :external_referral_household_members).to([]).
        and change(HmisExternalApis::AcHmis::Referral, :count).to(0)
    end
  end

  describe 'with_service_in_range scope' do
    include_context 'hmis service setup'

    # c1 received a HUD Bed Night Service 8 months ago
    let!(:c1) { create :hmis_hud_client, data_source: ds1 }
    let!(:c1_e1) { create :hmis_hud_enrollment, data_source: ds1, client: c1, project: p1, entry_date: 1.year.ago }
    let!(:c1_e1_s1_hud) { create(:hmis_hud_service_bednight, date_provided: 8.months.ago, data_source: ds1, client: c1, enrollment: c1_e1) }

    # c1 received a HUD Bed Night Service 2 months ago, and a custom service 1 week ago and 8 months ago
    let!(:c2) { create :hmis_hud_client, data_source: ds1 }
    let!(:c2_e1) { create :hmis_hud_enrollment, data_source: ds1, client: c2, project: p1, entry_date: 1.year.ago }
    let!(:c2_e1_s1_hud) { create(:hmis_hud_service_bednight, date_provided: 2.months.ago, data_source: ds1, client: c2, enrollment: c2_e1) }
    let!(:c2_e1_s2_custom) { create(:hmis_custom_service, date_provided: 1.week.ago, custom_service_type: cst1, data_source: ds1, client: c2, enrollment: c2_e1) }
    let!(:c2_e1_s3_custom) { create(:hmis_custom_service, date_provided: 8.months.ago, custom_service_type: cst1, data_source: ds1, client: c2, enrollment: c2_e1) }

    let(:bed_night_cst) { Hmis::Hud::CustomServiceType.find_by(hud_record_type: 200) }
    let!(:p2) { create :hmis_hud_project, data_source: ds1, organization: o1 }

    it 'should work' do
      [
        [{ start_date: 1.year.ago }, [c1, c2]],
        [{ start_date: 1.year.ago, project_id: p1.id }, [c1, c2]],
        [{ start_date: 1.year.ago, project_id: p2.id }, []],
        [{ start_date: 2.weeks.ago }, [c2]],
        [{ start_date: 1.year.ago, end_date: 6.months.ago }, [c1, c2]], # c1 bed night, c2 custom
        [{ start_date: 1.year.ago, end_date: 6.months.ago, service_type_id: bed_night_cst.id }, [c1]],
        [{ start_date: 1.year.ago, end_date: 6.months.ago, service_type_id: bed_night_cst.id, project_id: p1.id }, [c1]],
        [{ start_date: 1.year.ago, service_type_id: cst1.id, project_id: p1.id }, [c2]],
      ].each do |args, expected_result|
        scope = Hmis::Hud::Client.with_service_in_range(**args)
        expect(scope.count).to eq(expected_result.length)
        expect(scope.pluck(:id)).to eq(expected_result.map(&:id)) if expected_result.any?
      end
    end

    it 'should include clients that had services at WIP Enrollments' do
      c1_e1.save_in_progress!
      expect(Hmis::Hud::Client.with_service_in_range(start_date: 1.year.ago)).to include(c1)
    end
  end
end
