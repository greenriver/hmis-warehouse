###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class BackgroundRenderJob < BaseJob
  include CableReady::Broadcaster
  queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

  SUBSCRIBER_WAIT_SECONDS = 1
  SUBSCRIBER_POLL_SECONDS = 0.2

  def perform(render_id, **options)
    return unless subscriber_waiting?(render_id)

    html = render_html(**options)
    payload = cable_ready[BackgroundRenderChannel.stream_name(render_id)].
      outer_html(
        selector: "[data-background-render-render-id-value=#{render_id.to_json}]",
        html: html,
      )
    payload.broadcast
  rescue Exception => e
    handle_error(render_id, e)
  end

  private def render_html(**_options)
    raise 'abstract method not implemented'
  end

  # The browser subscribes before it requests the render, so no subscriber means the page
  # was closed or reloaded. Jobs share a worker, so skip the render rather than wait.
  # The short wait covers the subscription reaching Redis just after the job starts.
  # Adapters other than Redis (async in test) can't report subscribers, so always render.
  private def subscriber_waiting?(render_id)
    pubsub = ActionCable.server.pubsub
    return true unless pubsub.respond_to?(:redis_connection_for_subscriptions)

    # Same channel name ActionCable::SubscriptionAdapter::ChannelPrefix subscribes to.
    channel = [ActionCable.server.config.cable[:channel_prefix], BackgroundRenderChannel.stream_name(render_id)].compact.join(':')
    redis = pubsub.redis_connection_for_subscriptions
    checks = (SUBSCRIBER_WAIT_SECONDS / SUBSCRIBER_POLL_SECONDS).round + 1
    checks.times do |check|
      sleep SUBSCRIBER_POLL_SECONDS if check.positive?
      return true if redis.pubsub('numsub', channel).last.to_i.positive?
    end
    false
  ensure
    redis&.close
  end

  private def handle_error(render_id, error)
    payload = cable_ready[BackgroundRenderChannel.stream_name(render_id)].
      alert(message: 'Sorry, an error occurred building the report.  Please refresh the page and try again.')

    if Rails.env.development?
      message = (["Error in #{self.class}", error.message] + error.backtrace).join("\n")
      payload.inner_html(
        selector: "[data-background-render-render-id-value=#{render_id.to_json}]",
        html: message,
      )
    end
    Sentry.capture_exception(error)
    payload.broadcast
  end
end
