class ExceptionNotifierLib
  def self.insert_log_url!(message_opts)
    log_stream_url = ENV.fetch('LOG_STREAM_URL', nil)
    return if log_stream_url.nil?

    fields = message_opts[:attachments][0][:fields]
    data_field = fields.find { |x| x[:title] == 'Data' }
    if data_field.nil?
      fields << {
        title: 'Data',
        value: "```log_url: #{log_stream_url}```",
      }
    else
      data_field[:value] = data_field[:value].tr('`', '')
      data_field[:value] += "\nlog_url: #{log_stream_url}"
      data_field[:value] = "```#{data_field[:value]}```"
    end
  end
end
