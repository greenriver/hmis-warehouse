###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2020
  class QuestionNine < Base
    QUESTION_NUMBER = 'Question 9'.freeze

    HEADER_ROW = [
      'Number of Persons Contacted',
      'All Persons Contacted',
      'First contact - NOT staying on the Streets, ES, or SH',
      'First contact - WAS staying on Streets, ES, or SH',
      'First contact - Worker unable to determine',
    ].freeze

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def ls_t
      @ls_t ||= report_living_situation_universe.arel_table
    end

    private def q9a_contacted
      table_name = 'Q9a'

      adults_and_hohs = universe.members.where(adult_or_hoh_clause)
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

    private def q9b_engaged(contact_counts)
      table_name = 'Q9b'

      adults_and_hohs = universe.members.where(adult_or_hoh_clause)
      engaged_ids = adults_and_hohs.where(a_t[:date_of_engagement].between(@report.start_date..@report.end_date)).pluck(a_t[:id])

      engaged_counts = populate_table(table_name, 7, 'Engaged', engaged_ids, summary_row: 'Rate of Engagement')
      engaged_counts.each do |col, count|
        ratio = percentage(count / contact_counts[col].to_f)
        @report.answer(question: table_name, cell: "#{col}7").update(summary: ratio)
      end
    end

    private def populate_table(table_name, table_rows, label, client_ids, summary_row: nil)
      buckets = {
        2 => ['Once', (1..1)],
        3 => ['2-5 Times', (2..5)],
        4 => ['6-9 Times', (6..9)],
        5 => ['10+ Times', (10..)],
        6 => ["Total Persons #{label}", (1..)],
      }

      row_labels = buckets.values.map(&:first)
      row_labels << summary_row if summary_row.present?
      last_row = {}

      metadata = {
        header_row: HEADER_ROW,
        row_labels: row_labels,
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
        },
      ].each do |col|
        buckets.each do |row, (_, range)|
          cell = "#{col[:column]}#{row}"
          answer = @report.answer(question: table_name, cell: cell)
          candidates = situations.select { |_, v| v.any? { |cls| col[:situations].include?(cls.living_situation) } }
          member_ids = candidates.select { |_, v| range.cover?(v.length) }.keys
          members = universe.members.where(a_t[:id].in(member_ids))
          answer.add_members(members)
          count = members.count
          answer.update(summary: count)
          last_row[col[:column]] = count
        end
      end

      last_row
    end
  end
end
