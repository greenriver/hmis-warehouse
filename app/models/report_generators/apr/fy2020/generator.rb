###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::Apr::Fy2020
  class Generator < HudReports::GeneratorBase
    def initialize(options)
      super(options)
    end

    def self.title
      'Annual Performance Report - FY 2020'
    end

    def self.questions
      {
        'Q4' => ReportGenerators::AprShared::Fy2020::QuestionFour,  # Project Identifiers in HMIS
        'Q5' => ReportGenerators::Apr::Fy2020::QuestionFive, # Report Validations Table
      }.freeze
    end
  end
end