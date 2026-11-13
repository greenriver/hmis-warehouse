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

    # An enrollment (with an assessment-related record) in the same data source that is NOT
    # part of the import. Created before the import runs so it exists when the job is enqueued, to
    # confirm the job is scoped to the imported enrollments rather than every enrollment in the DS.
    let!(:out_of_scope_enrollment) do
      create(:hmis_hud_enrollment, data_source: hmis_data_source).tap do |enrollment|
        create(:hmis_income_benefit, data_source: hmis_data_source, enrollment: enrollment, client: enrollment.client, data_collection_stage: 1)
      end
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

    it 'enqueues MigrateAssessmentsJob once scoped to the involved enrollment pks' do
      expected_enrollment_pks = GrdaWarehouse::Hud::Enrollment.
        where(data_source_id: hmis_data_source.id).
        where.not(id: out_of_scope_enrollment.id).
        pluck(:id)
      expect(expected_enrollment_pks.count).to eq(4) # 4 enrollments from the fixture (excludes out-of-scope)
      expect(expected_enrollment_pks).not_to include(out_of_scope_enrollment.id)

      expect(Hmis::MigrateAssessmentsJob).to have_been_enqueued.once.with(
        data_source_id: hmis_data_source.id,
        enrollment_ids: expected_enrollment_pks,
        upsert: true,
        generate_empty_intakes: true,
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
