# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SystemCohortsJob, type: :job do
  let(:job) { SystemCohortsJob.new }

  describe '#perform' do
    it 'processes the system cohorts' do
      expect { job.perform }.not_to raise_error
    end
  end
end
