###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ReportGenerators::Apr::Fy2020
  class Generator < HudReports::GeneratorBase
    def initialize(options)
      super(options, 'APR - 2020')
    end

    def run!
      ReportGenerators::AprShared::Fy2020::QuestionFour.new(self).run!
      ReportGenerators::Apr::Fy2020::QuestionFive.new(self).run!
    end
  end
end