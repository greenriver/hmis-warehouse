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
        header_row: [' '] + populations.keys,
        row_labels: q22a1_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 13,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      populations.each_with_index do |(_, population_clause), col_index|
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
        header_row: [' '] + populations.keys,
        row_labels: q22b1_lengths.keys,
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 17,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      populations.each_with_index do |(_, population_clause), col_index|
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

    private def populations
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
        '0 to 7 days' => '7 days or less',
        '8 to 14 days' => '8 to 14 days',
        '15 to 21 days' => '15 to 21 days',
        '22 to 30 days' => '22 to 30 days',
        '31 to 60 days' => '31 to 60 days',
        '61 to 180 days' => '61 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
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
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
    end

    private def q22e_lengths
      {
        '0 to 7 days' => '7 days or less',
        '8 to 14 days' => '8 to 14 days',
        '15 to 21 days' => '15 to 21 days',
        '22 to 30 days' => '22 to 30 days',
        '31 to 60 days' => '31 to 60 days',
        '61 to 180 days' => '61 to 180 days',
        '181 to 365 days' => '181 to 365 days',
        '366 to 730 days (1-2 Yrs)' => '366 to 730 days (1-2 Yrs)',
        '731 days or more' => '731 days or more',
        'Data Not Collected' => 'Data Not Collected',
      }.map do |k, label|
        [label, lengths[k]]
      end.to_h
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
        clients_with_enrollments.each do |_, enrollments|
          last_service_history_enrollment = enrollments.last
          hh_id = last_service_history_enrollment.household_id
          @household_types[hh_id] = household_makeup(hh_id, [@report.start_date, last_service_history_enrollment.first_date_in_program].max)
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
          household_type: @household_types[last_service_history_enrollment.household_id],
        )
      end
    end
  end
end
