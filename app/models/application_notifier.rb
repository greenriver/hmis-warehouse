###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Sends progress messages to Slack, possibly queuing and batching
# them as needed and if a service to do so is available. Logs
# any network/services errors and recovers as well as it can.
class ApplicationNotifier < Slack::Notifier
  def self.namespace_prefix
    'slack-notifier'
  end

  # Flush out any messages that have accumulated
  # in queues. Makes one KEYS request to see if there
  # is anything to do.
  def self.flush_queues
    redis = Redis.new(timeout: 1)
    redis.keys(namespace_prefix + '/*').each do |key|
      url, channel, username = * decode_key(key)
      next unless url.present?

      new(url, channel: channel, username: username).flush_queue
    end
  end

  def initialize(url, channel: nil, username: nil)
    # If Redis is available we will use it to rate limit connections to Slack.
    # It needs to be very responsive to be useful however so
    # skip it if we cant get a connection fast
    redis = Redis.new(timeout: 1)
    if redis.ping
      @redis = redis
      @namespace = self.class.encode_key(url, channel, username)
      Rails.logger.debug "ApplicationNotifier#ping queuing enabled at #{@redis.inspect} #{@namespace}"
    end

    super
  end

  # Send a message to Slack if possible
  # Rate limits messages in a queue if Redis is available
  def ping(message, options = {})
    return unless @endpoint&.host

    if @redis.nil? || message.is_a?(Hash) || options.present?
      # fallback on hard cases or if Redis is not available
      super
    else
      rate_limit message
    end
    nil # Dont leak a return value
  rescue OpenSSL::SSL::SSLError => e
    # Sometimes we see this in addition to the Slack::* error
    # if Slack is unwell
    Rails.logger.error('ApplicationNotifier#ping: ' + e.message)
  rescue Slack::Notifier::APIError => e
    Rails.logger.error('ApplicationNotifier#ping: ' + e.message)
  end

  # Send any rate_limit'd messages plus an optional additional_message.
  # Will break the resulting mega-message into 4K char and burst out
  # a sequence of posts. If this the queue is too big, say bigger than
  # 40KB, we will get a Slack rate limit error
  # and raise if Redis has become unavailable
  def flush_queue(additional_message = nil)
    message = ''
    # If we upgrade to Redis 6.2+ we can use lop n to
    # batch fetches
    while (batch = @redis.lpop("#{@namespace}/queue"))
      message += batch
    end
    message += additional_message.to_s

    # flush out in 4k blocks -- Slack limit
    chunk_size = 4_000
    io = StringIO.new(message)
    until io.eof?
      chunk = io.read(chunk_size)
      post text: chunk
    end
    @redis.set "#{@namespace}/last_post", Time.now.to_f
  end

  private def rate_limit(message)
    # Slack wants no more then one webhook per client per second
    last_post = @redis.get "#{@namespace}/last_post"
    if last_post && (Time.now - Time.at(last_post.to_f)) < 1.second
      @redis.rpush "#{@namespace}/queue", "#{Time.current.strftime('%I:%M:%S.%L%p')}: #{message}\n"
    else
      flush_queue message
    end
  rescue Redis::BaseError => e
    # If Redis has gone down, just try to get this message out
    Rails.logger.error('ApplicationNotifier#rate_limit: ' + e.message)
    post text: message
  end

  def self.encode_key(url, channel, username)
    [namespace_prefix, Base64.urlsafe_encode64(url), channel, username].join('/')
  end

  def self.decode_key(key)
    _, encoded_url, channel, username = *key.split('/')

    # incase there is junk in redis
    url = begin
            Base64.urlsafe_decode64(encoded_url)
          rescue StandardError
            nil
          end

    [url, channel, username]
  end
end
