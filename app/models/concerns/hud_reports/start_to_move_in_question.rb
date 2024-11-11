###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Required accessors:
#   a_t: Arel Type for the universe model
#

module HudReports::StartToMoveInQuestion
  extend ActiveSupport::Concern

  def start_to_move_in_question(question:, members:, populations: sub_populations)
    # PSH/RRH w/ move in date
    # OR project type 7 (other) with Funder 35 (Pay for Success)
    relevant_members = members.
      where(
        a_t[:project_type].in([3, 13]).
        or(a_t[:pay_for_success].eq(true)),
      ).
      where(
        [
          a_t[:move_in_date].between(@report.start_date..@report.end_date),
          leavers_clause.and(a_t[:move_in_date].eq(nil)),
        ].inject(&:or),
      )

    question_sheet(question: question) do |sheet|
      populations.keys.each { sheet.add_header(label: _1) }

      start_to_move_in_lengths.each_pair do |label, row_cond|
        sheet.append_row(label: label) do |row|
          populations.values.each do |col_cond|
            case row_cond
            when :average
              value = 0
              scope = relevant_members.where(col_cond).where(a_t[:move_in_date].between(@report.start_date..@report.end_date))
              # treat null values as having 0 time in this case
              stay_lengths = scope.pluck(a_t[:time_to_move_in]).map { |len| len || 0 }
              value = (stay_lengths.sum(0.0) / stay_lengths.count).round if stay_lengths.any? # using round since this is an average number of days
              row.append_cell_value(value: value)
            else
              scope = relevant_members.where(col_cond).where(row_cond)
              row.append_cell_members(members: scope)
            end
          end
        end
      end
    end
  end

  def start_to_move_in_lengths
    lengths = lengths(field: a_t[:time_to_move_in])
    ret = [
      '7 days or less',
      '8 to 14 days',
      '15 to 21 days',
      '22 to 30 days',
      '31 to 60 days',
      '61 to 90 days',
      '91 to 180 days',
      '181 to 365 days',
      '366 to 730 days (1-2 Yrs)',
    ]
    ret = ret.to_h do |label|
      cond = lengths.fetch(label).and(a_t[:move_in_date].between(@report.start_date..@report.end_date))
      [label, cond]
    end

    ret.merge(
      'Total (persons moved into housing)' => a_t[:move_in_date].between(@report.start_date..@report.end_date),
      'Average length of time to housing' => :average,
      'Persons who were exited without move-in' => a_t[:move_in_date].eq(nil),
      'Total persons' => Arel.sql('1=1'),
    ).freeze
  end
end
