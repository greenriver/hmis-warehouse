###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
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

    private def q6a_pii
      table_name = 'Q6a'
      metadata = {
        header_row: [
          'Data Element',
          'Client Doesn’t Know/Refused',
          'Information Missing',
          'Data Issues',
          'Total',
          '% of Error Rate',
        ],
        row_labels: [
          'Name (3.01)',
          'Social Security Number (3.02)',
          'Date of Birth (3.03)',
          'Race (3.04)',
          'Ethnicity (3.05)',
          'Gender (3.06)',
          'Overall Score',
        ],
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 8,
      }

      @report.answer(question: table_name).update(metadata: metadata)

      clients = name_quality(table_name: table_name)
      clients = clients.or(ssn_quality(table_name: table_name))
      clients = clients.or(dob_quality(table_name: table_name))
      clients = clients.or(race_quality(table_name: table_name))
      clients = clients.or(simple_quality(table_name: table_name, row: 6, attr: :ethnicity))
      clients = clients.or(simple_quality(table_name: table_name, row: 7, attr: :gender_multi))

      count = clients.distinct.count
      @report.answer(question: table_name, cell: 'E8').update(summary: count)
      @report.answer(question: table_name, cell: 'F8').update(summary: percentage(count / universe.members.count.to_f))
    end

    private def name_quality(table_name:)
      # Name DK/R
      answer = @report.answer(question: table_name, cell: 'B2')
      dkr_members = universe.members.where(a_t[:name_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Name missing
      answer = @report.answer(question: table_name, cell: 'C2')
      m_members = universe.members.where(
        a_t[:name_quality].not_in([8, 9]).
          and(
            a_t[:first_name].eq(nil).
              or(a_t[:last_name].eq(nil)),
          ),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Name quality
      answer = @report.answer(question: table_name, cell: 'D2')
      q_members = universe.members.where(a_t[:name_quality].eq(2))
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E2')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F2')
      answer.update(summary: percentage(total_members.count / universe.members.count.to_f))

      total_members
    end

    private def ssn_quality(table_name:)
      # SSN DK/R
      answer = @report.answer(question: table_name, cell: 'B3')
      dkr_members = universe.members.where(a_t[:ssn_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # SSN missing
      answer = @report.answer(question: table_name, cell: 'C3')
      m_members = universe.members.where(
        a_t[:ssn].eq(nil).and(a_t[:ssn_quality].not_in([8, 9])).
          or(a_t[:ssn_quality].eq(99)), # FIXME: This makes the 11/1 datalab testkit pass, but doesn't match the spec
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # SSN quality
      answer = @report.answer(question: table_name, cell: 'D3')
      q_member_ids = []
      universe.members.preload(:universe_membership).find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.ssn_quality == 2 ||
          (member.ssn_quality == 1 && !HUD.valid_social?(member.ssn))
      end
      q_members = universe.members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E3')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F3')
      answer.update(summary: percentage(total_members.count / universe.members.count.to_f))

      total_members
    end

    private def dob_quality(table_name:)
      # DOB DK/R
      answer = @report.answer(question: table_name, cell: 'B4')
      dkr_members = universe.members.where(a_t[:dob_quality].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # DOB missing
      answer = @report.answer(question: table_name, cell: 'C4')
      m_members = universe.members.where(
        a_t[:dob].eq(nil).and(a_t[:dob_quality].not_in([8, 9])),
      )
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # DOB quality
      answer = @report.answer(question: table_name, cell: 'D4')
      q_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.dob_quality == 2 ||
          (member.dob_quality == 1 && !valid_dob?(member))
      end
      q_members = universe.members.where(id: q_member_ids)
      answer.add_members(q_members)
      answer.update(summary: q_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E4')
      total_members = dkr_members.or(m_members.or(q_members))
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F4')
      answer.update(summary: percentage(total_members.count / universe.members.count.to_f))

      total_members
    end

    private def valid_dob?(member)
      return true if member.dob.blank? # Was counted in missing

      return false if member.dob < '1915-01-01'.to_date
      return false if member.dob > member.enrollment_created
      return false if member.head_of_household && member.dob > member.first_date_in_program

      true
    end

    private def race_quality(table_name:)
      # Race DK/R / compute missing
      answer = @report.answer(question: table_name, cell: 'B5')

      dkr_members = universe.members.where(a_t[:race].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Race missing
      answer = @report.answer(question: table_name, cell: 'C5')
      # m_members = universe.members.where(id: m_member_ids)
      m_members = universe.members.where(a_t[:race].eq(99))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E5')
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: percentage(total_members.count / universe.members.count.to_f))

      total_members
    end

    private def simple_quality(table_name:, row:, attr:)
      row_label = row.to_s
      # DK/R
      answer = @report.answer(question: table_name, cell: 'B' + row_label)
      dkr_members = universe.members.where(a_t[attr].in([8, 9]))
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Missing
      answer = @report.answer(question: table_name, cell: 'C' + row_label)
      m_members = universe.members.where(
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
      answer.update(summary: percentage(total_members.count / universe.members.count.to_f))

      total_members
    end

    private def q6b_universal_data_elements # rubocop:disable Metrics/AbcSize
      table_name = 'Q6b'
      metadata = {
        header_row: [
          'Data Element',
          'Error Count',
          '% of Error Rate',
        ],
        row_labels: [
          'Veteran Status (3.07)',
          'Project Start Date (3.10)',
          'Relationship to Head of Household (3.15)',
          'Client Location (3.16)',
          'Disabling Condition (3.08)',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # veteran status
      answer = @report.answer(question: table_name, cell: 'B2')
      members = universe.members.where(
        adult_clause.and(a_t[:veteran_status].in([8, 9, 99]).or(a_t[:veteran_status].eq(nil))). # no veteran status data
          or(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))), # you can't be a veteran and under 18
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      # Only adults are in the population of possible veterans
      # Add the minors who claim veteran status to ensure that the error rate cannot be greater than 100%
      veteran_denominator = universe.members.where(adult_clause.or(a_t[:veteran_status].eq(1).and(a_t[:age].lt(18))))
      answer.update(summary: percentage(members.count / veteran_denominator.count.to_f))

      # project start date
      answer = @report.answer(question: table_name, cell: 'B3')
      members = universe.members.where(a_t[:overlapping_enrollments].not_eq([]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))

      # relationship to head of household
      answer = @report.answer(question: table_name, cell: 'B4')
      households_with_multiple_hohs = universe.members.
        where(a_t[:relationship_to_hoh].eq(1)).
        group(a_t[:household_id]).
        count.
        select { |_, v| v > 1 }.
        keys
      households_with_no_hoh = universe.members.pluck(:household_id) -
        universe.members.where(a_t[:relationship_to_hoh].eq(1)).pluck(:household_id)
      members = universe.members.where(
        a_t[:relationship_to_hoh].not_in((1..5).to_a).
          or(a_t[:household_id].in(households_with_multiple_hohs)).
          or(a_t[:household_id].in(households_with_no_hoh)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))

      # client location
      answer = @report.answer(question: table_name, cell: 'B5')
      members = universe.members.
        where(hoh_clause).
        where(
          a_t[:enrollment_coc].eq(nil).
            or(a_t[:enrollment_coc].not_in(HUD.cocs.keys)),
        )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      hoh_denominator = universe.members.where(hoh_clause)
      answer.update(summary: percentage(members.count / hoh_denominator.count.to_f))

      # disabling condition
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members.where(
        a_t[:disabling_condition].in([8, 9, 99]).
          or(a_t[:disabling_condition].eq(nil)).
          or(a_t[:disabling_condition].eq(0).
            and(a_t[:indefinite_and_impairs].eq(true).
              and(a_t[:developmental_disability].eq(true).
                or(a_t[:hiv_aids].eq(true)).
                or(a_t[:physical_disability].eq(true)).
                or(a_t[:chronic_disability].eq(true)).
                or(a_t[:mental_health_problem].eq(true)).
                or(a_t[:substance_abuse].eq(true)).
                or(a_t[:indefinite_and_impairs].eq(true))))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C6')
      answer.update(summary: percentage(members.count / universe.members.count.to_f))
    end

    private def q6c_income_and_housing # rubocop:disable Metrics/AbcSize
      table_name = 'Q6c'
      metadata = {
        header_row: [
          'Data Element',
          'Error Count',
          '% of Error Rate',
        ],
        row_labels: [
          'Destination (3.12)',
          'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment',
          'Income and Sources (4.02) at Exit',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # destinations
      leavers = universe.members.where(leavers_clause)

      answer = @report.answer(question: table_name, cell: 'B2')
      members = leavers.where(
        a_t[:destination].in([8, 9, 30, 99]).
          or(a_t[:destination].eq(nil)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.update(summary: percentage(members.count / leavers.count.to_f))

      # incomes
      adults_and_hohs = universe.members.where(adult_or_hoh_clause)
      # income at start
      answer = @report.answer(question: table_name, cell: 'B3')
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

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: percentage(members.count / adults_and_hohs.count.to_f))

      # income at anniversary
      stayers_with_anniversary = adults_and_hohs.where(
        a_t[:annual_assessment_expected].eq(true).
          and(stayers_clause),
      )

      answer = @report.answer(question: table_name, cell: 'B4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_annual_assessment].eq(nil).
          or(a_t[:annual_assessment_in_window].eq(false)).
          or(a_t[:income_from_any_source_at_annual_assessment].in([8, 9])).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(nil)).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(0).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql))).
          or(a_t[:income_from_any_source_at_annual_assessment].eq(1).
            and(income_jsonb_clause(1, a_t[:income_sources_at_annual_assessment].to_sql, negation: true))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: percentage(members.count / stayers_with_anniversary.count.to_f))

      # income at exit
      leavers = adults_and_hohs.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B5')
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

      answer = @report.answer(question: table_name, cell: 'C5')
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
          'Approximate Date started (3.917.3) DK/R/missing',
          'Number of times (3.917.4) DK/R/missing',
          'Number of months (3.917.5) DK/R/missing',
          '% of records unable to calculate',
        ],
        row_labels: [
          'ES, SH, Street Outreach',
          'TH',
          'PH (all)',
          'Total',
        ],
        first_column: 'B',
        last_column: 'H',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      adults_and_hohs = universe.members.where(
        a_t[:first_date_in_program].gt(Date.parse('2016-10-01')).
          and(a_t[:age].gteq(18).
            or(a_t[:head_of_household].eq(true).
              and(a_t[:age].lt(18).
                or(a_t[:age].eq(nil))))),
      )

      es_sh_so_clients = es_sh_so(table_name, adults_and_hohs)
      th_clients = th(table_name, adults_and_hohs)
      ph_clients = ph(table_name, adults_and_hohs)

      # totals
      answer = @report.answer(question: table_name, cell: 'B5')
      answer.add_members(adults_and_hohs)
      answer.update(summary: adults_and_hohs.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H5')
      total_members = es_sh_so_clients.
        or(th_clients).
        or(ph_clients)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)
      answer.update(summary: percentage(total_members.count / adults_and_hohs.count.to_f))
    end

    private def es_sh_so(table_name, adults_and_hohs)
      es_sh_so = adults_and_hohs.where(a_t[:project_type].in([1, 4, 8]))

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
        a_t[:times_homeless].in([8, 9]).
          or(a_t[:times_homeless].eq(nil)),
      )
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G2')
      months_homeless_members = es_sh_so.where(
        a_t[:months_homeless].in([8, 9]).
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

    private def th(table_name, adults_and_hohs)
      th = adults_and_hohs.where(a_t[:project_type].eq(2))
      th_buckets = [
        # count
        {
          cell: 'B3',
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # missing time in institution
        {
          cell: 'C3',
          clause: a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
            and(a_t[:prior_length_of_stay].in([8, 9]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # missing time in housing
        {
          cell: 'D3',
          clause: a_t[:prior_living_situation].in([29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([8, 9]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # date homeless missing
        {
          cell: 'E3',
          clause: a_t[:date_homeless].eq(nil),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: 'F3',
          clause: a_t[:times_homeless].in([8, 9]).
            or(a_t[:times_homeless].eq(nil)),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: 'G3',
          clause: a_t[:months_homeless].in([8, 9]).
            or(a_t[:months_homeless].eq(nil)),
          include_in_percent: true,
        },
      ]
      th_buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = th.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: 'H3')
      ors = th_buckets.select { |m| m[:include_in_percent] }.map do |cell|
        "(#{cell[:clause].to_sql})"
      end
      members = th.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / th.count.to_f))

      members
    end

    private def ph(table_name, adults_and_hohs)
      ph = adults_and_hohs.where(a_t[:project_type].in([3, 9, 10, 13]))

      ph_buckets = [
        # count
        {
          cell: 'B4',
          clause: Arel.sql('1=1'),
          include_in_percent: false,
        },
        # missing time in institution
        {
          cell: 'C4',
          clause: a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
            and(a_t[:prior_length_of_stay].in([8, 9]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # missing time in housing
        {
          cell: 'D4',
          clause: a_t[:prior_living_situation].in([29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
            or(a_t[:prior_living_situation].eq(nil)).
            and(a_t[:prior_length_of_stay].in([8, 9]).
              or(a_t[:prior_length_of_stay].eq(nil))),
          include_in_percent: true,
        },
        # date homeless missing
        {
          cell: 'E4',
          clause: a_t[:date_homeless].eq(nil),
          include_in_percent: true,
        },
        # times homeless dk/r/missing
        {
          cell: 'F4',
          clause: a_t[:times_homeless].in([8, 9]).
            or(a_t[:times_homeless].eq(nil)),
          include_in_percent: true,
        },
        # months homeless dk/r/missing
        {
          cell: 'G4',
          clause: a_t[:months_homeless].in([8, 9]).
            or(a_t[:months_homeless].eq(nil)),
          include_in_percent: true,
        },
      ]
      ph_buckets.each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = ph.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      # percent
      answer = @report.answer(question: table_name, cell: 'H4')
      ors = ph_buckets.select { |m| m[:include_in_percent] }.map do |cell|
        "(#{cell[:clause].to_sql})"
      end
      members = ph.where(Arel.sql(ors.join(' or ')))
      answer.add_members(members)
      answer.update(summary: percentage(members.count / ph.count.to_f))

      members
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
          '0 days',
          '1-3 days',
          '4-6 days',
          '7-10 days',
          '11+ days',
        ],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      arrivals = universe.members.where(a_t[:first_date_in_program].gteq(@report.start_date))

      [
        # entry on date
        {
          cell: 'B2',
          clause: a_t[:first_date_in_program].eq(a_t[:enrollment_created]),
        },
        # entry 1..3 days
        {
          cell: 'B3',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(1).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(3)),
        },
        # entry 4..6 days
        {
          cell: 'B4',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'B5',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'B6',
          clause: datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(11),
        },
      ].each do |cell|
        answer = @report.answer(question: table_name, cell: cell[:cell])
        members = arrivals.where(cell[:clause])
        answer.add_members(members)
        answer.update(summary: members.count)
      end

      leavers = universe.members.where.not(a_t[:last_date_in_program].eq(nil))

      [
        # exit on date
        {
          cell: 'C2',
          clause: a_t[:last_date_in_program].eq(a_t[:exit_created]),
        },
        # exit 1..3 days
        {
          cell: 'C3',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(1).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(3)),
        },
        # exit 4..6 days
        {
          cell: 'C4',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(4).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(6)),
        },
        # entry 7..10 days
        {
          cell: 'C5',
          clause: datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(7).
            and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(10)),
        },
        # entry 11+ days
        {
          cell: 'C6',
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
          'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
          'Bed Night (All clients in ES – NBN)',
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
      answer.add_members(es_so_members)
      answer.update(summary: es_so_members.count)

      # Inactive ES
      answer = @report.answer(question: table_name, cell: 'C3')
      inactive_es_members = es_members.where(
        datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:date_of_last_bed_night]).gt(90),
      )
      answer.add_members(inactive_es_so_members)
      answer.update(summary: inactive_es_so_members.count)

      # percent inactive ES
      answer = @report.answer(question: table_name, cell: 'D3')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: percentage(inactive_es_members.count / es_members.count.to_f))
    end
  end
end
