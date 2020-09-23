###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyTwoBase < Base
    QUESTION_NUMBER = 'Question 22'.freeze
    QUESTION_TABLE_NUMBERS = ['Q22a1', 'Q22a2', 'Q22b', 'Q22c', 'Q22d', 'Q22e'].freeze

    def self.question_number
      QUESTION_NUMBER
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
      q_22a_populations.each_with_index do |(_, population_clause), col_index|
        q22a1_lengths.to_a.each_with_index do |(_, length_clause), row_index|
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
      table_name = 'Q22b1'
      metadata = {
        header_row: [' '] + q_22a_populations.keys,
        row_labels: q22b1_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q_22a_populations.each_with_index do |(_, population_clause), col_index|
        q22b1_lengths.to_a.each_with_index do |(_, length_clause), row_index|
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
      q22b_populations.each_with_index do |(_, population_clause), col_index|
        q22b_lengths.to_a.each_with_index do |(_, method), row_index|
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
      q22c_populations.each_with_index do |(_, population_clause), col_index|
        q22c_lengths.to_a.each_with_index do |(_, length_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          # Universe: All active clients where the head of household had a move-in date in the report date range plus leavers who exited in the date range and never had a move-in date.
          members = universe.members.where(population_clause).
            where(
              a_t[:move_in_date].between(@report.start_date..@report.end_date).
              or(leavers_clause),
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
      q22d_populations.each_with_index do |(_, population_clause), col_index|
        q22d_lengths.to_a.each_with_index do |(_, length_clause), row_index|
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
      q22e_populations.each_with_index do |(_, population_clause), col_index|
        q22e_lengths.to_a.each_with_index do |(_, length_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)

          members = universe.members.where(population_clause).where(length_clause)

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
      @q22c_populations ||= sub_populations
    end

    private def q22d_populations
      @q22d_populations ||= sub_populations
    end

    private def q22e_populations
      @q22e_populations ||= sub_populations
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

    private def q22b1_lengths
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
      {
        '7 days or less' => a_t[:approximate_time_to_move_in].between(0..7).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '8 to 14 days' => a_t[:approximate_time_to_move_in].between(8..14).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '15 to 21 days' => a_t[:approximate_time_to_move_in].between(15..21).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '22 to 30 days' => a_t[:approximate_time_to_move_in].between(22..30).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '31 to 60 days' => a_t[:approximate_time_to_move_in].between(31..60).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '61 to 180 days' => a_t[:approximate_time_to_move_in].between(61..180).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '181 to 365 days' => a_t[:approximate_time_to_move_in].between(181..365).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '366 to 730 days (1-2 Yrs)' => a_t[:approximate_time_to_move_in].between(366..730).
          and(a_t[:move_in_date].lteq(@report.end_date)),
        '731 days or more' => a_t[:approximate_time_to_move_in].gteq(731),
        'Total (persons moved into housing)' => a_t[:move_in_date].lteq(@report.end_date),
        'Not yet moved into housing' => a_t[:move_in_date].eq(nil).and(a_t[:date_to_street].not_eq(nil)),
        'Data not collected' => a_t[:approximate_time_to_move_in].eq(nil),
        'Total persons' => Arel.sql('1=1'),
      }.freeze
    end

    private def lengths
      {
        '0 to 7 days' => a_t[:length_of_stay].between(0..7),
        '8 to 14 days' => a_t[:length_of_stay].between(8..14),
        '15 to 21 days' => a_t[:length_of_stay].between(15..21),
        '22 to 30 days' => a_t[:length_of_stay].between(22..30),
        '30 days or less' => a_t[:length_of_stay].lteq(30),
        '31 to 60 days' => a_t[:length_of_stay].between(31..60),
        '61 to 90 days' => a_t[:length_of_stay].between(61..90),
        '61 to 180 days' => a_t[:length_of_stay].between(61..180),
        '91 to 180 days' => a_t[:length_of_stay].between(91..180),
        '181 to 365 days' => a_t[:length_of_stay].between(181..365),
        '366 to 730 days (1-2 Yrs)' => a_t[:length_of_stay].between(366..730),
        '731 to 1,095 days (2-3 Yrs)' => a_t[:length_of_stay].between(731..1_095),
        '731 days or more' => a_t[:length_of_stay].gteq(731),
        '1,096 to 1,460 days (3-4 Yrs)' => a_t[:length_of_stay].between(1_096..1_460),
        '1,461 to 1,825 days (4-5 Yrs)' => a_t[:length_of_stay].between(1_461..1_825),
        'More than 1,825 days (> 5 Yrs)' => a_t[:length_of_stay].gteq(1_825),
        'Data Not Collected' => a_t[:length_of_stay].eq(nil),
        'Total' => Arel.sql('1=1'),
      }.freeze
    end

    private def intentionally_blank
      [].freeze
    end

    private def universe
      batch_initializer = ->(clients_with_enrollments) do
        @household_types = {}
        @times_to_move_in = {}
        @move_in_dates = {}
        @approximate_move_in_dates = {}
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = last_service_history_enrollment.household_id
          @household_types[hh_id] = household_makeup(hh_id, [@report.start_date, last_service_history_enrollment.first_date_in_program].max)

          @times_to_move_in[last_service_history_enrollment.client_id] = time_to_move_in(last_service_history_enrollment)
          @move_in_dates[last_service_history_enrollment.client_id] = appropriate_move_in_date(last_service_history_enrollment)
          @approximate_move_in_dates[last_service_history_enrollment.client_id] = approximate_time_to_move_in(last_service_history_enrollment)
        end
      end

      @universe ||= build_universe(
        QUESTION_NUMBER,
        before_block: batch_initializer,
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
          head_of_household: last_service_history_enrollment[:head_of_household],
          head_of_household_id: last_service_history_enrollment.head_of_household_id,
          length_of_stay: stay_length(last_service_history_enrollment),
          time_to_move_in: @times_to_move_in[last_service_history_enrollment.client_id],
          household_type: @household_types[last_service_history_enrollment.household_id],
          project_type: last_service_history_enrollment.computed_project_type,
          move_in_date: @move_in_dates[last_service_history_enrollment.client_id],
          date_to_street: last_service_history_enrollment.enrollment.DateToStreetESSH,
          approximate_time_to_move_in: @approximate_move_in_dates[last_service_history_enrollment.client_id],
        )
      end
    end
  end
end
