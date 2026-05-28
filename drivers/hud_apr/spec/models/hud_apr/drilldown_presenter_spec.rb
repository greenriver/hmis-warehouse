###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudApr::DrilldownPresenter, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:allow_policy) { GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance }
  let(:deny_policy) { GrdaWarehouse::AuthPolicies::DenyPiiPolicy.instance }

  let(:record) do
    create(:hud_report_apr_client,
           report_instance: report,
           first_name: 'Jane',
           last_name: 'Smith',
           personal_id: 'P123',
           destination_client_id: 42,
           ssn: '123-45-6789',
           age: 35,
           dob: Date.new(1990, 6, 15),
           dob_quality: 1,
           sex: 1,
           veteran_status: 0,
           relationship_to_hoh: 1,
           first_date_in_program: Date.new(2026, 1, 1),
           last_date_in_program: Date.new(2026, 3, 15),
           head_of_household: true,
           destination: 435,
           project_type: 1,
           domestic_violence: 0,
           currently_fleeing: 0,
           prior_living_situation: 116,
           mental_health_problem: 1,
           hiv_aids: 0,
           income_from_any_source_at_start: 1,
           income_sources_at_start: { 'Earned' => 500, 'SSI' => 200 },
           household_members: ['Jane Smith', 'John Smith'])
  end

  let(:scope) { HudApr::Fy2020::AprClient.where(id: record.id) }

  before do
    allow(user).to receive(:reporting_policy_for_project).and_return(allow_policy)
  end

  describe '#headers' do
    it 'returns all enrollment fields when no question is specified' do
      presenter = described_class.new(scope, report, user)
      headers = presenter.headers

      expect(headers).to include(
        'personal_id' => 'HMIS Personal ID',
        'destination_client_id' => 'Warehouse Client ID',
        'first_name' => 'First name',
        'ssn' => 'SSN',
        'dob' => 'DOB',
      )
    end

    it 'returns filtered fields for a mapped question' do
      presenter = described_class.new(scope, report, user, question: 'Question 5')
      headers = presenter.headers

      expect(headers.keys).to include('destination_client_id', 'personal_id', 'first_name', 'last_name', 'age', 'dob')
      expect(headers.keys).not_to include('income_from_any_source_at_start', 'destination', 'project_type')
    end

    it 'returns all fields with a warning for an unmapped question' do
      expect(Rails.logger).to receive(:warn).with(/No field mapping for "Question 99"/)

      presenter = described_class.new(scope, report, user, question: 'Question 99')
      all_presenter = described_class.new(scope, report, user)

      expect(presenter.headers).to eq(all_presenter.headers)
    end
  end

  describe '#fields_for_question' do
    it 'includes common fields for every mapped question' do
      common = ['destination_client_id', 'personal_id', 'first_name', 'last_name', 'first_date_in_program', 'last_date_in_program', 'head_of_household']

      ('4'..'27').each do |n|
        question = "Question #{n}"
        presenter = described_class.new(scope, report, user, question: question)
        headers = presenter.headers

        missing = common - headers.keys
        expect(missing).to be_empty, "Question #{n} is missing common fields: #{missing.join(', ')}"
      end
    end

    it 'includes health fields for Question 13' do
      presenter = described_class.new(scope, report, user, question: 'Question 13')
      headers = presenter.headers

      expect(headers.keys).to include(
        'mental_health_problem', 'mental_health_problem_entry',
        'hiv_aids', 'hiv_aids_entry',
        'substance_abuse', 'substance_abuse_entry'
      )
    end

    it 'includes financial fields for Question 16' do
      presenter = described_class.new(scope, report, user, question: 'Question 16')
      headers = presenter.headers

      expect(headers.keys).to include(
        'income_date_at_start', 'income_from_any_source_at_start',
        'income_total_at_start', 'income_total_at_exit'
      )
    end

    it 'includes housing fields for Question 22' do
      presenter = described_class.new(scope, report, user, question: 'Question 22')
      headers = presenter.headers

      expect(headers.keys).to include('destination', 'housing_assessment', 'prior_living_situation')
    end

    it 'includes insurance fields for Question 21' do
      presenter = described_class.new(scope, report, user, question: 'Question 21')
      headers = presenter.headers

      expect(headers.keys).to include(
        'insurance_from_any_source_at_start',
        'insurance_from_any_source_at_annual_assessment',
        'insurance_from_any_source_at_exit',
      )
    end

    it 'only references field names that exist in enrollment_fields' do
      presenter = described_class.new(scope, report, user)
      known = presenter.send(:enrollment_fields).keys.map(&:to_s).to_set

      presenter.send(:extra_fields).each do |question, symbols|
        all_symbols = (presenter.send(:common_fields) + symbols).uniq
        unknown = all_symbols.map(&:to_s).reject { |s| known.include?(s) }
        expect(unknown).to be_empty, "#{question} references unknown fields: #{unknown.join(', ')}"
      end
    end
  end

  describe '#display_value' do
    let(:presenter) { described_class.new(scope, report, user, format: format) }
    let(:format) { :html }

    context 'HUD integer-to-label transforms' do
      it 'transforms destination codes' do
        val = presenter.display_value(record, 'destination')
        expect(val).to be_a(String)
        expect(val).not_to eq('435')
      end

      it 'transforms veteran_status codes' do
        val = presenter.display_value(record, 'veteran_status')
        expect(val).to be_a(String)
        expect(val).not_to eq('0')
      end

      it 'transforms relationship_to_hoh codes' do
        val = presenter.display_value(record, 'relationship_to_hoh')
        expect(val).to be_a(String)
        expect(val).not_to eq('1')
      end

      it 'transforms prior_living_situation codes' do
        val = presenter.display_value(record, 'prior_living_situation')
        expect(val).to be_a(String)
        expect(val).not_to eq('116')
      end

      it 'transforms project_type codes' do
        val = presenter.display_value(record, 'project_type')
        expect(val).to be_a(String)
      end

      it 'transforms sex codes' do
        val = presenter.display_value(record, 'sex')
        expect(val).to be_a(String)
      end

      it 'transforms dob_quality codes' do
        val = presenter.display_value(record, 'dob_quality')
        expect(val).to be_a(String)
        expect(val).not_to eq('1')
      end
    end

    context 'not_collected nil-to-99 fallback' do
      it 'treats nil as Data not collected for fields with not_collected flag' do
        record.update!(destination: nil)
        val = presenter.display_value(record, 'destination')
        expect(val).to be_present
      end
    end

    context 'boolean values' do
      it 'renders booleans with content_tag in HTML' do
        val = presenter.display_value(record, 'head_of_household')
        expect(val).to include('icon-checkmark')
      end

      it 'renders booleans as plain text in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'head_of_household')
        expect(val).to eq('Yes')
      end
    end

    context 'complex values' do
      it 'renders Hash values as formatted list in HTML' do
        val = presenter.display_value(record, 'income_sources_at_start')
        expect(val).to include('Earned')
        expect(val).to include('500')
        expect(val).to include('<ul')
      end

      it 'renders Hash values as newline-separated in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'income_sources_at_start')
        expect(val).to include('Earned')
        expect(val).to include("\n")
      end

      it 'renders Array values as list in HTML' do
        val = presenter.display_value(record, 'household_members')
        expect(val).to include('<ul')
        expect(val).to include('Jane Smith')
      end

      it 'renders Array values as newline-separated in Excel' do
        xlsx_presenter = described_class.new(scope, report, user, format: :xlsx)
        val = xlsx_presenter.display_value(record, 'household_members')
        expect(val).to include("Jane Smith\nJohn Smith")
      end
    end

    context 'PII masking' do
      it 'shows PII when policy allows' do
        expect(presenter.display_value(record, 'first_name')).to eq('Jane')
        expect(presenter.display_value(record, 'last_name')).to eq('Smith')
        expect(presenter.display_value(record, 'ssn')).to eq('123-45-6789')
        expect(presenter.display_value(record, 'dob')).to eq(Date.new(1990, 6, 15))
      end

      it 'masks PII when policy denies' do
        allow(user).to receive(:reporting_policy_for_project).and_return(deny_policy)

        expect(presenter.display_value(record, 'first_name')).to eq('Redacted')
        expect(presenter.display_value(record, 'last_name')).to eq('Redacted')
        expect(presenter.display_value(record, 'ssn')).to eq('Redacted')
        expect(presenter.display_value(record, 'dob')).to eq('Redacted')
      end

      it 'masks HIV status when policy denies' do
        record.update!(hiv_aids: 1)
        allow(user).to receive(:reporting_policy_for_project).and_return(deny_policy)

        expect(presenter.display_value(record, 'hiv_aids')).to eq('Redacted')
      end
    end
  end
end

RSpec.describe HudApr::CeAprDrilldownPresenter, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user) }
  let(:record) { create(:hud_report_apr_client, report_instance: report) }
  let(:scope) { HudApr::Fy2020::AprClient.where(id: record.id) }

  before do
    allow(user).to receive(:reporting_policy_for_project).
      and_return(GrdaWarehouse::AuthPolicies::AllowPiiPolicy.instance)
  end

  describe '#extra_fields' do
    it 'maps CE APR questions 5-10' do
      presenter = described_class.new(scope, report, user)
      keys = presenter.send(:extra_fields).keys

      expect(keys).to contain_exactly(
        'Question 5', 'Question 6', 'Question 7', 'Question 8', 'Question 9', 'Question 10'
      )
    end

    it 'includes CE-specific fields for Question 9' do
      presenter = described_class.new(scope, report, user, question: 'Question 9')
      headers = presenter.headers

      expect(headers.keys).to include(
        'ce_assessment_date', 'ce_assessment_type', 'ce_assessment_prioritization_status',
        'ce_event_date', 'ce_event_event'
      )
    end

    it 'includes CE-specific fields for Question 10' do
      presenter = described_class.new(scope, report, user, question: 'Question 10')
      headers = presenter.headers

      expect(headers.keys).to include('ce_event_date', 'ce_event_event', 'ce_event_referral_result')
    end

    it 'only references field names that exist in enrollment_fields' do
      presenter = described_class.new(scope, report, user)
      known = presenter.send(:enrollment_fields).keys.map(&:to_s).to_set

      presenter.send(:extra_fields).each do |question, symbols|
        all_symbols = (presenter.send(:common_fields) + symbols).uniq
        unknown = all_symbols.map(&:to_s).reject { |s| known.include?(s) }
        expect(unknown).to be_empty, "#{question} references unknown fields: #{unknown.join(', ')}"
      end
    end
  end
end
