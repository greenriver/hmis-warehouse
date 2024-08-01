###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module LogRagePayloadBehavior
  extend ActiveSupport::Concern

  def append_info_to_payload(payload)
    super
    payload[:server_protocol] = request.env['SERVER_PROTOCOL']
    payload[:remote_ip] = request.remote_ip
    payload[:ip] = request.ip
    payload[:remote_addr] = request.env['REMOTE_ADDR']
    payload[:x_forwarded_for] = request.headers['HTTP_X_FORWARDED_FOR']
    payload[:session_id] = request.env['rack.session.record'].try(:session_id)
    payload[:pid] = Process.pid
    payload[:request_id] = request.uuid
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '')
  end
end
