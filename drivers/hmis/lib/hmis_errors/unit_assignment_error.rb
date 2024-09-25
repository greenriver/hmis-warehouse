###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class UnitAssignmentError < ApiError
    def initialize(msg)
      # msg is passed through as display_message so it's shown to the user in production too
      super(msg, display_message: msg)
    end
  end
end
