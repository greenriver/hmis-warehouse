###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisErrors
  class ApiError < StandardError
    attr_reader :display_message
    # these instructive error messages should probably live in the front-end. It's convenient to have them here for now
    INTERNAL_ERROR_DISPLAY_MESSAGE = 'An error occurred on this page. The error has been reported and will be investigated by our support team. Please reload the page and try again. Contact your administrator if the problem persists.'.freeze
    STALE_OBJECT_ERROR = "Your changes couldn't be saved because someone else made updates to the same data while you were working on it. Please refresh the page and try saving your changes again. If the issue persists, contact support for assistance.".freeze

    def initialize(msg = nil, display_message: INTERNAL_ERROR_DISPLAY_MESSAGE)
      super(msg)
      @display_message = display_message
    end
  end
end
