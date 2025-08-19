# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CustomAssessmentFieldMap, type: :model do
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

  # Form definition for tests
  let(:form_definition) { create(:hmis_form_definition, identifier: 'housing_assessment') }

  # Field name constants
  let(:assessment_date_field) { 'housing_assessment.assessment_date' }
  let(:date_created_field) { 'housing_assessment.date_created' }
  let(:date_updated_field) { 'housing_assessment.date_updated' }
  let(:invalid_field) { 'housing_assessment.nonexistent_field' }
  let(:invalid_form_field) { 'nonexistent_form.assessment_date' }

  # Helper method to create custom assessment
  def create_assessment_for_client(client, assessment_date: nil, date_created: nil, date_updated: nil)
    assessment_date ||= current_date - 1.week
    date_created ||= current_date - 2.weeks
    date_updated ||= current_date - 1.day

    create(:hmis_custom_assessment,
           client: client,
           data_source: client.data_source,
           assessment_date: assessment_date,
           date_created: date_created,
           date_updated: date_updated,
           definition: form_definition)
  end

  describe '#client_query' do
    let(:assessment_date) { Date.new(2024, 6, 15) }
    let(:date_created) { Date.new(2024, 6, 10) }
    let(:date_updated) { Date.new(2024, 6, 20) }

    before do
      # Create a single assessment for each client
      create_assessment_for_client(client1, assessment_date: assessment_date, date_created: date_created, date_updated: date_updated)
      create_assessment_for_client(client2, assessment_date: Date.new(2024, 7, 1))
    end

    it 'returns the correct metadata values for a client' do
      # Verify that the correct values are returned from the most recent assessment
      result_assessment_date = field_map.client_query(all_destination_clients, assessment_date_field)
      expect(result_assessment_date[destination_client1.id]).to eq(assessment_date)

      result_date_created = field_map.client_query(all_destination_clients, date_created_field)
      expect(result_date_created[destination_client1.id].to_date).to eq(date_created)

      result_date_updated = field_map.client_query(all_destination_clients, date_updated_field)
      expect(result_date_updated[destination_client1.id].to_date).to eq(date_updated)
    end

    context 'error handling' do
      it 'raises ArgumentError for invalid field name' do
        expect do
          field_map.client_query(all_destination_clients, invalid_field)
        end.to raise_error(ArgumentError, /Unknown field/)
      end

      it 'raises ArgumentError for invalid form identifier' do
        expect do
          field_map.client_query(all_destination_clients, invalid_form_field)
        end.to raise_error(ArgumentError, /Unknown form identifier/)
      end
    end

    context 'with clients having no assessments' do
      let(:clients_no_assessments) { GrdaWarehouse::Hud::Client.where(id: destination_client3.id) }

      it 'returns nil for clients without assessments' do
        result = field_map.client_query(clients_no_assessments, assessment_date_field)
        expect(result[destination_client3.id]).to be_nil
      end

      it 'ensures all clients are in the result hash' do
        result = field_map.client_query(all_destination_clients, assessment_date_field)
        expect(result.keys).to contain_exactly(
          destination_client1.id,
          destination_client2.id,
          destination_client3.id,
        )
      end
    end

    context 'with different form identifiers' do
      let(:other_form_definition) { create(:hmis_form_definition, identifier: 'intake_assessment') }
      let(:intake_field) { 'intake_assessment.assessment_date' }

      before do
        # Create assessment with different form identifier
        create(:hmis_custom_assessment,
               client: client1,
               data_source: client1.data_source,
               assessment_date: Date.new(2024, 9, 1),
               definition: other_form_definition)
      end

      it 'only returns assessments for the specified form identifier' do
        result = field_map.client_query(all_destination_clients, intake_field)
        expect(result[destination_client1.id]).to eq(Date.new(2024, 9, 1))
        expect(result[destination_client2.id]).to be_nil # No intake assessment
      end
    end
  end

  describe 'field labels and formatting' do
    before { form_definition } # Ensure form definition is created

    it 'returns the correct label and formatted value for each field' do
      test_date = Date.new(2024, 6, 15)
      expected_formatted_date = '06/15/2024'

      {
        assessment_date: 'Date Assessment Administered',
        date_created: 'Date Assessment Created',
        date_updated: 'Date Assessment Last Updated',
      }.each do |field_key, expected_label|
        field = "housing_assessment.#{field_key}"

        # Test label_for
        expect(field_map.label_for(field)).to eq(expected_label)

        # Test format_for_display
        expect(field_map.format_for_display(field, test_date)).to eq(expected_formatted_date)
      end
    end

    it 'handles nil values gracefully for formatter' do
      expect(field_map.format_for_display('housing_assessment.assessment_date', nil)).to be_nil
    end

    it 'raises error for unknown fields' do
      expect { field_map.label_for('housing_assessment.unknown_field') }.to raise_error(ArgumentError, /Unknown field/)
      expect { field_map.format_for_display('housing_assessment.unknown_field', Date.current) }.to raise_error(ArgumentError, /Unknown field/)
    end
  end

  describe '#joins' do
    it 'returns joins used for SQL prefiltering' do
      result = field_map.joins('housing_assessment.assessment_date')
      expect(result).to eq([{ destination_client_latest_assessments: :custom_assessment }])
    end
  end

  describe '#arel_field' do
    it 'returns an arel expression for the requested field' do
      form_definition # ensure the identifier exists
      result = field_map.arel_field('housing_assessment.assessment_date')
      expect(result).to be_present
    end
  end
end
