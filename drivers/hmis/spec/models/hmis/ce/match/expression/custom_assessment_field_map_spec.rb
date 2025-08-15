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
    before do
      # Create assessments with different timestamps
      create_assessment_for_client(
        client1,
        assessment_date: Date.new(2024, 6, 15),
        date_created: Date.new(2024, 6, 10),
        date_updated: Date.new(2024, 6, 20),
      )
      create_assessment_for_client(
        client2,
        assessment_date: Date.new(2024, 7, 1),
        date_created: Date.new(2024, 6, 25),
        date_updated: Date.new(2024, 7, 5),
      )
    end

    context 'for assessment_date field' do
      it 'returns the assessment date for each client' do
        result = field_map.client_query(all_destination_clients, assessment_date_field)
        expect(result).to include(
          destination_client1.id => Date.new(2024, 6, 15),
          destination_client2.id => Date.new(2024, 7, 1),
        )
        expect(result[destination_client3.id]).to be_nil
      end
    end

    context 'for date_created field' do
      it 'returns the date created for each client' do
        result = field_map.client_query(all_destination_clients, date_created_field)
        expect(result[destination_client1.id].to_date).to eq(Date.new(2024, 6, 10))
        expect(result[destination_client2.id].to_date).to eq(Date.new(2024, 6, 25))
        expect(result[destination_client3.id]).to be_nil
      end
    end

    context 'for date_updated field' do
      it 'returns the date updated for each client' do
        result = field_map.client_query(all_destination_clients, date_updated_field)
        expect(result[destination_client1.id].to_date).to eq(Date.new(2024, 6, 20))
        expect(result[destination_client2.id].to_date).to eq(Date.new(2024, 7, 5))
        expect(result[destination_client3.id]).to be_nil
      end
    end

    context 'when client has multiple assessments' do
      before do
        # Create a more recent assessment for client1
        create_assessment_for_client(
          client1,
          assessment_date: Date.new(2024, 8, 1),
          date_created: Date.new(2024, 7, 25),
          date_updated: Date.new(2024, 8, 5),
        )
      end

      it 'selects the most recent assessment based on assessment date' do
        result = field_map.client_query(all_destination_clients, assessment_date_field)
        expect(result[destination_client1.id]).to eq(Date.new(2024, 8, 1))
      end

      it 'selects date_created from the most recent assessment' do
        result = field_map.client_query(all_destination_clients, date_created_field)
        expect(result[destination_client1.id].to_date).to eq(Date.new(2024, 7, 25))
      end

      it 'selects date_updated from the most recent assessment' do
        result = field_map.client_query(all_destination_clients, date_updated_field)
        expect(result[destination_client1.id].to_date).to eq(Date.new(2024, 8, 5))
      end
    end

    context 'when multiple assessments have the same assessment date' do
      let(:client_same_day) { create(:hmis_hud_client_with_warehouse_client) }
      let(:destination_client_same_day) { client_same_day.destination_client }
      let(:query_clients) { GrdaWarehouse::Hud::Client.where(id: destination_client_same_day.id) }

      before do
        same_day = current_date - 5.days
        # Create assessments with same assessment date but different creation times
        create_assessment_for_client(
          client_same_day,
          assessment_date: same_day,
          date_created: same_day - 1.hour,
          date_updated: same_day,
        )
        travel 1.second do
          create_assessment_for_client(
            client_same_day,
            assessment_date: same_day,
            date_created: same_day,
            date_updated: same_day + 1.hour,
          )
        end
      end

      it 'selects the most recently created assessment when assessment dates are the same' do
        result = field_map.client_query(query_clients, date_updated_field)
        expect(result[destination_client_same_day.id].to_time).to be_within(1.minute).of(((current_date - 5.days) + 1.hour).to_time)
      end
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

  describe '#label_for' do
    before { form_definition } # Ensure form definition is created

    it 'returns the correct label for assessment_date' do
      result = field_map.label_for('housing_assessment.assessment_date')
      expect(result).to eq('Date Assessment Administered')
    end

    it 'returns the correct label for date_created' do
      result = field_map.label_for('housing_assessment.date_created')
      expect(result).to eq('Date Assessment Created')
    end

    it 'returns the correct label for date_updated' do
      result = field_map.label_for('housing_assessment.date_updated')
      expect(result).to eq('Date Assessment Last Updated')
    end

    it 'raises error for unknown fields' do
      expect do
        field_map.label_for('housing_assessment.unknown_field')
      end.to raise_error(ArgumentError, /Unknown field/)
    end
  end

  describe '#format_for_display' do
    before { form_definition } # Ensure form definition is created
    let(:test_date) { Date.new(2024, 6, 15) }

    it 'formats assessment_date correctly' do
      result = field_map.format_for_display('housing_assessment.assessment_date', test_date)
      expect(result).to eq('06/15/2024')
    end

    it 'formats date_created correctly' do
      result = field_map.format_for_display('housing_assessment.date_created', test_date)
      expect(result).to eq('06/15/2024')
    end

    it 'formats date_updated correctly' do
      result = field_map.format_for_display('housing_assessment.date_updated', test_date)
      expect(result).to eq('06/15/2024')
    end

    it 'handles nil values gracefully' do
      result = field_map.format_for_display('housing_assessment.assessment_date', nil)
      expect(result).to be_nil
    end

    it 'raises error for unknown fields' do
      expect do
        field_map.format_for_display('housing_assessment.unknown_field', test_date)
      end.to raise_error(ArgumentError, /Unknown field/)
    end
  end

  describe '#joins' do
    it 'returns nil (not yet implemented)' do
      result = field_map.joins('housing_assessment.assessment_date')
      expect(result).to be_nil
    end
  end

  describe '#arel_field' do
    it 'returns nil (not yet implemented)' do
      result = field_map.arel_field('housing_assessment.assessment_date')
      expect(result).to be_nil
    end
  end
end
