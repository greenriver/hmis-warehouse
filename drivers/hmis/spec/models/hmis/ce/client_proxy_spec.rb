###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::ClientProxy, type: :model do
  let!(:destination_client) { create :grda_warehouse_hud_client }
  let!(:source_client) { create :hmis_hud_client }

  describe 'ClientProxy model validations' do
    it 'expects a destination client' do
      proxy = build(:hmis_ce_client_proxy, client: destination_client)
      expect(proxy.valid?).to be_truthy
      expect do
        proxy.save!
      end.to change(Hmis::Ce::ClientProxy, :count).from(0).to(1)
    end

    it 'raises for source client' do
      proxy = build(:hmis_ce_client_proxy, client: source_client)
      expect(proxy.valid?).to be_falsy
      expect do
        proxy.save!
      end.to raise_error(ActiveRecord::RecordInvalid, /must be destination client/)
    end
  end

  describe 'Client deletion behavior' do
    let!(:proxy) { create(:hmis_ce_client_proxy, client: destination_client) }
    let!(:candidate) { create(:hmis_ce_match_candidate, client_proxy: proxy) }

    it 'deletes associated proxies and candidates' do
      expect do
        destination_client.destroy!
      end.to change(Hmis::Ce::Match::Candidate, :count).by(-1).
        and change(Hmis::Ce::ClientProxy, :count).by(-1)

      expect(Hmis::Ce::ClientProxy.find_by(id: proxy.id)).to be_nil
      expect(Hmis::Ce::Match::Candidate.find_by(id: candidate.id)).to be_nil
    end
  end

  describe '#matching_cde_values' do
    let(:current_date) { Date.new(2024, 12, 26) }
    let!(:ds) { create(:hmis_data_source) }
    let(:form_definition) { create(:hmis_form_definition, identifier: 'test_form', data_source: ds) }
    let(:string_cded) do
      create(:hmis_custom_data_element_definition,
             owner_type: 'Hmis::Hud::CustomAssessment',
             key: 'language_preference',
             field_type: 'string',
             data_source: ds,
             form_definition_identifier: 'test_form')
    end
    let(:repeating_cded) do
      create(:hmis_custom_data_element_definition,
             owner_type: 'Hmis::Hud::CustomAssessment',
             key: 'allergies',
             field_type: 'string',
             repeats: true,
             data_source: ds,
             form_definition_identifier: 'test_form')
    end

    # Helper method to create assessment with custom data elements
    def create_assessment_for_client(client, language_preference: nil, allergies: [], assessment_date: nil)
      assessment_date ||= current_date - 1.week

      assessment = create(:hmis_custom_assessment,
                          client: client,
                          data_source: client.data_source,
                          assessment_date: assessment_date,
                          definition: form_definition)

      if language_preference
        create(:hmis_custom_data_element,
               owner: assessment,
               data_element_definition: string_cded,
               value_string: language_preference,
               data_source: client.data_source)
      end

      allergies.each do |allergy|
        create(:hmis_custom_data_element,
               owner: assessment,
               data_element_definition: repeating_cded,
               value_string: allergy,
               data_source: client.data_source)
      end

      assessment
    end
    let(:client1) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
    let(:destination_client1) { client1.destination_client }
    let(:client2) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
    let(:destination_client2) { client2.destination_client }
    let(:client3_no_assessment) { create(:hmis_hud_client_with_warehouse_client, data_source: ds) }
    let(:destination_client3) { client3_no_assessment.destination_client }

    let!(:proxy_for_client1) { create(:hmis_ce_client_proxy, client: destination_client1) }
    let!(:proxy_for_client2) { create(:hmis_ce_client_proxy, client: destination_client2) }
    let!(:proxy_for_client3) { create(:hmis_ce_client_proxy, client: destination_client3) }

    let(:proxy_scope) { Hmis::Ce::ClientProxy.where(id: [proxy_for_client1.id, proxy_for_client2.id, proxy_for_client3.id]) }

    before do
      create_assessment_for_client(
        client1,
        language_preference: 'English',
        allergies: ['Peanuts', 'Dust'],
      )
      create_assessment_for_client(
        client2,
        language_preference: 'French',
        # Client 2 has no 'allergies' data
      )
    end

    it 'matches client proxies whose latest assessment has a non-repeating CDE value in the list' do
      expect(proxy_scope.matching_cde_values(string_cded, ['English'])).to contain_exactly(proxy_for_client1)
    end

    it 'matches any of several string values (OR within one filter)' do
      expect(proxy_scope.matching_cde_values(string_cded, ['English', 'French'])).to contain_exactly(proxy_for_client1, proxy_for_client2)
    end

    it 'matches when any repeating CDE row matches one of the filter values' do
      expect(proxy_scope.matching_cde_values(repeating_cded, ['Peanuts'])).to contain_exactly(proxy_for_client1)
    end

    it 'is bounded to the current scope client ids' do
      expect(described_class.where(id: proxy_for_client2.id).matching_cde_values(string_cded, ['English', 'French'])).
        to contain_exactly(proxy_for_client2)
    end
  end
end
