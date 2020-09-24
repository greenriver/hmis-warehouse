###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionNine < Base
    include ArelHelper

    QUESTION_NUMBER = 'Question 9'.freeze
    QUESTION_TABLE_NUMBERS = ['Q9a', 'Q9b'].freeze

    HEADER_ROW = [
      'Number of Persons Contacted',
      'All Persons Contacted',
      'First contact – NOT staying on the Streets, ES, or SH',
      'First contact – WAS staying on Streets, ES, or SH',
      'First contact – Worker unable to determine',
    ].freeze

    def self.question_number
      QUESTION_NUMBER
    end

    def run_question!
      @report.start(QUESTION_NUMBER, QUESTION_TABLE_NUMBERS)

      contact_counts = q9a_contacted
      q9b_engaged(contact_counts)

      @report.complete(QUESTION_NUMBER)
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def ls_t
      @ls_t ||= report_living_situation_universe.arel_table
    end

    private def q9a_contacted
      table_name = 'Q9a'

      adults_and_hohs =  universe.members.where(adult_or_hoh_clause)
      contacted_ids = adults_and_hohs.joins(apr_client: :hud_report_apr_living_situations).
        where(
          ls_t[:information_date].between(@report.start_date..@report.end_date).
            and(a_t[:date_of_engagement].gteq(ls_t[:information_date]).
              or(a_t[:date_of_engagement].eq(nil))).
            or(a_t[:date_of_engagement].between(@report.start_date..@report.end_date)),
        ).
        pluck(a_t[:id])

      populate_table(table_name, 6, 'Contacted', contacted_ids)
    end

    private  def q9b_engaged(contact_counts)
      table_name = 'Q9b'

      adults_and_hohs =  universe.members.where(adult_or_hoh_clause)
      engaged_ids = adults_and_hohs.where(a_t[:date_of_engagement].between(@report.start_date..@report.end_date)).pluck(:id)

      engaged_counts = populate_table(table_name, 7, 'Engaged', engaged_ids)
      engaged_counts.each do |col, count|
        ratio = format('%1.4f', count / contact_counts[col].to_f)
        @report.answer(question: table_name, cell: "#{col}").update(summary: ratio)
      end
    end

    private def populate_table(table_name, table_rows, label, client_ids)
      buckets = {
        2 => ['Once', (1..1)],
        3 => ['2-5 Times', (2..5)],
        4 => ['6-9 Times', (6..9)],
        5 => ['10+ Times', (10..)],
        6 => ["Total Persons #{label}", (1..)],
      }

      last_row = {}

      metadata = {
        header_row: HEADER_ROW,
        row_labels: buckets.values.map(&:first),
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: table_rows,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      situations = report_living_situation_universe.
        where(hud_report_apr_client_id: client_ids).
        order(information_date: :asc).
        group_by(&:hud_report_apr_client_id)

      [
        {
          column: 'B',
          situations: HUD.living_situations.keys,
        },
        {
          column: 'C',
          situations: HUD.living_situations.keys - [16, 1, 18, 37, 8, 9, 99],
        },
        {
          column: 'D',
          situations: [16, 1, 18],
        },
        {
          column: 'E',
          situations: [37, 8, 9, 99],
        }
      ].each do |col|
        clients = situations.select { |k, v| (v.living_situation & col[:situations]).present? }
        buckets.each do |row, (_, range)|
          cell = "#{col[:columm]}#{row}"
          answer = @report.answer(question: table_name, cell: cell)
          member_ids = clients.select { |k, v| range.cover?(v.length) }.keys
          members = universe.members.where(a_t[:id].in(member_ids))
          answer.add_members(members)
          count = members.count
          answer.update(summary: count)
          last_row[col[:column]] = count
        end
      end

      last_row
    end

    private def universe
      batch_initializer = ->(clients_with_enrollments) do
      end

      batch_finalizer = ->(clients_with_enrollments, report_clients) do
        living_situations = []

        report_clients.each do |client, apr_client|
          last_enrollment = clients_with_enrollments[client.id].last.enrollment
          last_enrollment.current_living_situations.each do |living_situation|
            living_situations << apr_client.hud_report_apr_living_situations.build(
              information_date: living_situation.InformationDate,
              living_situation: living_situation.CurrentLivingSituation,
            )
          end
        end

        report_living_situation_universe.import(
          living_situations,
          on_duplicate_key_update: {
            conflict_target: [:apr_client_id],
            columns: living_situations.first&.changed || [],
          },
        )
      end

      @universe ||= build_universe(
        QUESTION_NUMBER,
        preloads: {
          enrollment: [
            :client,
            :current_living_situations,
          ],
        },
        before_block: batch_initializer,
        after_block: batch_finalizer,
      ) do |_, enrollments|
        last_service_history_enrollment = enrollments.last
        enrollment = last_service_history_enrollment.enrollment
        source_client = enrollment.client

        report_client_universe.new(
          client_id: source_client.id,
          data_source_id: source_client.data_source_id,
          report_instance_id: @report.id,

          project_type: last_service_history_enrollment.project_type,
          project_tracking_method: last_service_history_enrollment.project_tracking_method,
          date_of_engagement: last_service_history_enrollment.enrollment.DateOfEngagement,
        )
      end
    end
  end
end
