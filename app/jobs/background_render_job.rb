class BackgroundRenderJob < BaseJob
  include CableReady::Broadcaster
  queue_as :short_running

  def perform(render_id, **options)
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

  private def render_html(**options)
    raise "abstract method not implemented"
  end

  private def handle_error(render_id, error)
    payload = cable_ready[BackgroundRenderChannel.stream_name(render_id)].
      alert(message: "Sorry, an error occurred building the report.  Please refresh the page and try again.")

    if Rails.env.development?
      message = (["Error in #{self.class}", error.message] + error.backtrace).join("\n")
      payload.inner_html(
        selector: "[data-background-render-render-id-value=#{render_id.to_json}]",
        html: message,
      )
    end

    payload.broadcast
  end
end
