###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::DestinationClientLatestAssessment, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }

  # Clients
  let(:client1) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client1) { client1.destination_client }
  let(:client2) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client2) { client2.destination_client }
  let(:client3_no_assessment) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client3) { client3_no_assessment.destination_client }

  # Form definitions
  let(:form1) { create(:hmis_form_definition, identifier: 'form_1') }
  let(:form2) { create(:hmis_form_definition, identifier: 'form_2') }

  # Helper to create assessments
  def create_assessment(client, definition, assessment_date)
    create(:hmis_custom_assessment,
           client: client,
           data_source: client.data_source,
           assessment_date: assessment_date,
           definition: definition)
  end

  describe 'database view behavior' do
    before do
      # Client 1: Multiple assessments for the same form
      create_assessment(client1, form1, current_date - 10.days) # Older
      create_assessment(client1, form1, current_date - 5.days) # Newest for form1
      create_assessment(client1, form1, current_date - 20.days) # Oldest

      # Client 1: Assessment for a different form
      create_assessment(client1, form2, current_date - 8.days)

      # Client 2: Single assessment
      create_assessment(client2, form1, current_date - 15.days)

      # Client 3 has no assessments
    end

    it 'is a read-only model' do
      expect(described_class.new).to be_readonly
    end

    it 'correctly identifies the latest assessment for a client and form' do
      latest_for_client1_form1 = described_class.find_by(
        destination_client_id: destination_client1.id,
        form_identifier: 'form_1',
      )
      expect(latest_for_client1_form1.custom_assessment.assessment_date).to eq(current_date - 5.days)
    end

    it 'returns the correct assessment when a client has assessments for multiple forms' do
      latest_for_client1_form2 = described_class.find_by(
        destination_client_id: destination_client1.id,
        form_identifier: 'form_2',
      )
      expect(latest_for_client1_form2.custom_assessment.assessment_date).to eq(current_date - 8.days)
    end

    it 'handles clients with only one assessment' do
      latest_for_client2 = described_class.find_by(
        destination_client_id: destination_client2.id,
        form_identifier: 'form_1',
      )
      expect(latest_for_client2.custom_assessment.assessment_date).to eq(current_date - 15.days)
    end

    it 'does not return a record for clients with no assessments' do
      latest_for_client3 = described_class.find_by(destination_client_id: destination_client3.id)
      expect(latest_for_client3).to be_nil
    end

    context 'when multiple assessments are on the same day' do
      let!(:assessment1) { create_assessment(client1, form1, current_date - 2.days) }
      let!(:assessment2) { create_assessment(client1, form1, current_date - 2.days) }

      it 'prefers the one with the higher ID as the latest' do
        latest = described_class.find_by(
          destination_client_id: destination_client1.id,
          form_identifier: 'form_1',
        )
        # In case of a tie in date, the view orders by ID descending
        expect(latest.custom_assessment_id).to eq([assessment1.id, assessment2.id].max)
      end
    end
  end

  describe '.with_cde_value scope' do
    let(:current_date) { Date.new(2024, 12, 26) }
    # Form definition, CDEDs, and clients must share a data source: the view keys on the form
    # definition's data_source_id, and with_cde_value filters on it.
    let!(:ds) { create(:hmis_data_source) }
    let(:form_definition) { create(:hmis_form_definition, identifier: 'cde_value_form', data_source: ds) }
    let(:string_cded) do
      create(:hmis_custom_data_element_definition,
             owner_type: 'Hmis::Hud::CustomAssessment',
             key: 'language_preference',
             field_type: 'string',
             data_source: ds,
             form_definition_identifier: 'cde_value_form')
    end
    let(:repeating_cded) do
      create(:hmis_custom_data_element_definition,
             owner_type: 'Hmis::Hud::CustomAssessment',
             key: 'allergies',
             field_type: 'string',
             repeats: true,
             data_source: ds,
             form_definition_identifier: 'cde_value_form')
    end

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

    let(:candidate_client_ids) { [destination_client1.id, destination_client2.id] }

    # Convenience: the matching destination client ids for a given scope, bounded to candidates.
    def matching_ids(cded, filter_values)
      described_class.
        where(destination_client_id: candidate_client_ids).
        with_cde_value(cded, filter_values).
        distinct.
        pluck(:destination_client_id)
    end

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

    it 'matches rows whose latest assessment has a non-repeating CDE value in the list' do
      expect(matching_ids(string_cded, ['English'])).to contain_exactly(destination_client1.id)
    end

    it 'matches any of several string values (OR across filter values)' do
      expect(matching_ids(string_cded, ['English', 'French'])).to contain_exactly(destination_client1.id, destination_client2.id)
    end

    it 'matches when any repeating CDE row matches one of the filter values' do
      expect(matching_ids(repeating_cded, ['Peanuts'])).to contain_exactly(destination_client1.id)
    end

    it 'is bounded by the destination_client_id restriction the caller applies' do
      result = described_class.
        where(destination_client_id: [destination_client2.id]).
        with_cde_value(string_cded, ['English', 'French']).
        distinct.
        pluck(:destination_client_id)
      expect(result).to contain_exactly(destination_client2.id)
    end

    it 'returns no rows when no value matches' do
      expect(matching_ids(string_cded, ['Klingon'])).to be_empty
    end
  end
end
