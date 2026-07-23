# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Hmis::Ce::Configuration, type: :model do
  subject(:configuration) { described_class.new }

  def set_config(key, value)
    AppConfigProperty.create!(key: "hmis_ce/#{key}", value: value)
  end

  describe '#eligibility_lookback_months' do
    it 'defaults to 0 when unset' do
      expect(configuration.eligibility_lookback_months).to eq(0)
    end

    it 'returns a valid configured value' do
      set_config(:eligibility_lookback_months, 3)
      expect(configuration.eligibility_lookback_months).to eq(3)
    end

    it 'raises Misconfiguration for a non-integer value' do
      set_config(:eligibility_lookback_months, 'abc')
      expect { configuration.eligibility_lookback_months }.
        to raise_error(described_class::Misconfiguration, /expected an integer/)
    end

    it 'raises Misconfiguration for a value outside 0..12' do
      set_config(:eligibility_lookback_months, 13)
      expect { configuration.eligibility_lookback_months }.
        to raise_error(described_class::Misconfiguration, /must be between 0 and 12/)
    end
  end

  describe '#eligibility_project_group_id' do
    it 'returns nil when unset' do
      expect(configuration.eligibility_project_group_id).to be_nil
    end

    it 'returns the configured integer id' do
      set_config(:eligibility_project_group_id, 42)
      expect(configuration.eligibility_project_group_id).to eq(42)
    end

    it 'raises Misconfiguration for a non-integer value' do
      set_config(:eligibility_project_group_id, 'nope')
      expect { configuration.eligibility_project_group_id }.
        to raise_error(described_class::Misconfiguration, /expected an integer/)
    end
  end

  describe '#eligibility_project_group' do
    let!(:hmis_data_source) { create(:hmis_data_source) }
    let!(:project_group) { create(:hmis_project_group, data_source: hmis_data_source) }

    it 'returns nil when unset' do
      expect(configuration.eligibility_project_group).to be_nil
    end

    it 'returns the configured project group' do
      set_config(:eligibility_project_group_id, project_group.id)
      expect(configuration.eligibility_project_group).to eq(project_group)
    end

    it 'raises Misconfiguration when the group does not exist' do
      set_config(:eligibility_project_group_id, project_group.id + 1_000_000)
      expect { configuration.eligibility_project_group }.
        to raise_error(described_class::Misconfiguration, /does not exist/)
    end

    it 'raises Misconfiguration when the group is deleted' do
      set_config(:eligibility_project_group_id, project_group.id)
      # Bypass CE eligibility destroy guard; simulate a soft-deleted group.
      project_group.update_column(:deleted_at, Time.current)
      expect { configuration.eligibility_project_group }.
        to raise_error(described_class::Misconfiguration, /deleted project group/)
    end
  end
end
