###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe GenerateClientRoiAuthorizationsJob, type: :job do
  include ActiveJob::TestHelper

  let(:task_class) { GrdaWarehouse::Tasks::GenerateClientRoiAuthorizationsTask }

  describe '#perform' do
    before do
      allow(task_class).to receive(:perform)
    end

    it 'leaves the task to its own defaults when called without arguments' do
      expect(task_class).to receive(:perform).with(no_args)
      described_class.new.perform
    end

    it 'passes client_ids and batch_size through to the task' do
      expect(task_class).to receive(:perform).with(client_ids: [1, 2], batch_size: 10)
      described_class.new.perform(client_ids: [1, 2], batch_size: 10)
    end
  end

  describe 'enqueuing' do
    it 'runs at maintenance priority' do
      described_class.perform_later
      expect(ActiveJob::Base.queue_adapter.enqueued_jobs.last[:priority]).to eq(BaseJob::MAINTENANCE_PRIORITY_15)
    end
  end
end
