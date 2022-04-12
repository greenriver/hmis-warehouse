require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  describe 'when including extrapolated enrollments' do
    before(:all) do
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: true,
        cas_sync_months: 1,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      Delayed::Job.delete_all
    end
    it 'finds two clients who are active for CAS' do
      travel_to Time.local(2016, 2, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(2)
      end
    end

    it 'finds no client who is active for CAS' do
      travel_to Time.local(2016, 3, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(0)
      end
    end
  end

  describe 'when excluding extrapolated enrollments' do
    before(:all) do
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :active_clients,
        ineligible_uses_extrapolated_days: false,
        cas_sync_months: 1,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      Delayed::Job.delete_all
    end

    it 'finds one client who is active for CAS' do
      travel_to Time.local(2016, 2, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
      end
    end

    it 'finds no client who is active for CAS' do
      travel_to Time.local(2016, 3, 15) do
        expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(0)
      end
    end
  end
end
