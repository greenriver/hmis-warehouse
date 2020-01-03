###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Api::Health::Claims::Patients
  class ClaimsVolumeController < BaseController
    def load_data
      @data = group_by_date(scope.order(year: :asc, month: :asc))
    end

    def source
      ::Health::Claims::ClaimsVolume
    end
  end
end
