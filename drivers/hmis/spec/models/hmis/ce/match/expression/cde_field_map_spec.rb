# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CdeFieldMap, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }

  let!(:client1) { create(:hmis_hud_client_with_warehouse_client) }
  let!(:destination_client1) { client1.destination_client }
  let!(:client2) { create(:hmis_hud_client_with_warehouse_client) }
  let!(:destination_client2) { client2.destination_client }
  let!(:client3_no_assessment) { create(:hmis_hud_client_with_warehouse_client) }
  let!(:destination_client3) { client3_no_assessment.destination_client }

  let(:all_destination_clients) { GrdaWarehouse::Hud::Client.where(id: [destination_client1.id, destination_client2.id, destination_client3.id]) }

  # Create a form definition and custom data element definition
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'test_form') }
  let!(:string_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'language_preference',
           field_type: 'string',
           form_definition_identifier: 'test_form')
  end
  let!(:repeating_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'allergies',
           field_type: 'string',
           repeats: true,
           form_definition_identifier: 'test_form')
  end

  describe '#client_query' do
    before do
      # Setup an assessment for client1
      assessment_c1 = create(:hmis_custom_assessment,
                             client: client1,
                             data_source: client1.data_source,
                             assessment_date: current_date - 1.week,
                             definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment_c1,
             data_element_definition: string_cded,
             value_string: 'English',
             data_source: client1.data_source)
      create(:hmis_custom_data_element,
             owner: assessment_c1,
             data_element_definition: repeating_cded,
             value_string: 'Peanuts',
             data_source: client1.data_source)
      create(:hmis_custom_data_element,
             owner: assessment_c1,
             data_element_definition: repeating_cded,
             value_string: 'Dust',
             data_source: client1.data_source)

      # Setup assessment for client2
      assessment_c2 = create(:hmis_custom_assessment,
                             client: client2,
                             data_source: client2.data_source,
                             assessment_date: current_date - 1.week,
                             definition: form_definition)
      create(:hmis_custom_data_element,
             owner: assessment_c2,
             data_element_definition: string_cded,
             value_string: 'French',
             data_source: client2.data_source)
      # Client 2 has no 'allergies' data
    end

    it 'fetches values for multiple clients and selects the most recent assessment' do
      # Initial check for all clients
      initial_result = field_map.client_query(all_destination_clients, 'custom_assessment.language_preference')
      expect(initial_result).to include(
        destination_client1.id => 'English',
        destination_client2.id => 'French',
      )

      # Expect client1's value to change when a more recent assessment is added
      expect do
        # Create an even more recent assessment for client1
        new_assessment = create(:hmis_custom_assessment,
                                client: client1,
                                data_source: client1.data_source,
                                assessment_date: current_date, # Newest date
                                definition: form_definition)
        create(:hmis_custom_data_element,
               owner: new_assessment,
               data_element_definition: string_cded,
               value_string: 'Klingon',
               data_source: client1.data_source)
      end.to change { field_map.client_query(all_destination_clients, 'custom_assessment.language_preference')[destination_client1.id] }.
        from('English').to('Klingon')

      # Verify other clients were not affected
      final_result = field_map.client_query(all_destination_clients, 'custom_assessment.language_preference')
      expect(final_result[destination_client2.id]).to eq('French')
    end

    it 'returns an array for repeating CDEs' do
      result = field_map.client_query(all_destination_clients, 'custom_assessment.allergies')
      expect(result[destination_client1.id]).to contain_exactly('Peanuts', 'Dust')
    end

    it 'returns an empty array for repeating CDEs if no value is present' do
      result = field_map.client_query(all_destination_clients, 'custom_assessment.allergies')
      expect(result[destination_client2.id]).to eq([])
    end

    it 'handles clients without any assessments gracefully' do
      # Returns empty array for repeating fields
      result_repeating = field_map.client_query(all_destination_clients, 'custom_assessment.allergies')
      expect(result_repeating[destination_client3.id]).to eq([])

      # Returns nil for non-repeating fields
      result_non_repeating = field_map.client_query(all_destination_clients, 'custom_assessment.language_preference')
      expect(result_non_repeating[destination_client3.id]).to be_nil
    end

    context 'when a client has multiple assessments on the same day' do
      let!(:client_with_same_day_assessments) { create(:hmis_hud_client_with_warehouse_client) }
      let!(:destination_client_same_day) { client_with_same_day_assessments.destination_client }
      let(:query_clients) { GrdaWarehouse::Hud::Client.where(id: destination_client_same_day.id) }

      before do
        same_day = current_date - 5.days
        # first one created
        assessment1 = create(:hmis_custom_assessment,
                             client: client_with_same_day_assessments,
                             data_source: client_with_same_day_assessments.data_source,
                             assessment_date: same_day,
                             definition: form_definition)
        create(:hmis_custom_data_element,
               owner: assessment1,
               data_element_definition: string_cded,
               value_string: 'First',
               data_source: client_with_same_day_assessments.data_source)

        # second one created, should be picked
        assessment2 = create(:hmis_custom_assessment,
                             client: client_with_same_day_assessments,
                             data_source: client_with_same_day_assessments.data_source,
                             assessment_date: same_day,
                             definition: form_definition)
        create(:hmis_custom_data_element,
               owner: assessment2,
               data_element_definition: string_cded,
               value_string: 'Second',
               data_source: client_with_same_day_assessments.data_source)
      end

      it 'selects the most recently created assessment' do
        result = field_map.client_query(query_clients, 'custom_assessment.language_preference')
        expect(result[destination_client_same_day.id]).to eq('Second')
      end
    end
  end

  describe '#arel_field' do
    it 'returns nil' do
      result = field_map.arel_field('custom_assessment.language_preference')
      expect(result).to be_nil
    end
  end

  describe '#joins' do
    it 'returns nil since CDE fields are not directly joinable for prefiltering' do
      result = field_map.joins('custom_assessment.language_preference')
      expect(result).to be_nil
    end
  end
end
