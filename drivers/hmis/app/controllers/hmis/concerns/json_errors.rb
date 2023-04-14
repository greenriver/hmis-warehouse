###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Hmis::Concerns::JsonErrors
  extend ActiveSupport::Concern

  def render_json_error(status, type, message: nil, backtrace: nil)
    status = Rack::Utils::SYMBOL_TO_STATUS_CODE[status] if status.is_a? Symbol
    error = { type: type }
    error[:message] = message if message.present?
    error[:backtrace] = backtrace if backtrace.present? && Rails.env.development?
    render status: status, json: { error: error }
  end
end
