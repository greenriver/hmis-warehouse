require 'rails_helper'

RSpec.describe Hmis::Form::FormProcessor, type: :model do
  let!(:ds) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds.id) } }
  let(:hmis_hud_user) { Hmis::Hud::User.from_user(hmis_user) }

  let!(:fd) { create :hmis_form_definition }

  let(:o1) { create :hmis_hud_organization, data_source: ds, user: hmis_hud_user }
  let(:p1) { create :hmis_hud_project, data_source: ds, organization: o1, user: hmis_hud_user }
  let(:c1) { create :hmis_hud_client, data_source: ds, user: hmis_hud_user }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds, project: p1, client: c1, user: hmis_hud_user }

  before(:all) do
    cleanup_test_environment
  end
  after(:all) do
    cleanup_test_environment
  end

  it 'ingests EnrollmentCoC into the hud tables' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'EnrollmentCoc.cocCode' => 'MA-507',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
    expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')
  end

  it 'ingests IncomeBenefit into the hud tables (income sources)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.earned' => nil,
      'IncomeBenefit.earnedAmount' => nil,
      'IncomeBenefit.unemployment' => true,
      'IncomeBenefit.unemploymentAmount' => 100,
      'IncomeBenefit.otherIncomeSource' => false,
      'IncomeBenefit.otherIncomeAmount' => 0,
      'IncomeBenefit.otherIncomeSourceIdentify' => '_HIDDEN',
    }

    assessment.custom_form.form_processor.run!
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

  it 'ingests IncomeBenefit into the hud tables (non-cash benefits, all hidden)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'IncomeBenefit.benefitsFromAnySource' => 'NO',
      'IncomeBenefit.snap' => '_HIDDEN',
      'IncomeBenefit.wic' => '_HIDDEN',
      'IncomeBenefit.otherBenefitsSource' => '_HIDDEN',
      'IncomeBenefit.otherBenefitsSourceIdentify' => '_HIDDEN',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.benefits_from_any_source).to eq(0)
    expect(income_benefits.snap).to eq(0) # overridden
    expect(income_benefits.wic).to eq(0) # overridden
    expect(income_benefits.other_benefits_source).to eq(0) # overridden
    expect(income_benefits.other_benefits_source_identify).to eq(nil)
  end

  it 'ingests IncomeBenefit into the hud tables (health insurance)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'IncomeBenefit.insuranceFromAnySource' => 'YES',
      'IncomeBenefit.medicaid' => true,
      'IncomeBenefit.schip' => nil,
      'IncomeBenefit.otherInsurance' => nil,
      'IncomeBenefit.otherInsuranceIdentify' => '_HIDDEN',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.insurance_from_any_source).to eq(1)
    expect(income_benefits.medicaid).to eq(1)
    expect(income_benefits.schip).to eq(0) # overridden
    expect(income_benefits.other_insurance).to eq(0) # overridden
    expect(income_benefits.other_insurance_identify).to eq(nil)
  end

  it 'ingests IncomeBenefit into the hud tables (health insurance saves as 99)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'IncomeBenefit.insuranceFromAnySource' => nil,
      'IncomeBenefit.medicaid' => nil,
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.insurance_from_any_source).to eq(99)
    expect(income_benefits.medicaid).to eq(nil)
  end

  it 'ingests HealthAndDV into the hud tables (no)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'HealthAndDv.domesticViolenceVictim' => 'NO',
      'HealthAndDv.currentlyFleeing' => '_HIDDEN',
      'HealthAndDv.whenOccurred' => '_HIDDEN',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.health_and_dvs.count).to eq(1)

    health_and_dv = assessment.enrollment.health_and_dvs.first
    expect(health_and_dv.domestic_violence_victim).to eq(0)
    expect(health_and_dv.currently_fleeing).to eq(nil)
    expect(health_and_dv.when_occurred).to eq(nil)
  end

  it 'ingests HealthAndDV into the hud tables (99)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'HealthAndDv.domesticViolenceVictim' => nil,
      'HealthAndDv.currentlyFleeing' => '_HIDDEN',
      'HealthAndDv.whenOccurred' => '_HIDDEN',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.health_and_dvs.count).to eq(1)

    health_and_dv = assessment.enrollment.health_and_dvs.first
    expect(health_and_dv.domestic_violence_victim).to eq(99)
    expect(health_and_dv.currently_fleeing).to eq(nil)
    expect(health_and_dv.when_occurred).to eq(nil)
  end

  it 'ingests HealthAndDV into the hud tables (yes, with 99 conditional)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'HealthAndDv.domesticViolenceVictim' => 'YES',
      'HealthAndDv.currentlyFleeing' => nil,
      'HealthAndDv.whenOccurred' => 'CLIENT_REFUSED',
    }

    assessment.custom_form.form_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.health_and_dvs.count).to eq(1)

    health_and_dv = assessment.enrollment.health_and_dvs.first
    expect(health_and_dv.domestic_violence_victim).to eq(1)
    expect(health_and_dv.currently_fleeing).to eq(99)
    expect(health_and_dv.when_occurred).to eq(9)
  end

  it 'ingests DisabilityGroup into multiple Disabilities' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
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

    assessment.custom_form.form_processor.run!
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
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'DisabilityGroup.physicalDisability' => nil,
      'DisabilityGroup.physicalDisabilityIndefiniteAndImpairs' => '_HIDDEN',
      'DisabilityGroup.developmentalDisability' => 'NO',
      'DisabilityGroup.developmentalDisabilityIndefiniteAndImpairs' => '_HIDDEN',
      'DisabilityGroup.chronicHealthCondition' => 'YES',
      'DisabilityGroup.chronicHealthConditionIndefiniteAndImpairs' => nil,
      'DisabilityGroup.hivAids' => nil,
      'DisabilityGroup.mentalHealthDisorder' => nil,
      'DisabilityGroup.substanceUseDisorder' => 'BOTH_ALCOHOL_AND_DRUG_USE_DISORDERS',
      'DisabilityGroup.substanceUseDisorderIndefiniteAndImpairs' => nil,
      'DisabilityGroup.disablingCondition' => nil,
    }

    assessment.custom_form.form_processor.run!
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

  it 'pulls validation errors up from HUD records' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.custom_form.hud_values = {
      'EnrollmentCoc.user_id' => nil,
    }

    assessment.custom_form.form_processor.run!
    expect(assessment.custom_form.valid?).to be false
    expect(assessment.custom_form.errors[:user]).to include('must exist')
  end

  describe 'updating existing assessment' do
    it "doesn't touch an existing value, if it isn't listed (but applies the listed fields)" do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.custom_form.form_processor.run!
      assessment.save_not_in_progress

      assessment.custom_form.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.custom_form.form_processor.run!
      assessment.custom_form.save!
      assessment.save_not_in_progress
      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(1)
    end

    it 'clears an existing value, if it is null' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.custom_form.form_processor.run!
      assessment.save_not_in_progress

      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => nil,
        'IncomeBenefit.incomeFromAnySource' => nil,
      }

      assessment.custom_form.form_processor.run!
      assessment.custom_form.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to be_nil
    end

    it 'adjusts the information dates as appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.custom_form.form_processor.run!
      assessment.save_not_in_progress

      test_date = '2020-10-15'.to_date
      assessment.assessment_date = test_date

      assessment.custom_form.form_processor.run!
      assessment.custom_form.save!
      assessment.save_not_in_progress

      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.first.information_date).to eq(test_date)
    end

    it 'adds an exit record when appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.custom_form.form_processor.run!
      assessment.save_not_in_progress

      expect(assessment.enrollment.exit).to be_nil
      expect(assessment.enrollment.exit_date).to be_nil

      assessment.custom_form.hud_values = {
        'Exit.destination' => '1',
      }

      assessment.custom_form.form_processor.run!
      assessment.custom_form.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.exit).to be_present
      expect(assessment.enrollment.exit.destination).to eq(1)
    end

    it 'updates enrollment entry date when appropriate' do
      assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.custom_form.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.custom_form.form_processor.run!
      assessment.save_not_in_progress

      old_entry_date = assessment.enrollment.entry_date
      new_entry_date = '2024-03-14'
      expect(old_entry_date).not_to be_nil

      assessment.custom_form.hud_values = {
        'Enrollment.entryDate' => new_entry_date,
      }

      assessment.custom_form.form_processor.run!
      assessment.custom_form.form_processor.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.entry_date).not_to eq(old_entry_date)
      expect(assessment.enrollment.entry_date).to eq(Date.parse(new_entry_date))
    end
  end
end
