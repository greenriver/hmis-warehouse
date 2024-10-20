###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###
#
# frozen_string_literal: true

require 'memery'

# app-specific helper methods
module RackAttackRequestHelpers
  include Memery
  extend ActiveSupport::Concern

  memoize def tracking_enabled?
    !internal_lb_check?
  end

  def warehouse_authentication_attempt?
    path == '/users/sign_in' && post?
  end

  def hmis_authentication_attempt?
    path == '/hmis/login' && post?
  end

  def password_reset_attempt?
    get? && path == '/users/password/edit'
  end

  def okta_callback?
    get? && path =~ /\A(\/hmis)?\/users\/auth\/okta\/callback\z/
  end

  def rapid_paths?
    path.include?('rollup') || path.include?('cohort') || path.include?('core_demographics')
  end

  # Seems to be client history path `pdf_client_history`. Unsure if this needs to be a relative path
  def history_pdf_path?
    path.include?('history/pdf')
  end

  # returns the x-forward-for ip if we think the sending ip is trusted. Depends the RemoteIp rails middleware installed higher in the stack
  memoize def request_ip
    result = env['action_dispatch.remote_ip']&.to_s
    raise 'could not find remote_ip, check middleware for ActionDispatch::RemoteIp' unless result.present?

    result
  end

  def anonymous?
    !authenticated?
  end

  def authenticated?
    warden_user.present?
  end

  protected

  WARDEN_CHECK_EXCLUDE_URLS = ['/hmis/app_settings', '/hmis/user', '/messages/poll'].to_set.freeze
  private_constant :WARDEN_CHECK_EXCLUDE_URLS
  memoize def warden_user
    # Avoid calling warden for user status endpoints. Calling warden here bumps
    # last_request_at, regardless of skip_trackable in the controller. This means
    # sessions may not expire as expected
    strip_path = path.split('.', 2)[0]
    return nil if strip_path.in?(WARDEN_CHECK_EXCLUDE_URLS)

    # If we explicitly added a parameter to avoid updating last_request_at, honor it
    return nil if env['QUERY_STRING'].include?('skip_trackable=true')

    env['warden']&.user.presence || env['warden']&.user(:hmis_user).presence
  end

  def internal_lb_check?
    env['HTTP_USER_AGENT'] == 'ELB-HealthChecker/2.0' && path.include?('status') && trusted_proxy?
  end

  # is the source ip on a local or private network?
  def trusted_proxy?
    ActionDispatch::RemoteIp::TRUSTED_PROXIES.any? do |range|
      range.include?(request_ip)
    end
  end
end

class Rack::Attack::Request
  include RackAttackRequestHelpers
end

# rubocop:disable Style/IfUnlessModifier
Rack::Attack.tap do |config|
  # Throttling configuration
  # * Multiple throttles can match the same request
  # * Names must be unique or they will be silently overwritten

  brute_force_options = {
    limit: 20,
    period: 3.minutes,
  }

  # Goal: prevent brute-force enumeration of credentials
  config.throttle('per-ip limit on auth requests', **brute_force_options) do |request|
    if request.tracking_enabled? && request.anonymous?
      request.request_ip if request.hmis_authentication_attempt? || request.warehouse_authentication_attempt?
    end
  end

  # Goal: prevent brute-force enumeration of password reset tokens
  config.throttle('per-ip limit on password resets', **brute_force_options) do |request|
    if request.tracking_enabled? && request.anonymous? && request.password_reset_attempt?
      request.request_ip
    end
  end

  # Goal: prevent brute-force enumeration of okta redirects
  config.throttle('per-ip limit on okta redirects', **brute_force_options) do |request|
    if request.tracking_enabled? && request.anonymous? && request.okta_callback?
      request.request_ip
    end
  end

  # Goal: Prevent excessive requests to generate PDFs since that endpoint does not require authentication.
  config.throttle(
    'per-ip limit on unauthenticated requests for history pdf',
    limit: 25,
    period: 10.seconds,
  ) do |request|
    if request.tracking_enabled? && request.anonymous? && request.history_pdf_path?
      request.request_ip
    end
  end

  # Goal: limit burst requests from unauthenticated clients, such as spiders
  config.throttle(
    'General per-ip limit on unauthenticated requests',
    limit: 10,
    period: 1.second,
  ) do |request|
    if request.tracking_enabled? && request.anonymous?
      request.request_ip
    end
  end

  # Goal: prevent scripts run through authenticated user accounts from harvesting data or excessive use of the site, with an allowance for known poor behavior for cohorts, roll-ups, and other pages that load more than one request per page.
  config.throttle(
    'General per-ip limit on authenticated requests',
    limit: ->(request) { request.rapid_paths? ? 250 : 150 },
    period: 5.seconds,
  ) do |request|
    if request.tracking_enabled? && request.authenticated?
      request.request_ip
    end
  end
end
# rubocop:enable Style/IfUnlessModifier

# #Custom limit response
# Rack::Attack.throttled_response = lambda do |env|
#   #puts "throttleDDDD"
#   match_data = env['rack.attack.match_data']
#   now = match_data[:epoch_time]

#   headers = {
#     'X-RateLimit-Limit' => match_data[:limit].to_s,
#     'X-RateLimit-Remaining' => '0',
#     'X-RateLimit-Reset' => (now + (match_data[:period] - now % match_data[:period])).to_s
#   }

#   [ 429, headers, ["Throttled\n"]]
# end

ActiveSupport::Notifications.subscribe(/rack_attack/) do |_name, start, _finish, _request_id, payload|
  request = payload[:request]

  # safelist matches are un-interesting
  next if request.env['rack.attack.match_type'].to_s.in?(['safelist'])

  # collect some useful data
  data = {
    rails_env: Rails.env.to_s,
  }
  # ... the attach match
  data.merge! request.env.slice('rack.attack.match_type', 'rack.attack.matched', 'rack.attack.match_discriminator', 'rack.attack.match_data')
  # ... the request
  data.merge!(
    server_protocol: request.env['SERVER_PROTOCOL'],
    host: request.env['HTTP_HOST'],
    method: request.request_method,
    path: request.fullpath,
    amzn_trace_id: request.env['HTTP_X_AMZN_TRACE_ID'],
    request_start: request.env['HTTP_X_REQUEST_START'].try(:gsub, /\At=/, '').presence || start,
    remote_ip: request.env['action_dispatch.remote_ip']&.to_s,
    user_id: request.env['warden'].user&.id,
    session_id: request.env['rack.session'].id,
    user_agent: request.env['HTTP_USER_AGENT'],
    accept: request.env['HTTP_ACCEPT'],
    accept_language: request.accept_language,
  )
  # ... get a record on disk
  Rails.logger.warn JSON.generate(data)

  # ... and now try to send to somewhere useful
  if defined?(Slack::Notifier) && ENV['EXCEPTION_WEBHOOK_URL'].present?
    notifier_config = Rails.application.config_for(:exception_notifier).fetch(:slack, nil)
    notifier = Slack::Notifier.new(
      notifier_config[:webhook_url],
      channel: notifier_config[:channel],
      username: 'Rack-Attack',
    )

    fields = data.map do |k, v|
      { title: k.to_s, value: v.to_s }
    end
    attachment = {
      fallback: JSON.pretty_generate(data),
      color: :warning,
      fields: fields,
    }
    notifier.ping(
      text: '*Rack attack event*',
      attachments: [attachment],
      http_options: { open_timeout: 1 },
    )
  end
end
