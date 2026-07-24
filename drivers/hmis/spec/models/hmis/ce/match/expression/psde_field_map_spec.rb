# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::Expression::PsdeFieldMap, type: :model do
  let!(:destination_data_source) { create(:destination_data_source) }
  let!(:hmis_data_source) { create(:hmis_data_source) }
  let(:current_date) { Date.new(2024, 12, 26) }
  let(:field_map) { described_class.new(current_date: current_date) }
  let(:field_key) { 'total_monthly_income' }

  let(:client) { create(:hmis_hud_client_with_warehouse_client, data_source: hmis_data_source) }
  let(:destination_client) { client.destination_client }
  let(:clients) { GrdaWarehouse::Hud::Client.where(id: destination_client.id) }

  let!(:enrollment) do
    create(
      :hmis_hud_enrollment,
      data_source: hmis_data_source,
      client: client,
      EntryDate: current_date - 1.month,
    )
  end

  describe '#client_query' do
    it 'returns income values for known fields' do
      create(
        :hmis_income_benefit,
        :skip_validate,
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        information_date: current_date - 1.week,
        income_from_any_source: 1,
        total_monthly_income: '500',
      )

      expect(field_map.client_query(clients, field_key)).to eq({ destination_client.id => 500.0 })
    end

    it 'resolves a known disability value' do
      create(
        :hmis_disability,
        :skip_validate,
        enrollment: enrollment,
        client: client,
        data_source: hmis_data_source,
        disability_type: 9,
        disability_response: 1,
        information_date: current_date - 1.week,
        data_collection_stage: 1,
      )

      expect(field_map.client_query(clients, 'mental_health_disorder')).
        to eq({ destination_client.id => true })
    end

    it 'raises for unknown fields' do
      expect { field_map.client_query(clients, 'unknown_field') }.
        to raise_error(ArgumentError, /Unknown PSDE field/)
    end
  end

  describe '#fields' do
    it 'includes total monthly income' do
      expect(field_map.fields.map(&:key)).to include(field_key)
    end

    it 'includes the disability and health/DV fields' do
      expect(field_map.fields.map(&:key)).to include(
        'mental_health_disorder',
        'substance_use_disorder',
        'physical_disability',
        'developmental_disability',
        'chronic_health_condition',
        'hiv_aids',
        'domestic_violence_survivor',
      )
    end
  end

  describe '#label_for' do
    it 'returns the registry label' do
      expect(field_map.label_for(field_key)).to eq('Total Monthly Income')
    end

    it 'returns the registry label for a disability field' do
      expect(field_map.label_for('mental_health_disorder')).to eq('Mental Health Disorder')
    end
  end

  describe '#arel_field and #joins' do
    it 'returns nil for SQL prefiltering' do
      expect(field_map.arel_field(field_key)).to be_nil
      expect(field_map.joins(field_key)).to be_nil
    end
  end

  describe '.field_key_for' do
    it 'builds the psde namespace key' do
      expect(described_class.field_key_for(field_key)).to eq("psde.#{field_key}")
    end
  end
end
