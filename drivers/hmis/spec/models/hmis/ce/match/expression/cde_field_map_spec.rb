# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CdeFieldMap, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }

  let(:client1) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client1) { client1.destination_client }
  let(:client2) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client2) { client2.destination_client }
  let(:client3_no_assessment) { create(:hmis_hud_client_with_warehouse_client) }
  let(:destination_client3) { client3_no_assessment.destination_client }

  let(:all_destination_clients) { GrdaWarehouse::Hud::Client.where(id: [destination_client1.id, destination_client2.id, destination_client3.id]) }

  # Create a form definition and custom data element definition
  # Field name constants
  let(:language_field) { 'custom_assessment.language_preference' }
  let(:allergies_field) { 'custom_assessment.allergies' }
  let(:invalid_field) { 'custom_assessment.nonexistent_field' }

  let(:form_definition) { create(:hmis_form_definition, identifier: 'test_form') }
  let(:string_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'language_preference',
           field_type: 'string',
           form_definition_identifier: 'test_form')
  end
  let(:repeating_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'allergies',
           field_type: 'string',
           repeats: true,
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

  describe '#client_query' do
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

    it 'selects values from the most recent assessment' do
      # Create an older assessment
      create_assessment_for_client(client1, language_preference: 'English', assessment_date: current_date - 10.days)
      # Create a more recent assessment that should be selected
      create_assessment_for_client(client1, language_preference: 'Klingon', assessment_date: current_date)

      result = field_map.client_query(all_destination_clients, language_field)
      expect(result[destination_client1.id]).to eq('Klingon')
    end

    it 'returns an array for repeating CDEs' do
      result = field_map.client_query(all_destination_clients, allergies_field)
      expect(result[destination_client1.id]).to contain_exactly('Peanuts', 'Dust')
    end

    it 'handles clients without assessments and missing repeating values' do
      # Client3 has no assessments - returns empty array for repeating fields, nil for non-repeating
      result_repeating = field_map.client_query(all_destination_clients, allergies_field)
      expect(result_repeating[destination_client3.id]).to eq([])

      result_non_repeating = field_map.client_query(all_destination_clients, language_field)
      expect(result_non_repeating[destination_client3.id]).to be_nil

      # Client2 has assessment but no allergies data - returns empty array for missing repeating field
      expect(result_repeating[destination_client2.id]).to eq([])
    end

    it 'raises an error for invalid field names' do
      expect do
        field_map.client_query(all_destination_clients, invalid_field)
      end.to raise_error(ArgumentError, /Unknown CDE in field/)
    end
  end
end
