# frozen_string_literal: true

###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'

# app-specific helper methods
module RackAttackRequestHelpers
  include Memery
  extend ActiveSupport::Concern

  memoize def tracking_enabled?
    return false if internal_lb_check?

    !Rails.env.test? || /t|1/.match?(params['rack_attack_enabled'].to_s)
  end

  def warehouse_authentication_attempt?
    path == '/users/sign_in' && post?
  end

  def hmis_authentication_attempt?
    path == '/hmis/login' && post?
  end

  def password_reset_attempt?
    get? && path == '/users/password'
  end

  def okta_callback?
    get? && path =~ /\A(\/hmis)?\/users\/auth\/okta\/callback\z/
  end

  def rapid_paths?
    path.include?('rollup') || path.include?('cohort') || path.include?('core_demographics')
  end

  def history_pdf_path?
    path.include?('history/pdf')
  end

  # extract the params from a JSON submission
  def json_params
    input = env['rack.input']
    str = input&.read
    input&.rewind
    # some preflight sanity checks before we parse
    return nil unless str.present? && str[0] == '{' && str[-1] == '}' && str.size <= 5_000

    JSON.parse(str)
  rescue JSON::ParserError
    nil
  end

  # returns the x-forward-for ip if we think the sending ip is trusted. Uses the RemoteIp rails middleware
  def request_ip
    if env['HTTP_X_PROXY_SECRET_KEY'] == ENV['PROXY_SECRET_KEY'] || trusted_proxy?
      result = env['action_dispatch.remote_ip']
      raise 'could not find remote_ip, check middleware for ActionDispatch::RemoteIp' unless result

      result
    else
      ip
    end
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
      range.include?(request.ip)
    end
  end
end

class Rack::Attack::Request
  include RackAttackRequestHelpers
end

# rubocop:disable Style/IfUnlessModifier
Rack::Attack.tap do |config|
  # Description: per-ip limit on auth requests
  # Goal: prevent brute-force enumeration of credentials and password reset tokens
  config.throttle(
    'authentication attempts per ip',
    limit: 60,
    period: 5.minutes
  ) do |request|
    if request.tracking_enabled? && request.anonymous?
      if request.hmis_authentication_attempt? ||
        request.warehouse_authentication_attempt? ||
        request.password_reset_attempt? ||
        request.okta_callback?

        request.request_ip
      end
    end
  end

  # Description: per-email limit on auth requests
  # Goal: prevent brute-force enumeration of passwords for one account. Perhaps this could be removed since devise should handle this already
  config.throttle(
    'logins per account',
    limit: 10,
    period: 180.seconds
  ) do |request|
    if request.tracking_enabled? && request.anonymous?
      params = nil
      if request.hmis_authentication_attempt?
        # hmis uses json
        params = request.json_params['hmis_user']
      elsif request.warehouse_authentication_attempt?
        params = request.params['user']
      end
      params['email']&.strip&.downcase&.presence if params.is_a?(Hash)
    end
  end

  # Description: per-ip limit on unauthenticated requests
  # Goal: limit burst requests from unauthenticated clients, such as spiders
  config.throttle(
    'authentication attempts per ip',
    limit: 10,
    period: 1.second
  ) do |request|
    if request.tracking_enabled? && request.anonymous?
      request.request_ip
    end
  end

  # Description: per-ip limit on authenticated requests where some 'rapid' paths are less throttled
  # Goal: the idea seems to be to prevent scripts run through authenticated user accounts with an allowance for known poor behavior for cohort management interface
  config.throttle(
    'authenticated requests per ip',
    limit: ->(request) { request.rapid_paths? ? 250 : 150 },
    period: 5.seconds,
  ) do |request|
    if request.tracking_enabled? && request.authenticated?
      request.request_ip
    end
  end

  # Description: per-ip limit on unauthenticated requests a 'history pdf'
  # Goal: TBD
  config.throttle(
    'requests per unauthenticated user to history pdf',
    limit: 25,
    period: 10.seconds
  ) do |request|
    if request.tracking_enabled? && request.anonymous? && request.history_pdf_path?
      request_ip(request)
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
    remote_ip: request.env['action_dispatch.remote_ip'],
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
