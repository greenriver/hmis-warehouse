###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudApr::Generators::Dq::Fy2026::QuestionTwo, type: :model, exclude_fixpoints: true do
  include_context 'HUD DQ FY2026 setup'

  describe 'personally identifiable information tab' do
    before do
      es_project_type = HudHelper.util('2026').project_type_number_from_code(:es).first
      @project = create_project(project_type: es_project_type)

      name_issue_client = create_client_with_warehouse_link(
        ssn: '521348765',
        dob: Date.new(1988, 3, 3),
        name_data_quality: 8,
        ssn_data_quality: 1,
        dob_data_quality: 1,
      )
      name_issue_client.update!(White: 1)
      name_issue_enrollment = create_enrollment(
        client: name_issue_client,
        project: @project,
        entry_date: Date.new(2025, 12, 1),
        living_situation: 1,
      )
      create_bed_night_service(
        enrollment: name_issue_enrollment,
        date: Date.new(2025, 12, 2),
      )

      ssn_missing_client = create_client_with_warehouse_link(
        first_name: 'Alex',
        last_name: 'NoSsn',
        dob: Date.new(1992, 2, 2),
        ssn: nil,
        ssn_data_quality: 99,
        dob_data_quality: 1,
      )
      ssn_missing_client.update!(White: 1)
      ssn_missing_enrollment = create_enrollment(
        client: ssn_missing_client,
        project: @project,
        entry_date: Date.new(2026, 1, 5),
        living_situation: 1,
      )
      create_bed_night_service(
        enrollment: ssn_missing_enrollment,
        date: Date.new(2026, 1, 6),
      )

      dob_race_issue_client = create_client_with_warehouse_link(
        first_name: 'Casey',
        last_name: 'Quality',
        ssn: '529874123',
        ssn_data_quality: 1,
        dob: Date.new(1990, 1, 1),
        dob_data_quality: 2,
      )
      dob_race_issue_client.update!(RaceNone: 99)
      dob_race_issue_enrollment = create_enrollment(
        client: dob_race_issue_client,
        project: @project,
        entry_date: Date.new(2026, 2, 10),
        living_situation: 1,
      )
      create_bed_night_service(
        enrollment: dob_race_issue_enrollment,
        date: Date.new(2026, 2, 11),
      )

      @report = setup_dq_report([@project.id], ['Question 2'])
      run_dq_question(@report, described_class)
      @table_name = 'Q2'
    end

    it 'categorizes missing and invalid data correctly' do
      expect(@report.answer(question: @table_name, cell: 'B2').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'C3').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'D4').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'C5').summary).to eq(1)
      expect(@report.answer(question: @table_name, cell: 'E6').summary).to eq(3)
    end
  end
end
