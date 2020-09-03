###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionSix < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q6'
    QUESTION_TABLE_NUMBERS = ('Q6a'..'Q6f').to_a

    def run!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      q6a_pii
      q6b_universal_data_elements
      q6c_income_and_housing
      q6d_chronic_homelessness
      q6e_timeliness
      q6f_inactive_records

      @report.complete(QUESTION_NUMBER)
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def q6a_pii
      table_name = 'Q6a'
      metadata = {
        header_row: ['Data Element', 'Client Doesn’t Know/Refused', 'Information Missing',
          'Data Issues', 'Total', '% of Error Rate'],
        row_labels: ['Name (3.01)', 'Social Security Number (3.02)', 'Date of Birth (3.03)', 'Race (3.04)',
          'Ethnicity (3.05)', 'Gender (3.06)', 'Overall Score'],
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
      clients = clients.or(simple_quality(table_name: table_name, row: 7, attr: :gender))

      count = clients.distinct.count
      @report.answer(question: table_name, cell: 'E8').update(summary: count)
      @report.answer(question: table_name, cell: 'F8').update(summary: format('%1.4f', count / universe.members.count.to_f ))
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
        a_t[:first_name].eq(nil).
          or(a_t[:last_name].eq(nil)),
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
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

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
      m_members = universe.members.where(a_t[:ssn].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # SSN quality
      answer = @report.answer(question: table_name, cell: 'D3')
      q_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.ssn_quality == 2 || !HUD.valid_social?(member.ssn)
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
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

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
      m_members = universe.members.where(a_t[:dob].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # DOB quality
      answer = @report.answer(question: table_name, cell: 'D4')
      q_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        q_member_ids << u_member.id if member.dob_quality == 2 || !valid_dob?(member)
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
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

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
      dkr_member_ids = []
      m_member_ids = []
      universe.members.find_each do |u_member|
        member = u_member.universe_membership
        dkr_member_ids << u_member.id if member.race.any?(8) || member.race.any?(9)
        m_member_ids << u_member.id if member.race.all?(nil)
      end
      dkr_members = universe.members.where(id: dkr_member_ids)
      answer.add_members(dkr_members)
      answer.update(summary: dkr_members.count)

      # Race missing
      answer = @report.answer(question: table_name, cell: 'C5')
      m_members = universe.members.where(id: m_member_ids)
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E5')
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F5')
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

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
      m_members = universe.members.where(a_t[attr].eq(nil))
      answer.add_members(m_members)
      answer.update(summary: m_members.count)

      # Total
      answer = @report.answer(question: table_name, cell: 'E' + row_label)
      total_members = dkr_members.or(m_members)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # Percentage
      answer = @report.answer(question: table_name, cell: 'F' + row_label)
      answer.update(summary: format('%1.4f', total_members.count / universe.members.count.to_f ))

      total_members
    end

    private def q6b_universal_data_elements
      table_name = 'Q6b'
      metadata = {
        header_row: ['Data Element', 'Error Count', '% of Error Rate'],
        row_labels: [ 'Veteran Status (3.07)', 'Project Start Date (3.10)', 'Relationship to Head of Household (3.15)',
          'Client Location (3.16)', 'Disabling Condition (3.08)'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # veteran status
      answer = @report.answer(question: table_name, cell: 'B2')
      members = universe.members.where(
        a_t[:veteran_status].in([nil, 8, 9]).
          or(a_t[:veteran_status].eq(1).
            and(a_t[:age].lt(18)))
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.update(summary: format('%1.4f', members.count / universe.members.count.to_f ))

      # project start date
      answer = @report.answer(question: table_name, cell: 'B3')
      members = universe.members.where(a_t[:overlapping_enrollments].not_eq([]))
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: format('%1.4f', members.count / universe.members.count.to_f ))

      # relationship to head of household
      answer = @report.answer(question: table_name, cell: 'B4')
      households_with_multiple_hohs = universe.members.
        where(a_t[:relationship_to_hoh].eq(1)).
        group(a_t[:household_id]).
        count.
        select{ |_, v| v > 1 }.
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
      answer.update(summary: format('%1.4f', members.count / universe.members.count.to_f ))

      # client location
      answer = @report.answer(question: table_name, cell: 'B5')
      members = universe.members.where(
        a_t[:enrollment_coc].eq(nil).
          or(a_t[:enrollment_coc].not_in(HUD.cocs.keys)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      hoh_denominator = universe.members.where(a_t[:head_of_household].eq(true))
      answer.update(summary: format('%1.4f', members.count / hoh_denominator.count.to_f ))

      # disabling condition
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members.where(
        a_t[:disabling_condition].in([8, 9, nil]).
          or(a_t[:disabling_condition].eq(0).
            and(a_t[:indefinite_and_impairs].eq(true).
              and(a_t[:developmental_disability].eq(true).
                or(a_t[:hiv_aids].eq(true)).
                or(a_t[:physical_disability].eq(true)).
                or(a_t[:chronic_disability].eq(true)).
                or(a_t[:mental_health_problem].eq(true)).
                or(a_t[:substance_abuse].eq(true)).
                or(a_t[:indefinite_and_impairs].eq(true)),
              ),
            ),
          ),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C6')
      answer.update(summary: format('%1.4f', members.count / universe.members.count.to_f ))
    end

    private def q6c_income_and_housing
      table_name = 'Q6c'
      metadata = {
        header_row: ['Data Element', 'Error Count', '% of Error Rate'],
        row_labels: [ 'Destination (3.12)', 'Income and Sources (4.02) at Start',
          'Income and Sources (4.02) at Annual Assessment', 'Income and Sources (4.02) at Exit'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 5,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # destinations
      leavers = universe.members.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B2')
      members = leavers.where(
        a_t[:destination].in([nil, 8, 9, 30])
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C2')
      answer.update(summary: format('%1.4f', members.count / leavers.count.to_f ))

      # incomes
      adults_and_hohs = universe.members.where(
        a_t[:age].gteq(18).
          or(a_t[:head_of_household].eq(true).
            and(a_t[:age].lt(18).
              or(a_t[:age].eq(nil)))),
      )
      # income at start
      answer = @report.answer(question: table_name, cell: 'B3')
      members = adults_and_hohs.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([nil, 8, 9])).
          or(a_t[:income_from_any_source_at_start].eq(0).
            and(a_t[:income_sources_at_start].not_eq([]))).
          or(a_t[:income_from_any_source_at_start].eq(1).
            and(a_t[:income_sources_at_start].eq([]))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C3')
      answer.update(summary: format('%1.4f', members.count / adults_and_hohs.count.to_f ))

      # income at anniversary
      stayers_with_anniversary = adults_and_hohs.where(
        a_t[:annual_assessment_expected].eq(true).
          and(a_t[:last_date_in_program].gt(@report.end_date))
      )

      answer = @report.answer(question: table_name, cell: 'B4')
      members = stayers_with_anniversary.where(
        a_t[:income_date_at_start].eq(nil).
          or(a_t[:income_date_at_start].not_eq(a_t[:first_date_in_program])).
          or(a_t[:income_from_any_source_at_start].in([nil, 8, 9])).
          or(a_t[:income_from_any_source_at_start].eq(0).
            and(a_t[:income_sources_at_start].not_eq([]))).
          or(a_t[:income_from_any_source_at_start].eq(1).
            and(a_t[:income_sources_at_start].eq([]))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C4')
      answer.update(summary: format('%1.4f', members.count / stayers_with_anniversary.count.to_f ))

      # income at exit
      leavers = adults_and_hohs.where(a_t[:last_date_in_program].lteq(@report.end_date))

      answer = @report.answer(question: table_name, cell: 'B5')
      members = leavers.where(
        a_t[:income_date_at_exit].eq(nil).
          or(a_t[:income_date_at_exit].not_eq(a_t[:last_date_in_program])).
          or(a_t[:income_from_any_source_at_exit].in([nil, 8, 9])).
          or(a_t[:income_from_any_source_at_exit].eq(0).
            and(a_t[:income_sources_at_exit].not_eq([]))).
          or(a_t[:income_from_any_source_at_exit].eq(1).
            and(a_t[:income_sources_at_exit].eq([]))),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      answer = @report.answer(question: table_name, cell: 'C5')
      answer.update(summary: format('%1.4f', members.count / leavers.count.to_f ))
    end

    private def q6d_chronic_homelessness
      table_name = 'Q6d'
      metadata = {
        header_row: ['Entering into project type', 'Count of total records', 'Missing time in institution (3.917.2)',
          'Missing time in housing (3.917.2)', 'Approximate Date started (3.917.3) DK/R/missing',
          'Number of times (3.917.4) DK/R/missing', 'Number of months (3.917.5) DK/R/missing',
          '% of records unable to calculate'],
        row_labels: [ 'ES, SH, Street Outreach', 'TH', 'PH (all)', 'Total'],
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
                or(a_t[:age].eq(nil)))),
          ),
      )

      es_sh_so_clients = es_sh_so(table_name, adults_and_hohs)
      th_clients = th(table_name, adults_and_hohs)
      ph_clients = ph(table_name, adults_and_hohs)

      # totals
      answer = @report.answer(question: table_name, cell: 'B5')
      total_members = es_sh_so_clients.
        or(th_clients).
        or(ph_clients)
      answer.add_members(total_members)
      answer.update(summary: total_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H5')
      answer.update(summary: format('%1.4f', total_members.count / adults_and_hohs.count.to_f ))
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
      times_homeless_members = es_sh_so.where(a_t[:times_homeless].in([nil, 8, 9]))
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G2')
      months_homeless_members = es_sh_so.where(a_t[:months_homeless].in([nil, 8, 9]))
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H2')
      members = date_homeless_members.
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: format('%1.4f', members.count / es_sh_so.count.to_f ))

      es_sh_so
    end

    private def th(table_name, adults_and_hohs)
      th = adults_and_hohs.where(a_t[:project_type].eq(2))

      # count
      answer = @report.answer(question: table_name, cell: 'B3')
      members = th
      answer.add_members(members)
      answer.update(summary: members.count)

      # date homeless missing
      answer = @report.answer(question: table_name, cell: 'C3')
      date_homeless_members = th.where(a_t[:date_homeless].eq(nil))
      answer.add_members(date_homeless_members)
      answer.update(summary: date_homeless_members.count)

      # missing time in institution
      answer = @report.answer(question: table_name, cell: 'D3')
      missing_institution = th.where(
        a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
          and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
      )
      answer.add_members(missing_institution)
      answer.update(summary: missing_institution.count)

      # missing time in housing
      answer = @report.answer(question: table_name, cell: 'E3')
      missing_housing = th.where(
        a_t[:prior_living_situation].in([nil, 29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
          and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
      )
      answer.add_members(missing_housing)
      answer.update(summary: missing_housing.count)

      # times homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'F3')
      times_homeless_members = th.where(a_t[:times_homeless].in([nil, 8, 9]))
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G3')
      months_homeless_members = th.where(a_t[:months_homeless].in([nil, 8, 9]))
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H3')
      members = date_homeless_members.
        or(missing_institution).
        or(missing_housing).
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: format('%1.4f', members.count / th.count.to_f ))

      th
    end

    private def ph(table_name, adults_and_hohs)
      ph = adults_and_hohs.where(a_t[:project_type].eq([3, 9, 10, 13]))

      # count
      answer = @report.answer(question: table_name, cell: 'B4')
      members = ph
      answer.add_members(members)
      answer.update(summary: members.count)

      # date homeless missing
      answer = @report.answer(question: table_name, cell: 'C4')
      date_homeless_members = ph.where(a_t[:date_homeless].eq(nil))
      answer.add_members(date_homeless_members)
      answer.update(summary: date_homeless_members.count)

      # missing time in institution
      answer = @report.answer(question: table_name, cell: 'D4')
      missing_institution = ph.where(
        a_t[:prior_living_situation].in([15, 6, 7, 25, 4, 5]).
          and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
      )
      answer.add_members(missing_institution)
      answer.update(summary: missing_institution.count)

      # missing time in housing
      answer = @report.answer(question: table_name, cell: 'E4')
      missing_housing = ph.where(
        a_t[:prior_living_situation].in([nil, 29, 14, 2, 32, 36, 35, 28, 19, 3, 31, 33, 34, 10, 20, 21, 11, 8, 9]).
          and(a_t[:prior_length_of_stay].in([nil, 8, 9])),
      )
      answer.add_members(missing_housing)
      answer.update(summary: missing_housing.count)

      # times homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'F4')
      times_homeless_members = ph.where(a_t[:times_homeless].in([nil, 8, 9]))
      answer.add_members(times_homeless_members)
      answer.update(summary: times_homeless_members.count)

      # months homeless dk/r/missing
      answer = @report.answer(question: table_name, cell: 'G4')
      months_homeless_members = ph.where(a_t[:months_homeless].in([nil, 8, 9]))
      answer.add_members(months_homeless_members)
      answer.update(summary: months_homeless_members.count)

      # percent
      answer = @report.answer(question: table_name, cell: 'H4')
      members = date_homeless_members.
        or(missing_institution).
        or(missing_housing).
        or(times_homeless_members).
        or(months_homeless_members)
      answer.add_members(members)
      answer.update(summary: format('%1.4f', members.count / ph.count.to_f ))

      ph
    end

    private def q6e_timeliness
      table_name = 'Q6e'
      metadata = {
        header_row: ['Time for Record Entry', 'Number of Project Start Records', 'Number of Project Exit Records'],
        row_labels: [ '0 days', '1-3 days', '4-6 days', '7-10 days', '11+ days'],
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 6,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # entry on date
      answer = @report.answer(question: table_name, cell: 'B2')
      members = universe.members.where(a_t[:first_date_in_program].eq(a_t[:enrollment_created]))
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 1..3 days
      answer = @report.answer(question: table_name, cell: 'B3')
      members = universe.members.where(
        datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(1).
          and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(3)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 4..6 days
      answer = @report.answer(question: table_name, cell: 'B4')
      members = universe.members.where(
        datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(4).
          and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(6)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 7..10 days
      answer = @report.answer(question: table_name, cell: 'B5')
      members = universe.members.where(
        datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(7).
          and(datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).lteq(10)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 11+ days
      answer = @report.answer(question: table_name, cell: 'B6')
      members = universe.members.where(
        datediff(report_client_universe, 'day', a_t[:enrollment_created], a_t[:first_date_in_program]).gteq(11),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      leavers = universe.members.where.not(a_t[:last_date_in_program].eq(nil))

      # exit on date
      answer = @report.answer(question: table_name, cell: 'C2')
      members = leavers.where(a_t[:last_date_in_program].eq(a_t[:exit_created]))
      answer.add_members(members)
      answer.update(summary: members.count)

      # exit 1..3 days
      answer = @report.answer(question: table_name, cell: 'C3')
      members = leavers.where(
        datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(1).
          and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(3)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # exit 4..6 days
      answer = @report.answer(question: table_name, cell: 'C4')
      members = leavers.where(
        datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(4).
          and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(6)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 7..10 days
      answer = @report.answer(question: table_name, cell: 'C5')
      members = leavers.where(
        datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(7).
          and(datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).lteq(10)),
      )
      answer.add_members(members)
      answer.update(summary: members.count)

      # entry 11+ days
      answer = @report.answer(question: table_name, cell: 'C6')
      members = leavers.where(
        datediff(report_client_universe, 'day', a_t[:exit_created], a_t[:last_date_in_program]).gteq(11),
      )
      answer.add_members(members)
      answer.update(summary: members.count)
    end

    private def q6f_inactive_records
      table_name = 'Q6f'
      metadata = {
        header_row: ['Data Element', '# of Records', '# of Inactive Records', ' # % of Inactive Records'],
        row_labels: [ 'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
          'Bed Night (All clients in ES – NBN)'],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      relevant_clients = universe.members.
        joins(report_cell: :report_instance)
        .where(
          datediff(report_client_universe, 'day', a_t[:first_date_in_program], hr_ri_t[:end_date]).lt(90).
            and(a_t[:last_date_in_program].eq(nil).
              or(a_t[:last_date_in_program].gt(@report.end_date)),
            ),
        ).
        distinct

      # Relevant Adults and HoH ES-NBN or SO
      answer = @report.answer(question: table_name, cell: 'B2')
      adults_and_hohs = relevant_clients.where(
        a_t[:age].gteq(18).
          or(a_t[:head_of_household].eq(true).
            and(a_t[:age].lt(18).
              or(a_t[:age].eq(nil)))),
      )
      es_so_members = relevant_clients.where(
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
        dates = member.universe_membership.first_date_in_program
        dates << member.universe_membership.
          joins(:hud_report_apr_living_situations).
          pluck(:information_date)
        dates.sort!
        dates.each_with_index do |date, index|
          next if index.zero? # Skip the first date

          es_so_member_ids << member.id if (date - dates[index - 1]).to_i > 90 # A gap of more than 90 days
        end
      end

      inactive_es_so_members = es_so_members.where(id: es_so_member_ids)
      answer.add_members(inactive_es_so_members)
      answer.update(summary: inactive_es_so_members.count)

      # percent inactive ES or SO
      answer = @report.answer(question: table_name, cell: 'D2')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: format('%1.4f', inactive_es_so_members.count / es_so_members.count.to_f ))

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
        datediff(report_client_universe, 'day', a_t[:date_of_last_bed_night], hr_ri_t[:end_date]).lteq(90),
      )
      answer.add_members(inactive_es_so_members)
      answer.update(summary: inactive_es_so_members.count)

      # percent inactive ES
      answer = @report.answer(question: table_name, cell: 'D3')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: format('%1.4f', inactive_es_members.count / es_members.count.to_f ))
    end

    private def universe
      batch_initializer = ->(clients) do
      end

      batch_finalizer = ->(clients_with_enrollments, report_clients) do
        living_situations = []

        report_clients.each do |client, apr_client|
          last_enrollment = clients_with_enrollments[client.id].last.enrollment
          last_enrollment.current_living_situations.each do |living_situation|
            living_situations << apr_client.hud_report_apr_living_situations.build(
              information_date: living_situation.InformationDate,
            )
          end
        end

        report_living_situation_universe.import(
          living_situations,
          on_duplicate_key_update: {
            conflict_target: [:apr_client_id],
            columns: living_situations.first&.changed || []
          }
        )
      end

      @universe ||= build_universe(
        QUESTION_NUMBER,
        before_block: batch_initializer,
        after_block: batch_finalizer,
      ) do |client, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        exit_record = last_service_history_enrollment.service_history_exit&.enrollment
        source_client = last_service_history_enrollment.source_client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        income_at_start = enrollment.income_benefits_at_entry
        income_at_annual_assessment = annual_assessment(enrollment)
        income_at_exit = exit_record&.income_benefits_at_exit
        last_bed_night = enrollment.services.bed_night.order(:DateProvided).last

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          first_name: source_client.FirstName,
          last_name: source_client.LastName,
          name_quality: source_client.NameDataQuality,
          ssn: source_client.SSN,
          ssn_quality: source_client.SSNDataQuality,
          dob: source_client.DOB,
          dob_quality: source_client.DOBDataQuality,
          age: source_client.age_on(client_start_date),
          head_of_household: last_service_history_enrollment.head_of_household,
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          enrollment_created: enrollment.DateCreated,
          race: HUD.races.keys.map { |key| source_client.public_send(key) },
          ethnicity: source_client.Ethnicity,
          gender: source_client.Gender,
          veteran_status: source_client.VeteranStatus,
          overlapping_enrollments: overlapping_enrollments(enrollments, last_service_history_enrollment),
          relationship_to_hoh: enrollment.RelationshipToHoH,
          household_id: last_service_history_enrollment.household_id,
          enrollment_coc: enrollment.enrollment_coc_at_entry&.CoCCode,
          disabling_condition: enrollment.DisablingCondition,
          developmental_disability: enrollment.disabilities.developmental.disabled.exists?,
          hiv_aids: enrollment.disabilities.hiv.disabled.exists?,
          physical_disability: enrollment.disabilities.physical.disabled.exists?,
          chronic_disability: enrollment.disabilities.chronic.disabled.exists?,
          mental_health_problem: enrollment.disabilities.mental.disabled.exists?,
          substance_abuse: enrollment.disabilities.substance.disabled.exists?,
          indefinite_and_impairs: enrollment.disabilities.chronically_disabled.exists?,
          destination: last_service_history_enrollment.destination,
          income_date_at_start: income_at_start&.InformationDate,
          income_from_any_source_at_start: income_at_start&.IncomeFromAnySource,
          income_sources_at_start: income_sources(income_at_start),
          annual_assessment_expected: annual_assessment_expected?(last_service_history_enrollment),
          income_date_at_annual_assessment: income_at_annual_assessment&.InformationDate,
          income_from_any_source_at_annual_assessment: income_at_annual_assessment&.IncomeFromAnySource,
          income_sources_at_annual_assessment: income_sources(income_at_annual_assessment),
          income_date_at_exit: income_at_exit&.InformationDate,
          income_from_any_source_at_exit: income_at_exit&.IncomeFromAnySource,
          income_sources_at_exit: income_sources(income_at_annual_assessment),
          project_type: last_service_history_enrollment.project_type,
          prior_living_situation: enrollment.LivingSituation,
          prior_length_of_stay: enrollment.LengthOfStay,
          date_homeless: enrollment.DateToStreetESSH,
          times_homeless: enrollment.TimesHomelessPastThreeYears,
          months_homeless: enrollment.MonthsHomelessPastThreeYears,
          came_from_street_last_night: enrollment.PreviousStreetESSH,
          exit_created: exit_record&.DateCreated,
          project_tracking_method: last_service_history_enrollment.project_tracking_method,
          date_of_last_bed_night: last_bed_night&.DateProvided,
        )
      end
    end

    private def annual_assessment(enrollment)
      enrollment.income_benefits_annual_update.
        where(ib_t[:InformationDate].lt(@report.end_date)).
        order(ib_t[:InformationDate].to_sql => :desc).
        first
    end

    private def income_sources(income)
      income&.slice(
        :Earned,
        :Unemployment,
        :SSI,
        :SSDI,
        :VADisabilityService,
        :VADisabilityNonService,
        :PrivateDisability,
        :WorkersComp,
        :TANF,
        :GA,
        :SocSecRetirement,
        :Pension,
        :ChildSupport,
        :Alimony,
        :OtherIncomeSource,
      )&.values || []
    end

    private def annual_assessment_expected?(enrollment)
      elapsed_years = @report.end_date.year - enrollment.first_date_in_program.year
      elapsed_years = if enrollment.first_date_in_program + elapsed_years.year > @report.end_date
        elapsed_years - 1
      end

      enrollment.head_of_household? && elapsed_years.positive?
    end

    private def overlapping_enrollments(enrollments, last_enrollment)
      last_enrollment_end = last_enrollment.last_date_in_program || Date.tomorrow
      enrollments.select do |enrollment|
        enrollment_end = enrollment.last_date_in_program || Date.tomorrow

        enrollment.id != last_enrollment.id && # Don't include the last enrollment
          enrollment.data_source_id == last_enrollment.data_source_id &&
          enrollment.project_id == last_enrollment.project_id &&
          enrollment.first_date_in_program < last_enrollment_end &&
          enrollment_end > last_enrollment.first_date_in_program
      end.map(&:enrollment_group_id).uniq
    end
  end
end