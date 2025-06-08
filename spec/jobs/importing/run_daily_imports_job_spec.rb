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
    allow(Reporting::PopulationDashboardPopulateJob).to receive(:set).and_return(double(perform_later: true))
    allow(PruneDocumentExportsJob).to receive(:perform_later)
    allow(Health::PruneDocumentExportsJob).to receive(:perform_later)
    allow(YouthFollowUpsJob).to receive(:set).and_return(double(perform_later: true))
    allow(SystemCohortsJob).to receive(:set).and_return(double(perform_later: true))
    allow(AccessGroup).to receive(:delayed_system_group_maintenance)
    allow(Collection).to receive(:delayed_system_group_maintenance)
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
      end

      it 'creates maintenance tasks' do
        expect do
          job.perform
        end.to change(GrdaWarehouse::Tasks::SystemMaintenanceTask, :count).by_at_least(15)
      end

      it 'creates task records with correct job_type' do
        job.perform

        tasks = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(job_type: 'Importing::RunDailyImportsJob')
        expect(tasks.count).to be >= 15
        expect(tasks.pluck(:name)).to include(
          'Revoke expired consent',
          'Identify Duplicates',
          'Clean projects',
          'Generate service history',
        )
      end

      it 'sets default alert threshold for tasks' do
        job.perform

        tasks = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(job_type: 'Importing::RunDailyImportsJob')
        expect(tasks.first.alert_threshold_minutes).to eq(60 * 36) # 36 hours default
      end

      it 'invokes each task and creates task runs' do
        job.perform

        tasks = GrdaWarehouse::Tasks::SystemMaintenanceTask.where(job_type: 'Importing::RunDailyImportsJob')
        tasks.each do |task|
          expect(task.system_maintenance_task_runs.count).to be >= 1
          run = task.system_maintenance_task_runs.last # Get the most recent run
          expect(run.started_at).to be_present
          expect(run.completed_at).to be_present
        end
      end

      it 'sends completion notification' do
        job.perform

        expect(notifier).to have_received(:ping).with(a_string_matching(/Nightly Process completed in/))
      end
    end
  end

  describe 'task lifecycle management' do
    let!(:existing_task) { create(:system_maintenance_task, job_type: 'Importing::RunDailyImportsJob', name: 'Revoke expired consent') }
    let!(:other_job_task) { create(:system_maintenance_task, job_type: 'SomeOtherJob', name: 'Other Job Task') }

    before do
      allow(GrdaWarehouse::DataSource).to receive(:with_advisory_lock).and_yield
    end

    it 'processes alerts for all existing tasks' do
      # Update both tasks to have short thresholds and old runs
      existing_task.update!(alert_threshold_minutes: 60)
      other_job_task.update!(alert_threshold_minutes: 60)

      # Create old runs that exceed the threshold for both tasks
      create(:system_maintenance_task_run,
             system_maintenance_task: existing_task,
             started_at: 2.hours.ago,
             completed_at: 2.hours.ago)
      create(:system_maintenance_task_run,
             system_maintenance_task: other_job_task,
             started_at: 2.hours.ago,
             completed_at: 2.hours.ago)

      # Mock Sentry to verify alerts are sent
      allow(Sentry).to receive(:capture_message)

      job.perform

      # Verify that alerts were sent for both tasks (which means process_alerts was called on all tasks)
      expect(Sentry).to have_received(:capture_message).with(a_string_matching(/Exceeded threshold/)).at_least(2).times
    end
  end

  describe 'expired task run cleanup' do
    let!(:task) { create(:system_maintenance_task, job_type: 'Importing::RunDailyImportsJob', name: 'Test Task') }
    let!(:recent_run) { create(:system_maintenance_task_run, system_maintenance_task: task, started_at: 1.month.ago) }
    let!(:expired_run) { create(:system_maintenance_task_run, system_maintenance_task: task, started_at: 7.months.ago) }
    let!(:other_job_task) { create(:system_maintenance_task, job_type: 'SomeOtherJob', name: 'Other Task') }
    let!(:other_job_run) { create(:system_maintenance_task_run, system_maintenance_task: other_job_task, started_at: 7.months.ago) }

    before do
      allow(GrdaWarehouse::DataSource).to receive(:with_advisory_lock).and_yield
    end

    it 'deletes expired task runs for all jobs' do
      job.perform

      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(recent_run.id)).to be true
      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(expired_run.id)).to be false
      expect(GrdaWarehouse::Tasks::SystemMaintenanceTaskRun.exists?(other_job_run.id)).to be false # Now cleaned up for all jobs
    end
  end
end
