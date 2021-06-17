class BackgroundRenderJob < BaseJob
  include CableReady::Broadcaster
  queue_as :short_running

  def perform(render_id, **options)
    html = render_html(**options)
    cable_ready[BackgroundRenderChannel.stream_name(render_id)].
      outer_html(
        selector: "[data-background-render-render-id-value=#{render_id.to_json}]",
        html: html,
      ).broadcast
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
      message = (["Error in #{self.class}", e.message] + e.backtrace).join("\n")
      payload.console_log(message: message)
    end

    payload.broadcast
  end
end
