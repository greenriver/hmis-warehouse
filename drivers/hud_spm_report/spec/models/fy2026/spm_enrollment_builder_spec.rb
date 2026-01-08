# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HudSpmReport::Fy2026::SpmEnrollmentBuilder, type: :model do
  let(:user) { create(:user) }
  let(:report) { create(:hud_reports_report_instance, user: user, start_date: '2020-01-01', end_date: '2020-12-31', options: { start: '2020-01-01', end: '2020-12-31' }) }
  let(:filter) { Filters::HudFilterBase.new(user_id: user.id).update(report.options) }
  let(:data_source) { create(:data_source_fixed_id) }
  let(:client) { create(:hud_client, data_source: data_source, FirstName: 'John', LastName: 'Doe', PersonalID: 'P123') }
  let(:dest_client) { create(:hud_client, data_source: data_source) }
  let!(:warehouse_link) { create(:warehouse_client, source: client, destination: dest_client) }
  let(:project) { create(:hud_project, data_source: data_source, ProjectType: 1) } # ES-NBN
  let(:enrollment) do
    create(:hud_enrollment,
           data_source: data_source,
           PersonalID: client.PersonalID,
           ProjectID: project.ProjectID,
           EntryDate: '2020-01-01',
           MoveInDate: '2020-02-01')
  end
  let(:she) { create(:she_entry, data_source: data_source, enrollment: enrollment, client: client) }
  let(:context) do
    create(:hud_reports_household_context,
           report_instance: report,
           service_history_enrollment: she,
           age: 35,
           inherited_date_to_street: Date.parse('2019-12-01'),
           inherited_move_in_date: Date.parse('2020-02-01'))
  end

  describe '.build' do
    it 'builds valid attributes from context and enrollment' do
      attributes = described_class.build(
        report: report,
        enrollment: enrollment,
        context: context,
        filter: filter,
        current_income: nil,
        previous_income: nil,
      )

      expect(attributes[:first_name]).to eq('John')
      expect(attributes[:last_name]).to eq('Doe')
      expect(attributes[:age]).to eq(35)
      expect(attributes[:start_of_homelessness]).to eq(Date.parse('2019-12-01'))
      expect(attributes[:move_in_date]).to eq(Date.parse('2020-02-01'))
      expect(attributes[:days_enrolled]).to be_present
    end

    it 'calculates days_enrolled correctly for active client' do
      enrollment.update!(EntryDate: '2020-01-01')
      # Exit is nil, so it uses report end date (2020-12-31)
      attributes = described_class.build(
        report: report,
        enrollment: enrollment,
        context: context,
        filter: filter,
        current_income: nil,
        previous_income: nil,
      )

      expected_days = (Date.parse('2020-12-31') - Date.parse('2020-01-01')).to_i + 1
      expect(attributes[:days_enrolled]).to eq(expected_days)
    end

    it 'calculates days_enrolled correctly for leaver' do
      create(:hud_exit, data_source: data_source, EnrollmentID: enrollment.EnrollmentID, PersonalID: enrollment.PersonalID, ExitDate: '2020-06-01')
      enrollment.reload

      attributes = described_class.build(
        report: report,
        enrollment: enrollment,
        context: context,
        filter: filter,
        current_income: nil,
        previous_income: nil,
      )

      expected_days = (Date.parse('2020-06-01') - Date.parse('2020-01-01')).to_i + 1
      expect(attributes[:days_enrolled]).to eq(expected_days)
    end

    it 'handles income values correctly' do
      current_income = double('IncomeBenefit',
                              id: 100,
                              hud_total_monthly_income: 1500,
                              earned_amount: 1000,
                              information_date: Date.parse('2020-12-01'))

      attributes = described_class.build(
        report: report,
        enrollment: enrollment,
        context: context,
        filter: filter,
        current_income: current_income,
        previous_income: nil,
      )

      expect(attributes[:current_income_benefits_id]).to eq(100)
      expect(attributes[:current_total_income]).to eq(1500)
      expect(attributes[:current_earned_income]).to eq(1000)
      expect(attributes[:current_non_employment_income]).to eq(500)
    end
  end
end
