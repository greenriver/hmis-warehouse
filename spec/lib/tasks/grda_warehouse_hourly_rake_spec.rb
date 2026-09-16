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
  include ActiveSupport::Testing::TimeHelpers

  let(:task_name) { 'grda_warehouse:hourly' }

  before(:all) do
    Rails.application.load_tasks if Rake::Task.tasks.none? { |t| t.name == 'grda_warehouse:hourly' }
  end

  before do
    Rake::Task[task_name].reenable
    Rake::Task['jobs:check_queue'].reenable

    # Skip every HMIS- and hour-gated branch so only the unconditional steps run.
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(false)

    allow_any_instance_of(MaintenanceTasksLifecycleJob).to receive(:perform)
    allow_any_instance_of(CheckJobQueue).to receive(:perform)
    allow(GrdaWarehouse::CustomImports::Config).to receive(:active).and_return([])
    allow(TaskQueue).to receive(:queue_unprocessed!)
    allow(GrdaWarehouse::ProjectGroup).to receive(:maintain_project_lists!)
    allow(MaReports::CsgEngage::Report).to receive(:run_if_ready)
    allow_any_instance_of(AppResourceMonitor::CollectStatsJob).to receive(:should_enqueue?).and_return(false)
    allow(GrdaWarehouse::Tasks::SyncAnalysisDataTask).to receive(:perform)
    allow(GrdaWarehouse::Tasks::CleanupClientSearchQueriesTask).to receive(:perform)
    allow(BuildTranslationCacheJob).to receive(:perform_later)
  end

  around do |example|
    # An hour that avoids every hour-gated branch in the task body (3, 4, 5, 17, 20, 23, and the metrics COLLECTION_HOUR).
    travel_to(Time.zone.parse('2026-01-01 10:00:00')) { example.run }
  end

  it 'completes without raising when every step succeeds' do
    expect { Rake::Task[task_name].invoke }.not_to raise_error
  end

  it 'does not let a raise in one step abort the rest of the run' do
    allow(GrdaWarehouse::ProjectGroup).to receive(:maintain_project_lists!).and_raise('boom')
    expect(Sentry).to receive(:capture_exception).with(instance_of(RuntimeError))

    expect { Rake::Task[task_name].invoke }.not_to raise_error

    expect(MaReports::CsgEngage::Report).to have_received(:run_if_ready)
    expect(BuildTranslationCacheJob).to have_received(:perform_later)
  end
end
