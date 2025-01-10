###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class NotAuthorizedError < StandardError
  attr_reader :message

  def initialize(message = nil)
    @message = message || 'Sorry you are not authorized to do that.'
    super(@message)
  end
end
