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

    it 'upserts on conflict instead of duplicating when two batches import for the same client_id and routine' do
      import_options = { on_duplicate_key_update: { conflict_target: [:client_id, :routine], columns: [:days_served] } }
      first_batch = GrdaWarehouse::WarehouseClientsProcessed.new(client_id: client.id, routine: 'service_history', days_served: 1)
      second_batch = GrdaWarehouse::WarehouseClientsProcessed.new(client_id: client.id, routine: 'service_history', days_served: 2)

      GrdaWarehouse::WarehouseClientsProcessed.import([first_batch], **import_options)
      GrdaWarehouse::WarehouseClientsProcessed.import([second_batch], **import_options)

      processed = GrdaWarehouse::WarehouseClientsProcessed.where(client_id: client.id, routine: 'service_history')
      expect(processed.count).to eq(1)
      expect(processed.sole.days_served).to eq(2)
    end

    it 'is idempotent when update_cached_counts runs for the same client more than once' do
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])
      GrdaWarehouse::WarehouseClientsProcessed.update_cached_counts(client_ids: [client.id])

      expect(GrdaWarehouse::WarehouseClientsProcessed.service_history.where(client_id: client.id).count).to eq(1)
    end
  end
end
