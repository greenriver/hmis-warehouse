###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

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
