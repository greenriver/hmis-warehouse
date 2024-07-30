###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2024
  class QuestionTwentyTwo < Base
    include HudReports::StartToMoveInQuestion
    QUESTION_NUMBER = 'Question 22'.freeze

    def self.table_descriptions
      {
        'Question 22' => 'Length of Participation',
        'Q22a1' => 'Length of Participation - CoC Projects',
        'Q22a2' => 'Length of Participation - ESG Projects',
        'Q22b' => 'Average and Median Length of Participation in Days',
        'Q22c' => 'Length of Time between Project Start Date and Housing Move-in Date',
        'Q22d' => 'Length of Participation by Household Type',
        'Q22e' => 'Length of Time Prior to Housing - based on 3.917 Date Homelessness Started',
        'Q22f' => 'Length of Time between Project Start Date and Housing Move-in Date by Race and Ethnicity',
        'Q22g' => 'Length of Time Prior to Housing by Race and Ethnicity - based on 3.917 Date Homelessness Started',
      }.freeze
    end

    private def q22a1_length_of_participation
      table_name = 'Q22a1'
      metadata = {
        header_row: [' '] + q_22a_populations.keys,
        row_labels: q22a1_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q_22a_populations.values.each_with_index do |population_clause, col_index|
        q22a1_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q22a2_length_of_participation
      table_name = 'Q22a2'
      metadata = {
        header_row: [' '] + q_22a_populations.keys,
        row_labels: q22a2_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 15,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q_22a_populations.values.each_with_index do |population_clause, col_index|
        q22a2_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q22b_average_length_of_participation
      table_name = 'Q22b'
      metadata = {
        header_row: [' '] + q22b_populations.keys,
        row_labels: q22b_lengths.keys,
        first_column: 'B',
        last_column: 'C',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q22b_populations.values.each_with_index do |population_clause, col_index|
        q22b_lengths.values.each_with_index do |method, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause)
          stay_lengths = members.pluck(a_t[:length_of_stay]).compact
          value = 0
          case method
          when :average
            value = (stay_lengths.sum(0.0) / stay_lengths.count).round(2) if stay_lengths.any?
          when :median
            if stay_lengths.any?
              sorted = stay_lengths.sort
              length = stay_lengths.count
              value = ((sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0).round(2)
            end
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q22c_start_to_move_in
      start_to_move_in_question(question: 'Q22c', members: universe.members)
    end

    private def q22d_participation_by_household_type
      table_name = 'Q22d'
      metadata = {
        header_row: [' '] + q22d_populations.keys,
        row_labels: q22d_lengths.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 12,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q22d_populations.values.each_with_index do |population_clause, col_index|
        q22d_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def q22e_time_prior_to_housing
      table_name = 'Q22e'
      metadata = {
        header_row: [' '] + q22d_populations.keys,
        row_labels: q22e_lengths.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 15,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      relevant_members = time_prior_to_housing_universe
      q22e_populations.values.each_with_index do |population_clause, col_index|
        q22e_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = relevant_members.where(population_clause).where(length_clause)

          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    def time_prior_to_housing_universe
      # 0 (ES-EE); 1 (EE-NbN); 2 (TH); 3 (PSH); 7 (Other) with 2.06 Funding
      # Source of HUD: Pay for Success (35); 8 (SH); 9 (PH); 13 (RRH)
      universe.members.where(a_t[:project_type].in([0, 1, 2, 3, 8, 9, 13]))
    end

    def q22f_start_to_move_in_by_race_and_ethnicity
      time_by_race_and_ethnicity_question(
        question: 'Q22f',
        move_in_col: a_t[:time_to_move_in],
        members: start_to_move_in_universe,
      )
    end

    def q22g_time_prior_to_housing_by_race_and_ethnicity
      time_by_race_and_ethnicity_question(
        question: 'Q22g',
        move_in_col: a_t[:approximate_time_to_move_in],
        members: time_prior_to_housing_universe,
      )
    end

    # Universe: All active clients where the head of household had a move-in date in the report date range plus leavers who exited in the date range and never had a move-in date.
    def start_to_move_in_universe
      # PSH/RRH w/ move in date
      # OR project type 7 (other) with Funder 35 (Pay for Success)
      relevant_members = universe.members.where(a_t[:project_type].in([3, 13]))
      relevant_members.where(
        [
          a_t[:move_in_date].between(@report.start_date..@report.end_date),
          leavers_clause.and(a_t[:move_in_date].eq(nil)),
        ].inject(&:or),
      )
    end

    private def q22b_populations
      {
        'Leavers' => leavers_clause,
        'Stayers' => stayers_clause,
      }
    end

    private def q22c_populations
      sub_populations
    end

    private def q22d_populations
      sub_populations
    end

    private def q22e_populations
      sub_populations
    end

    private def q22b_lengths
      {
        'Average Length' => :average,
        'Median Length' => :median,
      }
    end

    private def q_22a_populations
      {
        'Total' => Arel.sql('1=1'),
        'Leavers' => leavers_clause,
        'Stayers' => stayers_clause,
      }
    end

    private def q22a1_lengths
      [
        '30 days or less',
        '31 to 60 days',
        '61 to 90 days',
        '91 to 180 days',
        '181 to 365 days',
        '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)',
        'Total',
      ].to_h { [_1, lengths.fetch(_1)] }
    end

    private def q22a2_lengths
      [
        '0 to 7 days',
        '8 to 14 days',
        '15 to 21 days',
        '22 to 30 days',
        '31 to 60 days',
        '61 to 90 days',
        '91 to 180 days',
        '181 to 365 days',
        '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)',
        'Total',
      ].to_h { [_1, lengths.fetch(_1)] }
    end

    private def q22d_lengths
      [
        '7 days or less',
        '8 to 14 days',
        '15 to 21 days',
        '22 to 30 days',
        '31 to 60 days',
        '61 to 90 days',
        '91 to 180 days',
        '181 to 365 days',
        '366 to 730 days (1-2 Yrs)',
        '731 days or more',
        'Total',
      ].to_h { [_1, lengths.fetch(_1)] }
    end

    private def q22e_lengths
      move_in_field = a_t[:approximate_time_to_move_in]
      # PSH/RRH w/ move in date
      # OR project type 7 (other) with Funder 35 (Pay for Success)
      move_in_projects = HudUtility2024.residential_project_type_numbers_by_code[:ph]
      move_in_for_psh = a_t[:project_type].not_in(move_in_projects).
        or(a_t[:project_type].in(move_in_projects).and(a_t[:move_in_date].lteq(@report.end_date)))
      lengths = lengths(field: move_in_field)
      ret = [
        '7 days or less',
        '8 to 14 days',
        '15 to 21 days',
        '22 to 30 days',
        '31 to 60 days',
        '61 to 90 days',
        '91 to 180 days',
        '181 to 365 days',
        '366 to 730 days (1-2 Yrs)',
        '731 days or more',
      ].to_h { [_1, lengths.fetch(_1).and(move_in_for_psh)] }

      ret.merge(
        'Total (persons moved into housing)' => a_t[:approximate_time_to_move_in].not_eq(nil).
          and(a_t[:project_type].not_in(move_in_projects).
            or(a_t[:project_type].in(move_in_projects).
              and(a_t[:move_in_date].lteq(@report.end_date).and(a_t[:date_to_street].lteq(a_t[:move_in_date]))))),
        'Not yet moved into housing' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].not_eq(nil).
            and(a_t[:date_to_street].lteq(a_t[:first_date_in_program])).
            and(a_t[:approximate_time_to_move_in].eq(nil))).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].eq(nil).or(a_t[:move_in_date].gt(@report.end_date)))),
        'Data not collected' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].eq(nil).or(a_t[:date_to_street].gt(a_t[:first_date_in_program]))).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].lteq(@report.end_date).
              and(a_t[:date_to_street].eq(nil).or(a_t[:date_to_street].gt(a_t[:move_in_date]))))),
        'Total persons' => Arel.sql('1=1'),
      )
    end

    private def intentionally_blank
      [].freeze
    end

    def time_by_race_and_ethnicity_question(question:, move_in_col:, members:)
      sheet = question_sheet(question: question)
      first_row = 2
      last_row = 5
      groups = race_ethnicity_groups
      metadata = {
        header_row: [''] + groups.map { _1[:label] },
        row_labels: [
          'Persons Moved into housing',
          'Persons who were exited without move-in',
          'Average time to Move-In',
          'Median time to Move-In',
        ],
        first_column: 'B',
        last_column: 'K',
        first_row: first_row,
        last_row: last_row,
      }
      sheet.update_metadata(metadata)

      col_letters = (metadata[:first_column]..metadata[:last_column]).to_a
      groups.each.with_index do |group, idx|
        group_scope = members.where(group.fetch(:cond))
        letter = col_letters.fetch(idx)

        sheet.update_cell_members(
          cell: "#{letter}2",
          members: group_scope.where(move_in_col.not_eq(nil)),
        )
        sheet.update_cell_members(
          cell: "#{letter}3",
          members: group_scope.where(move_in_col.eq(nil)),
        )
        sheet.update_cell_value(
          cell: "#{letter}4",
          value: group_scope.pluck(Arel.sql("AVG(#{move_in_col.to_sql})")).first&.to_f&.round(4),
        )
        sheet.update_cell_value(
          cell: "#{letter}5",
          # median in pg
          value: group_scope.pluck(Arel.sql("percentile_cont(0.5) WITHIN GROUP (ORDER BY #{move_in_col.to_sql})")).first&.to_f,
        )
      end
    end
  end
end
