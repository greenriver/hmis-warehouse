###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.shared_context 'with ce processing setup' do
  let!(:destination_data_source) { create :destination_data_source }
  let!(:client1) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client2) { create :grda_warehouse_hud_client, data_source: destination_data_source }
  let!(:client3) { create :grda_warehouse_hud_client, data_source: destination_data_source }

  let!(:ce_data_source) { create(:hmis_primary_data_source) }
  let!(:pool) { create(:hmis_ce_match_candidate_pool_active, data_source: ce_data_source) }
  let(:now) { Time.current }

  before(:all) { cleanup_test_environment }

  before do
    allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
    allow_any_instance_of(Hmis::Ce::Configuration).to receive(:enabled?).and_return(true)
  end
end

RSpec.shared_examples 'a self-scheduling job' do |wait_time:|
  context 'with self-scheduling' do
    it 'schedules next batch when wait_time is provided' do
      travel_to now do
        described_class.perform_now(wait_time: wait_time)

        enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
        expect(enqueued_job).to be_present
        expect(enqueued_job[:at].to_i).to eq((now + wait_time).to_i)
      end
    end

    it 'does not schedule next batch when wait_time is nil' do
      described_class.perform_now(wait_time: nil)

      enqueued_job = enqueued_jobs.find { |j| j[:job] == described_class }
      expect(enqueued_job).to be_nil
    end
  end
end

RSpec.shared_examples 'a job that can be enqueued if not already running' do |wait_time:|
  describe '.enqueue_if_not_already_running' do
    it 'enqueues job when none are running' do
      expect { described_class.enqueue_if_not_already_running(wait_time: wait_time) }.
        to have_enqueued_job(described_class)
    end

    it 'does not enqueue job when one is already queued' do
      # First job
      described_class.perform_later(wait_time: wait_time)
      # Clear the jobs queue to simulate the check
      clear_enqueued_jobs

      # Mock the jobs_for_class to return a job (simulating one already queued)
      allow(Delayed::Job).to receive(:jobs_for_class).with(described_class.name).and_return([double('job')])

      expect { described_class.enqueue_if_not_already_running(wait_time: wait_time) }.
        not_to have_enqueued_job(described_class)
    end
  end
end
