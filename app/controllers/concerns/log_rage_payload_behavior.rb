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
    # Accurate client networking details resolved from trusted sources
    payload.merge!(resolve_request_ip(payload))
    # Rack session identifier to correlate logs with session state
    payload[:session_id] = request.env['rack.session.record'].try(:session_id)
    # Rails request UUID to link logs across systems
    payload[:request_id] = request.uuid
    # Upstream request start timestamp when provided by load balancers
    payload[:request_start] = request.headers['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '')
    # Authenticated HMIS/Warehouse user (when available)
    payload[:user_id] = current_app_user&.id if defined?(current_app_user)
  end

  private

  def resolve_request_ip(event_payload)
    headers_env = request.headers.env

    x_forwarded_for = headers_env['HTTP_X_FORWARDED_FOR'].presence || event_payload[:x_forwarded_for].presence
    forwarded_ip = x_forwarded_for&.split(',')&.first&.strip.presence

    remote_addr = headers_env['REMOTE_ADDR'].presence || event_payload[:remote_addr].presence
    payload_remote_ip = event_payload[:remote_ip].presence
    resolved_remote_ip = payload_remote_ip
    resolved_remote_ip ||= request.remote_ip.presence
    resolved_remote_ip ||= remote_addr
    resolved_client_ip = forwarded_ip || headers_env['HTTP_CLIENT_IP'].presence || resolved_remote_ip

    {
      remote_ip: resolved_remote_ip,
      ip: resolved_client_ip,
      remote_addr: remote_addr,
      x_forwarded_for: x_forwarded_for,
    }
  end
end
