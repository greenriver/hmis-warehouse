###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Grades
  class Missing < Base

    def self.grade_from_score score
      g_t = arel_table
      where(
        g_t[:percentage_low].lteq(score.to_i).
        and(g_t[:percentage_high].gteq(score.to_i).or(g_t[:percentage_high].eq(nil)))
      ).
      order(percentage_low: :asc).
      first
    end

    def self.install_default_grades!
      default_grades.each do |attributes|
        g = where(grade: attributes[:grade]).first_or_create
        g.update(attributes)
      end
    end

    def self.default_grades
      [
        {grade: :A, percentage_low: 0, percentage_high: 5, color: '#000000'},
        {grade: :AB, percentage_low: 6, percentage_high: 10, color: '#1b40a6'},
        {grade: :B, percentage_low: 11, percentage_high: 15, color: '#73b8f0'},
        {grade: :BC, percentage_low: 16, percentage_high: 20, color: '#03dbbb'},
        {grade: :C, percentage_low: 21, percentage_high: 25, color: '#00ad4e'},
        {grade: :CD, percentage_low: 26, percentage_high: 30, color: '#ffc70d'},
        {grade: :D, percentage_low: 31, percentage_high: 35, color: '#ff9a57'},
        {grade: :F, percentage_low: 36, percentage_high: 100, color: '#cc0000'},
      ]
    end
  end
end
