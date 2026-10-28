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

RSpec.describe GrdaWarehouse::WarehouseClientsProcessed::StatsCalculator, type: :model do
  describe '#enrolled_permanent_housing' do
    let(:data_source) { create :grda_warehouse_data_source }
    let(:organization) { create :hud_organization, data_source: data_source }

    def client_enrolled_in(project_type:, rrh_sub_type: nil, move_in_date: nil)
      project = create(
        :hud_project,
        data_source: data_source,
        OrganizationID: organization.OrganizationID,
        ProjectType: project_type,
        RRHSubType: rrh_sub_type,
      )
      create(
        :grda_warehouse_service_history,
        :service_history_entry,
        client_id: create(:grda_warehouse_hud_client).id,
        data_source: data_source,
        project_id: project.ProjectID,
        organization_id: project.OrganizationID,
        project_type: project_type,
        move_in_date: move_in_date,
      ).client_id
    end

    let!(:sso_moved_in) { client_enrolled_in(project_type: 13, rrh_sub_type: 1, move_in_date: Date.current - 5.days) }
    let!(:sso_not_moved_in) { client_enrolled_in(project_type: 13, rrh_sub_type: 1) }
    let!(:rrh_housing) { client_enrolled_in(project_type: 13, rrh_sub_type: 2) }
    let!(:rrh_legacy) { client_enrolled_in(project_type: 13, rrh_sub_type: nil) }
    let!(:psh) { client_enrolled_in(project_type: 3) }
    let!(:es) { client_enrolled_in(project_type: 0) }

    let(:client_ids) { [sso_moved_in, sso_not_moved_in, rrh_housing, rrh_legacy, psh, es] }
    let(:calculator) { described_class.new(client_ids: client_ids) }

    it 'flags PH enrollments other than RRH: Services Only, with or without a move-in date' do
      flagged = client_ids.select { |id| calculator.enrolled_permanent_housing(id) }

      expect(flagged).to contain_exactly(rrh_housing, rrh_legacy, psh)
    end
  end

  describe '#homeless_counts' do
    let(:client) { create :hud_client }
    let(:on_date) { Date.current - 1.year }

    before do
      she = create(:she_entry, client: client, project_type: 1)
      # 10 ES days before on_date, 5 after
      dates = (on_date - 10.days..on_date - 1.day).to_a + (on_date + 1.day..on_date + 5.days).to_a
      dates.each do |date|
        create(:service_history_service, client_id: client.id, service_history_enrollment_id: she.id, record_type: 'service', date: date, project_type: 1, homeless: true, literally_homeless: true)
      end
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    end

    it 'counts homeless days on or before on_date' do
      expect(described_class.new(client_ids: [client.id], on_date: on_date).homeless_counts[client.id]).to eq(10)
    end
  end

  describe '#homeless_counts_plus_overrides' do
    let(:client) { create :hud_client }
    let(:on_date) { Date.current - 1.year }
    let(:override_project) { create :hud_project, ProjectType: 6, include_in_days_homeless_override: true }

    def add_days(dates, project_type:, homeless:, project: nil)
      she_attrs = { client: client, project_type: project_type }
      she_attrs.merge!(project_id: project.ProjectID, organization_id: project.OrganizationID, data_source_id: project.data_source_id) if project
      she = create(:she_entry, **she_attrs)
      dates.each do |date|
        create(:service_history_service, client_id: client.id, service_history_enrollment_id: she.id, record_type: 'service', date: date, project_type: project_type, homeless: homeless, literally_homeless: homeless)
      end
    end

    before do
      # ES: 10 days before on_date, 5 after
      add_days((on_date - 10.days..on_date - 1.day).to_a + (on_date + 1.day..on_date + 5.days).to_a, project_type: 1, homeless: true)
      # Verified-days override project: one day before on_date, one after
      add_days([on_date - 30.days, on_date + 30.days], project_type: 6, homeless: nil, project: override_project)
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    end

    # The 10 ES days and the override day before on_date
    it 'counts homeless and override days on or before on_date' do
      expect(described_class.new(client_ids: [client.id], on_date: on_date).homeless_counts_plus_overrides[client.id]).to eq(11)
    end

    # All 15 ES days and both override days
    it 'counts every homeless and override day without on_date' do
      expect(described_class.new(client_ids: [client.id]).homeless_counts_plus_overrides[client.id]).to eq(17)
    end
  end

  describe 'three-year counts' do
    let(:client) { create :hud_client }
    let(:on_date) { Date.current - 1.year }
    # Inside the three years before on_date, but more than three years before today
    let(:old_date) { on_date - 2.years - 30.days }

    def add_days(dates, project_type:, literally_homeless:)
      she = create(:she_entry, client: client, project_type: project_type)
      dates.each do |date|
        create(:service_history_service, client_id: client.id, service_history_enrollment_id: she.id, record_type: 'service', date: date, project_type: project_type, homeless: true, literally_homeless: literally_homeless)
      end
    end

    before do
      # ES: 10 days before on_date, 5 after, and two old days
      es_dates = (on_date - 10.days..on_date - 1.day).to_a + (on_date + 1.day..on_date + 5.days).to_a + [old_date, old_date + 1.day]
      add_days(es_dates, project_type: 1, literally_homeless: true)
      # TH overlapping the first old ES day
      add_days([old_date], project_type: 2, literally_homeless: false)
      GrdaWarehouse::ServiceHistoryServiceMaterialized.refresh!
    end

    describe '#all_homeless_in_last_three_years' do
      # The 10 days before on_date and both old days
      it 'counts the three years before on_date' do
        expect(described_class.new(client_ids: [client.id], on_date: on_date).all_homeless_in_last_three_years[client.id]).to eq(12)
      end

      # The 10 days before and 5 after on_date; the old days are more than three years ago
      it 'counts the three years before today without on_date' do
        expect(described_class.new(client_ids: [client.id]).all_homeless_in_last_three_years[client.id]).to eq(15)
      end
    end

    describe '#all_literally_homeless_last_three_years' do
      # The 10 days before on_date and the old day without TH
      it 'counts the three years before on_date, excluding TH days in that window' do
        expect(described_class.new(client_ids: [client.id], on_date: on_date).all_literally_homeless_last_three_years[client.id]).to eq(11)
      end

      it 'counts the three years before today without on_date' do
        expect(described_class.new(client_ids: [client.id]).all_literally_homeless_last_three_years[client.id]).to eq(15)
      end
    end
  end

  describe 'sheltered and unsheltered counts' do
    let(:client) { create :hud_client }
    let(:on_date) { Date.current - 1.year }
    let(:calculator) { described_class.new(client_ids: [client.id], on_date: on_date, live: true) }

    def add_days(dates, project_type:, homeless:)
      she = create(:she_entry, client: client, project_type: project_type)
      Array.wrap(dates).each do |date|
        create(:service_history_service, client_id: client.id, service_history_enrollment_id: she.id, record_type: 'service', date: date, project_type: project_type, homeless: homeless, literally_homeless: homeless)
      end
    end

    before do
      # ES: 10 days before on_date, 3 after
      add_days((on_date - 10.days..on_date - 1.day).to_a + (on_date + 1.day..on_date + 3.days).to_a, project_type: 1, homeless: true)
      # SO: on the first ES day, two days before the ES stay, and one after on_date
      add_days([on_date - 10.days, on_date - 21.days, on_date - 20.days, on_date + 5.days], project_type: 4, homeless: true)
      # PH after move-in: on the last ES day before on_date and on one SO day
      add_days([on_date - 1.day, on_date - 21.days], project_type: 3, homeless: false)
    end

    # The 10 ES days before on_date, less the PH day
    it 'counts sheltered days, excluding PH days and days after on_date' do
      expect(calculator.sheltered_homeless_last_three_years[client.id]).to eq(9)
    end

    # The two SO days before the ES stay, less the PH day; the SO day on an ES day is sheltered
    it 'counts unsheltered days, excluding sheltered days, PH days, and days after on_date' do
      expect(calculator.unsheltered_homeless_last_three_years[client.id]).to eq(1)
    end
  end
end
