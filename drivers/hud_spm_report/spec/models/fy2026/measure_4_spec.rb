###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudSpmReport::Generators::Fy2026::MeasureFour, type: :model, exclude_fixpoints: true do
  include_context 'SPM test setup'

  describe 'income changes for stayers and leavers' do
    before do
      @ph_project = create_project(project_type: 3)
      create(
        :hud_funder,
        project: @ph_project,
        data_source: @ph_project.data_source,
        Funder: HudHelper.util('2026').spm_coc_funders.first,
        StartDate: '2019-01-01'.to_date,
      )

      build_stayer
      build_leaver

      @report = setup_report([@ph_project.id], ['Measure 4'])
      run_measure(@report, described_class)
    end

    it 'registers increased income for system stayers' do
      expect(value_for('4.1', 'C2')).to eq(1)
      expect(value_for('4.1', 'C3')).to eq(1)
      expect(percent_for('4.1', 'C4')).to eq(100.0)

      expect(value_for('4.2', 'C3')).to eq(1)
      expect(percent_for('4.2', 'C4')).to eq(100.0)

      expect(value_for('4.3', 'C3')).to eq(1)
      expect(percent_for('4.3', 'C4')).to eq(100.0)
    end

    it 'registers increased income for system leavers' do
      expect(value_for('4.4', 'C2')).to eq(1)
      expect(value_for('4.4', 'C3')).to eq(1)
      expect(percent_for('4.4', 'C4')).to eq(100.0)

      expect(value_for('4.5', 'C3')).to eq(1)
      expect(percent_for('4.5', 'C4')).to eq(100.0)

      expect(value_for('4.6', 'C3')).to eq(1)
      expect(percent_for('4.6', 'C4')).to eq(100.0)
    end

    private

    def build_stayer
      household_enrollments = []
      build_household(
        projects: [@ph_project],
        entry_date: '2022-01-01'.to_date,
        exit_date: nil,
        members: 1,
      ) do |client, enrollment|
        household_enrollments << { client: client, enrollment: enrollment }
      end

      stayer_enrollment = household_enrollments.first[:enrollment]
      create(
        :hud_income_benefit,
        enrollment: stayer_enrollment,
        data_source: stayer_enrollment.data_source,
        data_collection_stage: 1,
        information_date: stayer_enrollment.entry_date,
        earned_amount: 500,
        other_income_amount: 100,
        total_monthly_income: 600,
      )
      add_income_snapshot(
        enrollment: stayer_enrollment,
        information_date: '2023-01-15'.to_date,
        data_collection_stage: 5,
        earned_amount: 700,
        other_income_amount: 200,
      )
    end

    def build_leaver
      household_enrollments = []
      build_household(
        projects: [@ph_project],
        entry_date: '2023-01-05'.to_date,
        exit_date: '2023-04-05'.to_date,
        members: 1,
      ) do |client, enrollment|
        household_enrollments << { client: client, enrollment: enrollment }
      end

      leaver_enrollment = household_enrollments.first[:enrollment]
      create(
        :hud_income_benefit,
        enrollment: leaver_enrollment,
        data_source: leaver_enrollment.data_source,
        data_collection_stage: 1,
        information_date: leaver_enrollment.entry_date,
        earned_amount: 200,
        other_income_amount: 0,
        total_monthly_income: 200,
      )
      create(
        :hud_income_benefit,
        enrollment: leaver_enrollment,
        data_source: leaver_enrollment.data_source,
        data_collection_stage: 3,
        information_date: leaver_enrollment.exit.exit_date,
        earned_amount: 400,
        other_income_amount: 150,
        total_monthly_income: 550,
      )
    end

    def value_for(table, cell)
      @report.answer(question: table, cell: cell).summary
    end

    def percent_for(table, cell)
      value_for(table, cell).to_f.round(2)
    end
  end
end
