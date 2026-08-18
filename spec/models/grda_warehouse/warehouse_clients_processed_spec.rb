###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed, type: :model do
  before(:all) do
    import_hmis_csv_fixture(
      'spec/fixtures/files/service_history/materialized',
      version: 'AutoMigrate',
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

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed, type: :model do
  describe 'preventing duplicate rows per client_id and routine' do
    let(:client) { create(:grda_warehouse_hud_client, data_source: create(:destination_data_source)) }

    before do
      create(:warehouse_client, destination_id: client.id)
    end

    it 'raises RecordNotUnique for a second row with the same client_id and routine' do
      create(:grda_warehouse_warehouse_clients_processed, client_id: client.id)

      expect do
        GrdaWarehouse::WarehouseClientsProcessed.create!(client_id: client.id, routine: 'service_history')
      end.to raise_error(ActiveRecord::RecordNotUnique)
    end

    it 'wraps the upsert batch in the advisory lock with a bounded timeout' do
      expect(GrdaWarehouse::WarehouseClientsProcessed).to receive(:with_advisory_lock!).
        with(
          GrdaWarehouse::WarehouseClientsProcessed::UPSERT_ADVISORY_LOCK_NAME,
          timeout_seconds: GrdaWarehouse::WarehouseClientsProcessed::UPSERT_ADVISORY_LOCK_TIMEOUT_SECONDS,
        ).
        at_least(:once).and_call_original

      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])
    end

    it 'raises FailedToAcquireLock instead of silently dropping the batch when the lock cannot be acquired' do
      allow(GrdaWarehouse::WarehouseClientsProcessed).to receive(:with_advisory_lock!).
        with(
          GrdaWarehouse::WarehouseClientsProcessed::UPSERT_ADVISORY_LOCK_NAME,
          timeout_seconds: GrdaWarehouse::WarehouseClientsProcessed::UPSERT_ADVISORY_LOCK_TIMEOUT_SECONDS,
        ).
        and_raise(WithAdvisoryLock::FailedToAcquireLock.new(GrdaWarehouse::WarehouseClientsProcessed::UPSERT_ADVISORY_LOCK_NAME))

      expect do
        GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])
      end.to raise_error(WithAdvisoryLock::FailedToAcquireLock)
    end

    it 'upserts instead of duplicating when update_cached_counts runs again for a client whose stats changed' do
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])

      # advance the clock so last_service_updated_at actually differs, forcing a real
      # second write instead of a no-op (with equal stats, update_cached_counts would
      # see no changed attributes and never call import a second time)
      travel_to(1.day.from_now) do
        GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])
      end

      processed = GrdaWarehouse::WarehouseClientsProcessed.service_history.where(client_id: client.id)
      expect(processed.count).to eq(1)
      expect(processed.sole.last_service_updated_at.to_date).to eq(1.day.from_now.to_date)
    end

    it 'upserts instead of duplicating on the limited-data (skip_expensive_calculations) code path too' do
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id], skip_expensive_calculations: true)

      travel_to(1.day.from_now) do
        GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id], skip_expensive_calculations: true)
      end

      processed = GrdaWarehouse::WarehouseClientsProcessed.service_history.where(client_id: client.id)
      expect(processed.count).to eq(1)
      expect(processed.sole.last_service_updated_at.to_date).to eq(1.day.from_now.to_date)
    end

    # A test simulating two concurrent writers racing to upsert the same (client_id,
    # routine) was attempted but dropped: it was not practical to reproduce under
    # transactional fixtures. The advisory-lock-is-used and upsert-not-duplicate tests
    # above are the closest coverage achievable within that constraint.
  end
end
