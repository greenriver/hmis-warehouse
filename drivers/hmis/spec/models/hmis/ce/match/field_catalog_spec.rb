# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Match::FieldCatalog do
  describe '#field_for' do
    it 'returns nil for an unregistered PSDE key' do
      # Unregistered keys fall back to the raw expression editor rather than
      # hydrating into a clause with missing type metadata.
      expect(described_class.new.field_for('psde.not_registered')).to be_nil
    end

    it 'returns Field with source :CDE for a valid CDE key' do
      create(:hmis_custom_data_element_definition, key: 'my_key', owner_type: 'Hmis::Hud::CustomAssessment')
      expect(described_class.new.field_for('cde.custom_assessment.my_key')&.source).to eq(:CUSTOM_DATA_ELEMENT)
    end

    it 'returns Field with source :CLIENT for a valid client key' do
      expect(described_class.new.field_for('client.veteran_status')&.source).to eq(:CLIENT)
    end

    it 'returns Field with source :CLIENT for a valid client key without prefix' do
      expect(described_class.new.field_for('veteran_status')&.source).to eq(:CLIENT)
    end

    it 'returns Field with source :PSDE for a valid PSDE key' do
      expect(described_class.new.field_for('psde.total_monthly_income')&.source).to eq(:PSDE)
    end
  end
end
