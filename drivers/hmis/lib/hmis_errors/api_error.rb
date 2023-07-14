###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class ApiError < StandardError
    attr_reader :display_message
    INTERNAL_ERROR_DISPLAY_MESSAGE = 'An error occurred'.freeze

    def initialize(display_message: INTERNAL_ERROR_DISPLAY_MESSAGE)
      @display_message = display_message
    end
  end
end
