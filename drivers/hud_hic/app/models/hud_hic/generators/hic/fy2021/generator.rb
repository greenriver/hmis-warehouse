###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module  HudHic::Generators::Hic::Fy2021
  class Generator < ::HudReports::GeneratorBase
    def self.fiscal_year
      'FY 2021'
    end

    def self.generic_title
      'Housing Inventory Count'
    end

    def self.short_name
      'HIC'
    end

    def url
      hud_reports_hic_url(report, { host: ENV['FQDN'], protocol: 'https' })
    end

    def self.questions
      [
        HudHic::Generators::Hic::Fy2021::Report,
      ].map do |q|
        [q.question_number, q]
      end.to_h.freeze
    end
  end
end
