require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubReportPiiTask do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source, project_type: 0 }

  let!(:apr_client) do
    HudApr::Fy2020::AprClient.create!
  end

  def reload_records
    apr_client.reload
  end

  def verify_nullified_record(client)
    expect(client.first_name).to be_nil
  end

  context 'with null strategy' do
    before do
      described_class.new.perform(strategy: :null)
      reload_records
    end

    it 'nullifies all PII in clients' do
      verify_nullified_record(apr_client)
    end
  end

  context 'with fake strategy' do
    before do
      described_class.new.perform(strategy: :fake)
      reload_records
    end

    it 'replaces client PII with fake data' do
      expect(apr_client.first_name).not_to eq('John')
    end
  end

  context 'with identifier strategy' do
    before do
      described_class.new.perform(strategy: :identifier)
      reload_records
    end

    it 'replaces PII with identifier-based values' do
      expect(apr_client.first_name).to eq("FirstName#{client1.id}")
    end
  end
end
