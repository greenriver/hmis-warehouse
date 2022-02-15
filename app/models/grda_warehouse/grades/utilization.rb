###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Grades
  class Utilization < Base

    def self.grade_from_score score
      g_t = arel_table
      where(
        g_t[:percentage_under_low].lteq(score.to_i).
        and(g_t[:percentage_under_high].gteq(score.to_i)).
        or(
          g_t[:percentage_over_low].lteq(score.to_i).
          and(g_t[:percentage_over_high].gteq(score.to_i))
        ).
        or(
          g_t[:percentage_over_low].lteq(score.to_i).
          and(g_t[:percentage_over_high].eq(nil))
        )
      ).first
    end

    def self.install_default_grades!
      default_grades.each do |attributes|
        g = where(grade: attributes[:grade]).first_or_create
        g.update(attributes)
      end
    end

    def self.default_grades
      [
        {grade: :A, percentage_under_low: 95, percentage_under_high: 100, percentage_over_low: 101, percentage_over_high: 105, color: '#000000'},
        {grade: :AB, percentage_under_low: 90, percentage_under_high: 94, percentage_over_low: 106, percentage_over_high: 110, color: '#1b40a6'},
        {grade: :B, percentage_under_low: 85, percentage_under_high: 89, percentage_over_low: 111, percentage_over_high: 115, color: '#73b8f0'},
        {grade: :BC, percentage_under_low: 80, percentage_under_high: 84, percentage_over_low: 116, percentage_over_high: 120, color: '#03dbbb'},
        {grade: :C, percentage_under_low: 75, percentage_under_high: 79, percentage_over_low: 121, percentage_over_high: 125, color: '#00ad4e'},
        {grade: :CD, percentage_under_low: 70, percentage_under_high: 74, percentage_over_low: 126, percentage_over_high: 130, color: '#ffc70d'},
        {grade: :D, percentage_under_low: 65, percentage_under_high: 69, percentage_over_low: 131, percentage_over_high: 135, color: '#ff9a57'},
        {grade: :F, percentage_under_low: 0, percentage_under_high: 64, percentage_over_low: 136, percentage_over_high: nil, color: '#cc0000'},
      ]
    end
  end
end
