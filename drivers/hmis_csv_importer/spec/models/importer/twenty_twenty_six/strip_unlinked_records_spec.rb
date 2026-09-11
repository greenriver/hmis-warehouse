###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisCsvImporter, type: :model do
  before(:all) do
    HmisCsvImporter::Utility.clear!
    GrdaWarehouse::Utility.clear!

    travel_to Time.local(2020, 1, 1) do
      @loader = import_hmis_csv_fixture(
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/strip_unlinked_records',
        data_source: FactoryBot.create(:strip_unlinked_records_ds),
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end
  end

  it 'does not load the enrollment with no matching client' do
    expect(GrdaWarehouse::Hud::Enrollment.count).to eq(1)
    expect(GrdaWarehouse::Hud::Enrollment.first.EnrollmentID).to eq('E-1')
  end

  it 'logs the discarded enrollment' do
    note = @loader.loader_log.row_processing_notes.find_by(file_name: 'Enrollment.csv')
    expect(note.reason).to eq('no_matching_personal_id')
  end

  describe 'cascading the discard to every enrollment-related file' do
    # Each fixture file has a row tied to the surviving Enrollment (E-1, suffixed
    # -STAY) and a row tied to the orphaned Enrollment (E-2, suffixed -GONE). If
    # the cascade in UnlinkedRecordFilter stopped working for a given file, the
    # -GONE row would load right alongside -STAY, which contain_exactly would catch.
    it 'keeps the Disability row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::Disability.pluck(:DisabilitiesID)).to contain_exactly('Disabilities-STAY')
    end

    it 'keeps the EmploymentEducation row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::EmploymentEducation.pluck(:EmploymentEducationID)).to contain_exactly('EmploymentEducation-STAY')
    end

    it 'keeps the HealthAndDV row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::HealthAndDv.pluck(:HealthAndDVID)).to contain_exactly('HealthAndDV-STAY')
    end

    it 'keeps the IncomeBenefits row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::IncomeBenefit.pluck(:IncomeBenefitsID)).to contain_exactly('IncomeBenefits-STAY')
    end

    it 'keeps the Services row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::Service.pluck(:ServicesID)).to contain_exactly('Services-STAY')
    end

    it 'keeps the Exit row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::Exit.pluck(:ExitID)).to contain_exactly('Exit-STAY')
    end

    it 'keeps the Assessment row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::Assessment.pluck(:AssessmentID)).to contain_exactly('Assessment-STAY')
    end

    it 'keeps the AssessmentQuestions row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::AssessmentQuestion.pluck(:AssessmentQuestionID)).to contain_exactly('AssessmentQuestions-STAY')
    end

    it 'keeps the AssessmentResults row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::AssessmentResult.pluck(:AssessmentResultID)).to contain_exactly('AssessmentResults-STAY')
    end

    it 'keeps the Event row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::Event.pluck(:EventID)).to contain_exactly('Event-STAY')
    end

    it 'keeps the CurrentLivingSituation row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::CurrentLivingSituation.pluck(:CurrentLivingSitID)).to contain_exactly('CurrentLivingSituation-STAY')
    end

    it 'keeps the YouthEducationStatus row for the surviving enrollment and discards the other' do
      expect(GrdaWarehouse::Hud::YouthEducationStatus.pluck(:YouthEducationStatusID)).to contain_exactly('YouthEducationStatus-STAY')
    end

    it 'logs all 12 cascaded discards as orphaned_child_record, one per file' do
      cascaded = @loader.loader_log.row_processing_notes.where.not(file_name: 'Enrollment.csv')
      expect(cascaded.pluck(:file_name, :reason)).to contain_exactly(
        ['Disabilities.csv', 'orphaned_child_record'],
        ['EmploymentEducation.csv', 'orphaned_child_record'],
        ['HealthAndDV.csv', 'orphaned_child_record'],
        ['IncomeBenefits.csv', 'orphaned_child_record'],
        ['Services.csv', 'orphaned_child_record'],
        ['Exit.csv', 'orphaned_child_record'],
        ['Assessment.csv', 'orphaned_child_record'],
        ['AssessmentQuestions.csv', 'orphaned_child_record'],
        ['AssessmentResults.csv', 'orphaned_child_record'],
        ['Event.csv', 'orphaned_child_record'],
        ['CurrentLivingSituation.csv', 'orphaned_child_record'],
        ['YouthEducationStatus.csv', 'orphaned_child_record'],
      )
    end
  end
end
