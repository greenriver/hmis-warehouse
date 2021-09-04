###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2021
  class QuestionTwentySix < Base
    include ArelHelper

    QUESTION_NUMBER = 'Q26: Demographics'.freeze
    QUESTION_TABLE_NUMBER = 'Q26'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    EMPTY_CELL = ' '.freeze

    TABLE_HEADER = [
      EMPTY_CELL,
      EMPTY_CELL,
      'Of those with an active, enrolled PATH status during this reporting period, how many individuals are in each of the following categories?',
    ].freeze

    def sections
      {
        '26a. Gender' => genders,
        '26b. Age' => age_ranges,
        '26c. Race (Note: An individual who identifies as multiracial should be counted in all applicable categories. This demographic element will not sum to total persons enrolled)' => races,
        '26d. Ethnicity' => ethnicities,
        '26e. Veteran Status (adults only)' => veteran_statuses,
        '26f. Co-occurring disorder' => substance_use_disorders,
        '26g. SOAR connection' => soar_connections,
        '26h. Prior Living Situation' => prior_living_situations,
        '26i. Length of stay in prior living situation (emergency shelter or place not meant for human habitation only)' => length_of_stays,
        '26j. Chronically homeless (at project start)' => chronically_homeless_statuses,
        '26k. Domestic Violence History (adults only)' => domestic_violence_statuses,
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: TABLE_HEADER,
        row_labels: [],
        first_column: 'A',
        last_column: 'C',
        first_row: 2,
        last_row: 104, # Line 57 is skipped in the spec
      }
      @report.answer(question: table_name).update(metadata: metadata)

      row_number = 2
      sections.each do |section_label, contents|
        sum = 0
        sum_members = []
        contents.each_with_index do |(label, query), index|
          answer = @report.answer(question: table_name, cell: 'A' + row_number.to_s)
          if index.zero?
            answer.update(summary: section_label)
          else
            answer.update(summary: EMPTY_CELL)
          end

          answer = @report.answer(question: table_name, cell: 'B' + row_number.to_s)
          answer.update(summary: label)

          if query.present?
            answer = @report.answer(question: table_name, cell: 'C' + row_number.to_s)
            if query == :total
              answer.update(summary: sum)
              answer.add_members(sum_members)
            else
              members = universe.members.where(active_and_enrolled_clients).where(query)
              answer.add_members(members)
              sum_members += members
              count = members.count
              sum += count
              answer.update(summary: count)
            end
          end
          row_number += 1
        end
      end

      @report.complete(QUESTION_NUMBER)
    end

    private def genders
      {
        'Female' => a_t[:gender_multi].eq(0),
        'Male' => a_t[:gender_multi].eq(1),
        'No Single Gender' => a_t[:gender_multi].in(::HUD.no_single_gender_queries),
        'Questioning' => a_t[:gender_multi].in(::HUD.questioning_gender_queries),
        'Transgender' => a_t[:gender_multi].in(::HUD.transgender_gender_queries),
        'Client doesn\'t know' => a_t[:gender_multi].eq(8),
        'Client refused' => a_t[:gender_multi].eq(9),
        'Data not collected' => a_t[:gender_multi].eq(99),
        'Total' => :total,
      }.freeze
    end

    private def age_ranges
      {
        '17 and under' => a_t[:age].between(0..17).and(a_t[:dob_quality].in([1, 2])),
        '18-23' => a_t[:age].between(18..23).and(a_t[:dob_quality].in([1, 2])),
        '24-30' => a_t[:age].between(24..30).and(a_t[:dob_quality].in([1, 2])),
        '31-40' => a_t[:age].between(31..40).and(a_t[:dob_quality].in([1, 2])),
        '41-50' => a_t[:age].between(41..50).and(a_t[:dob_quality].in([1, 2])),
        '51-61' => a_t[:age].between(51..61).and(a_t[:dob_quality].in([1, 2])),
        '62 and over' => a_t[:age].between(55..61).and(a_t[:dob_quality].in([1, 2])),
        "Client doesn't know" => a_t[:dob_quality].eq(8),
        'Client refused' => a_t[:dob_quality].eq(9),
        'Data not collected' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
        'Total' => :total,
      }.freeze
    end

    private def races
      # Hard coding here until we receive 2022 specs
      # h = HUD.races.reject { |k, _| k == 'RaceNone' }.
      h = {
        'AmIndAKNative' => 'American Indian, Alaska Native, or Indigenous', # 1
        'Asian' => 'Asian or Asian American', # 2
        'BlackAfAmerican' => 'Black, African American, or African', # 3
        'NativeHIOtherPacific' => 'Native Hawaiian or Pacific Islander', # 4
        'White' => 'White', # 5
      }.map do |k, v|
        [
          v,
          a_t[k.underscore].eq(1),
        ]
      end.to_h
      [8, 9, 99].each do |v|
        h[HUD.race_none(v)] = a_t[:race_none].eq(v)
      end
      h['Total'] = nil
      h.freeze
    end

    private def ethnicities
      {
        'Non-Hispanic/Non-Latin(a)(o)(x)' => a_t[:ethnicity].eq(0),
        'Hispanic/Latin(a)(o)(x)' => a_t[:ethnicity].eq(1),
        'Client Doesn\'t Know' => a_t[:ethnicity].eq(8),
        'Client Refused' => a_t[:ethnicity].eq(9),
        'Data Not Collected' => a_t[:ethnicity].eq(99),
        'Total' => :total,
      }.freeze
    end

    private def veteran_statuses
      {
        'Veteran' => adults.and(a_t[:veteran].eq(1)),
        'Non-veteran' => adults.and(a_t[:veteran].eq(0)),
        "Client doesn't know" => adults.and(a_t[:veteran].eq(8)),
        'Client refused' => adults.and(a_t[:veteran].eq(9)),
        'Data not collected' => adults.and(a_t[:veteran].eq(99)),
        'Total' => :total,
      }.freeze
    end

    private def substance_use_disorders
      {
        'Co-occurring substance use disorder' => a_t[:substance_use_disorder].in([1, 2, 3]),
        'No co-occurring substance use disorder' => a_t[:substance_use_disorder].eq(0),
        'Unknown' => a_t[:substance_use_disorder].in([8, 9, 99]),
        'Total' => :total,
      }
    end

    private def soar_connections
      {
        'Yes' => a_t[:soar].eq(1),
        'No' => a_t[:soar].eq(0),
        "Client doesn't know" => a_t[:soar].eq(8),
        'Client refused' => a_t[:soar].eq(9),
        'Data not collected' => a_t[:soar].eq(99),
        'Total' => :total,
      }
    end

    private def prior_living_situations
      h = [
        'Literally Homeless',
        16, 1, 18,
        # BLANK_CELL, # Line 57 is missing from the spec
        'Institutional Situation',
        15, 6, 7, 25, 5, 4,
        'Transitional and Permanent Housing Situation',
        14, 11, 21, 3, 10, 19, 28, 31, 20, 33, 34, 29, 35, 36, 2, 32, 8, 9, 99
      ].map do |value|
        if value.is_a?(String)
          [value, nil]
        else
          [
            HUD.available_situations[value],
            a_t[:prior_living_situation].eq(value),
          ]
        end
      end.to_h
      h['Total'] = :total
      h.freeze
    end

    private def length_of_stays
      h = [10, 11, 2, 3, 4, 5, 8, 9, 99].map do |v|
        [
          HUD.length_of_stays[v],
          a_t[:prior_living_situation].in([1, 16]).and(a_t[:length_of_stay].eq(v)),
        ]
      end.to_h
      h['Total'] = :total
      h.freeze
    end

    private def chronically_homeless_statuses
      {
        'Yes' => a_t[:chronically_homeless].eq('yes'),
        'No' => a_t[:chronically_homeless].eq('no'),
        'Unknown' => a_t[:chronically_homeless].not_in(['yes', 'no']),
        'Total' => :total,
      }
    end

    private def domestic_violence_statuses
      {
        'Yes' => adults.and(a_t[:domestic_violence].eq(1)),
        'No' => adults.and(a_t[:domestic_violence].eq(0)),
        "Client doesn't know" => adults.and(a_t[:domestic_violence].eq(8)),
        'Client refused' => adults.and(a_t[:domestic_violence].eq(9)),
        'Data not collected' => adults.and(a_t[:domestic_violence].eq(99)),
        'Total' => :total,
      }.freeze
    end
  end
end
