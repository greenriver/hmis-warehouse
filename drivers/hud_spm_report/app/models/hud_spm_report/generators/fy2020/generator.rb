###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HudSpmReport::Generators::Fy2020
  class Generator < ::HudReports::GeneratorBase
    def self.title
      'System Performance Measures - FY 2020'.freeze
    end

    def self.short_name
      'System Performance Measures'.freeze
    end

    def url
      hud_reports_spm_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudSpmReport::Generators::Fy2020::MeasureOne,
        HudSpmReport::Generators::Fy2020::MeasureTwo,
        HudSpmReport::Generators::Fy2020::MeasureThree,
        HudSpmReport::Generators::Fy2020::MeasureFour,
        HudSpmReport::Generators::Fy2020::MeasureFive,
        HudSpmReport::Generators::Fy2020::MeasureSix,
        HudSpmReport::Generators::Fy2020::MeasureSeven,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end

    def self.valid_question_number(question_number)
      questions.keys.detect { |q| q == question_number } || questions.keys.first
    end
  end
end
