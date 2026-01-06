###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudApr::Generators::Dq::Fy2026::QuestionThree, type: :model, exclude_fixpoints: true do
  include_context 'HUD DQ FY2026 setup'

  describe 'universal data elements data quality' do
    before do
      es_project_type = HudHelper.util('2026').project_type_number_from_code(:es).first
      @project = create_project(project_type: es_project_type)

      # Row 2: Veteran Status (3.07)
      # B2: Adult with Veteran Status 8 or 9
      client_v_8 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1), veteran_status: 8)
      create_enrollment(client: client_v_8, project: @project, entry_date: Date.new(2026, 1, 1))

      # C2: Adult with Veteran Status 99 or nil
      client_v_99 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1), veteran_status: 99)
      create_enrollment(client: client_v_99, project: @project, entry_date: Date.new(2026, 1, 1))

      # D2: Child with Veteran Status 1
      client_v_child = create_client_with_warehouse_link(dob: Date.new(2015, 1, 1), veteran_status: 1)
      create_enrollment(client: client_v_child, project: @project, entry_date: Date.new(2026, 1, 1))

      # Row 3: Project Start Date (3.10)
      # D3: Overlapping enrollments
      client_overlap = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_overlap, project: @project, entry_date: Date.new(2026, 2, 1), exit_date: Date.new(2026, 2, 10))
      create_enrollment(client: client_overlap, project: @project, entry_date: Date.new(2026, 2, 5), exit_date: Date.new(2026, 2, 15))

      # Row 4: Relationship to Head of Household (3.15)
      # C4: Missing (Relationship = nil)
      client_rel_nil = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_rel_nil, project: @project, entry_date: Date.new(2026, 3, 1), relationship_to_ho_h: nil)

      # D4: Data issues (Multiple HoHs)
      client_hoh1 = create_client_with_warehouse_link(veteran_status: 0)
      enr_hoh1 = create_enrollment(client: client_hoh1, project: @project, entry_date: Date.new(2026, 4, 1), relationship_to_ho_h: 1)
      client_hoh2 = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_hoh2, project: @project, entry_date: Date.new(2026, 4, 1), household_id: enr_hoh1.household_id, relationship_to_ho_h: 1)

      # Row 5: Enrollment CoC (3.16)
      # C5: Missing (CoC = nil) for HoH
      client_coc_nil = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_coc_nil, project: @project, entry_date: Date.new(2026, 5, 1), relationship_to_ho_h: 1, enrollment_coc: nil)

      # D5: Data issues (Invalid CoC) for HoH
      client_coc_invalid = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_coc_invalid, project: @project, entry_date: Date.new(2026, 5, 1), relationship_to_ho_h: 1, enrollment_coc: 'XX-999')

      # Row 6: Disabling Condition (3.08)
      # B6: DK/PNR (8/9)
      client_dis_8 = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_dis_8, project: @project, entry_date: Date.new(2026, 6, 1), disabling_condition: 8)

      # C6: Info missing (99)
      client_dis_99 = create_client_with_warehouse_link(veteran_status: 0)
      create_enrollment(client: client_dis_99, project: @project, entry_date: Date.new(2026, 6, 1), disabling_condition: 99)

      # D6: Data issues (Disabling Condition = 0 but has qualifying disability)
      client_dis_issue = create_client_with_warehouse_link(veteran_status: 0)
      enr_dis_issue = create_enrollment(client: client_dis_issue, project: @project, entry_date: Date.new(2026, 6, 1), disabling_condition: 0)
      create_disability(
        enrollment: enr_dis_issue,
        information_date: enr_dis_issue.entry_date,
        disability_type: 5, # Substance abuse
        disability_response: 1, # Yes
        indefinite_and_impairs: 1,
      )

      @report = setup_dq_report([@project.id], ['Question 3'])
      run_dq_question(@report, described_class)
      @table_name = 'Q3'
    end

    it 'counts issues correctly' do
      # Row 2: Veteran Status
      expect(@report.answer(question: @table_name, cell: 'B2').summary).to eq(1) # client_v_8
      expect(@report.answer(question: @table_name, cell: 'C2').summary).to eq(1) # client_v_99
      expect(@report.answer(question: @table_name, cell: 'D2').summary).to eq(1) # client_v_child
      expect(@report.answer(question: @table_name, cell: 'E2').summary).to eq(3)

      # Row 3: Project Start Date
      expect(@report.answer(question: @table_name, cell: 'D3').summary).to eq(1) # client_overlap (only one AprClient record per client)
      expect(@report.answer(question: @table_name, cell: 'E3').summary).to eq(1)

      # Row 4: Relationship to Head of Household
      expect(@report.answer(question: @table_name, cell: 'C4').summary).to eq(1) # client_rel_nil
      expect(@report.answer(question: @table_name, cell: 'D4').summary).to eq(2) # both client_hoh1 and client_hoh2 are in a household with multiple HoHs
      expect(@report.answer(question: @table_name, cell: 'E4').summary).to eq(3)

      # Row 5: Enrollment CoC
      expect(@report.answer(question: @table_name, cell: 'C5').summary).to eq(1) # client_coc_nil
      expect(@report.answer(question: @table_name, cell: 'D5').summary).to eq(1) # client_coc_invalid
      expect(@report.answer(question: @table_name, cell: 'E5').summary).to eq(2)

      # Row 6: Disabling Condition
      expect(@report.answer(question: @table_name, cell: 'B6').summary).to eq(1) # client_dis_8
      expect(@report.answer(question: @table_name, cell: 'C6').summary).to eq(1) # client_dis_99
      expect(@report.answer(question: @table_name, cell: 'D6').summary).to eq(1) # client_dis_issue
      expect(@report.answer(question: @table_name, cell: 'E6').summary).to eq(3)
    end
  end
end
