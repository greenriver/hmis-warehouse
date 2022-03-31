###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::Apr::Fy2020
  class Generator < ::HudReports::GeneratorBase
    include HudApr::CellDetailsConcern

    def self.fiscal_year
      'FY 2020'
    end

    def self.generic_title
      'Annual Performance Report'
    end

    def self.short_name
      'APR'
    end

    def url
      hud_reports_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        'Question 4',
        'Question 5',
        'Question 6',
        'Question 7',
        'Question 8',
        'Question 9',
        'Question 10',
        'Question 11',
        'Question 12',
        'Question 13',
        'Question 14',
        'Question 15',
        'Question 16',
        'Question 17',
        'Question 18',
        'Question 19',
        'Question 20',
        'Question 21',
        'Question 22',
        'Question 23',
        'Question 25',
        'Question 26',
        'Question 27',
      ].map { |q| [q, q] }.to_h
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end
  end
end
