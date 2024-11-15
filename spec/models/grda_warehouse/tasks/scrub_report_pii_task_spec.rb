require 'rails_helper'

RSpec.describe GrdaWarehouse::Tasks::ScrubPii::ScrubReportPiiTask do
  let(:data_source) { create(:grda_warehouse_data_source) }
  let(:project) { create :grda_warehouse_hud_project, data_source: data_source, project_type: 0 }

  let!(:clients) do
    attrs = {first_name: 'RealName'}
    [
      HudApr::Fy2020::AprClient.create!(attrs),
      HapReport::HapClient.create!(attrs),
      HomelessSummaryReport::Client.create!(attrs),
      HudDataQualityReport::Fy2020::DqClient.create!(attrs),
      HudPathReport::Fy2020::PathClient.create!(attrs),
      HudSpmReport::Fy2020::SpmClient.create!(attrs),
      IncomeBenefitsReport::Client.create!(attrs),
      MaYyaReport::Client.create!(attrs),
    ]
  end

  def reload_records
    clients.each(&:reload)
  end

  context 'with null strategy' do
    before do
      described_class.new.perform(strategy: :null)
      reload_records
    end

    it 'nullifies all PII in clients' do
      clients.each do |client|
        expect(client.first_name).to be_nil
      end
    end
  end

  context 'with fake strategy' do
    before do
      described_class.new.perform(strategy: :fake)
      reload_records
    end

    it 'replaces client PII with fake data' do
      expect(apr_client.first_name).not_to eq('RealName')
      expect(apr_client.first_name).not_to be_null
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
