###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2020
  class QuestionNineteenToTwentyFour < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q19-Q24: Outcomes'.freeze
    QUESTION_TABLE_NUMBER = 'Q19-Q24'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      'Outcomes',
      'At PATH project Start',
      'AT PATH project exit (for clients who were exited from PATH this year – leavers)',
      'At report end date (for clients who were still active in PATH as of report end date – stayers)',
    ].freeze

    ROW_LABELS = [
      '19. Income from any source',
      'Yes',
      'No',
      'Client doesn’t know',
      'Client refused',
      'Data not collected',
      'Total',
      '20. SSI/SSDI',
      'Yes',
      'No',
      '21. Non-cash benefits from any source',
      'Yes',
      'No',
      'Client doesn’t know',
      'Client refused',
      'Data not collected',
      'Total',
      '22. Covered by health insurance',
      'Yes',
      'No',
      'Client doesn’t know',
      'Client refused',
      'Data not collected',
      'Total',
      '23. Medicaid/Medicare',
      'Yes',
      'No',
      '24. All other health insurance',
      'Yes',
      'No',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROW_LABELS,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 31,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Income from any source
      sum = {
        B: [0, []],
        C: [0, []],
        D: [0, []],
      }
      [1, 0, 8, 9, 99].each_with_index do |value, index|
        row_number = index + 3 # Rows 3 - 7

        sum[:B] = accumulate_sum(sum[:B], column_with_value(table_name, 'B' + row_number.to_s, all_members, :income_from_any_source_entry, value))
        sum[:C] = accumulate_sum(sum[:C], column_with_value(table_name, 'C' + row_number.to_s, leavers, :income_from_any_source_exit, value))
        sum[:D] = accumulate_sum(sum[:D], column_with_value(table_name, 'D' + row_number.to_s, stayers, :income_from_any_source_report_end, value))
      end

      [:B, :C, :D].each do |col|
        answer = @report.answer(question: table_name, cell: col.to_s + '8')
        answer.update(summary: sum[col].first)
        answer.add_members(sum[col].last)
      end

      # SSI/SSDI
      cell_with_query(table_name, 'B10', all_members, receiving_ssi_or_ssdi(:incomes_at_entry))
      cell_with_query(table_name, 'C10', leavers, receiving_ssi_or_ssdi(:incomes_at_exit))
      cell_with_query(table_name, 'D10', stayers, receiving_ssi_or_ssdi(:incomes_at_report_end))

      cell_with_query(table_name, 'B11', all_members, not_receiving_ssi_or_ssdi(:incomes_at_entry))
      cell_with_query(table_name, 'C11', leavers, not_receiving_ssi_or_ssdi(:incomes_at_exit))
      cell_with_query(table_name, 'D11', stayers, not_receiving_ssi_or_ssdi(:incomes_at_report_end))

      # Non-cash benefits
      sum = {
        B: [0, []],
        C: [0, []],
        D: [0, []],
      }
      [1, 0, 8, 9, 99].each_with_index do |value, index|
        row_number = index + 13 # Rows 13 - 17

        sum[:B] = accumulate_sum(sum[:B], column_with_value(table_name, 'B' + row_number.to_s, all_members, :benefits_from_any_source_entry, value))
        sum[:C] = accumulate_sum(sum[:C], column_with_value(table_name, 'C' + row_number.to_s, leavers, :benefits_from_any_source_exit, value))
        sum[:D] = accumulate_sum(sum[:D], column_with_value(table_name, 'D' + row_number.to_s, stayers, :benefits_from_any_source_report_end, value))
      end

      [:B, :C, :D].each do |col|
        answer = @report.answer(question: table_name, cell: col.to_s + '18')
        answer.update(summary: sum[col].first)
        answer.add_members(sum[col].last)
      end

      # Health Insurance
      sum = {
        B: [0, []],
        C: [0, []],
        D: [0, []],
      }
      [1, 0, 8, 9, 99].each_with_index do |value, index|
        row_number = index + 20 # Rows 20-24

        sum[:B] = accumulate_sum(sum[:B], column_with_value(table_name, 'B' + row_number.to_s, all_members, :insurance_from_any_source_entry, value))
        sum[:C] = accumulate_sum(sum[:C], column_with_value(table_name, 'C' + row_number.to_s, leavers, :insurance_from_any_source_exit, value))
        sum[:D] = accumulate_sum(sum[:D], column_with_value(table_name, 'D' + row_number.to_s, stayers, :insurance_from_any_source_report_end, value))
      end

      [:B, :C, :D].each do |col|
        answer = @report.answer(question: table_name, cell: col.to_s + '25')
        answer.update(summary: sum[col].first)
        answer.add_members(sum[col].last)
      end

      # Medicaid/Medicare
      cell_with_query(table_name, 'B27', all_members, receiving_medicaid_or_medicare(:incomes_at_entry))
      cell_with_query(table_name, 'C27', leavers, receiving_medicaid_or_medicare(:incomes_at_exit))
      cell_with_query(table_name, 'D27', stayers, receiving_medicaid_or_medicare(:incomes_at_report_end))

      cell_with_query(table_name, 'B28', all_members, not_receiving_medicaid_or_medicare(:incomes_at_entry))
      cell_with_query(table_name, 'C28', leavers, not_receiving_medicaid_or_medicare(:incomes_at_exit))
      cell_with_query(table_name, 'D28', stayers, not_receiving_medicaid_or_medicare(:incomes_at_report_end))

      # Other Health Insurance
      cell_with_query(table_name, 'B30', all_members, receiving_other_health_insurance(:incomes_at_entry))
      cell_with_query(table_name, 'C30', leavers, receiving_other_health_insurance(:incomes_at_exit))
      cell_with_query(table_name, 'D30', stayers, receiving_other_health_insurance(:incomes_at_report_end))

      cell_with_query(table_name, 'B31', all_members, not_receiving_other_health_insurance(:incomes_at_entry))
      cell_with_query(table_name, 'C31', leavers, not_receiving_other_health_insurance(:incomes_at_exit))
      cell_with_query(table_name, 'D31', stayers, not_receiving_other_health_insurance(:incomes_at_report_end))

      @report.complete(QUESTION_NUMBER)
    end

    def accumulate_sum(left, right)
      [left, right].transpose.map { |l, r| l + r }
    end

    def column_with_value(table_name, table_cell, phase, db_column, value)
      answer = @report.answer(question: table_name, cell: table_cell)
      members = universe.members.where(active_and_enrolled_clients).where(phase).where(a_t[db_column].eq(value))
      answer.add_members(members)
      count = members.count
      answer.update(summary: count)
      [count, members.to_a]
    end

    def cell_with_query(table_name, table_cell, phase, query)
      answer = @report.answer(question: table_name, cell: table_cell)
      members = universe.members.where(active_and_enrolled_clients).where(phase).where(query)
      answer.add_members(members)
      count = members.count
      answer.update(summary: count)
    end

    def receiving_ssi_or_ssdi(column)
      jsonb_test(column, 'SSI', 1) + ' OR ' + jsonb_test(column, 'SSDI', 1)
    end

    def not_receiving_ssi_or_ssdi(column)
      jsonb_test(column, 'SSI', 0) + ' AND ' + jsonb_test(column, 'SSDI', 0)
    end

    def receiving_medicaid_or_medicare(column)
      jsonb_test(column, 'Medicaid', 1) + ' OR ' + jsonb_test(column, 'Medicare', 1)
    end

    def not_receiving_medicaid_or_medicare(column)
      jsonb_test(column, 'Medicaid', 0) + ' AND ' + jsonb_test(column, 'Medicare', 0)
    end

    def receiving_other_health_insurance(column)
      [
        'SCHIP',
        'VAMedicalServices',
        'EmployerProvided',
        'COBRA',
        'PrivatePay',
        'StateHealthIns',
        'IndianHealthServices',
      ].map { |type| jsonb_test(column, type, 1) }.join(' OR ')
    end

    def not_receiving_other_health_insurance(column)
      [
        'SCHIP',
        'VAMedicalServices',
        'EmployerProvided',
        'COBRA',
        'PrivatePay',
        'StateHealthIns',
        'IndianHealthServices',
      ].map { |type| jsonb_test(column, type, 0) }.join(' AND ')
    end

    def jsonb_test(column, key, value)
      "#{column} @> '{\"#{key}\": #{value}}'"
    end
  end
end
