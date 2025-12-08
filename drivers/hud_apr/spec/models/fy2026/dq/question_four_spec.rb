###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require_relative './shared_context'

RSpec.describe HudApr::Generators::Dq::Fy2026::QuestionFour, type: :model, exclude_fixpoints: true do
  include_context 'HUD DQ FY2026 setup'

  def create_valid_income(enrollment, date, stage)
    create(:hud_income_benefit,
           enrollment: enrollment,
           data_source: enrollment.data_source,
           InformationDate: date,
           IncomeFromAnySource: 0,
           DataCollectionStage: stage)
  end

  describe 'income and housing data quality' do
    before do
      es_project_type = HudHelper.util('2026').project_type_number_from_code(:es).first
      @project = create_project(project_type: es_project_type)

      # Row 2: Destination (3.12)
      # Universe: Leavers (All)

      # Client 1: Destination = 8 (Client doesn't know) -> B2
      # B2: Destination is 8 or 9
      client1 = create_client_with_warehouse_link
      enr1 = create_enrollment(
        client: client1,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: Date.new(2026, 1, 1),
        destination: 8,
      )
      create_valid_income(enr1, enr1.entry_date, 1)
      create_valid_income(enr1, enr1.real_exit_date, 3)

      # Client 2: Destination = 99 (Data not collected) -> C2
      # C2: Destination is 30, 99, or nil
      client2 = create_client_with_warehouse_link
      enr2 = create_enrollment(
        client: client2,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: Date.new(2026, 1, 2),
        destination: 99,
      )
      create_valid_income(enr2, enr2.entry_date, 1)
      create_valid_income(enr2, enr2.real_exit_date, 3)

      # Row 3: Income at Start
      # Universe: Adults and HoHs
      # Client 3: Income = 8 (Client doesn't know) -> B3
      client3 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr3 = create_enrollment(
        client: client3,
        project: @project,
        entry_date: Date.new(2026, 2, 1),
      )
      create(:hud_income_benefit,
             enrollment: enr3,
             data_source: enr3.data_source,
             InformationDate: enr3.entry_date,
             IncomeFromAnySource: 8,
             DataCollectionStage: 1)

      # Client 4: Income Missing (nil) -> C3
      client4 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr4 = create_enrollment(
        client: client4,
        project: @project,
        entry_date: Date.new(2026, 2, 1),
      )
      create(:hud_income_benefit,
             enrollment: enr4,
             data_source: enr4.data_source,
             InformationDate: enr4.entry_date,
             IncomeFromAnySource: nil,
             DataCollectionStage: 1)

      # Client 5: Inconsistent (No income, but source yes) -> D3
      client5 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr5 = create_enrollment(
        client: client5,
        project: @project,
        entry_date: Date.new(2026, 2, 1),
      )
      create(:hud_income_benefit,
             enrollment: enr5,
             data_source: enr5.data_source,
             InformationDate: enr5.entry_date,
             IncomeFromAnySource: 0,
             Earned: 1,
             DataCollectionStage: 1)

      # Row 4: Income at Annual Assessment
      # Universe: Stayers >= 365 days
      # Client 6: AA with Income = 9 (Refused) -> B4
      client6 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr6 = create_enrollment(
        client: client6,
        project: @project,
        entry_date: Date.new(2024, 10, 1), # Entered > 1 year ago
      )
      create_valid_income(enr6, enr6.entry_date, 1)
      # Make sure they are a stayer (active after end date)
      create_bed_night_service(enrollment: enr6, date: Date.new(2026, 10, 1))
      # Anniversary is 2025-10-01
      create(:hud_income_benefit,
             enrollment: enr6,
             data_source: enr6.data_source,
             InformationDate: Date.new(2025, 10, 1),
             IncomeFromAnySource: 9,
             DataCollectionStage: 5)

      # Client 7: AA Missing (no record) -> C4
      client7 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr7 = create_enrollment(
        client: client7,
        project: @project,
        entry_date: Date.new(2024, 10, 1),
      )
      create_valid_income(enr7, enr7.entry_date, 1)
      # Make sure they are a stayer
      create_bed_night_service(enrollment: enr7, date: Date.new(2026, 10, 1))

      # Client 8: Inconsistent AA (Yes but no sources) -> D4
      client8 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr8 = create_enrollment(
        client: client8,
        project: @project,
        entry_date: Date.new(2024, 10, 1),
      )
      create_valid_income(enr8, enr8.entry_date, 1)
      # Make sure they are a stayer
      create_bed_night_service(enrollment: enr8, date: Date.new(2026, 10, 1))
      create(:hud_income_benefit,
             enrollment: enr8,
             data_source: enr8.data_source,
             InformationDate: Date.new(2025, 10, 1),
             IncomeFromAnySource: 1,
             DataCollectionStage: 5)

      # Row 5: Income at Exit
      # Universe: Leavers (Adults/HoH)
      # Client 9: Income at Exit = 8 -> B5
      # Client 9 is adult leaver, should be in universe for B2 and B5
      client9 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr9 = create_enrollment(
        client: client9,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: Date.new(2026, 1, 1),
        destination: 101, # Valid destination (Emergency Shelter)
      )
      create_valid_income(enr9, enr9.entry_date, 1)
      create(:hud_income_benefit,
             enrollment: enr9,
             data_source: enr9.data_source,
             InformationDate: enr9.real_exit_date,
             IncomeFromAnySource: 8,
             DataCollectionStage: 3)

      # Client 10: Income at Exit Inconsistent -> D5
      # Client 10 is adult leaver, should be in universe for B2 (valid dest) and D5
      client10 = create_client_with_warehouse_link(dob: Date.new(1980, 1, 1))
      enr10 = create_enrollment(
        client: client10,
        project: @project,
        entry_date: Date.new(2025, 11, 1),
        exit_date: Date.new(2026, 1, 1),
        destination: 101, # Valid destination (Emergency Shelter)
      )
      create_valid_income(enr10, enr10.entry_date, 1)
      create(:hud_income_benefit,
             enrollment: enr10,
             data_source: enr10.data_source,
             InformationDate: enr10.real_exit_date,
             IncomeFromAnySource: 0,
             Earned: 1,
             DataCollectionStage: 3)

      @report = setup_dq_report([@project.id], ['Question 4'])
      run_dq_question(@report, described_class)
      @table_name = 'Q4'
    end

    it 'counts issues correctly' do
      # Row 2: Destination
      expect(@report.answer(question: @table_name, cell: 'B2').summary).to eq(1) # Client 1

      # C2 issue: Expected 1 (Client 2), got 3.
      # Clients with exit date and destination 30/99/nil.
      # Client 2 has dest 99.
      # Clients 3-8 have no exit date.
      # Clients 9-10 have exit date and dest 1.

      expect(@report.answer(question: @table_name, cell: 'C2').summary).to eq(1) # Client 2

      # E2 (Total) should be 2 (1+1)
      expect(@report.answer(question: @table_name, cell: 'E2').summary).to eq(2)

      # Row 3: Income at Start
      expect(@report.answer(question: @table_name, cell: 'B3').summary).to eq(1) # Client 3
      expect(@report.answer(question: @table_name, cell: 'C3').summary).to eq(1) # Client 4
      expect(@report.answer(question: @table_name, cell: 'D3').summary).to eq(1) # Client 5
      # E3 (Total) should be 3
      expect(@report.answer(question: @table_name, cell: 'E3').summary).to eq(3)

      # Row 4: Income at Annual Assessment
      expect(@report.answer(question: @table_name, cell: 'B4').summary).to eq(1) # Client 6
      expect(@report.answer(question: @table_name, cell: 'C4').summary).to eq(1) # Client 7
      expect(@report.answer(question: @table_name, cell: 'D4').summary).to eq(1) # Client 8
      # E4 (Total) should be 3
      expect(@report.answer(question: @table_name, cell: 'E4').summary).to eq(3)

      # Row 5: Income at Exit
      expect(@report.answer(question: @table_name, cell: 'B5').summary).to eq(1) # Client 9
      # Client 10 is D5.
      expect(@report.answer(question: @table_name, cell: 'D5').summary).to eq(1) # Client 10
      # E5 (Total) should be 2
      expect(@report.answer(question: @table_name, cell: 'E5').summary).to eq(2)
    end
  end
end
