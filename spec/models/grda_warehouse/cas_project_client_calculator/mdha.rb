require 'rails_helper'

RSpec.describe GrdaWarehouse::CasProjectClientCalculator::Mdha, type: :model do
  describe 'days homeless' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: true,
        cas_sync_months: 1,
        cas_calculator: 'GrdaWarehouse::CasProjectClientCalculator::Mdha',
      )
      @calculator = GrdaWarehouse::Config.get(:cas_calculator).constantize.new
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/days_homeless',
        version: 'AutoMigrate',
      )
      GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: GrdaWarehouse::Hud::Client.destination.pluck(:id))
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      Delayed::Job.delete_all
      GrdaWarehouse::Config.delete_all
    end
    it 'does not add additional days if the client is missing Date to Street' do
      travel_to Time.local(2016, 2, 15) do
        c = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-1')
        expect(c.days_homeless).to be_positive
        expect(c.days_homeless).to eq(@calculator.value_for_cas_project_client(client: c, column: :days_homeless))
      end
    end
    it 'client has zero days if moved in' do
      travel_to Time.local(2016, 2, 15) do
        c = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-2')
        expect(c.days_homeless).to be_zero
        expect(c.days_homeless).to eq(@calculator.value_for_cas_project_client(client: c, column: :days_homeless))
      end
    end
    it 'adds additional days if the client has an earlier Date to Street' do
      travel_to Time.local(2016, 2, 15) do
        c = GrdaWarehouse::Hud::Client.destination.find_by(personal_id: '1-3')
        expect(c.days_homeless).to be_zero
        expect(c.days_homeless).to be < (@calculator.value_for_cas_project_client(client: c, column: :days_homeless))
      end
    end
  end
end
