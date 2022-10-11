###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class QuestionTwentyFive < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q25: Housing Outcomes'.freeze
    QUESTION_TABLE_NUMBER = 'Q25'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    TABLE_HEADER = [
      '25. Destination at Exit',
      'count',
    ].freeze

    ROWS = [
      ['Temporary Destinations', nil],
      ['Emergency shelter, including hotel or motel paid for with emergency shelter voucher, or RHY-funded Host Home Shelter', 1],
      ['Moved from one HOPWA funded project to HOPWA TH', 27],
      ['Transitional housing for homeless persons', 2],
      ['Staying or living with family, temporary tenure (e.g. room, apartment, or house)', 12],
      ['Staying or living with friends, temporary tenure (e.g. room, apartment, or house)', 13],
      ['Place not meant for habitation (e.g., a vehicle, an abandoned building, bus/train/subway station/airport or anywhere outside)', 16],
      ['Safe Haven', 18],
      ['Hotel or motel paid for without emergency shelter voucher', 14],
      ['Host Home (non-crisis)', 32],
      ['Subtotal', :subtotal],
      ['Institutional Situation', nil],
      ['Foster care home or foster care group home', 15],
      ['Psychiatric hospital or other psychiatric facility', 4],
      ['Substance abuse treatment facility or detox center', 5],
      ['Hospital or other residential non-psychiatric medical facility', 6],
      ['Jail, prison, or juvenile detention facility', 7],
      ['Long-term care facility or nursing home', 25],
      ['Subtotal', :subtotal],
      ['Permanent Destinations', nil],
      ['Moved from one HOPWA funded project to HOPWA PH', 25],
      ['Owned by client, no ongoing housing subsidy', 11],
      ['Owned by client, with ongoing housing subsidy', 21],
      ['Permanent housing (other than RRH) for formerly homeless persons', 3],
      ['Rental by client, no ongoing housing subsidy', 10],
      ['Rental by client, with RRH or equivalent subsidy', 31],
      ['Rental by client, with VASH housing subsidy', 19],
      ['Rental by client, with GPD TIP housing subsidy', 28],
      ['Rental by client, with other ongoing housing subsidy', 20],
      ['Rental by client with HCV voucher (tenant or project based)', 33],
      ['Rental by client in a public housing unit', 34],
      ['Residential project or halfway house with no homeless criteria', 29],
      ['Staying or living with family, permanent tenure', 22],
      ['Staying or living with friends, permanent tenure', 23],
      ['Subtotal', :subtotal],
      ['Other Destinations', nil],
      ['Deceased', 24],
      ['Other', 17],
      ['No exit interview completed', 30],
      ['Client doesn\'t know', 8],
      ['Client refused', 9],
      ['Data not collected', 99],
      ['Subtotal', :subtotal],
      ['PATH-enrolled clients still active as of report end date (stayers)', :stayers],
      ['Total', :total],
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: ROWS.map(&:first),
        first_column: 'B',
        last_column: 'B',
        first_row: 2,
        last_row: 46,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      sum = 0
      sum_members = []
      ROWS.each_with_index do |(_label, destination), index|
        answer = @report.answer(question: table_name, cell: 'B' + (index + 2).to_s)
        case destination
        when nil # Internal label, leave blank
          next
        when :subtotal # Section sums
          answer.update(summary: sum)
          sum = 0
          answer.add_members(sum_members)
          sum_members = []
          next
        when :stayers
          members = universe.members.where(active_and_enrolled_clients).where(stayers)
        when :total
          members = universe.members.where(active_and_enrolled_clients)
        else
          query = a_t[:destination].eq(destination)
          query = query.or(a_t[:destination].eq(nil)) if destination == 99 # Also recognize blank as not collected
          members = universe.members.where(active_and_enrolled_clients).where(query)
        end
        answer.add_members(members)
        sum_members += members
        count = members.count
        sum += count
        answer.update(summary: count)
      end

      @report.complete(QUESTION_NUMBER)
    end
  end
end
