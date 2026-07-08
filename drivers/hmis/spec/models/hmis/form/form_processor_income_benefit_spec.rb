###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative '../../../requests/hmis/login_and_permissions'
require_relative '../../../support/hmis_base_setup'

RSpec.describe 'IncomeBenefit processor', type: :model do
  include_context 'hmis base setup'
  include_context 'hmis json forms seed'

  let(:fd) { Hmis::Form::Definition.find_by!(role: :INTAKE) }
  let(:c1) { create :hmis_hud_client_complete, data_source: ds1 }
  let!(:e1) { create :hmis_hud_enrollment, data_source: ds1, project: p1, client: c1 }

  HIDDEN = Hmis::Hud::Processors::Base::HIDDEN_FIELD_VALUE

  it 'succeeds if Income from Any Source is YES and income sources are specified' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.earnedAmount' => nil,
      'IncomeBenefit.unemploymentAmount' => 100,
      'IncomeBenefit.otherIncomeAmount' => 0,
      'IncomeBenefit.otherIncomeSourceIdentify' => HIDDEN,
    }

    assessment.form_processor.run!(user: hmis_user)
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
      'IncomeBenefit.earnedAmount' => nil,
      'IncomeBenefit.unemploymentAmount' => nil,
      'IncomeBenefit.otherIncomeAmount' => nil,
      'IncomeBenefit.otherIncomeSourceIdentify' => HIDDEN,
    }

    assessment.form_processor.run!(user: hmis_user)
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

  it 'fails if total income is specified without Income from Any Source' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => nil,
      'IncomeBenefit.totalMonthlyIncome' => 100,
    }

    assessment.form_processor.run!(user: hmis_user)

    expect(assessment.form_processor.valid?(:form_submission)).to be false
    expect(assessment.form_processor.errors.where(:income_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INCOME_SOURE_WITHOUT_SUMMARY)
  end

  it 'succeeds if Non-Cash Benefits from Any Source is NO' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.benefitsFromAnySource' => 'NO',
      'IncomeBenefit.snap' => HIDDEN,
      'IncomeBenefit.wic' => HIDDEN,
      'IncomeBenefit.otherBenefitsSource' => HIDDEN,
      'IncomeBenefit.otherBenefitsSourceIdentify' => HIDDEN,
    }

    assessment.form_processor.run!(user: hmis_user)
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.benefits_from_any_source).to eq(0)
    expect(income_benefits.snap).to eq(0) # overridden
    expect(income_benefits.wic).to eq(0) # overridden
    expect(income_benefits.other_benefits_source).to eq(0) # overridden
    expect(income_benefits.other_benefits_source_identify).to eq(nil)
  end

  it 'succeeds if Non-Cash Benefits from Any Source is CLIENT_PREFERS_NOT_TO_ANSWER' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.benefitsFromAnySource' => 'CLIENT_PREFERS_NOT_TO_ANSWER',
      'IncomeBenefit.snap' => HIDDEN,
      'IncomeBenefit.wic' => HIDDEN,
      'IncomeBenefit.otherBenefitsSource' => HIDDEN,
      'IncomeBenefit.otherBenefitsSourceIdentify' => HIDDEN,
    }

    assessment.form_processor.run!(user: hmis_user)
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.benefits_from_any_source).to eq(9)
    expect(income_benefits.snap).to be nil
    expect(income_benefits.wic).to be nil
    expect(income_benefits.other_benefits_source).to be nil
    expect(income_benefits.other_benefits_source_identify).to be nil
  end

  it 'fails if a benefit is specified without Non-Cash Benefits from Any Source' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.benefitsFromAnySource' => nil,
      'IncomeBenefit.snap' => 'YES',
    }

    assessment.form_processor.run!(user: hmis_user)

    expect(assessment.form_processor.valid?(:form_submission)).to be false
    expect(assessment.form_processor.errors.where(:benefits_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::BENEFIT_SOURCE_WITHOUT_SUMMARY)
  end

  it 'succeeds if Covered by Health Insurance is YES and providers are specified' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.insuranceFromAnySource' => 'YES',
      'IncomeBenefit.medicaid' => 'YES',
      'IncomeBenefit.schip' => nil,
      'IncomeBenefit.otherInsurance' => nil,
      'IncomeBenefit.otherInsuranceIdentify' => HIDDEN,
    }

    assessment.form_processor.run!(user: hmis_user)
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

    assessment.form_processor.run!(user: hmis_user)
    assessment.save_not_in_progress

    expect(assessment.enrollment.income_benefits.count).to eq(1)

    income_benefits = assessment.enrollment.income_benefits.first
    expect(income_benefits.insurance_from_any_source).to eq(99)
    expect(income_benefits.medicaid).to eq(99)
  end

  it 'fails if an insurance provider is specified without Covered by Health Insurance' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.insuranceFromAnySource' => nil,
      'IncomeBenefit.medicaid' => 'YES',
    }

    assessment.form_processor.run!(user: hmis_user)

    expect(assessment.form_processor.valid?(:form_submission)).to be false
    expect(assessment.form_processor.errors.where(:insurance_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INSURANCE_SOURCE_WITHOUT_SUMMARY)
  end

  it 'fails if summary questions are YES but no dependent sources were specified' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.benefitsFromAnySource' => 'YES',
      'IncomeBenefit.insuranceFromAnySource' => 'YES',
    }

    assessment.form_processor.run!(user: hmis_user)
    expect(assessment.form_processor.valid?(:form_submission)).to be false
    expect(assessment.form_processor.errors.where(:income_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INCOME_SOURCES_UNSPECIFIED)
    expect(assessment.form_processor.errors.where(:benefits_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::BENEFIT_SOURCES_UNSPECIFIED)
    expect(assessment.form_processor.errors.where(:insurance_from_any_source).first.options[:full_message]).
      to eq(Hmis::Hud::Validators::IncomeBenefitValidator::INSURANCE_SOURCES_UNSPECIFIED)
  end

  it 'raises when receiving a string value for a decimal col (regression #6868)' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.unemploymentAmount' => 'bad string',
      'IncomeBenefit.otherIncomeAmount' => 100,
      'IncomeBenefit.alimonyAmount' => nil,
    }

    assessment.form_processor.run!(user: hmis_user)
    expect do
      assessment.form_processor.save!
    end.to raise_error(ActiveRecord::RecordInvalid, /not a number/).
      and not_change(Hmis::Hud::IncomeBenefit, :count)
  end

  it 'does not raise when receiving a string that can be converted to an int' do
    assessment = Hmis::Hud::CustomAssessment.new_with_defaults(enrollment: e1, user: u1, form_definition: fd, assessment_date: Date.yesterday)
    assessment.form_processor.hud_values = {
      'IncomeBenefit.incomeFromAnySource' => 'YES',
      'IncomeBenefit.unemploymentAmount' => '200',
      'IncomeBenefit.otherIncomeAmount' => 100,
      'IncomeBenefit.alimonyAmount' => nil,
    }

    assessment.form_processor.run!(user: hmis_user)
    expect(assessment.form_processor.valid?(:form_submission)).to be true
  end
end
