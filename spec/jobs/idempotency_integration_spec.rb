# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Job Retry and Idempotency Integration', type: :job do
  class IdempotentTestJob < BaseJob
    def perform
    end
  end

  class NonIdempotentTestJob < BaseJob
    def supports_idempotent_retry?
      false
    end

    def perform
    end
  end

  let(:max_attempts) { Delayed::Worker.max_attempts }

  describe 'IdempotentTestJob' do
    it 'starts with 0 attempts' do
      IdempotentTestJob.perform_later
      dj = Delayed::Job.last
      expect(dj.attempts).to eq(0)
    end

    it 'resets attempts to 0 on requeue' do
      job_instance = IdempotentTestJob.new
      dj = Delayed::Job.create!(handler: 'test', attempts: 2)
      allow(job_instance).to receive(:provider_job_id).and_return(dj.id)

      job_instance.requeue_at(Time.current, 'test')
      expect(Delayed::Job.last.attempts).to eq(0)
    end
  end

  describe 'NonIdempotentTestJob' do
    it 'sets attempts to max_attempts - 1 on requeue' do
      job_instance = NonIdempotentTestJob.new
      dj = Delayed::Job.create!(handler: 'test', attempts: 0)
      allow(job_instance).to receive(:provider_job_id).and_return(dj.id)

      job_instance.requeue_at(Time.current, 'test')
      expect(Delayed::Job.last.attempts).to eq(max_attempts - 1)
    end

    it 'calculates correct attempts' do
      job = NonIdempotentTestJob.new
      expect(job.calculated_attempts).to eq(max_attempts - 1)
    end
  end
end
