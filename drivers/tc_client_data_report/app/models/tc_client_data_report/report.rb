###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module TcClientDataReport
  class Report
    include ::Filter::FilterScopes
    include ArelHelper

    def initialize(filter)
      @filter = filter
    end
  end
end
