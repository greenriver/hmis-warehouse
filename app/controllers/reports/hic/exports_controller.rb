###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Reports
  class Hic::ExportsController < Hic::BaseController
    def show
      @partial = versions.detect { |v| v == params[:version] } || versions.last
    end

    private def versions
      [
        'fy2017',
        'fy2019',
      ]
    end
  end
end
