###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports::Ahar::Fy2017
  class Veteran < Base
    def self.report_name
      'Veteran AHAR - FY 2017'
    end

    def self.generator
      ReportGenerators::Ahar::Fy2017::Veteran
    end

    def report_type
      1
    end
  end
end