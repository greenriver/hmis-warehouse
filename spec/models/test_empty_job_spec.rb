# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestEmptyJob, type: :model do
  describe 'when more than 100 jobs' do
    # Disable transactional fixtures to ensure jobs are committed to the database
    # and visible to the Delayed::Worker's separate database connection
    before do
      self.use_transactional_tests = false
      Delayed::Job.delete_all
      222.times do
        Delayed::Job.enqueue TestEmptyJob.new
      end
    end

    after do
      Delayed::Job.delete_all
      self.use_transactional_tests = true
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
