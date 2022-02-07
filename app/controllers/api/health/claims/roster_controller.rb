###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Api::Health::Claims
  class RosterController < BaseController
    def load_data
      @data = 'FIXME'
    end

    def source
      ::Health::Claims::Roster
    end
  end
end
