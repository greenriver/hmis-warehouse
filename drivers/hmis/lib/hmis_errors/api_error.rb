###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class ApiError < StandardError
    attr_reader :display_message
    INTERNAL_ERROR_DISPLAY_MESSAGE = 'An error occurred'.freeze
    STALE_OBJECT_ERROR = "Your changes couldn't be saved because someone else made updates to the same data while you were working on it. Please refresh the page and try saving your changes again. If the issue persists, contact support for assistance.".freeze

    def initialize(msg = nil, display_message: INTERNAL_ERROR_DISPLAY_MESSAGE)
      super(msg)
      @display_message = display_message
    end
  end
end
