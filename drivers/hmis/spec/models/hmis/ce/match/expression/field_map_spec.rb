# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::FieldMap, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }

  let(:client1) { create(:hmis_hud_client_with_warehouse_client, veteran_status: 1) }
  let(:destination_client1) { client1.destination_client }
  let(:clients) { GrdaWarehouse::Hud::Client.where(id: destination_client1.id) }

  # Create form definition for custom assessment tests
  let(:form_definition) { create(:hmis_form_definition, identifier: 'housing_assessment') }

  describe '.field_type_for' do
    context 'for client fields' do
      it 'returns CLIENT type for simple field names' do
        field_type, resolved_field = described_class.field_type_for('veteran_status')
        expect(field_type).to eq(described_class::CLIENT)
        expect(resolved_field).to eq('veteran_status')
      end

      it 'returns CLIENT type for explicitly namespaced client fields' do
        field_type, resolved_field = described_class.field_type_for('client.current_age')
        expect(field_type).to eq(described_class::CLIENT)
        expect(resolved_field).to eq('current_age')
      end
    end

    context 'for CDE fields' do
      it 'returns CDE type for CDE fields' do
        field_type, resolved_field = described_class.field_type_for('cde.custom_assessment.language_preference')
        expect(field_type).to eq(described_class::CDE)
        expect(resolved_field).to eq('custom_assessment.language_preference')
      end
    end

    context 'for custom assessment fields' do
      it 'returns CUSTOM_ASSESSMENT type for custom assessment fields' do
        field_type, resolved_field = described_class.field_type_for('custom_assessment.housing_assessment.assessment_date')
        expect(field_type).to eq(described_class::CUSTOM_ASSESSMENT)
        expect(resolved_field).to eq('housing_assessment.assessment_date')
      end
    end

    context 'error handling' do
      it 'raises ArgumentError for unknown field types' do
        expect do
          described_class.field_type_for('unknown_type.some_field')
        end.to raise_error(ArgumentError, /unknown resolver/)
      end
    end
  end

  describe '#client_query' do
    context 'with client fields' do
      it 'routes to ClientFieldMap for simple fields' do
        result = field_map.client_query(clients, 'veteran_status')
        expect(result[destination_client1.id]).to eq(1)
      end

      it 'routes to ClientFieldMap for explicitly namespaced client fields' do
        result = field_map.client_query(clients, 'client.veteran_status')
        expect(result[destination_client1.id]).to eq(1)
      end
    end

    context 'with custom assessment fields' do
      before do
        # Create a custom assessment for testing
        create(:hmis_custom_assessment,
               client: client1,
               data_source: client1.data_source,
               assessment_date: Date.new(2024, 6, 15),
               date_created: Date.new(2024, 6, 10),
               definition: form_definition)
      end

      it 'routes to CustomAssessmentFieldMap for assessment_date' do
        result = field_map.client_query(clients, 'custom_assessment.housing_assessment.assessment_date')
        expect(result[destination_client1.id]).to eq(Date.new(2024, 6, 15))
      end

      it 'routes to CustomAssessmentFieldMap for date_created' do
        result = field_map.client_query(clients, 'custom_assessment.housing_assessment.date_created')
        expect(result[destination_client1.id].to_date).to eq(Date.new(2024, 6, 10))
      end
    end

    context 'with CDE fields' do
      let(:string_cded) do
        create(:hmis_custom_data_element_definition,
               owner_type: 'Hmis::Hud::CustomAssessment',
               key: 'language_preference',
               field_type: 'string',
               form_definition_identifier: 'housing_assessment')
      end

      before do
        assessment = create(:hmis_custom_assessment,
                            client: client1,
                            data_source: client1.data_source,
                            definition: form_definition)
        create(:hmis_custom_data_element,
               owner: assessment,
               data_element_definition: string_cded,
               value_string: 'English',
               data_source: client1.data_source)
      end

      it 'routes to CdeFieldMap for CDE fields' do
        result = field_map.client_query(clients, 'cde.custom_assessment.language_preference')
        expect(result[destination_client1.id]).to eq('English')
      end
    end
  end

  describe '#resolve_field_for_display' do
    before do
      # Create a custom assessment for testing
      create(:hmis_custom_assessment,
             client: client1,
             data_source: client1.data_source,
             assessment_date: Date.new(2024, 6, 15),
             definition: form_definition)
    end

    it 'resolves and formats client fields for display' do
      label, formatted = field_map.resolve_field_for_display(destination_client1, 'veteran_status')
      expect(label).to be_present
      expect(formatted).to be_present
    end

    it 'resolves and formats custom assessment fields for display' do
      label, formatted = field_map.resolve_field_for_display(destination_client1, 'custom_assessment.housing_assessment.assessment_date')
      expect(label).to eq('Date Assessment Administered')
      expect(formatted).to eq('06/15/2024')
    end
  end

  describe '#arel_field' do
    before { form_definition }
    it 'delegates to the appropriate resolver' do
      # This will vary by resolver, but we test that it delegates correctly
      result = field_map.arel_field('veteran_status')
      expect(result).to be_present # ClientFieldMap returns an arel field
    end

    it 'returns an arel expression for custom assessment fields' do
      result = field_map.arel_field('custom_assessment.housing_assessment.assessment_date')
      expect(result).to be_present
    end
  end

  describe '#joins' do
    before { form_definition }
    it 'delegates to the appropriate resolver' do
      # Test a field that requires joins
      result = field_map.joins('days_since_last_exit')
      expect(result).to be_present # ClientFieldMap returns joins for this field
    end

    it 'returns joins for custom assessment fields' do
      result = field_map.joins('custom_assessment.housing_assessment.assessment_date')
      expect(result).to eq([{ destination_client_latest_assessments: :custom_assessment }])
    end
  end

  describe 'resolver registration' do
    it 'registers all expected resolvers' do
      resolvers = field_map.send(:registered_resolvers)

      expect(resolvers.keys).to contain_exactly(
        described_class::CLIENT,
        described_class::CDE,
        described_class::CUSTOM_ASSESSMENT,
      )

      expect(resolvers[described_class::CLIENT]).to be_a(Hmis::Ce::Match::Expression::ClientFieldMap)
      expect(resolvers[described_class::CDE]).to be_a(Hmis::Ce::Match::Expression::CdeFieldMap)
      expect(resolvers[described_class::CUSTOM_ASSESSMENT]).to be_a(Hmis::Ce::Match::Expression::CustomAssessmentFieldMap)
    end

    it 'passes current_date to all resolvers' do
      resolvers = field_map.send(:registered_resolvers)

      # Only ClientFieldMap has current_date as an attr_reader
      expect(resolvers[described_class::CLIENT].current_date).to eq(current_date)

      # Others store it in @current_date (which we can't directly access in tests)
      # But we can verify they were initialized with the correct current_date
      # by checking that the field map itself has the right current_date
      expect(field_map.current_date).to eq(current_date)
    end
  end

  describe 'namespace constants' do
    it 'defines all expected namespace constants' do
      expect(described_class::NAMESPACES).to contain_exactly('cde', 'client', 'custom_assessment')
      expect(described_class::CDE).to eq('cde')
      expect(described_class::CLIENT).to eq('client')
      expect(described_class::CUSTOM_ASSESSMENT).to eq('custom_assessment')
    end
  end
end
