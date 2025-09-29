###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module LogRagePayloadBehavior
  extend ActiveSupport::Concern

  def append_info_to_payload(payload)
    super
    payload[:server_protocol] = request.env['SERVER_PROTOCOL']
    payload.merge!(resolve_request_ip(payload))
    payload[:session_id] = request.env['rack.session.record'].try(:session_id)
    payload[:pid] = Process.pid
    payload[:request_id] = request.uuid
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '')
    payload[:user_id] = current_app_user&.id
  end

  private

  def resolve_request_ip(event_payload)
    headers_env = request.headers.env

    x_forwarded_for = headers_env['HTTP_X_FORWARDED_FOR'].presence || event_payload[:x_forwarded_for].presence
    forwarded_ip = x_forwarded_for&.split(',')&.first&.strip.presence

    remote_addr = headers_env['REMOTE_ADDR'].presence || event_payload[:remote_addr].presence
    request_remote_ip = request.remote_ip.presence
    payload_remote_ip = event_payload[:remote_ip].presence

    resolved_remote_ip = request_remote_ip || payload_remote_ip || remote_addr
    resolved_client_ip = forwarded_ip || headers_env['HTTP_CLIENT_IP'].presence || resolved_remote_ip

    {
      remote_ip: resolved_remote_ip,
      ip: resolved_client_ip,
      remote_addr: remote_addr,
      x_forwarded_for: x_forwarded_for,
    }
  end
end
