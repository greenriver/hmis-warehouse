require 'rails_helper'

RSpec.describe GrdaWarehouse::CasProjectClientCalculator::TcHat, type: :model do
  describe 'child in household' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: true,
        cas_sync_months: 1,
        cas_calculator: 'GrdaWarehouse::CasProjectClientCalculator::TcHmisHat',
      )
      @calculator = GrdaWarehouse::Config.get(:cas_calculator).constantize.new
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/child_in_household',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'finds the adult and child in the household' do
      clients = GrdaWarehouse::Hud::Client.destination.map do |client|
        client.personal_id if @calculator.value_for_cas_project_client(client: client, column: :child_in_household)
      end.compact
      expect(clients).to contain_exactly('1-2', '1-3')
    end

    it 'finds 1-1 to have an open case' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
      expect(@calculator.value_for_cas_project_client(client: client, column: :open_case)).to be_truthy
    end

    it 'finds 1-1 to have no history of drug use' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
      expect(@calculator.value_for_cas_project_client(client: client, column: :heavy_drug_use)).to be_falsey
    end

    it 'finds 1-1 to have no history of drug use' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
      expect(@calculator.value_for_cas_project_client(client: client, column: :heavy_drug_use)).to be_falsey
    end

    it 'finds 1-1 to have a DV date' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
      expect(@calculator.value_for_cas_project_client(client: client, column: :dv_date)).to eq('2015-01-02'.to_date)
    end

    it 'doesn\'t fail on null AssessmentAnswer for boolean' do
      client = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
      expect(@calculator.value_for_cas_project_client(client: client, column: :drug_test)).to be_nil
    end
  end
end
