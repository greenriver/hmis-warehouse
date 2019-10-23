class Rack::Attack
  def self.tracking_enabled?(req)
    !Rails.env.test? || /t|1/.match?(req.params['rack_attack_enabled'].to_s)
  end

  # track any remote ip that exceeds our basic request rate limits
  throttle('req/ip', limit: 10, period: 1.second) do |req|
    if tracking_enabled?(req)
      req.ip
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
  if defined?(Slack::Notifier)  && (webhook_url=ENV['EXCEPTION_WEBHOOK_URL']).present?
    notifier = Slack::Notifier.new(
      webhook_url
    )
    fields =  data.map do |k,v|
      {title: k.to_s, value: v.to_s}
    end
    attachment = {
      fallback: JSON::pretty_generate(data),
      color: :warning,
      fields: fields
    }
    notifier.post(
      text: '*Rack attack event*',
      attachments: [attachment],
      http_options: { open_timeout: 1 }
    )
  end
end
