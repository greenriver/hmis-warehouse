###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionSix < Base
    QUESTION_NUMBER = 'Question 6'.freeze

    def self.table_descriptions
      {
        'Question 6' => 'Data Quality',
        'Q6a' => 'Data Quality: Personally Identifiable Information',
        'Q6b' => 'Data Quality: Universal Data Elements',
        'Q6c' => 'Data Quality: Income and Housing Data Quality',
        'Q6d' => 'Data Quality: Chronic Homelessness',
        'Q6e' => 'Data Quality: Timeliness',
        'Q6f' => 'Data Quality: Inactive Records: Street Outreach and Emergency Shelter',
      }.freeze
    end

    private def dq_universe_members
      universe.members.where(engaged_clause)
    end

    private def q6a_pii
      table_name = 'Q6a'
      metadata = {
        header_row: [
          'Data Element',
          label_for(:dkptr),
          'Information Missing',
          'Data Issues',
          'Total',
          '% of Error Rate',
        ],
        row_labels: [
          'Name (3.01)',
          'Social Security Number (3.02)',
          'Date of Birth (3.03)',
          'Race/Ethnicity (3.04)',
          'Gender (3.06)',
          'Overall Score',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 7,
      }

      @report.answer(question: table_name).update(metadata: metadata)

      clients = name_quality(table_name: table_name)
      # NOTE: These "x_quality" methods are writing report data
      clients = clients.or(ssn_quality(table_name: table_name))
      clients = clients.or(dob_quality(table_name: table_name))
      clients = clients.or(race_and_ethnicity_quality(table_name: table_name))
      # clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :ethnicity))
      clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :gender_multi))

      count = clients.distinct.count
      @report.answer(question: table_name, cell: 'E7').update(summary: count)
      @report.answer(question: table_name, cell: 'F7').update(summary: percentage(count / dq_universe_members.count.to_f))
    end

    private def name_quality(table_name:)
      # Name DK/R
      answer = @report.answer(question: table_name, cell: 'B2')
      dkr_members = dq_universe_members.where(a_t[:name_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Name missing
      # Name DQ 99 or name missing and we didn't already count it for DK/R
      answer = @report.answer(question: table_name, cell: 'C2')
      m_members = dq_universe_members.where(
        a_t[:name_quality].eq(99).or(
          a_t[:name_quality].not_in([8, 9]).
            and(
              a_t[:first_name].eq(nil).
                or(a_t[:last_name].eq(nil)),
            ),
        ),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Name quality
      answer = @report.answer(question: table_name, cell: 'D2')
      q_members = dq_universe_members.where(a_t[:name_quality].eq(2))
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E2')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: percentage(total_members.count / dq_universe_members.count.to_f))

      total_members
    end

    private def ssn_quality(table_name:)
      # SSN DK/R
      answer = @report.answer(question: table_name, cell: 'B3')
      dkr_members = dq_universe_members.where(a_t[:ssn_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # SSN missing
      answer = @report.answer(question: table_name, cell: 'C3')
      m_members = dq_universe_members.where(
        a_t[:ssn].eq(nil).and(a_t[:ssn_quality].not_in([8, 9])).
          or(a_t[:ssn_quality].eq(99)),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # SSN quality
      answer = @report.answer(question: table_name, cell: 'D3')
      q_member_ids = []
      dq_universe_members.preload(:universe_membership).find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.ssn_quality == 2 ||
          (member.ssn_quality == 1 && member.ssn.present? && !HudUtility2024.valid_social?(member.ssn))
      end
      q_members = dq_universe_members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E3')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: percentage(total_members.count / dq_universe_members.count.to_f))

      total_members
    end

    private def dob_quality(table_name:)
      # DOB DK/R
      answer = @report.answer(question: table_name, cell: 'B4')
      dkr_members = dq_universe_members.where(
        a_t[:dob].eq(nil).and(a_t[:dob_quality].in([8, 9])),
      )
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # DOB missing
      answer = @report.answer(question: table_name, cell: 'C4')
      m_members = dq_universe_members.where(
        a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # DOB quality
      answer = @report.answer(question: table_name, cell: 'D4')
      q_member_ids = []
      dq_universe_members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.dob_quality == 2 ||
          (member.dob_quality == 1 && !valid_dob?(member)) ||
          (member.dob_quality.in?([8, 9, 99]) && member.dob.present?) ||
          (member.dob.present? && member.dob > member.client_created_at)
      end
      q_members = dq_universe_members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E4')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: percentage(total_members.count / dq_universe_members.count.to_f))

      total_members
    end

    private def valid_dob?(member)
      return true if member.dob.blank? # Was counted in missing

      return false if member.dob < '1915-01-01'.to_date
      return false if member.dob > member.enrollment_created
      return false if member.head_of_household && member.dob > member.first_date_in_program

      true
    end

    private def race_and_ethnicity_quality(table_name:)
      # in 2024, race and ethnicity are the same column
      race_col = a_t[:race_multi]

      # Race DK/R / compute missing
      answer = @report.answer(question: table_name, cell: 'B5')

      dkr_members = dq_universe_members.where(race_col.in(['8', '9']))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Race missing
      answer = @report.answer(question: table_name, cell: 'C5')
      m_members = dq_universe_members.where(race_col.eq('99'))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E5')
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: percentage(total_members.count / dq_universe_members.count.to_f))

      total_members
    end

    private def simple_quality(table_name:, row:, attr:)
      row_label = row.to_s
      # DK/R
      answer = @report.answer(question: table_name, cell: 'B' + row_label)
      dkr_members = dq_universe_members.where(a_t[attr].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Missing
      answer = @report.answer(question: table_name, cell: 'C' + row_label)
      m_members = dq_universe_members.where(
        a_t[attr].eq(nil).
          or(a_t[attr].eq(99)),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E' + row_label)
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F' + row_label)
      answer.update(summary: percentage(total_members.count / dq_universe_members.count.to_f))

      total_members
    end

    ###
    # Q6b
    ###

    def q6b_universal_data_elements
      table_name = 'Q6b'
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

      sheet = question_sheet(question: table_name)
      q6b_veteran_row(sheet)
      q6b_project_row(sheet)
      q6b_hoh_relationship_row(sheet)
      q6b_client_location_row(sheet)
      q6b_disabling_condition_row(sheet)
    end

    def q6b_veteran_row(sheet)
      adult_scope = dq_universe_members.where(adult_clause)
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
        members: dq_universe_members.where(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))),
      )

      total_cell = sheet.update_cell_value(cell: 'E2', value: [dkpntr_cell, missing_cell, issue_cell].map(&:value).sum)
      total_cell.add_members([dkpntr_cell, missing_cell, issue_cell].map(&:members).sum)
      # Issue Rate
      # Number of adults (age 18 or over) + Number of children (under age 18)
      denominator = dq_universe_members.where(a_t[:age].not_eq(nil)).count.to_f
      sheet.update_cell_value(cell: 'F2', value: percentage(issue_cell.value / denominator))
    end

    def q6b_project_row(sheet)
      issue_cell = sheet.update_cell_members(
        cell: 'D3',
        members: dq_universe_members.where.not(a_t[:overlapping_enrollments].eq([])),
      )
      total_cell = sheet.update_cell_value(cell: 'E3', value: issue_cell.value)
      total_cell.add_members(issue_cell.members)
      # Issue Rate
      sheet.update_cell_value(cell: 'F3', value: percentage(issue_cell.value / dq_universe_members.count.to_f))
    end

    def q6b_hoh_relationship_row(sheet)
      households_with_multiple_hohs = []
      households_with_no_hoh = []

      dq_universe_members.preload(:universe_membership).find_each do |member|
        apr_client = member.universe_membership
        count_of_heads = apr_client.household_members.select { |household_member| household_member['relationship_to_hoh'] == 1 }.count
        households_with_multiple_hohs << apr_client.household_id if count_of_heads > 1
        households_with_no_hoh << apr_client.household_id if count_of_heads.zero?
      end

      missing_cell = sheet.update_cell_members(
        cell: 'C4',
        members: dq_universe_members.where(a_t[:relationship_to_hoh].eq(nil)),
      )
      issue_cell = sheet.update_cell_members(
        cell: 'D4',
        members: dq_universe_members.where(
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
      sheet.update_cell_value(cell: 'F4', value: percentage(issue_cell.value / dq_universe_members.count.to_f))
    end

    def q6b_client_location_row(sheet)
      hoh_scope = dq_universe_members.where(hoh_clause)

      missing_cell = sheet.update_cell_members(cell: 'C5', members: hoh_scope.where(a_t[:enrollment_coc].eq(nil)))
      issue_cell = sheet.update_cell_members(cell: 'D5', members: hoh_scope.where(a_t[:enrollment_coc].not_in(HudUtility2024.cocs.keys)))

      # Totals
      total_cell = sheet.update_cell_value(cell: 'E5', value: missing_cell.value + issue_cell.value)
      total_cell.add_members(missing_cell.members + issue_cell.members)

      # Issue Rate
      hoh_denominator = dq_universe_members.where(hoh_clause)
      sheet.update_cell_value(cell: 'F5', value: percentage(issue_cell.value / hoh_denominator.count.to_f))
    end

    def q6b_disabling_condition_row(sheet)
      dkpntr_cell = sheet.update_cell_members(
        cell: 'B6',
        members: dq_universe_members.where(a_t[:disabling_condition].in([8, 9])),
      )
      missing_cell = sheet.update_cell_members(
        cell: 'C6',
        members: dq_universe_members.where(a_t[:disabling_condition].eq(99).or(a_t[:disabling_condition].eq(99))),
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
        members: dq_universe_members.where(a_t[:disabling_condition].eq(0)).where(qualifies_for_disability),
      )

      total_cell = sheet.update_cell_value(cell: 'E6', value: [dkpntr_cell, missing_cell, issue_cell].map(&:value).sum)
      total_cell.add_members([dkpntr_cell, missing_cell, issue_cell].map(&:members).sum)
      # Issue Rate
      sheet.update_cell_value(cell: 'F6', value: percentage(issue_cell.value / dq_universe_members.count.to_f))
    end

    ###
    # Q6c
    ###

    private def q6c_income_and_housing # rubocop:disable Metrics/AbcSize
      table_name = 'Q6c'
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
          'Destination (3.12)',
          'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment',
          'Income and Sources (4.02) at Exit',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # destinations
      leavers = dq_universe_members.where(leavers_clause)

      answer = @report.answer(question: table_name, cell: 'B2')
      members = leavers.where(a_t[:destination].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      members = leavers.where(
        a_t[:destination].in([30, 99]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # D2 does not have programming specs
      #
      answer = @report.answer(question: table_name, cell: 'E2')
      members = leavers.where(
        a_t[:destination].in([8, 9, 30, 99]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: percentage(members.count / leavers.count.to_f))

      # incomes
      adults_and_hohs = dq_universe_members.where(adult_or_hoh_clause)
      # income at start
      answer = @report.answer(question: table_name, cell: 'B3')
      members = adults_and_hohs.where(a_t[:income_from_any_source_at_start].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([99])).
          or(a_t[:income_from_any_source_at_start].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D3')
      members = adults_and_hohs.where(
        a_t[:income_from_any_source_at_start].eq(0). # any says no, but there is a source
          and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql)).
        or(
          a_t[:income_from_any_source_at_start].eq(1). # any says yes, but no sources
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_start].eq(nil)).
          or(a_t[:income_from_any_source_at_start].eq(0). # any says no, but there is a source
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql))).
          or(a_t[:income_from_any_source_at_start].eq(1). # any says yes, but no sources
            and(income_jsonb_clause(1, a_t[:income_sources_at_start].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: percentage(members.count / adults_and_hohs.count.to_f))

      # income at anniversary
      stayers_with_anniversary = adults_and_hohs.where(
        a_t[:annual_assessment_expected].eq(true).
          and(stayers_clause),
      )

      answer = @report.answer(question: table_name, cell: 'B4')
      members = stayers_with_anniversary.where(a_t[:income_from_any_source_at_annual_assessment].in([8, 9]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([99])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D4')
      members = stayers_with_anniversary.where(
        a_t[:income_from_any_source_at_annual_assessment].eq(0).
          and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql)).
        or(
          a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql))).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: percentage(members.count / stayers_with_anniversary.count.to_f))

      # income at exit
      leavers = adults_and_hohs.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B5')
      members = leavers.where(a_t[:income_from_any_source_at_exit].in([8, 9, 99]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([99])).
          or(a_t[:income_from_any_source_at_exit].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'D5')
      members = leavers.where(
        a_t[:income_from_any_source_at_exit].eq(0).
          and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql)).
        or(
          a_t[:income_from_any_source_at_exit].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql, negation: true)),
        ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'E5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([8, 9, 99])).
          or(a_t[:income_from_any_source_at_exit].eq(nil)).
          or(a_t[:income_from_any_source_at_exit].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql))).
          or(a_t[:income_from_any_source_at_exit].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_exit].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: percentage(members.count / leavers.count.to_f))
    end

    private def q6d_chronic_homelessness
      table_name = 'Q6d'
      metadata = {
        header_row: [
          'Entering into project type',
          'Count of total records',
          'Missing time in institution (3.917.2)',
          'Missing time in housing (3.917.2)',
          'Approximate date this episode started (3.917.3) DK/PNTA/missing',
          'Number of times (3.917.4) DK/PNTA/missing',
          'Number of months (3.917.5) DK/PNTA/missing',
          '% of records unable to calculate',
        ],
        row_labels: [
          'ES-EE, ES-NbN, SH, Street Outreach',
          'TH',
          'PH (all)',
          'CE',
          'SSO, Day Shelter, HP',
          'Total',
        ],
        first_column: 'B',
        last_column: 'H',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      adults_and_hohs = dq_universe_members.where(
        a_t[:project_type].in([0, 1, 4, 8, 2, 3, 9, 10, 13]).
          and(a_t[:first_date_in_program].gt(Date.parse('2016-10-01')).
            and(a_t[:age].gteq(18).
              or(a_t[:head_of_household].eq(true).
                and(a_t[:age].lt(18).
                  or(a_t[:age].eq(nil)))))),
      )

      es_sh_so_clients = es_sh_so(table_name, adults_and_hohs)
      th_clients = project_type_row(table_name, adults_and_hohs, row_number: 3, project_types: [2])
      ph_clients = project_type_row(table_name, adults_and_hohs, row_number: 4, project_types: [3, 9, 10, 13])
      ce_clients = project_type_row(table_name, adults_and_hohs, row_number: 5, project_types: [14])
      sso_clients = project_type_row(table_name, adults_and_hohs, row_number: 6, project_types: [6, 11, 12])

      # totals
      answer = @report.answer(question: table_name, cell: 'B7')
      answer.add_members(adults_and_hohs)
      answer.update(summary: adults_and_hohs.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H7')
      total_members = es_sh_so_clients.
        or(th_clients).
        or(ph_clients).
        or(ce_clients).
        or(sso_clients)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)
      answer.update(summary: percentage(total_members.count / adults_and_hohs.count.to_f))
    end

    private def es_sh_so(table_name, adults_and_hohs)
      es_sh_so = adults_and_hohs.where(a_t[:project_type].in([0, 1, 4, 8]))

      # count
      answer = @report.answer(question: table_name, cell: 'B2')
      members = es_sh_so
      answer.add_members(members)
      answer.update(summary: members.count)

      # date homeless missing
      answer = @report.answer(question: table_name, cell: 'E2')
      date_homeless_members = es_sh_so.where(a_t[:date_homeless].eq(nil))
      answer.add_members(date_homeless_members)
      answer.update(summary: date_homeless_members.count)

      # times homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'F2')
      times_homeless_members = es_sh_so.where(
        a_t[:times_homeless].in([8, 9, 99]).
          or(a_t[:times_homeless].eq(nil)),
      )
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G2')
      months_homeless_members = es_sh_so.where(
        a_t[:months_homeless].in([8, 9, 99]).
          or(a_t[:months_homeless].eq(nil)),
      )
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H2')
      members = date_homeless_members.
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: percentage(members.count / es_sh_so.count.to_f))

      members
    end

    private def project_type_row(table_name, adults_and_hohs, row_number:, project_types:)
      scope = adults_and_hohs.where(a_t[:project_type].in(project_types))
      buckets = [
        # count
        {
          cell: "B#{row_number}",
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # missing time in institution
        {
          cell: "C#{row_number}",
          clause: a_t[:prior_living_situation].in((200..299).to_a).
            and(a_t[:prior_length_of_stay].in([8, 9, 99]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # missing time in housing
        # FIXME
        {
          cell: "D#{row_number}",
          clause: a_t[:prior_living_situation].in((0..99).to_a + (300..499).to_a).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([8, 9, 99]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # date homeless missing
        {
          cell: "E#{row_number}",
          clause: residence_restriction.and(a_t[:date_homeless].eq(nil)),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: "F#{row_number}",
          clause: residence_restriction.and(
            a_t[:times_homeless].in([8, 9, 99]).
            or(a_t[:times_homeless].eq(nil)),
          ),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: "G#{row_number}",
          clause: residence_restriction.and(
            a_t[:months_homeless].in([8, 9, 99]).
            or(a_t[:months_homeless].eq(nil)),
          ),
          include_in_percent: true,
        },
      ]
      buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = scope.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: "H#{row_number}")
      ors = buckets.select { |m| m[:include_in_percent] }.map do |cell|
        "(#{cell[:clause].to_sql})"
      end
      members = scope.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / scope.count.to_f))

      members
    end

    private def residence_restriction
      @residence_restriction ||= a_t[:prior_living_situation].in((100..199).to_a).
        or(
          a_t[:prior_living_situation].in((200..299).to_a).
            and(a_t[:prior_length_of_stay].in([10, 11, 2, 3])).
            and(a_t[:came_from_street_last_night].eq(1)),
        ).
        or(
          a_t[:prior_living_situation].in((0..99).to_a + (300..499).to_a).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([10, 11])).
            and(a_t[:came_from_street_last_night].eq(1)),
        )
    end

    private def q6e_timeliness
      table_name = 'Q6e'
      metadata = {
        header_row: [
          'Time for Record Entry',
          'Number of Project Start Records',
          'Number of Project Exit Records',
        ],
        row_labels: [
          '< 0 days',
          '0 days',
          '1-3 days',
          '4-6 days',
          '7-10 days',
          '11+ days',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 7,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      arrivals = dq_universe_members.where(a_t[:first_date_in_program].gteq(@report.start_date))

      [
        {
          cell: 'B2',
          clause: a_t[:first_date_in_program].gt(a_t[:enrollment_created]).and(a_t[:first_date_in_program].gteq(@report.start_date)),
        },
        # entry on date
        {
          cell: 'B3',
          clause: a_t[:first_date_in_program].eq(a_t[:enrollment_created]),
        },
        # entry 1..3 days
        {
          cell: 'B4',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gt(0).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(3)),
        },
        # entry 4..6 days
        {
          cell: 'B5',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'B6',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'B7',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = arrivals.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      leavers = dq_universe_members.where.not(a_t[:last_date_in_program].eq(nil))

      [
        {
          cell: 'C2',
          # It's possible we don't need the report start criteria, there's a current bug in the Test Kit
          # https://airtable.com/appFAz3WpgFmIJMm6/shr8TvO6KfAZ3mOJd/tblYhwasMJptw5fjj/viw7VMUmDdyDL70a7/recQoBOA5VwRFp8jJ
          clause: a_t[:last_date_in_program].gt(a_t[:exit_created]).and(a_t[:exit_created].gteq(@report.start_date)),
        },
        # exit on date
        {
          cell: 'C3',
          clause: a_t[:last_date_in_program].eq(a_t[:exit_created]),
        },
        # exit 1..3 days
        {
          cell: 'C4',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gt(0).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(3)),
        },
        # exit 4..6 days
        {
          cell: 'C5',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'C6',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'C7',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = leavers.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end
    end

    private def q6f_inactive_records
      table_name = 'Q6f'
      metadata = {
        header_row: [
          'Data Element',
          '# of Records',
          '# of Inactive Records',
          '# % of Inactive Records',
        ],
        row_labels: [
          'Contact (Adults and Heads of Household in Street Outreach or ES - NBN)',
          'Bed Night (All clients in ES - NBN)',
        ],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Clients whose enrollment date is more than 90 days before the end of the report, and are still
      # enrolled until after the reporting period
      relevant_clients = universe.universe_members.joins(:apr_client).
        joins(report_cell: :report_instance).
        where(
          datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:first_date_in_program]).gteq(90).
            and(
              a_t[:last_date_in_program].eq(nil).
                or(a_t[:last_date_in_program].gt(@report.end_date)),
            ),
        )

      # Relevant Adults and HoH ES-NBN or SO
      answer = @report.answer(question: table_name, cell: 'B2')
      adults_and_hohs = relevant_clients.where(adult_or_hoh_clause)

      es_so_members = adults_and_hohs.where(
        a_t[:project_type].eq(4).
          and(a_t[:date_of_engagement].lt(@report.end_date).or(a_t[:date_of_engagement].eq(nil))).
          or(a_t[:project_type].eq(1).
            and(a_t[:project_tracking_method].eq(3))),
      )
      answer.add_members(es_so_members)
      answer.update(summary: es_so_members.count)

      # Inactive ES or SO
      answer = @report.answer(question: table_name, cell: 'C2')

      # inactive_es_so_members is based on ids so that 'or' works.
      es_so_member_ids = []
      es_so_members.find_each do |member|
        first_date_in_program = member.universe_membership.first_date_in_program
        next if first_date_in_program > @report.end_date - 90.days # Less than 90 days in report period

        last_current_living_situation = [
          member.universe_membership.hud_report_apr_living_situations.maximum(:information_date),
          first_date_in_program,
        ].compact.max
        es_so_member_ids << member.id if (@report.end_date - last_current_living_situation).to_i > 90
      end

      inactive_es_so_members = es_so_members.where(id: es_so_member_ids)
      answer.add_members(inactive_es_so_members)
      answer.update(summary: inactive_es_so_members.count)

      # percent inactive ES or SO
      answer = @report.answer(question: table_name, cell: 'D2')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: percentage(inactive_es_so_members.count / es_so_members.count.to_f))

      # Relevant ES-NBN
      answer = @report.answer(question: table_name, cell: 'B3')
      es_members = relevant_clients.where(
        a_t[:project_type].eq(1).
          and(a_t[:project_tracking_method].eq(3)),
      )
      answer.add_members(es_members)
      answer.update(summary: es_members.count)

      # Inactive ES
      answer = @report.answer(question: table_name, cell: 'C3')
      inactive_es_members = es_members.where(
        datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:date_of_last_bed_night]).gt(90),
      )
      answer.add_members(inactive_es_members)
      answer.update(summary: inactive_es_members.count)

      # percent inactive ES
      answer = @report.answer(question: table_name, cell: 'D3')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: percentage(inactive_es_members.count / es_members.count.to_f))
    end
  end
end
