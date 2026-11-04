###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Importing::RunDailyImportsJob, type: :job do
  let(:job) { described_class.new }
  let(:notifier) { instance_double('Notifier') }

  before do
    allow(job).to receive(:setup_notifier).and_return(notifier)
    job.instance_variable_set(:@notifier, notifier)
    allow(notifier).to receive(:ping)

    # Mock the actual task implementations to avoid running real maintenance tasks
    allow(GrdaWarehouse::Hud::Client).to receive(:revoke_expired_consent)
    allow(GrdaWarehouse::HmisClient).to receive(:maintain_client_consent)
    allow(GrdaWarehouse::Tasks::IdentifyDuplicates).to receive(:new).and_return(double(run!: true, match_existing!: true))
    allow(GrdaWarehouse::ClientMatch).to receive(:auto_process!)
    allow(GrdaWarehouse::Tasks::ProjectCleanup).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::Tasks::ClientCleanup).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::Tasks::ServiceHistory::Enrollment).to receive(:batch_process_date_range!)
    allow(GrdaWarehouse::Tasks::ServiceHistory::Enrollment).to receive(:batch_process_unprocessed!)
    allow(GrdaWarehouse::Tasks::SanityCheckServiceHistory).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::Tasks::EarliestResidentialService).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::ServiceHistoryServiceMaterialized).to receive(:refresh!)
    allow(GrdaWarehouse::ServiceHistoryServiceMaterialized).to receive(:new).and_return(double(double_check_materialized_view: true))
    allow(GrdaWarehouse::WarehouseClientsProcessed).to receive(:update_cached_counts)
    allow(Nickname).to receive(:populate!)
    allow(UniqueName).to receive(:update!)
    allow(GrdaWarehouse::Tasks::CensusImport).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::ChEnrollment).to receive(:maintain!)
    allow(GrdaWarehouse::Tasks::ChronicallyHomeless).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::Tasks::DmhChronicallyHomeless).to receive(:new).and_return(double(run!: true))
    allow(GrdaWarehouse::Tasks::HudChronicallyHomeless).to receive(:new).and_return(double(run!: true))
    allow(ReportingSetupJob).to receive(:set).and_return(double(perform_later: true))
    allow(Delayed::Job).to receive(:queued?).and_return(false)
    allow(GrdaWarehouse::Report::Base).to receive(:update_fake_materialized_views)
    allow(HudReports::HouseholdContext).to receive(:prune!)
    allow(Reporting::PopulationDashboardPopulateJob).to receive(:set).and_return(double(perform_later: true))
    allow(PruneDocumentExportsJob).to receive(:perform_later)
    allow(YouthFollowUpsJob).to receive(:set).and_return(double(perform_later: true))
    allow(SystemCohortsJob).to receive(:set).and_return(double(perform_later: true))
    allow(AccessGroup).to receive(:delayed_system_group_maintenance)
    allow(Collection).to receive(:delayed_system_group_maintenance)
    allow(GrdaWarehouse::Tasks::CleanupOrphanedSystemCollections).to receive(:new).and_return(double(delay: double(run!: true)))
    allow(GrdaWarehouse::Cohort).to receive(:delay).and_return(double(maintain_auto_maintained!: true))
    allow(SyncSyntheticDataJob).to receive(:perform_later)
    allow(CasBase).to receive(:db_exists?).and_return(false)
    allow(job).to receive(:create_statistical_matches)
    allow(job).to receive(:generate_logging_info)
    allow(job).to receive(:update_from_hmis_forms)
    allow(job).to receive(:sync_with_cas)
    allow(job).to receive(:warm_cache)
    allow(job).to receive(:destination_client_ids).and_return([1, 2, 3])
    allow(GrdaWarehouse::Config).to receive(:get).with(:release_duration).and_return('Other')

    # Mock import settling
    allow(GrdaWarehouse::DataSource).to receive(:importable).and_return([])
  end

  describe '#perform' do
    context 'when lock cannot be acquired' do
      before do
        allow(GrdaWarehouse::DataSource).to receive(:with_advisory_lock).and_return(false)
      end

      it 'notifies about already running process and exits' do
        job.perform
        expect(notifier).to have_received(:ping).with('Nightly process already running EXITING!!!')
      end

      it 'does not register or run any maintenance tasks' do
        expect do
          job.perform
        end.not_to change(GrdaWarehouse::Tasks::SystemMaintenanceTask, :count)
      end
    end

    context 'when lock is acquired successfully' do
      before do
        allow(GrdaWarehouse::DataSource).to receive(:with_advisory_lock).and_yield
        # Allow the MaintenanceTasksLifecycleJob to actually run and create its task
        allow(MaintenanceTasksLifecycleJob).to receive(:perform_now).and_call_original
      end

      it 'creates maintenance tasks' do
        expect do
          job.perform
        end.to change { GrdaWarehouse::Tasks::SystemMaintenanceTask.count }.by_at_least(10)
      end

      it 'sets default alert threshold for tasks' do
        job.perform

        task = GrdaWarehouse::Tasks::SystemMaintenanceTask.first!
        expect(task.completion_alert_minutes).to eq(60 * 36) # 36 hours default
      end

      it 'invokes each task and creates task runs' do
        job.perform

        tasks = GrdaWarehouse::Tasks::SystemMaintenanceTask.order(:id)
        tasks.each do |task|
          expect(task.system_maintenance_task_runs.count).to be >= 1
          run = task.system_maintenance_task_runs.last # Get the most recent run
          expect(run.started_at).to be_present
          expect(run.completed_at).to be_present
        end
      end

      it 'queues the client retention pass at maintenance priority instead of running it inline' do
        expect { job.perform }.to have_enqueued_job(ClientRetentionJob).at_priority(BaseJob::MAINTENANCE_PRIORITY_15)
      end

      it 'sends completion notification' do
        job.perform

        expect(notifier).to have_received(:ping).with(a_string_matching(/Nightly Process completed in/))
      end

      describe 'chronic backfill' do
        def configure_months_to_build(value)
          create(:app_config_property, key: 'chronic_backfill/months_to_build', value: value)
        end

        def chronic_dates_calculated
          [
            GrdaWarehouse::Tasks::ChronicallyHomeless,
            GrdaWarehouse::Tasks::DmhChronicallyHomeless,
            GrdaWarehouse::Tasks::HudChronicallyHomeless,
          ].map do |task_class|
            calculated = []
            expect(task_class).to have_received(:new).at_least(:once) do |date:|
              calculated << date
            end
            calculated
          end
        end

        around do |example|
          travel_to(Time.zone.local(run_date.year, run_date.month, run_date.day, 3)) { example.run }
        end

        context 'when it is not the 1st or 15th' do
          let(:run_date) { Date.new(2026, 11, 14) }

          it 'does not recalculate' do
            job.perform

            expect(GrdaWarehouse::Tasks::ChronicallyHomeless).not_to have_received(:new)
          end
        end

        context 'on the 15th' do
          let(:run_date) { Date.new(2026, 11, 15) }

          it 'recalculates the 1st and 15th of the last 6 months when unset' do
            job.perform

            expected_dates = (0...6).flat_map do |i|
              month = run_date.months_ago(i)
              [month.change(day: 15), month.change(day: 1)]
            end
            chronic_dates_calculated.each do |dates|
              expect(dates).to match_array(expected_dates)
            end
          end

          it 'follows the configured number of months' do
            configure_months_to_build(2)

            job.perform

            expected_dates = [
              Date.new(2026, 11, 15),
              Date.new(2026, 11, 1),
              Date.new(2026, 10, 15),
              Date.new(2026, 10, 1),
            ]
            chronic_dates_calculated.each do |dates|
              expect(dates).to match_array(expected_dates)
            end
          end

          it 'skips the recalculation but still maintains ChEnrollment when set to 0' do
            configure_months_to_build(0)

            job.perform

            expect(GrdaWarehouse::ChEnrollment).to have_received(:maintain!)
            expect(GrdaWarehouse::Tasks::ChronicallyHomeless).not_to have_received(:new)
            expect(GrdaWarehouse::Tasks::DmhChronicallyHomeless).not_to have_received(:new)
            expect(GrdaWarehouse::Tasks::HudChronicallyHomeless).not_to have_received(:new)
          end
        end

        context 'on the 1st with one month configured' do
          let(:run_date) { Date.new(2026, 11, 1) }

          it 'recalculates only the 1st' do
            configure_months_to_build(1)

            job.perform

            chronic_dates_calculated.each do |dates|
              expect(dates).to eq([Date.new(2026, 11, 1)])
            end
          end
        end
      end
    end
  end
end
