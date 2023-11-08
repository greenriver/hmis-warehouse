###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudPathReport::Generators::Fy2024
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
        '26c. Race and Ethnicity' => races,
        '26e. Veteran Status (adults only)' => veteran_statuses,
        '26f. Co-occurring disorder' => substance_use_disorders,
        '26g. Connection with SOAR' => soar_connections,
        '26h. Prior Living Situation' => prior_living_situations,
        '26i. Length of stay in prior living situation (emergency shelter or place not meant for human habitation only)' => length_of_stays,
        '26j. Chronically homeless (at project start)' => chronically_homeless_statuses,
        '26k. Survivor of Domestic Violence (adults only)' => domestic_violence_statuses,
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
        last_row: 98,
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
      gender_col = a_t[:gender_multi]
      [
        ['Woman (Girl, if child)', 0],
        ['Man (Boy, if child)', 1],
        ['Culturally Specific Identity (e.g., Two-Spirit)', 2],
        ['Transgender', 5],
        ['Non-Binary', 4],
        ['Questioning', 6],
        ['Different Identity', 3],
        ['Client doesn’t know', 8],
        ['Client prefers not to answer', 9],
        ['Data not collected', 99],
      ].to_h do |label, value|
        [label, gender_col.matches_regexp("(^|,)#{value}(,|$)")]
      end.merge('Total' => :total)
    end

    private def age_ranges
      {
        '17 and under' => a_t[:age].between(0..17).and(a_t[:dob_quality].in([1, 2])),
        '18-24' => a_t[:age].between(18..24).and(a_t[:dob_quality].in([1, 2])),
        '25-34' => a_t[:age].between(25..34).and(a_t[:dob_quality].in([1, 2])),
        '35-44' => a_t[:age].between(35..44).and(a_t[:dob_quality].in([1, 2])),
        '45-54' => a_t[:age].between(45..54).and(a_t[:dob_quality].in([1, 2])),
        '55-64' => a_t[:age].between(55..64).and(a_t[:dob_quality].in([1, 2])),
        '65+' => a_t[:age].gteq(65).and(a_t[:dob_quality].in([1, 2])),
        "Client doesn't know" => a_t[:dob_quality].eq(8),
        'Client prefers not to answer' => a_t[:dob_quality].eq(9),
        'Data not collected' => a_t[:dob_quality].not_in([8, 9]).and(a_t[:dob_quality].eq(99).or(a_t[:dob_quality].eq(nil)).or(a_t[:age].lt(0)).or(a_t[:age].eq(nil))),
        'Total' => :total,
      }.freeze
    end

    private def races
      race_col = a_t[:race_multi]
      [
        ['American Indian, Alaska Native, or Indigenous', 1],
        ['Asian or Asian American', 2],
        ['Black, African American, or African', 3],
        ['Hispanic/Latina/e/o', 6],
        ['Middle Eastern or North African', 7],
        ['Native Hawaiian or Pacific Islander', 4],
        ['White', 5],
        ['Client doesn’t know', 8],
        ['Client prefers not to answer', 9],
        ['Data not collected', 99],
      ].to_h do |label, value|
        [label, race_col.matches_regexp("(^|,)#{value}(,|$)")]
      end.merge('Total' => :total)
    end

    private def veteran_statuses
      {
        'Veteran' => adults.and(a_t[:veteran].eq(1)),
        'Non-veteran' => adults.and(a_t[:veteran].eq(0)),
        "Client doesn't know" => adults.and(a_t[:veteran].eq(8)),
        'Client prefers not to answer' => adults.and(a_t[:veteran].eq(9)),
        'Data not collected' => adults.and(a_t[:veteran].eq(99).or(a_t[:veteran].eq(nil))),
        'Total' => :total,
      }.freeze
    end

    private def substance_use_disorders
      {
        'Co-occurring substance use disorder' => a_t[:substance_use_disorder].in([1, 2, 3]),
        'No co-occurring substance use disorder' => a_t[:substance_use_disorder].eq(0),
        'Unknown' => a_t[:substance_use_disorder].in([8, 9, 99]).or(a_t[:substance_use_disorder].eq(nil)),
        'Total' => :total,
      }
    end

    private def soar_connections
      {
        'Yes' => a_t[:soar].eq(1),
        'No' => a_t[:soar].eq(0),
        "Client doesn't know" => a_t[:soar].eq(8),
        'Client prefers not to answer' => a_t[:soar].eq(9),
        'Data not collected' => a_t[:soar].eq(99).or(a_t[:soar].eq(nil)),
        'Total' => :total,
      }
    end

    def prior_living_situation_rows
      excluded_values = [327, 422, 423, 426, 30, 17, 24, :subtotal, :stayers].to_set
      PRIOR_LIVING_SITUATION_ROWS.filter do |_, v|
        !v.in?(excluded_values)
      end
    end

    private def prior_living_situations
      prior_living_situation_rows.to_h do |label, value|
        next [label, value] unless value.is_a? Integer

        query = a_t[:prior_living_situation].eq(value)
        query = query.or(a_t[:prior_living_situation].eq(nil)) if value == 99
        [label, query]
      end
    end

    private def length_of_stays
      h = [10, 11, 2, 3, 4, 5, 8, 9, 99].map do |v|
        query = a_t[:length_of_stay].eq(v)
        query = query.or(a_t[:length_of_stay].eq(nil)) if v == 99
        [
          HudUtility2024.length_of_stays[v],
          a_t[:prior_living_situation].in([1, 16]).and(query),
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
        'Client prefers not to answer' => adults.and(a_t[:domestic_violence].eq(9)),
        'Data not collected' => adults.and(a_t[:domestic_violence].eq(99).or(a_t[:domestic_violence].eq(nil))),
        'Total' => :total,
      }.freeze
    end
  end
end
