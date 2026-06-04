###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared'

RSpec.describe HmisCsvImporter::Cleanup::ExpireImportersJob, type: :model do
  include_context 'HmisCsvImporter cleanup context'
  it_behaves_like 'HmisCsvImporter cleanup record expiration'

  def records
    HmisCsvTwentyTwentyFour::Importer::Organization
  end

  def run_job(**options)
    default_options = {
      model_name: 'HmisCsvTwentyTwentyFour::Importer::Organization',
      dry_run: false,
    }
    HmisCsvImporter::Cleanup::ExpireImportersJob.new.perform(**default_options.merge(options))
  end

  describe '#models' do
    let(:job) { described_class.new }

    it 'includes importer classes from all active versions (>= 2024)' do
      models = job.send(:models)
      expect(models).to include(HmisCsvTwentyTwentyFour::Importer::Organization)
      expect(models).to include(HmisCsvTwentyTwentySix::Importer::Organization)
    end

    it 'excludes importer classes from frozen legacy versions (< 2024)' do
      models = job.send(:models)
      expect(models).not_to include(HmisCsvTwentyTwenty::Importer::Organization)
      expect(models).not_to include(HmisCsvTwentyTwentyTwo::Importer::Organization)
    end

    it 'never expires Export or Project tables' do
      models = job.send(:models)
      expect(models).not_to include(HmisCsvTwentyTwentyFour::Importer::Export)
      expect(models).not_to include(HmisCsvTwentyTwentyFour::Importer::Project)
      expect(models).not_to include(HmisCsvTwentyTwentySix::Importer::Export)
      expect(models).not_to include(HmisCsvTwentyTwentySix::Importer::Project)
    end

    it 'raises if an active-version module does not implement expiring_importer_classes' do
      stub_module = Module.new
      stub_const('StubDataLake2028', stub_module)
      allow(Rails.application.config).to receive(:hmis_data_lakes).and_return(
        Rails.application.config.hmis_data_lakes.merge('2028' => 'StubDataLake2028'),
      )
      expect { job.send(:models) }.to raise_error(/StubDataLake2028.*expiring_importer_classes/)
    end
  end
end
