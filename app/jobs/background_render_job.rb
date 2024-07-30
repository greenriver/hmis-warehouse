###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BackgroundRenderJob < BaseJob
  include CableReady::Broadcaster
  queue_as ENV.fetch('DJ_SHORT_QUEUE_NAME', :short_running)

  def perform(render_id, **options)
    # Before we run this, let's make sure someone still wants it.
    pubsub = ActionCable.server.pubsub
    channels = pubsub.send(:redis_connection).pubsub('channels', '*')
    # Give this some time to find the stream
    found_stream = nil
    timeout = 15
    while found_stream.blank?
      found_stream = channels.detect { |stream| stream.include?(render_id) }
      break if found_stream.present?

      sleep 1 if found_stream.blank?
      timeout -= 1
      break if timeout <= 0
    end

    return unless found_stream

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
