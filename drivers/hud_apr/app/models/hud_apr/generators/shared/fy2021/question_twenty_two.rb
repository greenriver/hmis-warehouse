###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2021
  class QuestionTwentyTwo < Base
    QUESTION_NUMBER = 'Question 22'.freeze

    def self.table_descriptions
      {
        'Question 22' => 'Length of participation',
        'Q22a1' => 'Length of Participation – CoC Projects',
        'Q22a2' => 'Length of Participation – ESG Projects',
        'Q22b' => 'Average and Median Length of Participation in Days',
        'Q22c' => 'Length of Time between Project Start Date and Housing Move-in Date',
        'Q22d' => 'Length of Participation by Household Type',
        'Q22e' => 'Length of Time Prior to Housing - based on 3.917 Date Homelessness Started',
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
        last_row: 13,
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
        last_row: 16,
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
            value = (stay_lengths.sum(0.0) / stay_lengths.count).round if stay_lengths.any?
          when :median
            if stay_lengths.any?
              sorted = stay_lengths.sort
              length = stay_lengths.count
              value = ((sorted[(length - 1) / 2] + sorted[length / 2]) / 2.0).round
            end
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q22c_start_to_move_in
      table_name = 'Q22c'
      metadata = {
        header_row: [' '] + q22c_populations.keys,
        row_labels: q22c_lengths.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 13,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      relevant_members = universe.members.where(a_t[:project_type].in([3, 13]))
      q22c_populations.values.each_with_index do |population_clause, col_index|
        q22c_lengths.values.each_with_index do |length_clause, row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          # Universe: All active clients where the head of household had a move-in date in the report date range plus leavers who exited in the date range and never had a move-in date.
          members = relevant_members.where(population_clause).
            where(
              a_t[:move_in_date].between(@report.start_date..@report.end_date).
              or(leavers_clause.and(a_t[:move_in_date].eq(nil))),
            )

          if length_clause.is_a?(Symbol)
            case length_clause
            when :average
              value = 0
              members = members.where(a_t[:move_in_date].between(@report.start_date..@report.end_date))
              stay_lengths = members.pluck(a_t[:time_to_move_in])
              value = (stay_lengths.sum(0.0) / stay_lengths.count).round(2) if stay_lengths.any?
            end
          else
            members = members.where(length_clause)
            value = members.count
          end

          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q22d_participation_by_household_type
      table_name = 'Q22d'
      metadata = {
        header_row: [' '] + q22d_populations.keys,
        row_labels: q22d_lengths.keys,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 16,
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
        last_row: 14,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      relevant_members = universe.members.where(a_t[:project_type].in([1, 2, 3, 8, 9, 13]))
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
      {
        '30 days or less' => '30 days or less',
        '31 to 60 days' => '31 to 60 days',
        '61 to 90 days' => '61 to 90 days',
        '91 to 180 days' => '91 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)' => '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)' => '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)' => '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)' => 'More than 1,825 days (> 5 Yrs)',
        'Data Not Collected' => 'Data Not Collected',
        'Total' => 'Total',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q22a2_lengths
      {
        '0 to 7 days' => '0 to 7 days',
        '8 to 14 days' => '8 to 14 days',
        '15 to 21 days' => '15 to 21 days',
        '22 to 30 days' => '22 to 30 days',
        '31 to 60 days' => '31 to 60 days',
        '61 to 90 days' => '61 to 90 days',
        '91 to 180 days' => '91 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)' => '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)' => '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)' => '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)' => 'More than 1,825 days (> 5 Yrs)',
        'Data Not Collected' => 'Data Not Collected',
        'Total' => 'Total',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q22c_lengths
      {
        '0 to 7 days' => a_t[:time_to_move_in].between(0..7).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '8 to 14 days' => a_t[:time_to_move_in].between(8..14).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '15 to 21 days' => a_t[:time_to_move_in].between(15..21).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '22 to 30 days' => a_t[:time_to_move_in].between(22..30).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '31 to 60 days' => a_t[:time_to_move_in].between(31..60).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '61 to 180 days' => a_t[:time_to_move_in].between(61..180).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '181 to 365 days' => a_t[:time_to_move_in].between(181..365).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        '366 to 730 days (1-2 Yrs)' => a_t[:time_to_move_in].between(366..730).
          and(a_t[:move_in_date].between(@report.start_date..@report.end_date)),
        'Total (persons moved into housing)' => a_t[:move_in_date].between(@report.start_date..@report.end_date),
        'Average length of time to housing' => :average,
        'Persons who were exited without move-in' => a_t[:move_in_date].eq(nil),
        'Total persons' => Arel.sql('1=1'),
      }.freeze
    end

    private def q22d_lengths
      {
        '0 to 7 days' => '7 days or less',
        '8 to 14 days' => '8 to 14 days',
        '15 to 21 days' => '15 to 21 days',
        '22 to 30 days' => '22 to 30 days',
        '31 to 60 days' => '31 to 60 days',
        '61 to 90 days' => '61 to 90 days',
        '91 to 180 days' => '91 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 to 1,095 days (2-3 Yrs)' => '731 to 1,095 days (2-3 Yrs)',
        '1,096 to 1,460 days (3-4 Yrs)' => '1,096 to 1,460 days (3-4 Yrs)',
        '1,461 to 1,825 days (4-5 Yrs)' => '1,461 to 1,825 days (4-5 Yrs)',
        'More than 1,825 days (> 5 Yrs)' => 'More than 1,825 days (> 5 Yrs)',
        'Data Not Collected' => 'Data Not Collected',
        'Total' => 'Total',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q22e_lengths
      move_in_projects = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      move_in_for_psh = a_t[:project_type].not_in(move_in_projects).
        or(a_t[:project_type].in(move_in_projects).and(a_t[:move_in_date].lteq(@report.end_date)))
      {
        '7 days or less' => a_t[:approximate_time_to_move_in].between(0..7).
          and(move_in_for_psh),
        '8 to 14 days' => a_t[:approximate_time_to_move_in].between(8..14).
          and(move_in_for_psh),
        '15 to 21 days' => a_t[:approximate_time_to_move_in].between(15..21).
          and(move_in_for_psh),
        '22 to 30 days' => a_t[:approximate_time_to_move_in].between(22..30).
          and(move_in_for_psh),
        '31 to 60 days' => a_t[:approximate_time_to_move_in].between(31..60).
          and(move_in_for_psh),
        '61 to 180 days' => a_t[:approximate_time_to_move_in].between(61..180).
          and(move_in_for_psh),
        '181 to 365 days' => a_t[:approximate_time_to_move_in].between(181..365).
          and(move_in_for_psh),
        '366 to 730 days (1-2 Yrs)' => a_t[:approximate_time_to_move_in].between(366..730).
          and(move_in_for_psh),
        '731 days or more' => a_t[:approximate_time_to_move_in].gteq(731).
          and(move_in_for_psh),
        'Total (persons moved into housing)' => a_t[:approximate_time_to_move_in].not_eq(nil).
          and(a_t[:project_type].not_in(move_in_projects).
            or(a_t[:project_type].in(move_in_projects).
              and(a_t[:move_in_date].lteq(@report.end_date).and(a_t[:date_to_street].lteq(a_t[:move_in_date]))))),
        'Not yet moved into housing' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].not_eq(nil).
            and(a_t[:approximate_time_to_move_in].eq(nil))).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].eq(nil).or(a_t[:move_in_date].gt(@report.end_date)))),
        'Data not collected' => a_t[:project_type].not_in(move_in_projects).
          and(a_t[:date_to_street].eq(nil)).
          or(a_t[:project_type].in(move_in_projects).
            and(a_t[:move_in_date].lteq(@report.end_date).
              and(a_t[:date_to_street].eq(nil).or(a_t[:date_to_street].gt(a_t[:move_in_date]))))),
        'Total persons' => Arel.sql('1=1'),
      }.freeze
    end

    private def intentionally_blank
      [].freeze
    end
  end
end
