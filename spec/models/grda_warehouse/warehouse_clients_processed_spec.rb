require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed, type: :model do
  before(:all) do
    import_hmis_csv_fixture(
      'spec/fixtures/files/service_history/materialized',
      version: '6.11',
    )

    # Add includes_verified_days_homeless override
    GrdaWarehouse::Hud::Project.find_by(ProjectName: 'Services Only').update(include_in_days_homeless_override: true)
    # Update
    GrdaWarehouse::ServiceHistoryServiceMaterialized.rebuild!
    @client_ids = GrdaWarehouse::ServiceHistoryServiceMaterialized.distinct.pluck(:client_id)
    GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: @client_ids)
  end
  after(:all) do
    # Because we are only running the import once, we have to do our own DB and file cleanup
    GrdaWarehouse::Utility.clear!
    cleanup_hmis_csv_fixtures
    Delayed::Job.delete_all
  end

  it 'sets up the harness' do
    expect(GrdaWarehouse::ServiceHistoryServiceMaterialized.count).to_not eq(0)
    expect(GrdaWarehouse::WarehouseClientsProcessed.count).to be > 0
    expect(GrdaWarehouse::WarehouseClientsProcessed.count).to eq(@client_ids.count)
    expect(GrdaWarehouse::Hud::Project.homeless.count).to be > 0
    expect(GrdaWarehouse::Hud::Project.includes_verified_days_homeless.count).to eq(1)
  end

  it 'counts homeless days' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')

    expect(client.source_enrollments.joins(:project).merge(GrdaWarehouse::Hud::Project.homeless).count).to be > 0
  end

  it 'includes the override days in the plus overrides count' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')
    expect(client.processed_service_history.days_homeless_plus_overrides).to be > client.processed_service_history.homeless_days
  end

  it 'excludes overlapping homeless days' do
    client = GrdaWarehouse::Hud::Client.destination.find_by(LastName: 'Two')

    homeless_count = client.service_history_services.joins(service_history_enrollment: :project).merge(GrdaWarehouse::Hud::Project.homeless).count
    override_count = client.service_history_services.joins(service_history_enrollment: :project).merge(GrdaWarehouse::Hud::Project.includes_verified_days_homeless).count

    expect(client.processed_service_history.days_homeless_plus_overrides).to be < homeless_count + override_count
  end
end
