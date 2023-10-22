require 'rails_helper'

RSpec.describe TestEmptyJob, type: :model do
  describe 'when more than 100 jobs' do
    before do
      222.times do
        Delayed::Job.enqueue TestEmptyJob.new
      end
    end

    it 'works off all jobs when looping' do
      expect(Delayed::Job.where(failed_at: nil).count).to be > 100
      Delayed::Worker.new.work_off while Delayed::Job.where(failed_at: nil).count > 0
      expect(Delayed::Job.where(failed_at: nil).count).to eq(0)
      # No failed jobs
      expect(Delayed::Job.count).to eq(0)
    end

    it 'works off all jobs when told to work off 1,000' do
      expect(Delayed::Job.where(failed_at: nil).count).to be > 100
      Delayed::Worker.new.work_off(1_000)
      expect(Delayed::Job.where(failed_at: nil).count).to eq(0)
      # No failed jobs
      expect(Delayed::Job.count).to eq(0)
    end
  end
end
