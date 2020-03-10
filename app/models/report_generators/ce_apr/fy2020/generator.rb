###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::CeApr::Fy2020
  class Generator < HudReports::GeneratorBase
    def initialize(options)
      super(options, 'CE APR - 2020')
    end

    def run!
      QuestionFour.new(self).run!
    end
  end
end