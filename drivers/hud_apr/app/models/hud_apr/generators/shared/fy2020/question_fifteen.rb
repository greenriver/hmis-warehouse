###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionFifteen < Base
    QUESTION_NUMBER = 'Question 15'.freeze
    QUESTION_TABLE_NUMBER = 'Q15'.freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q15_living_situation
      metadata = {
        header_row: [' '] + sub_populations.keys,
        row_labels: living_situation_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 35,
      }
      @report.answer(question: QUESTION_TABLE_NUMBER).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      sub_populations.each_with_index do |(_, population_clause), col_index|
        living_situations.to_a.each_with_index do |(_, situation_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: QUESTION_TABLE_NUMBER, cell: cell)
          members = universe.members.
            where(adult_or_hoh_clause).
            where(population_clause).
            where(situation_clause)
          answer.add_members(members)
          answer.update(summary: members.count)
        end
      end
    end

    private def living_situation_headers
      living_situations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def living_situations
      {
        'Homeless Situations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:prior_living_situation].eq(1),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:prior_living_situation].eq(2),
        'Place not meant for habitation' => a_t[:prior_living_situation].eq(16),
        'Safe Haven' => a_t[:prior_living_situation].eq(18),
        'Host Home (non-crisis)' => a_t[:prior_living_situation].eq(32),
        'Subtotal - Homeless' => a_t[:prior_living_situation].in([1, 2, 16, 18, 32]),
        'Institutional Settings' => nil,
        'Psychiatric hospital or other psychiatric facility' => a_t[:prior_living_situation].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:prior_living_situation].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:prior_living_situation].eq(6),
        'Jail, prison or juvenile detention facility' => a_t[:prior_living_situation].eq(7),
        'Foster care home or foster care group home' => a_t[:prior_living_situation].eq(15),
        'Long-term care facility or nursing home' => a_t[:prior_living_situation].eq(25),
        'Residential project or halfway house with no homeless criteria' => a_t[:prior_living_situation].eq(29),
        'Subtotal - Institutional' => a_t[:prior_living_situation].in([4, 5, 6, 7, 15, 25, 29]),
        'Other Locations' => nil,
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:prior_living_situation].eq(3),
        'Owned by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:prior_living_situation].eq(21),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:prior_living_situation].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:prior_living_situation].eq(33),
        'Rental by client in a public housing unit' => a_t[:prior_living_situation].eq(34),
        'Rental by client, no ongoing housing subsidy' => a_t[:prior_living_situation].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:prior_living_situation].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:prior_living_situation].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:prior_living_situation].eq(20),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:prior_living_situation].eq(14),
        "Staying or living in a friend's room, apartment or house" => a_t[:prior_living_situation].eq(36),
        "Staying or living in a family member's room, apartment or house" => a_t[:prior_living_situation].eq(35),
        'Client Doesn’t Know/Client Refused' => a_t[:prior_living_situation].in([8, 9]),
        'Data Not Collected' => a_t[:prior_living_situation].eq(99).or(a_t[:prior_living_situation].eq(nil)),
        'Subtotal - Other' => a_t[:prior_living_situation].in(
          [
            3,
            11,
            21,
            31,
            33,
            34,
            10,
            19,
            28,
            20,
            14,
            36,
            35,
            8,
            9,
            99,
          ],
        ).or(a_t[:prior_living_situation].eq(nil)),
        'Total' => Arel.sql('1=1'),
      }
    end

    private def intentionally_blank
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B9',
        'C9',
        'D9',
        'E9',
        'F9',
        'B18',
        'C18',
        'D18',
        'E18',
        'F18',
      ].freeze
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

      @universe ||= build_universe(QUESTION_NUMBER, before_block: batch_initializer) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client
        client_start_date = [@report.start_date, last_service_history_enrollment.first_date_in_program].max

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          age: source_client.age_on(client_start_date),
          prior_living_situation: enrollment.LivingSituation,
          household_type: @household_types[last_service_history_enrollment.household_id],
          first_date_in_program: last_service_history_enrollment.first_date_in_program,
          last_date_in_program: last_service_history_enrollment.last_date_in_program,
        )
      end
    end
  end
end
