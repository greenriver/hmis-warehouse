###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionTwentyThree < Base
    QUESTION_NUMBER = 'Question 23'.freeze
    QUESTION_TABLE_NUMBERS = ['Q23c'].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    private def q23c_destination
      table_name = 'Q23c'
      metadata = {
        header_row: [' '] + q23c_populations.keys,
        row_labels: q23c_destinations_headers,
        first_column: 'B',
        last_column: 'F',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      cols = (metadata[:first_column]..metadata[:last_column]).to_a
      rows = (metadata[:first_row]..metadata[:last_row]).to_a
      q23c_populations.each_with_index do |(_, population_clause), col_index|
        q23c_destinations.to_a.each_with_index do |(_, destination_clause), row_index|
          cell = "#{cols[col_index]}#{rows[row_index]}"
          next if intentionally_blank.include?(cell)

          answer = @report.answer(question: table_name, cell: cell)
          value = 0

          if destination_clause.is_a?(Symbol)
            case destination_clause
            when :percentage
              members = universe.members.where(population_clause)
              positive = members.where(q23c_destinations['Total persons exiting to positive housing destinations']).count
              total = members.count
              excluded = members.where(q23c_destinations['Total persons whose destinations excluded them from the calculation']).count
              value = (positive.to_f / (total - excluded) * 100).round(4) if total.positive? && excluded != total
            end
          else
            members = universe.members.where(population_clause).where(destination_clause)
            value = members.count
          end
          answer.add_members(members)
          answer.update(summary: value)
        end
      end
    end

    private def q23c_destinations_headers
      q23c_destinations.keys.map do |label|
        next 'Subtotal' if label.include?('Subtotal')

        label
      end
    end

    private def q23c_populations
      @q23c_populations ||= sub_populations
    end

    private def q23c_destinations
      {
        'Permanent Destinations' => nil,
        'Moved from one HOPWA funded project to HOPWA PH' => a_t[:destination].eq(26),
        'Owned by client, no ongoing housing subsidy' => a_t[:destination].eq(11),
        'Owned by client, with ongoing housing subsidy' => a_t[:destination].eq(21),
        'Rental by client, no ongoing housing subsidy' => a_t[:destination].eq(10),
        'Rental by client, with VASH housing subsidy' => a_t[:destination].eq(19),
        'Rental by client, with GPD TIP housing subsidy' => a_t[:destination].eq(28),
        'Rental by client, with other ongoing housing subsidy' => a_t[:destination].eq(20),
        'Permanent housing (other than RRH) for formerly homeless persons' => a_t[:destination].eq(3),
        'Staying or living with family, permanent tenure' => a_t[:destination].eq(22),
        'Staying or living with friends, permanent tenure' => a_t[:destination].eq(23),
        'Rental by client, with RRH or equivalent subsidy' => a_t[:destination].eq(31),
        'Rental by client, with HCV voucher (tenant or project based)' => a_t[:destination].eq(33),
        'Rental by client in a public housing unit' => a_t[:destination].eq(34),
        'Subtotal - Permanent' => a_t[:destination].in([26, 11, 21, 10, 19, 28, 20, 3, 22, 23, 31, 33, 34]),
        'Temporary Destinations' => nil,
        'Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home shelter' => a_t[:destination].eq(1),
        'Moved from one HOPWA funded project to HOPWA TH' => a_t[:destination].eq(27),
        'Transitional housing for homeless persons (including homeless youth)' => a_t[:destination].eq(2),
        'Staying or living with family, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(12),
        'Staying or living with friends, temporary tenure (e.g. room, apartment or house)' => a_t[:destination].eq(13),
        'Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)' => a_t[:destination].eq(16),
        'Safe Haven' => a_t[:destination].eq(18),
        'Hotel or motel paid for without emergency shelter voucher' => a_t[:destination].eq(14),
        'Host Home (non-crisis)' => a_t[:destination].eq(32),
        'Subtotal - Temporary' => a_t[:destination].in([1, 27, 2, 12, 13, 16, 18, 14, 32]),
        'Institutional Settings' => nil,
        'Foster care home or group foster care home' => a_t[:destination].eq(15),
        'Psychiatric hospital or other psychiatric facility' => a_t[:destination].eq(4),
        'Substance abuse treatment facility or detox center' => a_t[:destination].eq(5),
        'Hospital or other residential non-psychiatric medical facility' => a_t[:destination].eq(6),
        'Jail, prison, or juvenile detention facility' => a_t[:destination].eq(7),
        'Long-term care facility or nursing home' => a_t[:destination].eq(25),
        'Subtotal - Institutional' => a_t[:destination].in([15, 4, 5, 6, 7, 25]),
        'Other Destinations' => nil,
        'Residential project or halfway house with no homeless criteria' => a_t[:destination].eq(29),
        'Deceased' => a_t[:destination].eq(24),
        'Other' => a_t[:destination].eq(17),
        "Client Doesn't Know/Client Refused" => a_t[:destination].in([8, 9]),
        'Data Not Collected (no exit interview completed)' => a_t[:destination].in([30, 99]),
        'Subtotal - Other' => a_t[:destination].in([29, 24, 17, 8, 9, 30, 99]),
        'Total' => leavers_clause,
        'Total persons exiting to positive housing destinations' => a_t[:project_type].in([1, 2]).
          and(a_t[:destination].in(positive_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(positive_destinations(4)))).
          or(a_t[:project_type].not_in([1, 2, 4]).and(a_t[:destination].in(positive_destinations(8)))),
        'Total persons whose destinations excluded them from the calculation' => a_t[:project_type].not_eq(4).
          and(a_t[:destination].in(excluded_destinations(1))).
          or(a_t[:project_type].eq(4).and(a_t[:destination].in(excluded_destinations(4)))),
        'Percentage' => :percentage,
      }.freeze
    end

    private def intentionally_blank
      [
        'B2',
        'C2',
        'D2',
        'E2',
        'F2',
        'B17',
        'C17',
        'D17',
        'E17',
        'F17',
        'B28',
        'C28',
        'D28',
        'E28',
        'F28',
        'B36',
        'C36',
        'D36',
        'E36',
        'F36',
      ].freeze
    end

    private def positive_destinations(project_type)
      case project_type
      when 4
        [1, 15, 14, 27, 4, 18, 12, 13, 5, 2, 25, 32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      when 1, 2
        [32, 26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      else
        [26, 11, 21, 3, 10, 28, 20, 19, 22, 23, 31, 33, 34]
      end
    end

    private def excluded_destinations(project_type)
      case project_type
      when 4
        [6, 29, 24]
      else
        [15, 6, 25, 24]
      end
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
          household_type: @household_types[last_service_history_enrollment.household_id],
          project_type: last_service_history_enrollment.computed_project_type,
          destination: last_service_history_enrollment.destination,
        )
      end
    end
  end
end
