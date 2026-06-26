###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe TestJob, type: :job do
  describe 'simulating an AWS credential failure' do
    subject(:run) { described_class.new.perform(simulate_credential_failure: true, wrap_credential_failure: wrapped) }

    context 'raised directly' do
      let(:wrapped) { false }

      it 'raises a real credential error the catch-all plugin recognizes' do
        expect { run }.to raise_error(Aws::STS::Errors::ExpiredTokenException) do |error|
          expect(AwsCredentialFailurePlugin.credential_failure?(error)).to be true
        end
      end
    end

    context 'wrapped in another error' do
      let(:wrapped) { true }

      it 'raises a wrapper whose cause chain is detected by credential_failure?' do
        expect { run }.to raise_error(RuntimeError) do |error|
          # The credential error rides along as the cause, not the top-level error,
          # exercising the .cause-chain walk in credential_failure?.
          expect(error).not_to be_a(Aws::STS::Errors::ExpiredTokenException)
          expect(error.cause).to be_a(Aws::STS::Errors::ExpiredTokenException)
          expect(AwsCredentialFailurePlugin.credential_failure?(error)).to be true
        end
      end
    end
  end

  describe '.simulate_credential_failure' do
    around do |example|
      previous_adapter = ActiveJob::Base.queue_adapter
      ActiveJob::Base.queue_adapter = :delayed_job
      example.run
    ensure
      ActiveJob::Base.queue_adapter = previous_adapter
    end

    it 'enqueues exactly one job and does not stack the random load simulation' do
      expect { described_class.simulate_credential_failure }.to change(Delayed::Job, :count).by(1)
    end
  end
end
