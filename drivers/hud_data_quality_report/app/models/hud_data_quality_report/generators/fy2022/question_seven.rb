###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudDataQualityReport::Generators::Fy2022
  class QuestionSeven < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 7'.freeze
    QUESTION_TABLE_NUMBER = 'Q7'.freeze
    QUESTION_TABLE_NUMBERS = [QUESTION_TABLE_NUMBER].freeze

    def self.table_descriptions
      {
        'Question 7' => 'Inactive Records: Street Outreach & Emergency Shelter',
      }.freeze
    end

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, [QUESTION_TABLE_NUMBER])
      table_name = QUESTION_TABLE_NUMBER

      metadata = {
        header_row: [
          'Data Element',
          '# of Records',
          '# of Inactive Records',
          '% of Inactive Records',
        ],
        row_labels: [
          'Contact (Adults and Heads of Household in Street Outreach or ES – NBN)',
          'Bed Night (All clients in ES – NBN)',
        ],
        first_column: 'B',
        last_column: 'D',
        first_row: 2,
        last_row: 3,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      # Clients whose enrollment date is more than 90 days before the end of the report, and are still
      # enrolled until after the reporting period
      relevant_clients = universe.universe_members.joins(:dq_client).
        joins(report_cell: :report_instance).
        where(
          datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:first_date_in_program]).gteq(90).
            and(
              a_t[:last_date_in_program].eq(nil).
                or(a_t[:last_date_in_program].gt(@report.end_date)),
            ),
        )

      # Relevant Adults and HoH ES-NBN or SO
      answer = @report.answer(question: table_name, cell: 'B2')
      adults_and_hohs = relevant_clients.where(adult_or_hoh_clause)

      es_so_members = adults_and_hohs.where(
        a_t[:project_type].eq(4).
          and(a_t[:date_of_engagement].lt(@report.end_date)).
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
        first_date_in_program = member.universe_membership.first_date_in_program
        next if first_date_in_program > @report.end_date - 90.days # Less than 90 days in report period

        last_current_living_situation = [
          member.universe_membership.hud_report_dq_living_situations.maximum(:information_date),
          first_date_in_program,
        ].compact.max
        es_so_member_ids << member.id if (@report.end_date - last_current_living_situation).to_i > 90
      end

      inactive_es_so_members = es_so_members.where(id: es_so_member_ids)
      answer.add_members(inactive_es_so_members)
      answer.update(summary: inactive_es_so_members.count)

      # percent inactive ES or SO
      answer = @report.answer(question: table_name, cell: 'D2')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: percentage(inactive_es_so_members.count / es_so_members.count.to_f))

      # Relevant ES-NBN
      answer = @report.answer(question: table_name, cell: 'B3')
      es_members = relevant_clients.where(
        a_t[:project_type].eq(1).
          and(a_t[:project_tracking_method].eq(3)),
      )
      answer.add_members(es_members)
      answer.update(summary: es_members.count)

      # Inactive ES
      answer = @report.answer(question: table_name, cell: 'C3')
      inactive_es_members = es_members.where(
        datediff(report_client_universe, 'day', hr_ri_t[:end_date], a_t[:date_of_last_bed_night]).gt(90),
      )
      answer.add_members(inactive_es_members)
      answer.update(summary: inactive_es_members.count)

      # percent inactive ES
      answer = @report.answer(question: table_name, cell: 'D3')
      answer.add_members(inactive_es_so_members)
      answer.update(summary: percentage(inactive_es_members.count / es_members.count.to_f))

      @report.complete(QUESTION_NUMBER)
    end
  end
end
