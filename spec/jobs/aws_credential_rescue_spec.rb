###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AwsCredentialRescue, type: :job do
  around do |example|
    previous_adapter = ActiveJob::Base.queue_adapter
    ActiveJob::Base.queue_adapter = :delayed_job
    example.run
  ensure
    ActiveJob::Base.queue_adapter = previous_adapter
  end

  # A real (autoloadable-style) job so the Delayed::Job handler round-trips cleanly.
  class CredentialRescueTestJob < BaseJob
    include AwsCredentialRescue

    def perform
      # not exercised directly; we call with_aws_credential_rescue from the specs
    end
  end

  # Match the plugin's detection (by class name) without depending on the AWS SDK.
  let(:credential_error_class) { stub_const('Aws::STS::Errors::ExpiredTokenException', Class.new(StandardError)) }
  let(:credential_error) { credential_error_class.new('token expired') }
  let(:job) { CredentialRescueTestJob.new }

  before { allow(SignalHandlerPlugin).to receive(:stop_current_worker!) }

  # Build a real, properly-serialized Delayed::Job row and point the running job at it.
  def enqueue_and_attach!(target_job = job)
    CredentialRescueTestJob.perform_later
    row = Delayed::Job.last
    allow(target_job).to receive(:provider_job_id).and_return(row.id)
    row
  end

  describe '#with_aws_credential_rescue' do
    it 'returns the block value and does nothing when there is no error' do
      enqueue_and_attach!
      expect { expect(job.with_aws_credential_rescue { 42 }).to eq(42) }.
        not_to change(Delayed::Job, :count)
      expect(SignalHandlerPlugin).not_to have_received(:stop_current_worker!)
    end

    it 're-raises non-credential errors untouched' do
      enqueue_and_attach!
      expect do
        expect { job.with_aws_credential_rescue { raise ArgumentError, 'boom' } }.
          to raise_error(ArgumentError, 'boom')
      end.not_to change(Delayed::Job, :count)
      expect(SignalHandlerPlugin).not_to have_received(:stop_current_worker!)
    end

    context 'on a credential failure (first occurrence)' do
      it 'reschedules a fresh future attempt carrying an incremented count, and stops the worker' do
        enqueue_and_attach!
        result = nil
        expect do
          result = job.with_aws_credential_rescue(wait: 15.minutes) { raise credential_error }
        end.to change(Delayed::Job, :count).by(1)

        expect(result).to eq(:rescheduled)
        clone = Delayed::Job.last
        expect(clone.run_at).to be > 14.minutes.from_now
        expect(clone.attempts).to eq(job.calculated_attempts)
        expect(clone.failed_at).to be_nil
        expect(clone.last_error).to be_nil
        expect(clone.payload_object.job_data[AwsCredentialRescue::CREDENTIAL_RESCHEDULE_KEY]).to eq(1)
        expect(SignalHandlerPlugin).to have_received(:stop_current_worker!)
      end
    end

    context 'when the reschedule budget is already exhausted' do
      it 'reads the count from the running job and re-raises (and does not reschedule again)' do
        # First failure produces a clone whose serialized data carries count 1.
        enqueue_and_attach!
        job.with_aws_credential_rescue { raise credential_error }
        clone = Delayed::Job.last
        expect(clone.payload_object.job_data[AwsCredentialRescue::CREDENTIAL_RESCHEDULE_KEY]).to eq(1)

        # That clone is now the running job; a second credential failure should give up.
        second = CredentialRescueTestJob.new
        allow(second).to receive(:provider_job_id).and_return(clone.id)

        expect do
          expect { second.with_aws_credential_rescue { raise credential_error } }.
            to raise_error(credential_error_class)
        end.not_to change(Delayed::Job, :count)
      end
    end

    context 'when the delayed_job row cannot be found' do
      it 'notifies Sentry and re-raises rather than silently dropping the job (no clone created)' do
        # Without a job row to clone we can't reschedule, so re-raise: the catch-all plugin
        # records the failure (and stops the worker) instead of the work being lost.
        allow(job).to receive(:provider_job_id).and_return(999_999)
        allow(Sentry).to receive(:capture_message)

        expect do
          expect { job.with_aws_credential_rescue { raise credential_error } }.
            to raise_error(credential_error_class)
        end.not_to change(Delayed::Job, :count)
        expect(Sentry).to have_received(:capture_message).with(/Unable to find delayed_job for credential reschedule/)
        expect(SignalHandlerPlugin).not_to have_received(:stop_current_worker!)
      end
    end
  end
end
