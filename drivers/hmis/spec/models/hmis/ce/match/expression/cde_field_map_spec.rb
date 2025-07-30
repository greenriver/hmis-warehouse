# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::CdeFieldMap, type: :model do
  let!(:destination_data_source) { create :destination_data_source }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new }

  let!(:client) { create(:hmis_hud_client_with_warehouse_client) }
  let!(:destination_client) { client.destination_client }

  # Create a form definition and custom data element definition
  let!(:form_definition) { create(:hmis_form_definition, identifier: 'test_form') }
  let!(:string_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'language_preference',
           field_type: 'string',
           form_definition_identifier: 'test_form')
  end
  let!(:boolean_cded) do
    create(:hmis_custom_data_element_definition,
           owner_type: 'Hmis::Hud::CustomAssessment',
           key: 'has_disability',
           field_type: 'boolean',
           form_definition_identifier: 'test_form')
  end

  describe '#arel_field' do
    context 'with valid CDE field' do
      it 'returns Arel SQL literal for string field' do
        result = field_map.arel_field('custom_assessment.language_preference')
        expect(result).to be_a(Arel::Nodes::SqlLiteral)
        sql_string = result.instance_variable_get(:@raw) || result.to_s
        expect(sql_string).to include('value_string')
        expect(sql_string).to include('CustomAssessments')
        expect(sql_string).to include('ORDER BY')
        expect(sql_string).to include('LIMIT 1')
      end

      it 'returns Arel SQL literal for boolean field' do
        result = field_map.arel_field('custom_assessment.has_disability')
        expect(result).to be_a(Arel::Nodes::SqlLiteral)
        sql_string = result.instance_variable_get(:@raw) || result.to_s
        expect(sql_string).to include('value_boolean')
      end
    end
  end

  describe '#joins' do
    it 'returns nil since CDE fields use correlated subqueries' do
      result = field_map.joins('custom_assessment.language_preference')
      expect(result).to be_nil
    end
  end

  describe 'integration with SQL prefilter' do
    let!(:project) { create(:hmis_hud_project, data_source: client.data_source) }
    let!(:enrollment) { create(:hmis_hud_enrollment, client: client, project: project, data_source: client.data_source) }

    let!(:custom_assessment) do
      create(:hmis_custom_assessment,
             client: client,
             data_source: client.data_source,
             assessment_date: current_date - 1.week,
             date_updated: current_date - 1.week,
             definition: form_definition)
    end

    let!(:string_cde) do
      create(:hmis_custom_data_element,
             owner: custom_assessment,
             data_element_definition: string_cded,
             value_string: 'English',
             data_source: client.data_source)
    end

    let!(:boolean_cde) do
      create(:hmis_custom_data_element,
             owner: custom_assessment,
             data_element_definition: boolean_cded,
             value_boolean: true,
             data_source: client.data_source)
    end

    # Form processor is automatically created by the custom assessment factory

    it 'correctly filters clients using CDE fields in SQL' do
      # Create a client universe that includes our test client
      client_universe = GrdaWarehouse::Hud::Client.where(id: destination_client.id)

      # Use a simple expression that should match our test data
      pool = create(:hmis_ce_match_candidate_pool,
                   requirement_expression: 'custom_assessment.language_preference = "English"')

      prefilter = Hmis::Ce::Match::Internal::SqlPrefilter.new(pool, field_map)
      result = prefilter.call(client_universe)

      # The client should be eligible since they have "English" as language preference
      expect(result.eligible_clients.pluck(:id)).to include(destination_client.id)
    end

    it 'correctly excludes clients that do not match CDE criteria' do
      client_universe = GrdaWarehouse::Hud::Client.where(id: destination_client.id)

      # Expression that should NOT match our test data
      pool = create(:hmis_ce_match_candidate_pool,
                   requirement_expression: 'custom_assessment.language_preference = "Spanish"')

      prefilter = Hmis::Ce::Match::Internal::SqlPrefilter.new(pool, field_map)
      result = prefilter.call(client_universe)

      # The client should not be eligible since they don't have "Spanish" as language preference
      expect(result.eligible_clients.pluck(:id)).not_to include(destination_client.id)
    end

    it 'handles boolean CDE fields correctly' do
      client_universe = GrdaWarehouse::Hud::Client.where(id: destination_client.id)

      pool = create(:hmis_ce_match_candidate_pool,
                   requirement_expression: 'custom_assessment.has_disability = TRUE')

      prefilter = Hmis::Ce::Match::Internal::SqlPrefilter.new(pool, field_map)
      result = prefilter.call(client_universe)

      expect(result.eligible_clients.pluck(:id)).to include(destination_client.id)
    end
  end

  describe '#value_column_for_field_type' do
    it 'maps field types to correct value columns' do
      expect(field_map.send(:value_column_for_field_type, 'string')).to eq(:value_string)
      expect(field_map.send(:value_column_for_field_type, 'boolean')).to eq(:value_boolean)
      expect(field_map.send(:value_column_for_field_type, 'date')).to eq(:value_date)
      expect(field_map.send(:value_column_for_field_type, 'integer')).to eq(:value_integer)
      expect(field_map.send(:value_column_for_field_type, 'float')).to eq(:value_float)
      expect(field_map.send(:value_column_for_field_type, 'text')).to eq(:value_text)
      expect(field_map.send(:value_column_for_field_type, 'json')).to eq(:value_json)
      expect(field_map.send(:value_column_for_field_type, 'file')).to eq(:value_file_id)
      expect(field_map.send(:value_column_for_field_type, 'unknown')).to be_nil
    end
  end
end
