###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe UnifiedErrorReporter do
  let(:error) { StandardError.new('something went wrong') }

  before do
    allow(Sentry).to receive(:initialized?).and_return(true)
    allow(Sentry).to receive(:capture_exception_with_info)
  end

  describe '.call' do
    it 'logs the message' do
      expect(Rails.logger).to receive(:error).with('custom message')
      described_class.call(error, 'custom message')
    end

    it 'uses the exception message when no custom message is given' do
      expect(Rails.logger).to receive(:error).with('something went wrong')
      described_class.call(error)
    end

    it 'sends the exception to Sentry' do
      allow(Rails.logger).to receive(:error)
      described_class.call(error, 'custom message')
      expect(Sentry).to have_received(:capture_exception_with_info).with(error, 'custom message', {})
    end

    it 'forwards context to Sentry' do
      allow(Rails.logger).to receive(:error)
      ctx = { url: 'https://example.com' }
      described_class.call(error, 'oops', context: ctx)
      expect(Sentry).to have_received(:capture_exception_with_info).with(error, 'oops', ctx)
    end

    it 'pings the Slack notifier when provided' do
      notifier = instance_double(ApplicationNotifier)
      allow(notifier).to receive(:ping)
      described_class.call(error, 'boom', slack_notifier: notifier)
      expect(notifier).to have_received(:ping).with('boom')
    end

    it 'skips Rails.logger.error when a slack_notifier is provided (notifier already logs)' do
      allow(Rails.logger).to receive(:error)
      notifier = instance_double(ApplicationNotifier)
      allow(notifier).to receive(:ping)
      described_class.call(error, 'boom', slack_notifier: notifier)
      expect(Rails.logger).not_to have_received(:error)
    end

    it 'skips Sentry when sentry: false' do
      allow(Rails.logger).to receive(:error)
      described_class.call(error, 'boom', sentry: false)
      expect(Sentry).not_to have_received(:capture_exception_with_info)
    end

    it 'skips Sentry when Sentry is not initialized' do
      allow(Sentry).to receive(:initialized?).and_return(false)
      allow(Rails.logger).to receive(:error)
      described_class.call(error, 'boom')
      expect(Sentry).not_to have_received(:capture_exception_with_info)
    end
  end
end
