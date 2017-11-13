require 'rails_helper'

RSpec.describe Reporting::RunHudChronicJob, type: :job do

  before(:each) do
    ActiveJob::Base.queue_adapter = :test
  end

  describe 'perform' do

    let(:ids) { [1,2,3] }
    let(:date) { Date.today }
    let(:enqueue_job) {
      Reporting::RunHudChronicJob.perform_later(ids, date.to_s)
    }

    before(:each) do
      enqueue_job
    end

    it 'enqueues a job' do
      expect( Reporting::RunHudChronicJob ).to have_been_enqueued
    end

  end

end