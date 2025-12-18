# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Delayed::Backend::ActiveRecord::Job, type: :model do
  describe '#handle_cancellation!' do
    let(:job) { described_class.create!(handler: 'some_handler') }

    context 'when cancellation has been requested' do
      before do
        job.update!(cancellation_requested_at: Time.current)
      end

      it 'raises a JobCancelled exception' do
        expect { job.handle_cancellation! }.to raise_error(ApplicationJob::JobCancelled, 'Job cancelled')
      end
    end

    context 'when cancellation has not been requested' do
      it 'does not raise an exception' do
        expect { job.handle_cancellation! }.not_to raise_error
      end
    end
  end
end
