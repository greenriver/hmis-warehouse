###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SyncAnalysisDataTaskJob, type: :job do
  include ActiveJob::TestHelper

  let(:task_class) { GrdaWarehouse::Tasks::SyncAnalysisDataTask }

  describe '#perform' do
    it 'delegates to the task' do
      expect(task_class).to receive(:perform).with(no_args)
      described_class.new.perform
    end
  end

  describe 'enqueuing' do
    it 'runs on the long-running queue at maintenance priority' do
      described_class.perform_later
      enqueued = ActiveJob::Base.queue_adapter.enqueued_jobs.last
      expect(enqueued[:queue]).to eq(ENV.fetch('DJ_LONG_QUEUE_NAME', 'long_running').to_s)
      expect(enqueued[:priority]).to eq(BaseJob::MAINTENANCE_PRIORITY_15)
    end
  end
end
