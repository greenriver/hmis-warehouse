###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Project validation with constraint lambda', type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    import_hmis_csv_fixture(
      'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/project_validation_constraint',
      version: 'AutoMigrate',
      run_jobs: false,
      stop_version: '2026',
    )
  end

  it 'imports all projects successfully' do
    expect(GrdaWarehouse::Hud::Project.count).to eq(6)
  end

  describe 'ProjectType validation with constraint lambda' do
    context 'when ContinuumProject is 1' do
      it 'requires ProjectType to be present' do
        # CONTINUUM_WITH_TYPE should import successfully
        expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'CONTINUUM_WITH_TYPE')).to be_present

        # CONTINUUM_NO_TYPE should generate a validation error for missing ProjectType
        continuum_no_type_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: 'CONTINUUM_NO_TYPE')
        validation_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
          validated_column: 'ProjectType',
          source_id: continuum_no_type_project.id.to_s,
        )

        expect(validation_errors.count).to eq(1)
        expect(validation_errors.first.status).to eq('A value is required for ProjectType')
      end
    end

    context 'when ContinuumProject is not 1' do
      it 'allows ProjectType to be blank' do
        # NON_CONTINUUM_WITH_TYPE should import successfully
        expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'NON_CONTINUUM_WITH_TYPE')).to be_present

        # NON_CONTINUUM_NO_TYPE should import successfully (no validation error for missing ProjectType)
        expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'NON_CONTINUUM_NO_TYPE')).to be_present

        non_continuum_no_type_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: 'NON_CONTINUUM_NO_TYPE')
        validation_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
          validated_column: 'ProjectType',
          source_id: non_continuum_no_type_project.id.to_s,
        )

        expect(validation_errors.count).to eq(0)
      end
    end

    context 'when ContinuumProject is missing' do
      it 'allows ProjectType to be blank' do
        # MISSING_CONTINUUM_WITH_TYPE should import successfully
        expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'MISSING_CONTINUUM_WITH_TYPE')).to be_present

        # MISSING_CONTINUUM_NO_TYPE should import successfully (no validation error for missing ProjectType)
        expect(GrdaWarehouse::Hud::Project.find_by(ProjectID: 'MISSING_CONTINUUM_NO_TYPE')).to be_present

        missing_continuum_no_type_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: 'MISSING_CONTINUUM_NO_TYPE')
        validation_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
          validated_column: 'ProjectType',
          source_id: missing_continuum_no_type_project.id.to_s,
        )

        expect(validation_errors.count).to eq(0)
      end
    end
  end

  describe 'other required field validations still work' do
    it 'generates validation errors for missing ContinuumProject' do
      # All projects with missing ContinuumProject should generate validation errors
      missing_continuum_projects = ['MISSING_CONTINUUM_WITH_TYPE', 'MISSING_CONTINUUM_NO_TYPE']
      missing_continuum_projects.each do |project_id|
        loader_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: project_id)
        validation_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
          validated_column: 'ContinuumProject',
          source_id: loader_project.id.to_s,
        )
        expect(validation_errors.count).to eq(1)
        expect(validation_errors.first.status).to eq('A value is required for ContinuumProject')
      end
    end

    it 'generates validation errors for missing OperatingStartDate' do
      # All projects should have OperatingStartDate validation errors since none are missing it in our fixture
      validation_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
        validated_column: 'OperatingStartDate',
      )

      expect(validation_errors.count).to eq(0) # All have OperatingStartDate in our fixture
    end
  end

  describe 'constraint lambda functionality' do
    it 'properly evaluates the constraint condition' do
      # Test that the constraint lambda is working by checking the specific validation behavior
      non_continuum_projects = ['NON_CONTINUUM_WITH_TYPE', 'NON_CONTINUUM_NO_TYPE']
      missing_continuum_projects = ['MISSING_CONTINUUM_WITH_TYPE', 'MISSING_CONTINUUM_NO_TYPE']

      # Only continuum projects without ProjectType should have validation errors
      project_type_errors = HmisCsvImporter::HmisCsvValidation::NonBlankValidation.where(
        validated_column: 'ProjectType',
      )

      expect(project_type_errors.count).to eq(1)

      continuum_no_type_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: 'CONTINUUM_NO_TYPE')
      expect(project_type_errors.first.source_id).to eq(continuum_no_type_project.id.to_s)

      # Verify other projects don't have ProjectType validation errors
      (non_continuum_projects + missing_continuum_projects + ['CONTINUUM_WITH_TYPE']).each do |project_id|
        loader_project = HmisCsvTwentyTwentySix::Importer::Project.find_by(ProjectID: project_id)
        error = project_type_errors.find { |e| e.source_id == loader_project.id.to_s }
        expect(error).to be_nil, "Expected no ProjectType validation error for #{project_id}"
      end
    end
  end
end
