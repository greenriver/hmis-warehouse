require 'rails_helper'

RSpec.describe Hmis::Form::Processor, type: :model do
  let!(:ds) { create :hmis_data_source }
  let!(:user) { create(:user).tap { |u| u.add_viewable(ds) } }
  let(:hmis_user) { Hmis::User.find(user.id)&.tap { |u| u.update(hmis_data_source_id: ds.id) } }
  let(:hmis_hud_user) { Hmis::Hud::User.from_user(hmis_user) }

  let!(:fd) { create :hmis_form_definition }

  let(:o1) { create :hmis_hud_organization, data_source: ds, user: hmis_hud_user }
  let(:p1) { create :hmis_hud_project, data_source: ds, organization: o1, user: hmis_hud_user }
  let(:c1) { create :hmis_hud_client, data_source: ds, user: hmis_hud_user }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds, project: p1, client: c1, user: hmis_hud_user }

  it 'ingests EnrollmentCoC into the hud tables' do
    assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
    assessment.assessment_detail.hud_values = {
      'EnrollmentCoc.cocCode' => 'MA-507',
    }

    assessment.assessment_detail.processor.run!
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

    assessment.assessment_detail.processor.run!
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

    assessment.assessment_detail.processor.run!
    assessment.save_not_in_progress

    expect(assessment.enrollment.disabilities.count).to eq(6)
    expect(assessment.enrollment.disabling_condition).to eq(1)

    disabilities = assessment.enrollment.disabilities
    # Physical Disability
    expect(disabilities.find_by(disability_type: 5).disability_response).to eq(1)
    expect(disabilities.find_by(disability_type: 5).indefinite_and_impairs).to eq(1)
    # Developmental Disability
    expect(disabilities.find_by(disability_type: 6).disability_response).to eq(0)
    expect(disabilities.find_by(disability_type: 6).indefinite_and_impairs).to eq(nil)
    # Substance Use
    expect(disabilities.find_by(disability_type: 10).disability_response).to eq(3)
  end

  describe 'updating existing assessment' do
    it "doesn't touch an existing value, if it isn't listed (but applies the listed fields)" do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.processor.run!
      assessment.save_not_in_progress

      assessment.assessment_detail.hud_values = {
        'IncomeBenefit.incomeFromAnySource' => 'YES',
      }

      assessment.assessment_detail.processor.run!
      assessment.save_not_in_progress

      expect(assessment.enrollment.enrollment_cocs.count).to eq(1)
      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq('MA-507')

      income_benefits = assessment.enrollment.income_benefits.first
      expect(income_benefits.income_from_any_source).to eq(1)
    end

    it 'clears an existing value, if it is null' do
      assessment = Hmis::Hud::Assessment.new_with_defaults(enrollment: e1, user: hmis_hud_user, form_definition: fd, assessment_date: Date.current)
      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode' => 'MA-507',
      }

      assessment.assessment_detail.processor.run!
      assessment.save_not_in_progress

      assessment.assessment_detail.hud_values = {
        'EnrollmentCoc.cocCode ' => nil,
      }

      assessment.assessment_detail.processor.run!
      assessment.save_not_in_progress

      expect(assessment.enrollment.enrollment_cocs.first.coc_code).to eq(nil)
    end
  end
end
