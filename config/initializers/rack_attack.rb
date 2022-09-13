# Rails.logger.debug "Running initializer in #{__FILE__}"

class Rack::Attack
  PRIVATE_IP = /(^10\.)|(^172\.1[6-9]\.)|(^172\.2[0-9]\.)|(^172\.3[0-1]\.)|(^192\.168\.)|(^127\.0\.0\.1)/

  def self.tracking_enabled?(request)
    return false if internal_lb_checks?(request)

    !Rails.env.test? || /t|1/.match?(request.params['rack_attack_enabled'].to_s)
  end

  def self.internal_lb_checks?(request)
    return false unless request.env['HTTP_USER_AGENT'] == 'ELB-HealthChecker/2.0'
    return false unless request.path.include?('status')
    return true if request.ip.match?(PRIVATE_IP)
  end

  def self.sign_in_path(request)
    request.path == '/users/sign_in' && request.post?
  end

  def self.rapid_paths(request)
    request.path.include?('rollup') || request.path.include?('cohort') || request.path.include?('core_demographics') || asset_paths(request)
  end

  def self.asset_paths(request)
    request.path.include?('assets')
  end

  def self.history_pdf_path(request)
    request.path.include?('history/pdf')
  end

  def self.user_email_present?(request)
    request.params['user'].present? && request.params['user']['email'].present?
  end

  def self.warden_user_present?(request)
    request.env['warden']&.user.present?
  end

  # track any remote ip that exceeds our basic request rate limits
  # tracker = if Rails.env.test? then :throttle else :track end
  tracker = :throttle

  send(tracker, 'requests per unauthenticated user per ip', limit: 10, period: 1.seconds) do |request|
    if tracking_enabled?(request)
      if !warden_user_present?(request) && !(sign_in_path(request) || history_pdf_path(request) || asset_paths(request))
        request.ip
      end
    end
  end
  send(tracker, 'requests per unauthenticated user to history pdf', limit: 25, period: 10.seconds) do |request|
    if tracking_enabled?(request)
      if !warden_user_present?(request) && history_pdf_path(request)
        request.ip
      end
    end
  end
  send(tracker, 'requests per unauthenticated user to assets', limit: 200, period: 10.seconds) do |request|
    if tracking_enabled?(request)
      if !warden_user_present?(request) && asset_paths(request)
        request.ip
      end
    end
  end
  send(tracker, 'requests per logged-in user per ip', limit: 150, period: 5.seconds) do |request|
    if tracking_enabled?(request)
      if warden_user_present?(request) && !(rapid_paths(request))
        request.ip
      end
    end
  end
  send(tracker, 'requests per logged-in user per ip special', limit: 250, period: 5.seconds) do |request|
    if tracking_enabled?(request)
      if warden_user_present?(request) && (rapid_paths(request))
        request.ip
      end
    end
  end
  send(tracker, 'logins per account', limit: 10, period: 180.seconds) do |request|
    if tracking_enabled?(request)
      if sign_in_path(request) && user_email_present?(request)
        request.params['user']['email']
      end
    end
  end
  # limit to 25 logins per user per hour
  send(tracker, 'block script logins per account', limit: 25, period: 3600.seconds) do |request|
    if tracking_enabled?(request)
      if sign_in_path(request) && user_email_present?(request)
        request.params['user']['email']
      end
    end
  end
end

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


ActiveSupport::Notifications.subscribe(/rack_attack/) do |name, start, finish, request_id, payload|
  request =  payload[:request]

  # safelist matches are un-interesting
  next if request.env['rack.attack.match_type'].to_s.in?(%w/safelist/)

  # collect some useful data
  data = {
    rails_env: Rails.env.to_s,
  }
  # ... the attach match
  data.merge! request.env.slice(*%w/
    rack.attack.match_type
    rack.attack.matched
    rack.attack.match_discriminator
    rack.attack.match_data
  /)
  # ... the request
  data.merge!(
    server_protocol: request.env['SERVER_PROTOCOL'],
    host: request.env['HTTP_HOST'],
    method: request.request_method,
    path: request.fullpath,
    amzn_trace_id: request.env['HTTP_X_AMZN_TRACE_ID'],
    request_start: (request.env['HTTP_X_REQUEST_START'].try(:gsub, /\At=/,'').presence || start),
    remote_ip:  request.env['action_dispatch.remote_ip'],
    user_id: request.env['warden'].user&.id,
    session_id: request.env['rack.session'].id,
    user_agent: request.env['HTTP_USER_AGENT'],
    accept: request.env['HTTP_ACCEPT'],
    accept_language: request.accept_language,
  )
  # ... get a record on disk
  Rails.logger.warn JSON::generate(data)

  # ... and now try to send ot somewhere useful
  if defined?(Slack::Notifier) && ENV['EXCEPTION_WEBHOOK_URL'].present?
    notifier_config = Rails.application.config_for(:exception_notifier).fetch(:slack, nil)
    notifier  = Slack::Notifier.new(
      notifier_config['webhook_url'],
      channel: notifier_config['channel'],
      username: 'Rack-Attack',
    )

    fields =  data.map do |k,v|
      {title: k.to_s, value: v.to_s}
    end
    attachment = {
      fallback: JSON::pretty_generate(data),
      color: :warning,
      fields: fields
    }
    notifier.ping(
      text: '*Rack attack event*',
      attachments: [attachment],
      http_options: { open_timeout: 1 }
    )
  end
end
