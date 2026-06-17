###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'HmisCsvImporter cleanup context' do
  let(:now) { DateTime.current }

  let(:data_source) do
    GrdaWarehouse::DataSource.create(name: 'Green River', short_name: 'GR', source_type: :sftp)
  end

  def import_csv_records(run_at:, for_data_source: data_source)
    travel_to(run_at) do
      import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_four/allowed_projects',
        version: 'AutoMigrate',
        data_source: for_data_source,
        run_jobs: false,
        allowed_projects: true,
        stop_version: '2024',
      )
    end
  end
end

# A record is kept if EITHER of the following is true:
#   1. Its rank (newest-first by id, partitioned by hud_key + data_source_id) is <= retain_item_count
#   2. Its log foreign key (loader_id / importer_log_id) belongs to an import run
#      created on or after retain_after_date
# Everything else is hard-deleted.
RSpec.shared_examples 'HmisCsvImporter cleanup record expiration' do
  describe 'with 5 daily imports' do
    let(:run_times) do
      5.times.map { |day| now - day.days }.reverse
    end

    before(:each) do
      run_times.each { |run_time| import_csv_records(run_at: run_time) }
    end

    it 'deletes at most max_per_run records' do
      max_per_run = 2
      expect do
        run_job(retain_after_date: now, retain_item_count: 1, max_per_run: max_per_run, batch_size: max_per_run + 1)
      end.to change { records.count }.from(5).to(3)
    end

    it 'retains records within period' do
      expect do
        run_job(retain_after_date: run_times[-2] - 1.minute, retain_item_count: 0)
      end.to change { records.count }.from(5).to(2)
    end

    it 'retains all records when retain_item_count is higher than total records' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 6)
      end.not_to(change { records.count })
    end

    it 'does not delete records in dry run mode' do
      expect do
        run_job(retain_after_date: now, retain_item_count: 1, dry_run: true)
      end.not_to(change { records.count })
    end
  end

  it 'handles case with no records' do
    expect do
      run_job(retain_after_date: now, retain_item_count: 1)
    end.not_to(change { records.count })
  end

  # Scenarios below assert on specific record identity (not just counts) to make
  # the retention rules concrete and verifiable.
  #
  # The fixture contains exactly one Organization per import, so each call to
  # import_csv_records produces one staging row for the Organization hud_key.
  # IDs are monotonically increasing, so `records.order(:id)` == oldest-to-newest.
  describe 'retention policy (explicit record identity)' do
    # Pin time so "recent" vs "old" comparisons are stable within each example.
    let(:base_time) { DateTime.current.beginning_of_hour }

    # 2.5 days ago splits records into "age-protected" (newer) vs "eligible for deletion" (older).
    let(:retain_after_date) { base_time - 2.5.days }

    describe 'keeps the last N versions of a HUD key (retain_item_count)' do
      # All 5 imports are older than the retain window, so age protection plays no role.
      before do
        [7, 6, 5, 4, 3].each { |days_ago| import_csv_records(run_at: base_time - days_ago.days) }
      end

      it 'keeps exactly the N newest records and deletes the rest' do
        ordered_ids = records.order(:id).pluck(:id)
        expect do
          run_job(retain_after_date: retain_after_date, retain_item_count: 3)
        end.to change { records.count }.from(5).to(3)
        expect(records.order(:id).pluck(:id)).to eq(ordered_ids.last(3))
      end
    end

    describe 'age protection: keeps recent imports beyond retain_item_count' do
      # Imports 1-3 are older than the retain window; imports 4-5 fall within it.
      before do
        [5, 4, 3].each { |days_ago| import_csv_records(run_at: base_time - days_ago.days) }
        [2, 1].each    { |days_ago| import_csv_records(run_at: base_time - days_ago.days) }
      end

      it 'keeps age-protected records even when they exceed retain_item_count' do
        ordered_ids = records.order(:id).pluck(:id)
        expect do
          run_job(retain_after_date: retain_after_date, retain_item_count: 1)
        end.to change { records.count }.from(5).to(2)
        expect(records.order(:id).pluck(:id)).to eq(ordered_ids.last(2))
      end
    end

    describe 'multi-data-source isolation' do
      let(:second_data_source) do
        GrdaWarehouse::DataSource.create(name: 'Other Source', short_name: 'OS', source_type: :sftp)
      end

      # 3 old imports per data source; same hud_key in both because they share the same CSV fixture.
      before do
        [8, 7, 6].each do |days_ago|
          import_csv_records(run_at: base_time - days_ago.days)
          import_csv_records(run_at: base_time - days_ago.days, for_data_source: second_data_source)
        end
      end

      it 'retains the last N records independently per data source' do
        ds1_ids = records.where(data_source_id: data_source.id).order(:id).pluck(:id)
        ds2_ids = records.where(data_source_id: second_data_source.id).order(:id).pluck(:id)

        expect do
          run_job(retain_after_date: retain_after_date, retain_item_count: 1)
        end.to change { records.count }.from(6).to(2)

        expect(records.where(data_source_id: data_source.id).pluck(:id)).to eq([ds1_ids.last])
        expect(records.where(data_source_id: second_data_source.id).pluck(:id)).to eq([ds2_ids.last])
      end
    end
  end
end
