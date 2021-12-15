###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Manual testing routine
# reload!; include NotifierConfig; setup_notifier('test_user')
# @notifier.ping('test message')
# 100.times { |i| @notifier.ping("new test message #{i}")}
# ApplicationNotifier.flush_queues
# 100.times { |i| @notifier.ping("new test message #{i}")}
# sleep(5)
# 100.times { |i| @notifier.ping("new test message #{i}")}
#
# 100.times { |i| @notifier.ping("new test message #{i}")}
# long_message_text = 'some really long text (close to 4kb) -- fix me, make me long'
# @notifier.ping(long_message_text)
# 100.times { |i| @notifier.ping("new test message #{i}")}
#

# Sends progress messages to Slack, possibly queuing and batching
# them as needed and if a service to do so is available. Logs
# any network/services errors and recovers as well as it can.
class ApplicationNotifier < Slack::Notifier
  # use the same redis instance we use for caching
  def self.redis
    Redis.new Rails.application.config_for(:cache_store).merge(
      timeout: 1,
      ssl: (ENV.fetch('CACHE_SSL') { 'false' }) == 'true',
    )
  end

  # prefix all keys with a CLIENT specific key
  def self.namespace_prefix
    'hmis-slack-notifier-' + ENV.fetch('CLIENT')
  end

  # Flush out any messages that have accumulated
  # in queues. Makes one KEYS request to see if there
  # is anything to do.
  def self.flush_queues(prefix: nil)
    # use the same redis instance we use for caching
    redis.keys(namespace_prefix + '/*').each do |key|
      next unless key.ends_with?('/queue') # there should be a single key ending in queue... for each  user, channel, username

      url, channel, username = * decode_key(key)
      next unless url.present?

      new(url, channel: channel, username: username).flush_queue(prefix: prefix, single_message: false)
    end
  end

  def initialize(url, channel: nil, username: nil)
    begin
      # If Redis is available we will use it to rate limit connections to Slack.
      # It needs to be very responsive to be useful however so
      # skip it if we cant get a connection fast
      redis = self.class.redis
      if redis&.ping
        @redis = redis
        @namespace = self.class.encode_key(url, channel, username)
        Rails.logger.debug "ApplicationNotifier#ping queuing enabled at #{@redis.inspect} #{@namespace}"
      end
    rescue Redis::BaseError => e
      Rails.logger.warn "ApplicationNotifier#ping queuing disabled. #{e.inspect}"
    end

    super
  end

  # Send a message to Slack if possible
  # Rate limits messages in a queue if Redis is available
  def ping(message, options = {}, insert_log_url = false)
    return unless @endpoint&.host

    if insert_log_url
      log_stream_url = ENV.fetch('LOG_STREAM_URL', nil)
      message += "\nLog url: #{log_stream_url}" unless log_stream_url.nil?
    end

    if @redis.nil? || message.is_a?(Hash) || options.present?
      # fallback on hard cases or if Redis is not available
      super(message, options)
    else
      rate_limit(message)
    end
    nil # Dont leak a return value
  rescue OpenSSL::SSL::SSLError => e
    # Sometimes we see this in addition to the Slack::* error
    # if Slack is unwell
    Rails.logger.error('ApplicationNotifier#ping: ' + e.message)
  rescue Slack::Notifier::APIError => e
    Rails.logger.error('ApplicationNotifier#ping: ' + e.message)
  end

  def post(payload={}, insert_log_url = false)
    if insert_log_url
      log_stream_url = ENV.fetch('LOG_STREAM_URL', nil)
      payload[:text] += "\nLog url: #{log_stream_url}" unless log_stream_url.nil?
    end

    super(payload)
  end

  # Send any rate_limit'd messages.
  # Will break the resulting mega-message into 4K char and burst out
  # a sequence of posts. If this the queue is too big, say bigger than
  # 40KB, we will get a Slack rate limit error
  # and raise if Redis has become unavailable
  def flush_queue(prefix: nil, single_message: true)
    message = ''
    messages = []
    chunk_size = 4_000
    # TODO: If we upgrade to Redis 6.2+ we can use lop n to
    # batch fetches
    # Store messages in chunks in an array for processing
    while (batch = @redis.lpop("#{@namespace}/queue"))
      message = prefix.to_s if message.blank?
      if (message + batch).bytesize > chunk_size
        messages << message if message.present?
        message = ''
        break message += batch if single_message
      end
      message += batch
    end
    messages << message if message.present?

    # flush out in 4k blocks -- Slack limit
    begin
      messages.each do |chunk|
        post(text: chunk)

        # keep slack happy even when bursting out remaining messages
        # if this is called when it has been more than a second since the last send, it might
        # delay things a bit (max 3 messages for a single_message flush).
        # if this is called from flush_messages with single_message: false
        # this will slow things down, but it should be happening in a background task
        # specifically for sending these that can tolerate the delay.
        sleep(0.7)
      end
      @redis.set "#{@namespace}/last_post", Time.now.to_f
    rescue Exception # rubocop:disable Lint/SuppressedException
    end
  end

  private def rate_limit(message)
    # Slack wants no more then one webhook per client per second
    last_post = @redis.get "#{@namespace}/last_post"
    @redis.rpush "#{@namespace}/queue", "#{message}\n"
    flush_queue unless last_post && (Time.now - Time.at(last_post.to_f)) < 1.second
  rescue Redis::BaseError => e
    # If Redis has gone down, just try to get this message out
    Rails.logger.error('ApplicationNotifier#rate_limit: ' + e.message)
    begin
      post text: message
    rescue Exception # rubocop:disable Lint/SuppressedException
    end
  end

  def self.encode_key(url, channel, username)
    # url and username can contain slaskes so we need to encode them
    [namespace_prefix, Base64.urlsafe_encode64(url.to_s), channel, Base64.urlsafe_encode64(username.to_s)].join('/')
  end

  def self.decode_key(key)
    _prefix, encoded_url, channel, username = *key.split('/')

    # Decode components as best we can, There might be a junk key in coming in
    url = begin
            Base64.urlsafe_decode64(encoded_url.to_s)
          rescue StandardError => e
            Rails.logger.error('ApplicationNotifier: encoded_url decode failed' + e.message)
          end
    if username.present?
      username = begin
              Base64.urlsafe_decode64(username.to_s)
            rescue StandardError => e
              Rails.logger.error('ApplicationNotifier: username decode failed' + e.message)
            end
    end

    [url, channel, username]
  end
end
