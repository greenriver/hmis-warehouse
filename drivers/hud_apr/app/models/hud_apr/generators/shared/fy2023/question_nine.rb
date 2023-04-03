###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Shared::Fy2023
  class QuestionNine < Base
    QUESTION_NUMBER = 'Question 9'.freeze

    def self.table_descriptions
      {
        'Question 9' => 'Contacts and Engagements',
        'Q9a' => 'Number of Persons Contacted',
        'Q9b' => 'Number of Persons Engaged',
      }.freeze
    end

    private def a_t
      @a_t ||= report_client_universe.arel_table
    end

    private def ls_t
      @ls_t ||= report_living_situation_universe.arel_table
    end

    private def q9a_contacted
      table_name = 'Q9a'

      adults_and_hohs = universe.members.where(adult_or_hoh_clause).
        where(a_t[:project_type].in([1, 4]))
      contacted_ids = adults_and_hohs.
        where(a_t[:date_of_engagement].between(@report.start_date..@report.end_date)).
        pluck(a_t[:id])
      contacted_ids += adults_and_hohs.joins(apr_client: :hud_report_apr_living_situations).
        where(
          ls_t[:information_date].between(@report.start_date..@report.end_date).
            and(
              ls_t[:information_date].lteq(a_t[:date_of_engagement]).
              or(a_t[:date_of_engagement].eq(nil)),
            ),
        ).
        pluck(a_t[:id])

      populate_table(table_name, 6, 'Contacted', 'Times', contacted_ids.uniq)
    end

    private def q9b_engaged(contact_counts)
      table_name = 'Q9b'

      adults_and_hohs = universe.members.where(adult_or_hoh_clause).
        where(a_t[:project_type].in([1, 4]))
      engaged_ids = adults_and_hohs.where(a_t[:date_of_engagement].between(@report.start_date..@report.end_date)).pluck(a_t[:id])

      engaged_counts = populate_table(table_name, 7, 'Engaged', 'Contacts', engaged_ids, summary_row: 'Rate of Engagement')
      engaged_counts.each do |col, count|
        ratio = percentage(count / contact_counts[col].to_f)
        @report.answer(question: table_name, cell: "#{col}7").update(summary: ratio)
      end
    end

    private def populate_table(table_name, table_rows, counted_label, buckets_label, client_ids, summary_row: nil)
      header_row = [
        "Number of Persons #{counted_label}",
        'All Persons Contacted',
        'First contact - NOT staying on the Streets, ES, or SH',
        'First contact - WAS staying on Streets, ES, or SH',
        'First contact - Worker unable to determine',
      ]

      buckets = {
        2 => ['Once', (1..1)],
        3 => ["2-5 #{buckets_label}", (2..5)],
        4 => ["6-9 #{buckets_label}", (6..9)],
        5 => ["10+ #{buckets_label}", (10..)],
        6 => ["Total Persons #{counted_label}", (1..)],
      }

      row_labels = buckets.values.map(&:first)
      row_labels << summary_row if summary_row.present?
      last_row = {}

      metadata = {
        header_row: header_row,
        row_labels: row_labels,
        first_column: 'B',
        last_column: 'E',
        first_row: 2,
        last_row: table_rows,
      }
      @report.answer(question: table_name).update(metadata: metadata)

      clients = universe.members.
        where(a_t[:id].in(client_ids)).
        map(&:universe_membership).
        index_by(&:id)

      situations = report_living_situation_universe.
        where(hud_report_apr_client_id: client_ids).
        order(information_date: :asc).
        group_by(&:hud_report_apr_client_id)

      [
        {
          column: 'B',
          situations: HudUtility.living_situations.keys,
        },
        {
          column: 'C',
          situations: HudUtility.living_situations.keys - [16, 1, 18, 37, 8, 9, 99],
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
          # Filter by column type
          candidates = situations.select { |_, v| col[:situations].include?(v.first[:living_situation]) }

          # Filter for:
          # Include all contacts in each clients’ count where all of the following are true. Note that contacts prior to the [report start date] are included in each person’s total count, provided those contacts are attached to the client’s latest relevant project stay. Contacts dated after the [date of engagement], [project exit date], and [report end date] are all excluded.
          #   a. [date of contact] >= [project start date]
          #   b. [project exit date] is null or [date of contact] <= [project exit date]
          #   c. [current living situation] <= [date of engagement] (or the [date of engagement] is null)
          #   d. [current living situation] <= [report end date]
          member_ids = candidates.select do |client_id, v|
            client = clients[client_id]
            clses = v.select do |cls|
              (
                # For actual CLS, they must occur after project start
                cls[:information_date] >= client.first_date_in_program ||
                # If the client was engaged before entry, and there was no CLS on the date of engagement, we added one, make sure to include it
                # NOTE, there is a "corner" case where a client only has a CLS on their date of engagement of situation 37, where we might count
                # them and really shouldn't
                client.date_of_engagement.present? &&
                client.date_of_engagement < client.first_date_in_program &&
                cls[:information_date] == client.date_of_engagement &&
                cls[:living_situation] == 37
              ) &&
              (client.last_date_in_program.blank? || cls[:information_date] <= client.last_date_in_program) &&
              (client.date_of_engagement.blank? || cls[:information_date] <= client.date_of_engagement) &&
              cls[:information_date] <= @report.end_date
            end
            range.cover?(clses.count)
          end.keys
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
