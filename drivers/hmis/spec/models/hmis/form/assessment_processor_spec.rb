require 'rails_helper'

RSpec.describe Hmis::Form::AssessmentProcessor, type: :model do
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
    assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.assessment_detail.hud_values = {
      'EnrollmentCoc.cocCode' => 'MA-507',
    }

    assessment.assessment_detail.assessment_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
    expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')
  end

  it 'ingests IncomeBenefit into the hud tables' do
    assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.assessment_detail.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.earned' => true,
      'IncomeBenefit.earnedAmount' => 1,
      'IncomeBenefit.otherInsurance' => false,
    }

    assessment.assessment_detail.assessment_processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.income_from_any_source).to eq(1)
    expect(income_benefits.earned).to eq(1)
    expect(income_benefits.earned_amount).to eq(1)
    expect(income_benefits.other_insurance).to eq(0)
  end

  it 'ingests DisabilityGroup into multiple Disabilities' do
    assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.assessment_detail.hud_values = {
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

    assessment.assessment_detail.assessment_processor.run!
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

  it 'pulls validation errors up from HUD records' do
    assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.assessment_detail.hud_values = {
      'EnrollmentCoc.user_id' => nil,
    }

    assessment.assessment_detail.assessment_processor.run!
    expect(assessment.assessment_detail.valid?).to be false
    expect(assessment.assessment_detail.errors[:user]).to include('must exist')
  end

  describe 'updating existing assessment' do
    it "doesn't touch an existing value, if it isn't listed (but applies the listed fields)" do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.save_not_in_progress

      assessment.assessment_detail.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.assessment_detail.save!
      assessment.save_not_in_progress
      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(1)
    end

    it 'clears an existing value, if it is null' do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.save_not_in_progress

      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => nil,
        'IncomeBenefit.incomeFromAnySource' => nil,
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.assessment_detail.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to be_nil
    end

    it 'adjusts the information dates as appropriate' do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.save_not_in_progress

      test_date = '2020-10-15'.to_date
      assessment.assessment_date = test_date

      assessment.assessment_detail.assessment_processor.run!
      assessment.assessment_detail.save!
      assessment.save_not_in_progress

      assessment.reload
      expect(assessment.enrollment.enrollment_cocs.first.information_date).to eq(test_date)
    end

    it 'adds an exit record when appropriate' do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.save_not_in_progress

      expect(assessment.enrollment.exit).to be_nil
      expect(assessment.enrollment.exit_date).to be_nil

      assessment.assessment_detail.hud_values = {
        'Exit.destination' => '1',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.assessment_detail.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.exit).to be_present
      expect(assessment.enrollment.exit.destination).to eq(1)
    end

    it 'updates enrollment entry date when appropriate' do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.save_not_in_progress

      old_entry_date = assessment.enrollment.entry_date
      new_entry_date = '2024-03-14'
      expect(old_entry_date).not_to be_nil

      assessment.assessment_detail.hud_values = {
        'Enrollment.entryDate' => new_entry_date,
      }

      assessment.assessment_detail.assessment_processor.run!
      assessment.assessment_detail.assessment_processor.save!
      assessment.save_not_in_progress
      assessment.reload

      expect(assessment.enrollment.entry_date).not_to eq(old_entry_date)
      expect(assessment.enrollment.entry_date).to eq(Date.parse(new_entry_date))
    end
  end
end
