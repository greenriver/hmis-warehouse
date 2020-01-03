###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports::Ahar::Fy2016
  class Veteran < Base
    def self.report_name
      'Veteran AHAR - FY 2016'
    end

    def report_type
      1
    end
  end
end