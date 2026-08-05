###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD CSV MigrateAssessmentsJob enqueue', type: :model do
  include ActiveJob::TestHelper

  fixture = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files'

  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  before do
    clear_enqueued_jobs
  end

  describe 'when importing into an HMIS data source' do
    let(:hmis_data_source) do
      create(:source_data_source, hmis: 'hmis.example.test', name: 'HMIS DS', short_name: 'HMIS')
    end

    before do
      allow(HmisEnforcement).to receive(:hmis_enabled?).and_return(true)
      import_hmis_csv_fixture(
        fixture,
        data_source: hmis_data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end

    it 'enqueues MigrateAssessmentsJob once with the data source and involved project pks' do
      expected_project_pks = GrdaWarehouse::Hud::Project.
        where(data_source_id: hmis_data_source.id, ProjectID: ['751']). # '751' is the ProjectID from the fixture's Project.csv
        pluck(:id)

      expect(Hmis::MigrateAssessmentsJob).to have_been_enqueued.once.with(
        data_source_id: hmis_data_source.id,
        project_ids: expected_project_pks,
      )
    end
  end

  describe 'when importing into a non-HMIS data source' do
    let(:vendor_data_source) { create(:source_data_source, name: 'Vendor DS', short_name: 'VND') }

    before do
      import_hmis_csv_fixture(
        fixture,
        data_source: vendor_data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end

    it 'does not enqueue MigrateAssessmentsJob' do
      expect(Hmis::MigrateAssessmentsJob).not_to have_been_enqueued
    end
  end
end
