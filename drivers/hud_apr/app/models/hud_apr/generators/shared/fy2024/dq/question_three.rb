###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024::Dq::QuestionThree
  extend ActiveSupport::Concern

  included do
    private def generate_q3(table_name)
      metadata = {
        header_row: [
          'Data Element',
          label_for(:dkptr),
          label_for(:info_missing),
          'Data Issues',
          'Total',
          '% of Issue Rate',
        ],
        row_labels: [
          'Veteran Status (3.07)',
          'Project Start Date (3.10)',
          'Relationship to Head of Household (3.15)',
          'Enrollment CoC (3.16)',
          'Disabling Condition (3.08)',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)
      universe_members = universe.members.where(engaged_clause)

      sheet = question_sheet(question: table_name)
      q3_veteran_row(sheet, universe_members)
      q3_project_row(sheet, universe_members)
      q3_hoh_relationship_row(sheet, universe_members)
      q3_client_location_row(sheet, universe_members)
      q3_disabling_condition_row(sheet, universe_members)
    end

    def q3_veteran_row(sheet, universe_members)
      adult_scope = universe_members.where(adult_clause)
      dkpntr_cell = sheet.update_cell_members(
        cell: 'B2',
        members: adult_scope.where(a_t[:veteran_status].in([8, 9])),
      )
      missing_cell = sheet.update_cell_members(
        cell: 'C2',
        members: adult_scope.where(a_t[:veteran_status].eq(99).or(a_t[:veteran_status].eq(nil))),
      )
      issue_cell = sheet.update_cell_members(
        cell: 'D2',
        members: universe_members.where(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))),
      )

      total_cell = sheet.update_cell_value(cell: 'E2', value: [dkpntr_cell, missing_cell, issue_cell].map(&:value).sum)
      total_cell.add_members([dkpntr_cell, missing_cell, issue_cell].map(&:members).sum([]))
      # Issue Rate
      # Number of adults (age 18 or over) + Number of children (under age 18)
      denominator = universe_members.where(a_t[:age].not_eq(nil)).count.to_f
      sheet.update_cell_value(cell: 'F2', value: percentage(issue_cell.value / denominator))
    end

    def q3_project_row(sheet, universe_members)
      issue_cell = sheet.update_cell_members(
        cell: 'D3',
        members: universe_members.where.not(a_t[:overlapping_enrollments].eq([])),
      )
      total_cell = sheet.update_cell_value(cell: 'E3', value: issue_cell.value)
      total_cell.add_members(issue_cell.members)
      # Issue Rate
      sheet.update_cell_value(cell: 'F3', value: percentage(issue_cell.value / universe_members.count.to_f))
    end

    def q3_hoh_relationship_row(sheet, universe_members)
      households_with_multiple_hohs = []
      households_with_no_hoh = []

      universe_members.preload(:universe_membership).find_each do |member|
        apr_client = member.universe_membership
        count_of_heads = apr_client.household_members.select { |household_member| household_member['relationship_to_hoh'] == 1 }.count
        households_with_multiple_hohs << apr_client.household_id if count_of_heads > 1
        households_with_no_hoh << apr_client.household_id if count_of_heads.zero?
      end

      missing_cell = sheet.update_cell_members(
        cell: 'C4',
        members: universe_members.where(a_t[:relationship_to_hoh].eq(nil)),
      )
      issue_cell = sheet.update_cell_members(
        cell: 'D4',
        members: universe_members.where(
          [
            a_t[:relationship_to_hoh].not_in((1..5).to_a),
            a_t[:household_id].in(households_with_multiple_hohs),
            a_t[:household_id].in(households_with_no_hoh),
          ].inject(&:or),
        ),
      )

      total_cell = sheet.update_cell_value(cell: 'E4', value: missing_cell.value + issue_cell.value)
      total_cell.add_members(missing_cell.members + issue_cell.members)
      # Issue Rate
      sheet.update_cell_value(cell: 'F4', value: percentage(issue_cell.value / universe_members.count.to_f))
    end

    def q3_client_location_row(sheet, universe_members)
      hoh_scope = universe_members.where(hoh_clause)

      valid_cocs = HudUtility2024.cocs.keys
      missing_cell = sheet.update_cell_members(cell: 'C5', members: hoh_scope.where(a_t[:enrollment_coc].eq(nil)))
      issue_cell = sheet.update_cell_members(cell: 'D5', members: hoh_scope.where(a_t[:enrollment_coc].not_in(valid_cocs)))

      # Totals
      total_cell = sheet.update_cell_value(cell: 'E5', value: missing_cell.value + issue_cell.value)
      total_cell.add_members(missing_cell.members + issue_cell.members)

      # Issue Rate
      hoh_denominator = universe_members.where(hoh_clause)
      sheet.update_cell_value(cell: 'F5', value: percentage(issue_cell.value / hoh_denominator.count.to_f))
    end

    def q3_disabling_condition_row(sheet, universe_members)
      dkpntr_cell = sheet.update_cell_members(
        cell: 'B6',
        members: universe_members.where(a_t[:disabling_condition].in([8, 9])),
      )
      missing_cell = sheet.update_cell_members(
        cell: 'C6',
        members: universe_members.where(a_t[:disabling_condition].eq(99).or(a_t[:disabling_condition].eq(99))),
      )

      qualifies_for_disability = [
        a_t[:developmental_disability_latest].eq(1).or(a_t[:hiv_aids_latest].eq(1)),
        a_t[:indefinite_and_impairs].eq(true).and(
          [
            a_t[:physical_disability_latest].eq(1),
            a_t[:chronic_disability_latest].eq(1),
            a_t[:mental_health_problem_latest].eq(1),
            a_t[:substance_abuse_latest].in([1, 2, 3]),
          ].inject(&:or),
        ),
      ].inject(&:or)
      issue_cell = sheet.update_cell_members(
        cell: 'D6',
        members: universe_members.where(a_t[:disabling_condition].eq(0)).where(qualifies_for_disability),
      )

      total_cell = sheet.update_cell_value(cell: 'E6', value: [dkpntr_cell, missing_cell, issue_cell].map(&:value).sum)
      total_cell.add_members([dkpntr_cell, missing_cell, issue_cell].map(&:members).sum([]))
      # Issue Rate
      sheet.update_cell_value(cell: 'F6', value: percentage(total_cell.value / universe_members.count.to_f))
    end
  end
end
