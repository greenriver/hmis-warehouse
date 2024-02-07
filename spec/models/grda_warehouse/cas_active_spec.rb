require 'rails_helper'

RSpec.describe GrdaWarehouse::ServiceHistoryService, type: :model do
  describe 'when including extrapolated enrollments' do
    before(:all) do
      GrdaWarehouse::Utility.clear!
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

  describe 'when syncing by project group' do
    let!(:data_source) { create :grda_warehouse_data_source, source_type: nil, authoritative: false }
    let!(:project) { create :hud_project, data_source_id: data_source.id }
    let!(:client) { create :hud_client, data_source: data_source, data_source_id: data_source.id }
    let!(:enrollment) { create :hud_enrollment, ProjectID: project.ProjectID, data_source_id: data_source.id }
    let!(:service_history_enrollment) do
      create :grda_warehouse_service_history, :service_history_entry,
             project: project, client: client, enrollment_group_id: enrollment.EnrollmentID,
             first_date_in_program: Date.yesterday, data_source_id: data_source.id
    end

    before(:all) do
      @cas_project_group = GrdaWarehouse::ProjectGroup.create!(name: 'test')
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :project_group,
        cas_sync_project_group_id: @cas_project_group.id,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
      @cas_project_group.destroy
    end

    it 'finds no client who is active for CAS' do
      @cas_project_group.projects = []
      clients = GrdaWarehouse::Hud::Client.destination.select(&:active_in_cas?)
      error_message = "Clients: #{clients.map(&:FirstName).join('; ')}"
      expect(clients.count).to eq(0), error_message
    end

    it 'finds one client who is active for CAS' do
      @cas_project_group.projects << project
      expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
    end
  end

  describe 'when syncing by ce enrollment' do
    before(:all) do
      @config = GrdaWarehouse::Config.first_or_create
      @config.update(
        so_day_as_month: true,
        cas_available_method: :ce_with_assessment,
      )
      import_hmis_csv_fixture(
        'spec/fixtures/files/service_history/cas_activity_methods',
        version: 'AutoMigrate',
      )
    end
    after(:all) do
      GrdaWarehouse::Utility.clear!
      cleanup_hmis_csv_fixtures
    end

    it 'finds one client who is active for CAS' do
      expect(GrdaWarehouse::Hud::Client.destination.map(&:active_in_cas?).count(true)).to eq(1)
    end
  end
end
