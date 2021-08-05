###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudApr::Generators::CeApr::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.title
      'Coordinated Entry Annual Performance Report - FY 2020'
    end

    def self.short_name
      'CE-APR'
    end

    def url
      hud_reports_ce_apr_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.filter_class
      HudApr::Filters::AprFilter
    end

    def self.questions
      [
        HudApr::Generators::CeApr::Fy2020::QuestionFour, # Project Identifiers in HMIS
        HudApr::Generators::CeApr::Fy2020::QuestionFive, # Report Validations
        HudApr::Generators::CeApr::Fy2020::QuestionSix, # Data Quality
        HudApr::Generators::CeApr::Fy2020::QuestionSeven, # Persons Served
        HudApr::Generators::CeApr::Fy2020::QuestionEight, # Households Served
        HudApr::Generators::CeApr::Fy2020::QuestionNine, # Participation in Coordinated Entry
        HudApr::Generators::CeApr::Fy2020::QuestionTen, # Total Coordinated Entry Activity During the Year
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || 'Question 4'
    end

    # FIXME: client scope will differ from the APR/CAPER and needs to use the enrollment for the most-recent CE Assessment 4.19 instead of the most-recent enrollment
    # Q9, Q10
  end
end
