###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# A shallow smoke test: it only asserts that the task body runs start to
# finish without raising, including when one step blows up. It does not
# assert anything about what the individual jobs/tasks do -- that's their
# own specs' responsibility.
RSpec.describe 'grda_warehouse:hourly', type: :task do
  include ActiveJob::TestHelper

  let(:task_name) { 'grda_warehouse:hourly' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'grda_warehouse:hourly' }
  end

  before do
    Rake::Task[task_name].reenable
    Rake::Task['jobs:check_queue'].reenable

    # Skip every HMIS-gated branch so only the unconditional steps run.
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)

    allow_any_instance_of(MaintenanceTasksLifecycleJob).to receive(:perform)
    allow_any_instance_of(CheckJobQueue).to receive(:perform)
    allow(GrdaWarehouse::CustomImports::Config).to receive(:active).and_return([])
    allow(TaskQueue).to receive(:queue_unprocessed!)
    allow(MaReports::CsgEngage::Report).to receive(:run_if_ready)
    allow_any_instance_of(AppResourceMonitor::CollectStatsJob).to receive(:should_enqueue?).and_return(false)
    allow(GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask).to receive(:perform)
    allow(BuildTranslationCacheJob).to receive(:perform_later)
  end

  it 'completes without raising when every step succeeds' do
    expect { Rake::Task[task_name].invoke }.not_to raise_error
  end

  it 'enqueues the jobs for the inline maintenance items covered by this epic' do
    Rake::Task[task_name].invoke

    expect(MaintainProjectGroupListsJob).to have_been_enqueued
    expect(SyncAnalysisDataJob).to have_been_enqueued
  end

  it 'does not enqueue a second copy of a job that is already waiting in the queue' do
    allow(Delayed::Job).to receive(:queued?).and_return(true)

    Rake::Task[task_name].invoke

    expect(MaintainProjectGroupListsJob).not_to have_been_enqueued
    expect(SyncAnalysisDataJob).not_to have_been_enqueued
  end

  # TaskQueue.queue_unprocessed! sits in the middle of the task body, so each step asserted below
  # comes after it and doubles as evidence the run kept going. BuildTranslationCacheJob is the last one.
  it 'does not let a raise in the first step abort the rest of the run' do
    allow(TaskQueue).to receive(:queue_unprocessed!).and_raise('boom')
    expect(Sentry).to receive(:capture_exception).with(instance_of(RuntimeError))

    expect { Rake::Task[task_name].invoke }.not_to raise_error

    expect(MaintainProjectGroupListsJob).to have_been_enqueued
    expect(MaReports::CsgEngage::Report).to have_received(:run_if_ready)
    expect(SyncAnalysisDataJob).to have_been_enqueued
    expect(GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask).to have_received(:perform)
    expect(BuildTranslationCacheJob).to have_received(:perform_later)
  end
end
