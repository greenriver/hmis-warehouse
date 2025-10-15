###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module LogRagePayloadBehavior
  extend ActiveSupport::Concern

  # Enhance Lograge payload with additional request context
  def append_info_to_payload(payload)
    super
    # The protocol negotiated with Rack (http/https)
    payload[:server_protocol] = request.env['SERVER_PROTOCOL']
    payload[:remote_ip] = request.remote_ip
    payload[:ip] = request.ip
    payload[:remote_addr] = request.env['REMOTE_ADDR']
    payload[:x_forwarded_for] = request.headers['HTTP_X_FORWARDED_FOR']
    # Rack session identifier to correlate logs with session state
    payload[:session_id] = request.env['rack.session.record'].try(:session_id)
    payload[:pid] = Process.pid
    # Rails request UUID to link logs across systems
    payload[:request_id] = request.uuid
    # Upstream request start timestamp when provided by load balancers
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '')
    # note, payload[:user_id] is set in the warehouse and hmis base controller which override this method
  end
end
