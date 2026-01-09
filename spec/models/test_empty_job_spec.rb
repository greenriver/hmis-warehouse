# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestEmptyJob, type: :model do
  describe 'when more than 100 jobs' do
    before do
      222.times do
        Delayed::Job.enqueue TestEmptyJob.new
      end
    end

    it 'works off all jobs' do
      expect(Delayed::Job.where(failed_at: nil).count).to be > 100
      work_off_all_ready_jobs
      expect(Delayed::Job.where(failed_at: nil).count).to eq(0)
      # No failed jobs
      expect(Delayed::Job.count).to eq(0)
    end
  end
end
