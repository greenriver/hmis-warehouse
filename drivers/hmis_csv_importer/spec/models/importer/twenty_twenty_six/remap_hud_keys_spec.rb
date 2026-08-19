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
        'drivers/hmis_csv_importer/spec/fixtures/files/twenty_twenty_six/remap_hud_keys',
        data_source: FactoryBot.create(:remap_hud_keys_ds),
        version: 'AutoMigrate',
        run_jobs: false,
        stop_version: '2026',
      )
    end
  end

  it 'remaps the client PersonalID to a stable de-identified value' do
    expect(GrdaWarehouse::Hud::Client.source.first.PersonalID).to eq(Digest::MD5.hexdigest('PersonalID--TEST-SRC--C-1'))
  end

  it 'remaps the same PersonalID identically on the enrollment' do
    expect(GrdaWarehouse::Hud::Enrollment.first.PersonalID).to eq(Digest::MD5.hexdigest('PersonalID--TEST-SRC--C-1'))
  end

  it 'remaps HouseholdID even though it is not any file\'s hud_key' do
    expect(GrdaWarehouse::Hud::Enrollment.first.HouseholdID).to eq(Digest::MD5.hexdigest('HouseholdID--TEST-SRC--H-1'))
  end

  it 'remaps ResProjectID even though it is not any file\'s hud_key' do
    expect(GrdaWarehouse::Hud::Affiliation.first.ResProjectID).to eq(Digest::MD5.hexdigest('ResProjectID--TEST-SRC--ES-RES'))
  end

  it 'remaps the same UserID identically whether it is User.csv\'s own hud_key or another file\'s audit field' do
    expected = Digest::MD5.hexdigest('UserID--TEST-SRC--user')
    expect(GrdaWarehouse::Hud::User.first.UserID).to eq(expected)
    expect(GrdaWarehouse::Hud::EmploymentEducation.first.UserID).to eq(expected)
  end

  it 'remaps ExportID identically across files even though every file shares the same literal export batch value' do
    expected = Digest::MD5.hexdigest('ExportID--TEST-SRC--TEST')
    expect(GrdaWarehouse::Hud::Client.source.first.ExportID).to eq(expected)
    expect(GrdaWarehouse::Hud::Enrollment.first.ExportID).to eq(expected)
  end

  describe 'remaps every loadable file\'s own hud_key field' do
    it 'remaps Organization.OrganizationID' do
      expect(GrdaWarehouse::Hud::Organization.first.OrganizationID).to eq(Digest::MD5.hexdigest('OrganizationID--TEST-SRC--ORG-ID'))
    end

    it 'remaps Project.ProjectID' do
      expect(GrdaWarehouse::Hud::Project.first.ProjectID).to eq(Digest::MD5.hexdigest('ProjectID--TEST-SRC--ES'))
    end

    it 'remaps Enrollment.EnrollmentID' do
      expect(GrdaWarehouse::Hud::Enrollment.first.EnrollmentID).to eq(Digest::MD5.hexdigest('EnrollmentID--TEST-SRC--E-1'))
    end

    it 'remaps ProjectCoc.ProjectCoCID' do
      expect(GrdaWarehouse::Hud::ProjectCoc.first.ProjectCoCID).to eq(Digest::MD5.hexdigest('ProjectCoCID--TEST-SRC--COC-C-ID'))
    end

    it 'remaps HmisParticipation.HMISParticipationID' do
      expect(GrdaWarehouse::Hud::HmisParticipation.first.HMISParticipationID).to eq(Digest::MD5.hexdigest('HMISParticipationID--TEST-SRC--GR-ES'))
    end

    it 'remaps Affiliation.AffiliationID' do
      expect(GrdaWarehouse::Hud::Affiliation.first.AffiliationID).to eq(Digest::MD5.hexdigest('AffiliationID--TEST-SRC--AFF-1'))
    end

    it 'remaps Assessment.AssessmentID' do
      expect(GrdaWarehouse::Hud::Assessment.first.AssessmentID).to eq(Digest::MD5.hexdigest('AssessmentID--TEST-SRC--ASSESS-1'))
    end

    it 'remaps AssessmentQuestion.AssessmentQuestionID, and its AssessmentID foreign reference' do
      question = GrdaWarehouse::Hud::AssessmentQuestion.first
      expect(question.AssessmentQuestionID).to eq(Digest::MD5.hexdigest('AssessmentQuestionID--TEST-SRC--AQ-1'))
      expect(question.AssessmentID).to eq(Digest::MD5.hexdigest('AssessmentID--TEST-SRC--ASSESS-1'))
    end

    it 'remaps AssessmentResult.AssessmentResultID, and its AssessmentID foreign reference' do
      result = GrdaWarehouse::Hud::AssessmentResult.first
      expect(result.AssessmentResultID).to eq(Digest::MD5.hexdigest('AssessmentResultID--TEST-SRC--AR-1'))
      expect(result.AssessmentID).to eq(Digest::MD5.hexdigest('AssessmentID--TEST-SRC--ASSESS-1'))
    end

    it 'remaps CeParticipation.CEParticipationID' do
      expect(GrdaWarehouse::Hud::CeParticipation.first.CEParticipationID).to eq(Digest::MD5.hexdigest('CEParticipationID--TEST-SRC--CEP-1'))
    end

    it 'remaps EmploymentEducation.EmploymentEducationID' do
      expect(GrdaWarehouse::Hud::EmploymentEducation.first.EmploymentEducationID).to eq(Digest::MD5.hexdigest('EmploymentEducationID--TEST-SRC--EE-1'))
    end

    it 'remaps Event.EventID' do
      expect(GrdaWarehouse::Hud::Event.first.EventID).to eq(Digest::MD5.hexdigest('EventID--TEST-SRC--EVT-1'))
    end

    it 'remaps Funder.FunderID' do
      expect(GrdaWarehouse::Hud::Funder.first.FunderID).to eq(Digest::MD5.hexdigest('FunderID--TEST-SRC--FUND-1'))
    end

    it 'remaps Inventory.InventoryID' do
      expect(GrdaWarehouse::Hud::Inventory.first.InventoryID).to eq(Digest::MD5.hexdigest('InventoryID--TEST-SRC--INV-1'))
    end

    it 'remaps User.UserID' do
      expect(GrdaWarehouse::Hud::User.first.UserID).to eq(Digest::MD5.hexdigest('UserID--TEST-SRC--user'))
    end

    it 'remaps YouthEducationStatus.YouthEducationStatusID' do
      expect(GrdaWarehouse::Hud::YouthEducationStatus.first.YouthEducationStatusID).to eq(Digest::MD5.hexdigest('YouthEducationStatusID--TEST-SRC--YES-1'))
    end
  end
end
