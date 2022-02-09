###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims
  class EdNyuSeverityController < BaseController
    def load_data
      @data = 'FIXME'
    end

    def source
      ::Health::Claims::EdNyuSeverity
    end
  end
end
