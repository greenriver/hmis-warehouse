###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared'

RSpec.describe HmisCsvImporter::Cleanup::ExpireLoadersJob, type: :model do
  include_context 'HmisCsvImporter cleanup context'
  include_examples 'HmisCsvImporter cleanup record expiration'

  def records
    HmisCsvTwentyTwentyFour::Loader::Organization
  end

  def run_job(**options)
    default_options = {
      model_name: 'HmisCsvTwentyTwentyFour::Loader::Organization',
      dry_run: false,
    }
    HmisCsvImporter::Cleanup::ExpireLoadersJob.new.perform(**default_options.merge(options))
  end

  describe '#models' do
    let(:job) { described_class.new }

    it 'includes loader classes from all active versions (>= 2024)' do
      models = job.send(:models)
      expect(models).to include(HmisCsvTwentyTwentyFour::Loader::Organization)
      expect(models).to include(HmisCsvTwentyTwentySix::Loader::Organization)
    end

    it 'excludes loader classes from frozen legacy versions (< 2024)' do
      models = job.send(:models)
      expect(models).not_to include(HmisCsvTwentyTwenty::Loader::Organization)
      expect(models).not_to include(HmisCsvTwentyTwentyTwo::Loader::Organization)
    end

    it 'raises if an active-version module does not implement expiring_loader_classes' do
      stub_module = Module.new
      stub_const('StubDataLake2028', stub_module)
      allow(Rails.application.config).to receive(:hmis_data_lakes).and_return(
        Rails.application.config.hmis_data_lakes.merge('2028' => 'StubDataLake2028'),
      )
      expect { job.send(:models) }.to raise_error(/StubDataLake2028.*expiring_loader_classes/)
    end
  end
end
