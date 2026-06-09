###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HUD CSV project_pk population', type: :model do
  fixture = 'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/enrollment_test_files'

  def enrollments_missing_project_pk(data_source_id)
    GrdaWarehouse::Hud::Enrollment.
      where(data_source_id: data_source_id).
      joins(:project).
      where('"Enrollment".project_pk IS DISTINCT FROM "Project".id')
  end

  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  after(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!
  end

  describe 'when importing into an HMIS data source' do
    let(:hmis_data_source) do
      create(:source_data_source, hmis: 'hmis.example.test', name: 'HMIS DS', short_name: 'HMIS')
    end

    before do
      import_hmis_csv_fixture(
        fixture,
        data_source: hmis_data_source,
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end

    it 'sets project_pk on enrollments to the matching Project id' do
      expect(GrdaWarehouse::Hud::Enrollment.where(data_source_id: hmis_data_source.id)).not_to be_empty
      expect(enrollments_missing_project_pk(hmis_data_source.id)).to be_empty
    end

    describe 'on re-import with unchanged enrollments' do
      before do
        GrdaWarehouse::Hud::Enrollment.where(data_source_id: hmis_data_source.id).update_all(project_pk: nil)
        import_hmis_csv_fixture(
          fixture,
          data_source: hmis_data_source,
          version: 'AutoMigrate',
          run_jobs: false,
          stop_version: '2026',
        )
      end

      it 'restores project_pk even when enrollments are otherwise unchanged' do
        expect(enrollments_missing_project_pk(hmis_data_source.id)).to be_empty
      end
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

    it 'does not set project_pk' do
      expect(
        GrdaWarehouse::Hud::Enrollment.where(data_source_id: vendor_data_source.id).where.not(project_pk: nil),
      ).to be_empty
    end
  end

  describe HmisCsvTwentyTwentySix::Importer::Enrollment do
    describe '.populate_project_pk!' do
      let(:data_source) { create(:source_data_source, hmis: 'hmis-1.test', name: 'HMIS 1', short_name: 'HMIS_1') }
      let(:project) { create(:hud_project, data_source: data_source) }
      let!(:enrollment) { create(:hud_enrollment, data_source: data_source, ProjectID: project.ProjectID, project_pk: nil) }

      it 'sets project_pk from the matching project' do
        described_class.populate_project_pk!(data_source_id: data_source.id, project_ids: [project.ProjectID])
        expect(enrollment.reload.project_pk).to eq(project.id)
      end

      it 'skips enrollments that already have the correct project_pk' do
        enrollment.update!(project_pk: project.id)
        expect do
          described_class.populate_project_pk!(data_source_id: data_source.id, project_ids: [project.ProjectID])
        end.not_to(change(enrollment, :project_pk))
      end
    end
  end
end
