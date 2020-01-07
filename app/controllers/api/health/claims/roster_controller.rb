###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
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
