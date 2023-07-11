###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'rails_helper'
require_relative '../../../support/hmis_base_setup'

RSpec.describe Hmis::Form::FormProcessor, type: :model do
  include_context 'hmis base setup'

  let!(:fd) { create :hmis_form_definition }
  let(:c1) { create :hmis_hud_client_complete, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  HIDDEN = Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE
  INVALID = 'INVALID'.freeze # Invalid enum representation

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  it 'ingests EnrollmentCoC into the hud tables' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'EnrollmentCoc.cocCode' => 'MA-507',
    }

    assessment.form_processor.run!(owner: assessment, user: hmis_user)
    assessment.save_not_in_progress

    expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
    expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')
  end

  describe 'IncomeBenefit processor' do
    it 'succeeds if overall is YES and sources are specified (income)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
        'IncomeBenefit.earned' => nil,
        'IncomeBenefit.earnedAmount' => nil,
        'IncomeBenefit.unemployment' => 'YES',
        'IncomeBenefit.unemploymentAmount' => 100,
        'IncomeBenefit.otherIncomeSource' => 'NO',
        'IncomeBenefit.otherIncomeAmount' => 0,
        'IncomeBenefit.otherIncomeSourceIdentify' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(1)
      expect(income_benefits.earned).to eq(0) # overridden
      expect(income_benefits.earned_amount).to eq(nil)
      expect(income_benefits.unemployment).to eq(1)
      expect(income_benefits.unemployment_amount).to eq(100)
      expect(income_benefits.other_income_source).to eq(0)
      expect(income_benefits.other_income_amount).to eq(0)
      expect(income_benefits.other_income_source_identify).to eq(nil)
    end

    it 'succeeds if section is left empty (income)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => nil,
        'IncomeBenefit.earned' => nil,
        'IncomeBenefit.earnedAmount' => nil,
        'IncomeBenefit.unemployment' => nil,
        'IncomeBenefit.unemploymentAmount' => nil,
        'IncomeBenefit.otherIncomeSource' => nil,
        'IncomeBenefit.otherIncomeAmount' => nil,
        'IncomeBenefit.otherIncomeSourceIdentify' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(99)
      expect(income_benefits.earned).to eq(99)
      expect(income_benefits.earned_amount).to be nil
      expect(income_benefits.unemployment).to eq(99)
      expect(income_benefits.unemployment_amount).to be nil
      expect(income_benefits.other_income_source).to eq(99)
      expect(income_benefits.other_income_amount).to be nil
      expect(income_benefits.other_income_source_identify).to be nil
    end

    it 'succeeds if overall is NO' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.benefitsFromAnySource' => 'NO',
        'IncomeBenefit.snap' => HIDDEN,
        'IncomeBenefit.wic' => HIDDEN,
        'IncomeBenefit.otherBenefitsSource' => HIDDEN,
        'IncomeBenefit.otherBenefitsSourceIdentify' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.benefits_from_any_source).to eq(0)
      expect(income_benefits.snap).to eq(0) # overridden
      expect(income_benefits.wic).to eq(0) # overridden
      expect(income_benefits.other_benefits_source).to eq(0) # overridden
      expect(income_benefits.other_benefits_source_identify).to eq(nil)
    end

    it 'succeeds if overall is CLIENT_REFUSED' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.benefitsFromAnySource' => 'CLIENT_REFUSED',
        'IncomeBenefit.snap' => HIDDEN,
        'IncomeBenefit.wic' => HIDDEN,
        'IncomeBenefit.otherBenefitsSource' => HIDDEN,
        'IncomeBenefit.otherBenefitsSourceIdentify' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.benefits_from_any_source).to eq(9)
      expect(income_benefits.snap).to be nil
      expect(income_benefits.wic).to be nil
      expect(income_benefits.other_benefits_source).to be nil
      expect(income_benefits.other_benefits_source_identify).to be nil
    end

    it 'succeeds if overall is YES and sources are specified (health insurance)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.insuranceFromAnySource' => 'YES',
        'IncomeBenefit.medicaid' => 'YES',
        'IncomeBenefit.schip' => nil,
        'IncomeBenefit.otherInsurance' => nil,
        'IncomeBenefit.otherInsuranceIdentify' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.insurance_from_any_source).to eq(1)
      expect(income_benefits.medicaid).to eq(1)
      expect(income_benefits.schip).to eq(0) # overridden
      expect(income_benefits.other_insurance).to eq(0) # overridden
      expect(income_benefits.other_insurance_identify).to eq(nil)
    end

    it 'succeeds if section is left empty (health insurance)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.insuranceFromAnySource' => nil,
        'IncomeBenefit.medicaid' => nil,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.income_benefits.count).to eq(1)

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.insurance_from_any_source).to eq(99)
      expect(income_benefits.medicaid).to eq(99)
    end

    it 'fails if overall iS YES but no sources were specified' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
        'IncomeBenefit.benefitsFromAnySource' => 'YES',
        'IncomeBenefit.insuranceFromAnySource' => 'YES',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      expect(assessment.form_processor.valid?).to be false
      expect(assessment.form_processor.errors.where(:income_from_any_source).first.options[:full_message]).to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INCOME_SOURCES_UNSPECIFIED)
      expect(assessment.form_processor.errors.where(:benefits_from_any_source).first.options[:full_message]).to eq(Hmis::Hud::Validators::IncomeBenefitValidator::BENEFIT_SOURCES_UNSPECIFIED)
      expect(assessment.form_processor.errors.where(:insurance_from_any_source).first.options[:full_message]).to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INSURANCE_SOURCES_UNSPECIFIED)
    end
  end

  describe 'HealthAndDV processor' do
    it 'ingests HealthAndDV into the hud tables (no)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'HealthAndDv.domesticViolenceVictim' => 'NO',
        'HealthAndDv.currentlyFleeing' => HIDDEN,
        'HealthAndDv.whenOccurred' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.health_and_dvs.count).to eq(1)

      health_and_dv = assessment.enrollment.health_and_dvs.first
      expect(health_and_dv.domestic_violence_victim).to eq(0)
      expect(health_and_dv.currently_fleeing).to eq(nil)
      expect(health_and_dv.when_occurred).to eq(nil)
    end

    it 'ingests HealthAndDV into the hud tables (99)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'HealthAndDv.domesticViolenceVictim' => nil,
        'HealthAndDv.currentlyFleeing' => HIDDEN,
        'HealthAndDv.whenOccurred' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.health_and_dvs.count).to eq(1)

      health_and_dv = assessment.enrollment.health_and_dvs.first
      expect(health_and_dv.domestic_violence_victim).to eq(99)
      expect(health_and_dv.currently_fleeing).to eq(nil)
      expect(health_and_dv.when_occurred).to eq(nil)
    end

    it 'ingests HealthAndDV into the hud tables (yes, with 99 conditional)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'HealthAndDv.domesticViolenceVictim' => 'YES',
        'HealthAndDv.currentlyFleeing' => nil,
        'HealthAndDv.whenOccurred' => 'CLIENT_REFUSED',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.health_and_dvs.count).to eq(1)

      health_and_dv = assessment.enrollment.health_and_dvs.first
      expect(health_and_dv.domestic_violence_victim).to eq(1)
      expect(health_and_dv.currently_fleeing).to eq(99)
      expect(health_and_dv.when_occurred).to eq(9)
    end
  end

  describe 'YouthEducationStatus processor' do
    it 'ingests YouthEducationStatus into the hud tables (unknown/refused/not collected)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'YouthEducationStatus.currentSchoolAttend' => 'DATA_NOT_COLLECTED',
        'YouthEducationStatus.mostRecentEdStatus' => HIDDEN,
        'YouthEducationStatus.currentEdStatus' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.youth_education_statuses.count).to eq(1)

      youth_education_status = assessment.enrollment.youth_education_statuses.first
      expect(youth_education_status.current_school_attend).to eq(99)
      expect(youth_education_status.most_recent_ed_status).to eq(nil)
      expect(youth_education_status.current_ed_status).to eq(nil)
    end

    it 'ingests YouthEducationStatus into the hud tables (0)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'YouthEducationStatus.currentSchoolAttend' => 'NOT_CURRENTLY_ENROLLED_IN_ANY_SCHOOL_OR_EDUCATIONAL_COURSE',
        'YouthEducationStatus.mostRecentEdStatus' => 'K12_GRADUATED_FROM_HIGH_SCHOOL',
        'YouthEducationStatus.currentEdStatus' => HIDDEN,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.youth_education_statuses.count).to eq(1)

      youth_education_status = assessment.enrollment.youth_education_statuses.first
      expect(youth_education_status.current_school_attend).to eq(0)
      expect(youth_education_status.most_recent_ed_status).to eq(0)
      expect(youth_education_status.current_ed_status).to eq(nil)
    end

    it 'ingests YouthEducationStatus into the hud tables (1)' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'YouthEducationStatus.currentSchoolAttend' => 'CURRENTLY_ENROLLED_BUT_NOT_ATTENDING_REGULARLY_WHEN_SCHOOL_OR_THE_COURSE_IS_IN_SESSION',
        'YouthEducationStatus.mostRecentEdStatus' => HIDDEN,
        'YouthEducationStatus.currentEdStatus' => 'PURSUING_BACHELOR_S_DEGREE',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.youth_education_statuses.count).to eq(1)

      youth_education_status = assessment.enrollment.youth_education_statuses.first
      expect(youth_education_status.current_school_attend).to eq(1)
      expect(youth_education_status.most_recent_ed_status).to eq(nil)
      expect(youth_education_status.current_ed_status).to eq(2)
    end
  end

  describe 'DisabilityGroup processor' do
    it 'ingests DisabilityGroup into multiple Disabilities' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'DisabilityGroup.physicalDisability' => 'YES',
        'DisabilityGroup.physicalDisabilityIndefiniteAndImpairs' => 'YES',
        'DisabilityGroup.developmentalDisability' => 'NO',
        'DisabilityGroup.chronicHealthCondition' => 'YES',
        'DisabilityGroup.chronicHealthConditionIndefiniteAndImpairs' => 'NO',
        'DisabilityGroup.hivAids' => 'YES',
        'DisabilityGroup.mentalHealthDisorder' => 'NO',
        'DisabilityGroup.substanceUseDisorder' => 'BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS',
        'DisabilityGroup.substanceUseDisorderIndefiniteAndImpairs' => 'YES',
        'DisabilityGroup.disablingCondition' => 'YES',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.disabilities.count).to eq(6)
      expect(assessment.enrollment.disabling_condition).to eq(1)

      disabilities = assessment.enrollment.disabilities
      # Physical Disability
      expect(disabilities.find_by(disability_type: 5).disability_response).to eq(1)
      expect(disabilities.find_by(disability_type: 5).indefinite_and_impairs).to eq(1)
      # Developmental Disability
      expect(disabilities.find_by(disability_type: 6).disability_response).to eq(0)
      expect(disabilities.find_by(disability_type: 6).indefinite_and_impairs).to be_nil
      # Substance Use
      expect(disabilities.find_by(disability_type: 10).disability_response).to eq(3)
    end

    it 'can process nil and _HIDDEN DisabilityGroup fields' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'DisabilityGroup.physicalDisability' => nil,
        'DisabilityGroup.physicalDisabilityIndefiniteAndImpairs' => HIDDEN,
        'DisabilityGroup.developmentalDisability' => 'NO',
        'DisabilityGroup.developmentalDisabilityIndefiniteAndImpairs' => HIDDEN,
        'DisabilityGroup.chronicHealthCondition' => 'YES',
        'DisabilityGroup.chronicHealthConditionIndefiniteAndImpairs' => nil,
        'DisabilityGroup.hivAids' => nil,
        'DisabilityGroup.mentalHealthDisorder' => nil,
        'DisabilityGroup.substanceUseDisorder' => 'BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS',
        'DisabilityGroup.substanceUseDisorderIndefiniteAndImpairs' => nil,
        'DisabilityGroup.disablingCondition' => nil,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.disabilities.count).to eq(6)
      expect(assessment.enrollment.disabling_condition).to eq(99)

      disabilities = assessment.enrollment.disabilities
      # Physical Disability
      expect(disabilities.find_by(disability_type: 5).disability_response).to eq(99) # nil is saved as 99
      expect(disabilities.find_by(disability_type: 5).indefinite_and_impairs).to be_nil # hidden is saved as nil
      # Developmental Disability
      expect(disabilities.find_by(disability_type: 6).disability_response).to eq(0)
      expect(disabilities.find_by(disability_type: 6).indefinite_and_impairs).to be_nil # hidden is saved as nil
      # Substance Use
      expect(disabilities.find_by(disability_type: 10).disability_response).to eq(3)
      expect(disabilities.find_by(disability_type: 10).indefinite_and_impairs).to eq(99) # nil is saved as 99
    end
  end

  describe 'updating existing assessment' do
    it "doesn't touch an existing value, if it isn't listed (but applies the listed fields)" do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      assessment.form_processor.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
        'IncomeBenefit.unemployment' => 'YES',
        'IncomeBenefit.unemploymentAmount' => 100,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(1)
      expect(income_benefits.unemployment).to eq(1)
    end

    it 'clears an existing value, if it is null' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => nil,
        'IncomeBenefit.incomeFromAnySource' => nil,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to be_nil
    end

    it 'adjusts the information dates as appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      test_date = '2020-10-15'.to_date
      assessment.assessment_date = test_date

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress

      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.first.information_date).to eq(test_date)
    end

    it 'adds an exit record when appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      expect(assessment.enrollment.exit).to be_nil
      expect(assessment.enrollment.exit_date).to be_nil

      assessment.form_processor.hud_values = {
        'Exit.exitDate' => assessment.enrollment.entry_date + 7.days,
        'Exit.destination' => 'SAFE_HAVEN',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.exit).to be_present
      expect(assessment.enrollment.exit.destination).to eq(18)
    end

    it 'updates enrollment entry date when appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      assessment.save_not_in_progress

      old_entry_date = assessment.enrollment.entry_date
      new_entry_date = '2024-03-14'
      expect(old_entry_date).not_to be_nil

      assessment.form_processor.hud_values = {
        'Enrollment.entryDate' => new_entry_date,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      # Unsaved changes should be present on the enrollment
      expect(assessment.enrollment.entry_date).to eq(Date.parse(new_entry_date))

      assessment.form_processor.save!
      assessment.enrollment.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.entry_date).not_to eq(old_entry_date)
      expect(assessment.enrollment.entry_date).to eq(Date.parse(new_entry_date))
    end
  end

  describe 'Processing PriorLivingSituation fields' do
    it 'correctly sets all fields' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
      assessment.form_processor.hud_values = {
        "EnrollmentCoc.cocCode": 'SC-501',
        "Enrollment.livingSituation": 'HOSPITAL_OR_OTHER_RESIDENTIAL_NON_PSYCHIATRIC_MEDICAL_FACILITY',
        "Enrollment.lengthOfStay": 'ONE_MONTH_OR_MORE_BUT_LESS_THAN_90_DAYS',
        "Enrollment.losUnderThreshold": 'YES',
        "Enrollment.previousStreetEssh": 'YES',
        "Enrollment.dateToStreetEssh": '2023-03-14',
        "Enrollment.timesHomelessPastThreeYears": 'FOUR_OR_MORE_TIMES',
        "Enrollment.monthsHomelessPastThreeYears": 'NUM_2',
      }.stringify_keys

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      enrollment = assessment.enrollment
      expect(enrollment.living_situation).to eq(6)
      expect(enrollment.length_of_stay).to eq(3)
      expect(enrollment.los_under_threshold).to eq(1)
      expect(enrollment.previous_street_essh).to eq(1)
      expect(enrollment.times_homeless_past_three_years).to eq(4)
      expect(enrollment.months_homeless_past_three_years).to eq(102)
    end

    it 'correctly nullifies fields' do
      e1.update(living_situation: 6)
      e1.update(length_of_stay: 3)
      e1.update(los_under_threshold: 1)
      e1.update(previous_street_essh: 0)
      e1.update(times_homeless_past_three_years: 4)
      e1.update(months_homeless_past_three_years: 102)
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)

      assessment.form_processor.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
        'Enrollment.livingSituation' => nil,
        'Enrollment.lengthOfStay' => nil,
        'Enrollment.losUnderThreshold' => nil,
        'Enrollment.previousStreetEssh' => nil,
        'Enrollment.dateToStreetEssh' => nil,
        'Enrollment.timesHomelessPastThreeYears' => nil,
        'Enrollment.monthsHomelessPastThreeYears' => nil,
      }

      assessment.form_processor.run!(owner: assessment, user: hmis_user)
      enrollment = assessment.enrollment
      expect(enrollment.living_situation).to eq(99)
      expect(enrollment.length_of_stay).to eq(99)
      expect(enrollment.los_under_threshold).to eq(99)
      expect(enrollment.previous_street_essh).to eq(99)
      expect(enrollment.times_homeless_past_three_years).to eq(99)
      expect(enrollment.months_homeless_past_three_years).to eq(99)
    end
  end

  def process_record(record:, hud_values:, user:, save: true)
    form_processor = Hmis::Form::FormProcessor.new
    form_processor.hud_values = hud_values
    form_processor.run!(owner: record, user: user)
    form_processor.owner.save! if save
    record.reload if save
    form_processor
  end

  describe 'Form processing for Enrollment' do
    let(:definition) { Hmis::Form::Definition.find_by(role: :ENROLLMENT) }
    let(:complete_hud_values) do
      {
        'entryDate' => Date.yesterday.strftime('%Y-%m-%d'),
        'relationshipToHoH' => 'SELF_HEAD_OF_HOUSEHOLD',
      }
    end

    it 'creates and updates all fields' do
      existing_enrollment = e1
      existing_enrollment.update(entry_date: 1.month.ago, relationship_to_hoh: 99)
      new_enrollment = Hmis::Hud::Enrollment.new(data_source: ds1, user: u1, client: c1, project: p1)
      [existing_enrollment, new_enrollment].each do |enrollment|
        process_record(record: enrollment, hud_values: complete_hud_values, user: hmis_user)
        expect(enrollment.relationship_to_hoh).to eq(1)
        expect(enrollment.entry_date.strftime('%Y-%m-%d')).to eq(complete_hud_values['entryDate'])
      end
    end
  end

  describe 'Form processing for Clients' do
    let(:primary_name) do
      {
        primary: true,
        first: 'Terry',
        middle: 'Mid',
        last: 'Breeze',
        suffix: 'Jr',
        nameDataQuality: 'FULL_NAME_REPORTED',
      }
    end
    let(:secondary_name) do
      {
        primary: false,
        first: 'Gerome',
        nameDataQuality: 'PARTIAL_STREET_NAME_OR_CODE_NAME_REPORTED',
      }
    end
    let(:complete_hud_values) do
      {
        "names": [primary_name.stringify_keys, secondary_name.stringify_keys],
        'dob' => '2000-03-29',
        'dobDataQuality' => 'FULL_DOB_REPORTED',
        'ssn' => 'XXXXX1234',
        'ssnDataQuality' => 'APPROXIMATE_OR_PARTIAL_SSN_REPORTED',
        'race' => [
          'WHITE',
          'ASIAN',
        ],
        'ethnicity' => 'HISPANIC_LATIN_A_O_X',
        'gender' => [
          'FEMALE',
          'TRANSGENDER',
        ],
        'pronouns' => [
          'she/her',
          'they/them',
        ],
        'veteranStatus' => 'CLIENT_REFUSED',
        'imageBlobId' => nil,
      }
    end
    let(:empty_hud_values) do
      empty = complete_hud_values.map { |k, _| [k, nil] }.to_h
      empty['names'] = { first: 'first', primary: true }.stringify_keys
      empty
    end

    it 'creates and updates all fields' do
      existing_client = c1
      existing_client.update(NoSingleGender: 1, BlackAfAmerican: 1)
      new_client = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_client, new_client].each do |client|
        process_record(record: client, hud_values: complete_hud_values, user: hmis_user)

        # Ensure primary name is stored on Client
        expect(client.first_name).to eq(primary_name[:first])
        expect(client.middle_name).to eq(primary_name[:middle])
        expect(client.last_name).to eq(primary_name[:last])
        expect(client.name_suffix).to eq(primary_name[:suffix])
        expect(client.name_data_quality).to eq(1)
        # Ensure all names persisted
        expect(client.names.count).to eq(2)
        expect(client.names.map(&:attributes)).to match([
                                                          a_hash_including(primary_name.excluding(:nameDataQuality).stringify_keys),
                                                          a_hash_including(secondary_name.excluding(:nameDataQuality).stringify_keys),
                                                        ])
        expect(client.dob.strftime('%Y-%m-%d')).to eq('2000-03-29')
        expect(client.dob_data_quality).to eq(1)
        expect(client.ssn).to eq('XXXXX1234')
        expect(client.ssn_data_quality).to eq(2)
        expect(client.ethnicity).to eq(1)
        expect(client.pronouns).to eq('she/her|they/them')
        expect(client.veteran_status).to eq(9)
        expect(client.race_fields).to contain_exactly('White', 'Asian')
        expect(client.RaceNone).to be nil
        expect(client.BlackAfAmerican).to eq(0)
        expect(client.NativeHIPacific).to eq(0)
        expect(client.AmIndAKNative).to eq(0)
        expect(client.gender_fields).to contain_exactly(:Female, :Transgender)
        expect(client.GenderNone).to be nil
        expect(client.NoSingleGender).to eq(0)
        expect(client.Male).to eq(0)
        expect(client.Questioning).to eq(0)
      end
    end

    it 'stores empty fields correctly' do
      existing_client = c1
      existing_client.update(NoSingleGender: 1, BlackAfAmerican: 1)
      new_client = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_client, new_client].each do |client|
        process_record(record: client, hud_values: empty_hud_values, user: hmis_user)

        expect(client.first_name).to eq('first')
        expect(client.middle_name).to be nil
        expect(client.last_name).to be nil
        expect(client.name_suffix).to be nil
        expect(client.name_data_quality).to eq(99)
        expect(client.names.size).to eq(1)
        expect(client.dob).to be nil
        expect(client.dob_data_quality).to eq(99)
        expect(client.ssn).to be nil
        expect(client.ssn_data_quality).to eq(99)
        expect(client.ethnicity).to eq(99)
        expect(client.pronouns).to be nil
        expect(client.veteran_status).to eq(99)
        expect(client.race_fields).to eq([])
        expect(client.RaceNone).to eq(99)
        expect(client.BlackAfAmerican).to eq(99)
        expect(client.NativeHIPacific).to eq(99)
        expect(client.AmIndAKNative).to eq(99)
        expect(client.gender_fields).to eq([])
        expect(client.GenderNone).to eq(99)
        expect(client.NoSingleGender).to eq(99)
        expect(client.Male).to eq(99)
        expect(client.Questioning).to eq(99)
      end
    end

    it 'handles empty arrays' do
      existing_client = c1
      existing_client.update(NoSingleGender: 1, BlackAfAmerican: 1)
      new_client = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_client, new_client].each do |client|
        hud_values = empty_hud_values.merge(
          'race' => [],
          'gender' => [],
          'pronouns' => [],
        )
        process_record(record: client, hud_values: hud_values, user: hmis_user)

        expect(client.race_fields).to eq([])
        expect(client.RaceNone).to eq(99)
        expect(client.BlackAfAmerican).to eq(99)
        expect(client.NativeHIPacific).to eq(99)
        expect(client.AmIndAKNative).to eq(99)
        expect(client.gender_fields).to eq([])
        expect(client.GenderNone).to eq(99)
        expect(client.NoSingleGender).to eq(99)
        expect(client.Male).to eq(99)
        expect(client.Questioning).to eq(99)
        expect(client.pronouns).to be nil
      end
    end

    it 'handles Client Refused (8) and Client Doesn\t Know (9)' do
      existing_client = c1
      new_client = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_client, new_client].each do |client|
        hud_values = empty_hud_values.merge(
          'ethnicity' => 'CLIENT_REFUSED', # 9
          'veteranStatus' => 'CLIENT_REFUSED', # 9
          'dobDataQuality' => 'CLIENT_REFUSED', # 9
          'race' => ['CLIENT_REFUSED'], # 9
          'gender' => ['CLIENT_DOESN_T_KNOW'], # 8
        )
        process_record(record: client, hud_values: hud_values, user: hmis_user)

        expect(client.ethnicity).to eq(9)
        expect(client.veteran_status).to eq(9)
        expect(client.dob_data_quality).to eq(9)
        expect(client.race_fields).to eq([])
        expect(client.RaceNone).to eq(9)
        expect(client.gender_fields).to eq([])
        expect(client.GenderNone).to eq(8)
      end
    end

    it 'handles SSN and DOB fields being hidden' do
      existing_client = c1
      new_client = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_client, new_client].each do |client|
        expected_values = client.attributes.slice('SSN', 'DOB', 'DOBDataQuality', 'SSNDataQuality')
        expected_values['DOBDataQuality'] = 99 if client.dob_data_quality.nil?
        expected_values['SSNDataQuality'] = 99 if client.ssn_data_quality.nil?

        hud_values = complete_hud_values.merge(
          'dob' => Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE,
          'dobDataQuality' => Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE,
          'ssn' => Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE,
          'ssnDataQuality' => Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE,
        )
        process_record(record: client, hud_values: hud_values, user: hmis_user)

        expected_values.each do |key, val|
          expect(client.send(key)).to eq(val)
        end
      end
    end

    it 'updates, adds, and deletes CustomClientNames' do
      # Give client some names
      client = c1
      old_primary_name = create(:hmis_hud_custom_client_name, client: client, first: 'Atticus', primary: true)
      old_secondary_name = create(:hmis_hud_custom_client_name, client: client, first: 'Benjamin', primary: false)
      client.update(names: [old_primary_name, old_secondary_name])
      expect(client.names.size).to eq(2)

      # Submit a form that changes the names
      hud_values = complete_hud_values.merge(
        'names' => [
          # 1) Make the old primary name non-primary, _and_ update the name
          {
            id: old_primary_name.id,
            primary: false,
            first: 'Atticus Changed',
            nameDataQuality: 'CLIENT_REFUSED',
          }.stringify_keys,
          # 2) Add a NEW primary name
          {
            primary: true,
            first: 'Charlotte',
            nameDataQuality: 'CLIENT_REFUSED',
          }.stringify_keys,
          # 3) Delete the old secondary name (by not including it)
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      # Ensure primary name is stored on Client
      expect(client.first_name).to eq('Charlotte')
      # Ensure all names persisted
      expect(client.names.size).to eq(2)
      expect(client.names.pluck(:id)).not_to include(old_secondary_name.id)
      expect(client.names.map(&:attributes)).to match([
                                                        a_hash_including({ first: 'Atticus Changed', primary: false, id: old_primary_name.id }.stringify_keys),
                                                        a_hash_including({ first: 'Charlotte', primary: true }.stringify_keys),
                                                      ])
    end

    it 'handles "deleting" primary name' do
      client = c1
      # Give client a primary names
      old_primary_name = create(:hmis_hud_custom_client_name, client: c1, first: 'Atticus', primary: true)
      expect(client.names.size).to eq(1)

      # Submit a form that changes the primary  name but doesn't include the old ID
      hud_values = complete_hud_values.merge(
        'names' => [
          {
            primary: true,
            first: 'Charlotte',
            nameDataQuality: 'CLIENT_REFUSED',
          }.stringify_keys,
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      expect(client.names.primary_names.first.first).to eq('Charlotte')
      expect(client.names.size).to eq(1)
      # Even though ID was not specified, it is updated because client already had a primary
      expect(client.names.first.id).not_to eq(old_primary_name.id)
      expect(client.first_name).to eq('Charlotte')
    end

    it 'ignores nonexistent ids on names' do
      client = c1
      expect(client.names.size).to eq(0)

      # Submit a form that changes the primary  name but doesn't include the old ID
      hud_values = complete_hud_values.merge(
        'names' => [
          {
            id: '0', # Gets ignored, a new record is created
            primary: true,
            first: 'Charlotte',
            nameDataQuality: 'CLIENT_REFUSED',
          }.stringify_keys,
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      expect(client.names.size).to eq(1)
      expect(client.names.primary_names.first.first).to eq('Charlotte')
      expect(client.names.first.id).not_to eq(0)
      expect(client.first_name).to eq('Charlotte')
    end

    it 'fails if First and Last are missing from primary' do
      client = c1
      create(:hmis_hud_custom_client_name, client: client, first: 'Atticus', primary: true)
      expect(client.names.size).to eq(1)

      # Submit a form that changes the primary  name but doesn't include the old ID
      hud_values = complete_hud_values.merge(
        'names' => [
          {
            id: client.primary_name.id,
            primary: true,
            first: nil,
            last: nil,
            nameDataQuality: 'CLIENT_REFUSED',
          }.stringify_keys,
        ],
      )
      form_processor = process_record(record: client, hud_values: hud_values, user: hmis_user, save: false)

      expect(client.valid?).to eq(false)
      errs = form_processor.collect_active_record_errors
      expect(errs.errors.map(&:full_message)).to contain_exactly(Hmis::Hud::CustomClientName.first_or_last_required_message)
    end

    it 'fails if no names are primary' do
      existing_record = c1
      new_record = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_record, new_record].each do |record|
        hud_values = complete_hud_values.merge('names' => [secondary_name.stringify_keys])
        process_record(record: record, hud_values: hud_values, user: hmis_user, save: false)
        expect(record.valid?).to eq(false)
      end
    end

    it 'fails if two names are primary' do
      existing_record = c1
      new_record = Hmis::Hud::Client.new(data_source: ds1, user: u1)
      [existing_record, new_record].each do |record|
        hud_values = complete_hud_values.merge('names' => [primary_name.stringify_keys, primary_name.stringify_keys])
        process_record(record: record, hud_values: hud_values, user: hmis_user, save: false)
        expect(record.valid?).to eq(false)
      end
    end

    it 'updates, adds, and deletes CustomClientAddresses' do
      # Give client some addresses
      client = c1
      addr1 = create(:hmis_hud_custom_client_address, client: client)
      addr2 = create(:hmis_hud_custom_client_address, client: client)
      expect(client.addresses.size).to eq(2)

      # Submit a form that changes the address
      hud_values = complete_hud_values.merge(
        'addresses' => [
          # Update addr 1
          {
            id: addr1.id,
            city: 'foo',
          }.stringify_keys,
          # Add a new addr
          {
            city: 'bar',
          }.stringify_keys,
          # Delete addr 2 (by not including it)
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      expect(client.addresses.size).to eq(2)
      expect(client.addresses.pluck(:id)).to include(addr1.id)
      expect(client.addresses.pluck(:id)).not_to include(addr2.id)
      expect(client.addresses.pluck(:city)).to contain_exactly('foo', 'bar')
    end

    it 'updates, adds, and deletes client phone numbers' do
      # Give client some contacts
      client = c1
      contact1 = create(:hmis_hud_custom_client_contact_point, client: client, system: :phone)
      contact2 = create(:hmis_hud_custom_client_contact_point, client: client, system: :phone)
      expect(client.contact_points.phones.size).to eq(2)

      # Submit a form that changes the contacts
      hud_values = complete_hud_values.merge(
        'phoneNumbers' => [
          # Update contact 1
          {
            id: contact1.id,
            value: '8025550000',
          }.stringify_keys,
          # Add a new contact
          {
            value: '6031110000',
          }.stringify_keys,
          # Delete contact 2 (by not including it)
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      expect(client.contact_points.phones.size).to eq(2)
      expect(client.contact_points.pluck(:id)).to include(contact1.id)
      expect(client.contact_points.pluck(:id)).not_to include(contact2.id)
      expect(client.contact_points.pluck(:value)).to contain_exactly('8025550000', '6031110000')
    end

    it 'updates, adds, and deletes client emails' do
      # Give client some contacts
      client = c1
      contact1 = create(:hmis_hud_custom_client_contact_point, client: client, system: :email)
      contact2 = create(:hmis_hud_custom_client_contact_point, client: client, system: :email)
      expect(client.contact_points.emails.size).to eq(2)

      # Submit a form that changes the contacts
      hud_values = complete_hud_values.merge(
        'emailAddresses' => [
          # Update contact 1
          {
            id: contact1.id,
            value: 'foo@bar.com',
          }.stringify_keys,
          # Add a new contact
          {
            value: 'baz@boop.com',
          }.stringify_keys,
          # Delete contact 2 (by not including it)
        ],
      )
      process_record(record: client, hud_values: hud_values, user: hmis_user)

      expect(client.contact_points.emails.size).to eq(2)
      expect(client.contact_points.pluck(:id)).to include(contact1.id)
      expect(client.contact_points.pluck(:id)).not_to include(contact2.id)
      expect(client.contact_points.pluck(:value)).to contain_exactly('foo@bar.com', 'baz@boop.com')
    end
  end

  describe 'Form processing for Projects' do
    let(:complete_hud_values) do
      {
        'projectName' => 'Test Project',
        'description' => 'Description',
        'contactInformation' => 'Contact Info',
        'operatingStartDate' => '2023-01-13',
        'operatingEndDate' => '2023-01-28',
        'projectType' => 'ES',
        'trackingMethod' => 'NIGHT_BY_NIGHT',
        'residentialAffiliation' => HIDDEN,
        'housingType' => 'SITE_BASED_SINGLE_SITE',
        'targetPopulation' => 'PERSONS_WITH_HIV_AIDS',
        'HOPWAMedAssistedLivingFac' => 'NO',
        'continuumProject' => 'NO',
        'HMISParticipatingProject' => 'YES',
      }
    end
    let(:empty_hud_values) do
      {
        **complete_hud_values.map { |k, v| [k, v.is_a?(Array) ? [] : nil] }.to_h,
        'projectName' => 'Test Project',
        'operatingStartDate' => '2023-01-13',
        'projectType' => 'SO',
      }
    end

    it 'creates and updates all fields' do
      existing_project = p1
      new_project = Hmis::Hud::Project.new(data_source: ds1, user: u1, organization: o1)
      [existing_project, new_project].each do |project|
        process_record(record: project, hud_values: complete_hud_values, user: hmis_user)

        expect(project.project_name).to eq(complete_hud_values['projectName'])
        expect(project.description).to eq(complete_hud_values['description'])
        expect(project.contact_information).to eq(complete_hud_values['contactInformation'])
        expect(project.operating_start_date.strftime('%Y-%m-%d')).to eq(complete_hud_values['operatingStartDate'])
        expect(project.operating_end_date.strftime('%Y-%m-%d')).to eq(complete_hud_values['operatingEndDate'])

        expect(project.project_type).to eq(1)
        expect(project.tracking_method).to eq(3)
        expect(project.residential_affiliation).to be nil # not 99 because disabled
        expect(project.housing_type).to eq(1)
        expect(project.target_population).to eq(3)
        expect(project.hopwa_med_assisted_living_fac).to eq(0)
        expect(project.continuum_project).to eq(0)
        expect(project.hmis_participating_project).to eq(1)
      end
    end

    it 'stores empty fields correctly' do
      existing_project = p1
      new_project = Hmis::Hud::Project.new(data_source: ds1, user: u1, organization: o1)
      [existing_project, new_project].each do |project|
        process_record(record: project, hud_values: empty_hud_values, user: hmis_user)

        expect(project.description).to be nil
        expect(project.contact_information).to be nil
        expect(project.operating_end_date).to be nil
        expect(project.project_type).to eq(4)
        expect(project.tracking_method).to be nil
        expect(project.residential_affiliation).to eq(99)
        expect(project.housing_type).to be nil
        expect(project.target_population).to be nil
        expect(project.hopwa_med_assisted_living_fac).to be nil
        expect(project.continuum_project).to eq(99)
        expect(project.hmis_participating_project).to eq(99)
      end
    end

    it 'fails if validate if any enum field is invalid' do
      existing_project = p1
      new_project = Hmis::Hud::Project.new(data_source: ds1, user: u1, organization: o1)
      [existing_project, new_project].each do |project|
        hud_values = empty_hud_values.merge('residentialAffiliation' => 'INVALID')
        process_record(record: project, hud_values: hud_values, user: hmis_user, save: false)
        expect(project.valid?).to eq(false)
      end
    end
  end

  describe 'Form processing for Organizations' do
    let(:complete_hud_values) do
      {
        'organizationName' => 'Test org',
        'description' => 'description',
        'contactInformation' => 'contact info',
        'victimServiceProvider' => 'NO',
      }
    end

    it 'creates and updates all fields' do
      existing_record = o1
      new_record = Hmis::Hud::Organization.new(data_source: ds1, user: u1)
      [existing_record, new_record].each do |organization|
        process_record(record: organization, hud_values: complete_hud_values, user: hmis_user)

        expect(organization.organization_name).to eq('Test org')
        expect(organization.victim_service_provider).to eq(0)
        expect(organization.description).to eq('description')
        expect(organization.contact_information).to eq('contact info')
      end
    end

    it 'stores empty fields correctly' do
      existing_record = o1
      new_record = Hmis::Hud::Organization.new(data_source: ds1, user: u1)
      [existing_record, new_record].each do |organization|
        hud_values = complete_hud_values.merge(
          'description' => nil,
          'contactInformation' => nil,
          'victimServiceProvider' => nil,
        )
        process_record(record: organization, hud_values: hud_values, user: hmis_user)

        expect(organization.victim_service_provider).to eq(99)
        expect(organization.description).to be nil
        expect(organization.contact_information).to be nil
      end
    end
  end

  describe 'Form processing for Funders' do
    let!(:f1) { create :hmis_hud_funder, data_source: ds1, project: p1, user: u1, other_funder: 'exists' }
    let(:complete_hud_values) do
      {
        'funder' => 'HUD_COC_TRANSITIONAL_HOUSING',
        'otherFunder' => HIDDEN,
        'grantId' => 'ABCDEF',
        'startDate' => '2022-12-01',
        'endDate' => '2023-03-24',
      }
    end

    it 'creates and updates all fields' do
      existing_record = f1
      new_record = Hmis::Hud::Funder.new(data_source: ds1, user: u1, project: p1)
      [existing_record, new_record].each do |funder|
        process_record(record: funder, hud_values: complete_hud_values, user: hmis_user)

        expect(funder.funder).to eq(5)
        expect(funder.other_funder).to be nil
        expect(funder.grant_id).to eq('ABCDEF')
        expect(funder.start_date.strftime('%Y-%m-%d')).to eq('2022-12-01')
        expect(funder.end_date.strftime('%Y-%m-%d')).to eq('2023-03-24')
      end
    end

    it 'sets other funder' do
      existing_record = f1
      new_record = Hmis::Hud::Funder.new(data_source: ds1, user: u1, project: p1)
      [existing_record, new_record].each do |funder|
        hud_values = complete_hud_values.merge(
          'funder' => 'LOCAL_OR_OTHER_FUNDING_SOURCE',
          'otherFunder' => 'foo',
        )
        process_record(record: funder, hud_values: hud_values, user: hmis_user)

        expect(funder.funder).to eq(46)
        expect(funder.other_funder).to eq('foo')
      end
    end

    [
      [
        'fails if other funder not specified',
        ->(input) { input.merge('funder' => 'LOCAL_OR_OTHER_FUNDING_SOURCE', 'otherFunder' => nil) },
      ],
      [
        'fails if end date is before start date',
        ->(input) { input.merge('endDate' => '2021-01-01') },
      ],
    ].each do |test_name, input_proc|
      it test_name do
        existing_record = f1
        new_record = Hmis::Hud::Funder.new(data_source: ds1, user: u1, project: p1)
        [existing_record, new_record].each do |record|
          hud_values = input_proc.call(complete_hud_values)
          process_record(record: record, hud_values: hud_values, user: hmis_user, save: false)
          expect(record.valid?).to eq(false)
        end
      end
    end
  end

  describe 'Form processing for ProjectCoCs' do
    let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }
    let(:complete_hud_values) do
      {
        'cocCode' => 'MA-504',
        'geocode' => '250354',
        'geographyType' => 'SUBURBAN',
        'address1' => '1 State Street',
        'address2' => nil,
        'city' => 'Brockton',
        'state' => 'MA',
        'zip' => '12345',
      }
    end

    it 'creates and updates all fields' do
      existing_record = pc1
      new_record = Hmis::Hud::ProjectCoc.new(data_source: ds1, user: u1, project: p1)
      [existing_record, new_record].each do |record|
        process_record(record: record, hud_values: complete_hud_values, user: hmis_user)

        expect(record.coc_code).to eq('MA-504')
        expect(record.geocode).to eq('250354')
        expect(record.geography_type).to eq(2)
        expect(record.address1).to eq('1 State Street')
        expect(record.address2).to be nil
        expect(record.city).to eq('Brockton')
        expect(record.state).to eq('MA')
        expect(record.zip).to eq('12345')
      end
    end
  end

  describe 'Form processing for Inventory' do
    let!(:pc1) { create :hmis_hud_project_coc, data_source: ds1, project: p1, coc_code: 'CO-500', user: u1 }
    let!(:i1) { create :hmis_hud_inventory, data_source: ds1, project: p1, coc_code: pc1.coc_code, inventory_start_date: '2020-01-01', inventory_end_date: nil, user: u1 }
    let(:complete_hud_values) do
      {
        'cocCode' => 'CO-500',
        'householdType' => 'HOUSEHOLDS_WITH_AT_LEAST_ONE_ADULT_AND_ONE_CHILD',
        'availability' => 'SEASONAL',
        'esBedType' => 'OTHER',
        'inventoryStartDate' => '2019-01-03',
        'inventoryEndDate' => '2019-01-15',
        'unitInventory' => 0,
        'bedInventory' => 0,
      }
    end

    before(:each) do
      p1.update(operating_start_date: '2019-01-01', operating_end_date: '2019-02-01')
    end

    it 'creates and updates all fields' do
      existing_record = i1
      new_record = Hmis::Hud::Inventory.new(data_source: ds1, user: u1, project: p1)
      [existing_record, new_record].each do |record|
        process_record(record: record, hud_values: complete_hud_values, user: hmis_user)

        expect(record.coc_code).to eq('CO-500')
        expect(record.household_type).to eq(3)
        expect(record.availability).to eq(2)
        expect(record.es_bed_type).to eq(3)
        expect(record.inventory_start_date.strftime('%Y-%m-%d')).to eq('2019-01-03')
        expect(record.inventory_end_date.strftime('%Y-%m-%d')).to eq('2019-01-15')
        expect(record.bed_inventory).to eq(0)
        expect(record.unit_inventory).to eq(0)
      end
    end

    it 'succeeds if operating period matches project operating period' do
      existing_record = i1
      new_record = Hmis::Hud::Inventory.new(data_source: ds1, user: u1, project: p1)
      [existing_record, new_record].each do |record|
        hud_values = complete_hud_values.merge(
          'inventoryStartDate' => p1.operating_start_date.strftime('%Y-%m-%d'),
          'inventoryEndDate' => p1.operating_end_date.strftime('%Y-%m-%d'),
        )
        process_record(record: record, hud_values: hud_values, user: hmis_user)

        expect(record.inventory_start_date.strftime('%Y-%m-%d')).to eq('2019-01-01')
        expect(record.inventory_end_date.strftime('%Y-%m-%d')).to eq('2019-02-01')
      end
    end

    describe 'with custom data elements' do
      it 'creates a CustomDataElement' do
        existing_record = i1
        new_record = Hmis::Hud::Inventory.new(data_source: ds1, user: u1, project: p1)

        cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory')

        [existing_record, new_record].each do |record|
          hud_values = complete_hud_values.merge(
            cded.key => 'some value',
          )
          process_record(record: record, hud_values: hud_values, user: hmis_user)

          expect(record.custom_data_elements.size).to eq(1)
          expect(record.custom_data_elements.first.value_string).to eq('some value')
          expect(record.custom_data_elements.first.data_element_definition).to eq(cded)
        end
      end

      it 'updates a CustomDataElement (repeats: false)' do
        record = i1
        cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory')
        cde = create(:hmis_custom_data_element, owner: record, value_string: 'old value', data_element_definition: cded)
        expect(record.custom_data_elements.first!.value_string).to eq(cde.value_string)

        hud_values = complete_hud_values.merge(cded.key => 'new value')
        process_record(record: record, hud_values: hud_values, user: hmis_user)

        expect(record.custom_data_elements.size).to eq(1)
        updated_cde = record.custom_data_elements.first
        expect(updated_cde.value_string).to eq('new value')
        expect(updated_cde.user).not_to eq(cde.user)
        expect(updated_cde.date_updated).not_to eq(cde.date_updated)
        expect(updated_cde.data_element_definition).to eq(cded)
      end

      [nil, HIDDEN, []].each do |value|
        it "doesnt error when receiving custom data element value #{value} (new record / existing record with no value)" do
          existing_record = i1
          new_record = Hmis::Hud::Inventory.new(data_source: ds1, user: u1, project: p1)
          cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory')
          [existing_record, new_record].each do |record|
            hud_values = complete_hud_values.merge(cded.key => value)
            process_record(record: record, hud_values: hud_values, user: hmis_user)
          end
        end
      end

      it 'updates a CustomDataElement (repeats: true)' do
        record = i1
        cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory', repeats: true)
        common_attrs = { owner: record, data_element_definition: cded }
        old1 = create(:hmis_custom_data_element, value_string: 'old value 1', **common_attrs)
        old2 = create(:hmis_custom_data_element, value_string: 'old value 2', **common_attrs)
        old3 = create(:hmis_custom_data_element, value_string: 'old value 3', **common_attrs)
        expect(record.custom_data_elements.size).to eq(3)

        hud_values = complete_hud_values.merge(
          cded.key => ['new value 1', 'new value 2'],
        )
        process_record(record: record, hud_values: hud_values, user: hmis_user)

        expect(record.custom_data_elements.size).to eq(2)
        expect(record.custom_data_elements.map(&:value_string)).to contain_exactly('new value 1', 'new value 2')
        # Old records should have been replaced
        expect(record.custom_data_elements.map(&:id)).not_to include(old1.id, old2.id, old3.id)
      end

      it 'does not delete and replace if the values are the same' do
        record = i1
        cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory', repeats: true)
        old1 = create(:hmis_custom_data_element, owner: record, value_string: 'old value 1', data_element_definition: cded)
        old2 = create(:hmis_custom_data_element, owner: record, value_string: 'old value 2', data_element_definition: cded)
        expect(record.custom_data_elements.size).to eq(2)

        hud_values = complete_hud_values.merge(
          cded.key => [old1.value_string, old2.value_string],
        )
        process_record(record: record, hud_values: hud_values, user: hmis_user)

        expect(record.custom_data_elements.size).to eq(2)
        # Old records should remain, with updated timestamps
        expect(record.custom_data_elements.map(&:id)).to contain_exactly(old1.id, old2.id)
        expect(record.custom_data_elements.map(&:date_updated)).not_to include(old1.date_updated, old2.date_updated)
      end

      [nil, HIDDEN].each do |value|
        it "clears custom data element when set to #{value} (has 1 value)" do
          cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory')
          record = i1
          create(:hmis_custom_data_element, owner: record, value_string: 'old value', data_element_definition: cded)
          expect(record.custom_data_elements.size).to eq(1)

          hud_values = complete_hud_values.merge(cded.key => value)
          process_record(record: record, hud_values: hud_values, user: hmis_user)
          expect(record.custom_data_elements).to be_empty
        end
      end

      [nil, HIDDEN, []].each do |value|
        it "clears custom data element when set to #{value} (has 2 values)" do
          cded = create(:hmis_custom_data_element_definition, owner_type: 'Hmis::Hud::Inventory', repeats: true)
          record = i1
          create(:hmis_custom_data_element, owner: record, value_string: 'old value 1', data_element_definition: cded)
          create(:hmis_custom_data_element, owner: record, value_string: 'old value 2', data_element_definition: cded)
          expect(record.custom_data_elements.size).to eq(2)

          hud_values = complete_hud_values.merge(cded.key => value)
          process_record(record: record, hud_values: hud_values, user: hmis_user)
          expect(record.custom_data_elements).to be_empty
        end
      end
    end

    [
      [
        'fails if CoC code is null',
        ->(input) { input.merge('cocCode' => nil) },
      ],
      [
        'fails if CoC code is invalid for project',
        ->(input) { input.merge('cocCode' => 'MA-500') },
      ],
      [
        'fails if start date is null',
        ->(input) { input.merge('inventoryStartDate' => nil) },
      ],
      [
        'fails if end date is before start date',
        ->(input) { input.merge('inventoryEndDate' => '2002-01-01') },
      ],
      [
        'fails if count is negative',
        ->(input) { input.merge('bedInventory' => -1) },
      ],
      [
        'fails if start date too early',
        ->(input) { input.merge('inventoryStartDate' => '2018-12-31', 'inventoryEndDate' => nil) },
      ],
      [
        'fails if start date too early, with end date',
        ->(input) { input.merge('cocCode' => '2018-12-31') },
      ],
      [
        'fails if period fully outside of project operating period',
        ->(input) { input.merge('inventoryStartDate' => '2015-01-01', 'inventoryEndDate' => '2015-02-01') },
      ],
      [
        'fails if period fully outside of project operating period (other direction)',
        ->(input) { input.merge('inventoryStartDate' => '2022-01-01', 'inventoryEndDate' => '2022-02-01') },
      ],
    ].each do |test_name, input_proc|
      it test_name do
        existing_record = i1
        new_record = Hmis::Hud::Inventory.new(data_source: ds1, user: u1, project: p1)
        [existing_record, new_record].each do |record|
          hud_values = input_proc.call(complete_hud_values)
          process_record(record: record, hud_values: hud_values, user: hmis_user, save: false)
          expect(record.valid?).to eq(false)
        end
      end
    end
  end

  describe 'Form processing for Service' do
    include_context 'hmis service setup'
    # HUD Service: SSVF Financial Assistance (152), Child Care (10)
    let!(:hud_service) { create :hmis_hud_service, data_source: ds1, client: c1, enrollment: e1, record_type: 152, type_provided: 10 }
    # Custom Service
    let!(:custom_service) { create :hmis_custom_service, custom_service_type: cst1, data_source: ds1, client: c1, enrollment: e1 }
    let(:hud_service_values) do
      {
        'dateProvided' => '2023-03-13',
        'faAmount' => 200,
      }
    end

    let(:custom_service_values) do
      {
        'dateProvided' => '2023-03-13',
        'faAmount' => 100,
      }
    end

    it 'creates and updates all fields on a HUD Service' do
      existing_record = Hmis::Hud::HmisService.find_by(owner: hud_service)
      hud_service_type = Hmis::Hud::CustomServiceType.find_by(hud_record_type: hud_service.record_type, hud_type_provided: hud_service.type_provided)
      new_record = Hmis::Hud::HmisService.new(
        data_source: ds1,
        enrollment_id: e1.enrollment_id,
        personal_id: e1.personal_id,
        custom_service_type: hud_service_type,
      )

      [existing_record, new_record].each do |record|
        process_record(record: record, hud_values: hud_service_values, user: hmis_user, save: false)
        record.owner.save!

        hmis_service = Hmis::Hud::HmisService.find_by(owner: record.owner)
        expect(hmis_service.hud_service?).to eq(true)
        expect(hmis_service.custom_service?).to eq(false)
        expect(hmis_service.service_type).to eq(hud_service_type)
        expect(hmis_service.record_type).to eq(hud_service.record_type)
        expect(hmis_service.type_provided).to eq(hud_service.type_provided)
        expect(hmis_service.fa_amount).to eq(200)
        expect(hmis_service.date_provided.strftime('%Y-%m-%d')).to eq('2023-03-13')
      end
    end

    it 'creates and updates all fields on a Custom Service' do
      existing_record = Hmis::Hud::HmisService.find_by(owner: custom_service)
      new_record = Hmis::Hud::HmisService.new(
        data_source: ds1,
        enrollment_id: e1.enrollment_id,
        personal_id: e1.personal_id,
        custom_service_type: cst1,
      )
      [existing_record, new_record].each do |record|
        process_record(record: record, hud_values: custom_service_values, user: hmis_user, save: false)
        record.owner.save!

        hmis_service = Hmis::Hud::HmisService.find_by(owner: record.owner)
        expect(hmis_service.hud_service?).to eq(false)
        expect(hmis_service.custom_service?).to eq(true)
        expect(hmis_service.service_type).to eq(cst1)
        expect(hmis_service.record_type).to be nil
        expect(hmis_service.type_provided).to be nil
        expect(hmis_service.fa_amount).to eq(100)
        expect(hmis_service.date_provided.strftime('%Y-%m-%d')).to eq('2023-03-13')
      end
    end
  end

  describe 'Form processing for File' do
    include_context 'file upload setup'

    let(:hud_values) do
      {
        'tags' => [
          tag2.id.to_s,
        ],
        'clientId' => e1.client.id.to_s,
        'enrollmentId' => e1.id.to_s,
        'effectiveDate' => '2023-03-17',
        'expirationDate' => '2023-03-17',
        'confidential' => true,
        'fileBlobId' => blob.id.to_s,
      }
    end

    let!(:existing_file) { create :file, client: c1, enrollment: e1, blob: blob, user_id: hmis_user.id, tags: [tag] }
    let!(:new_file) { Hmis::File.new(name: blob.filename) }

    it 'should test' do
      [existing_file, new_file].each do |file|
        process_record(record: file, hud_values: hud_values, user: hmis_user)

        expect(file.name).to eq(blob.filename.to_s)
        expect(file.client).to eq(c1)
        expect(file.enrollment).to eq(e1)
        expect(file.effective_date.strftime('%Y-%m-%d')).to eq(hud_values['effectiveDate'])
        expect(file.expiration_date.strftime('%Y-%m-%d')).to eq(hud_values['expirationDate'])
        expect(file.confidential).to eq(hud_values['confidential'])
        expect(file.client_file.blob).to eq(blob)
      end
    end
  end
end
