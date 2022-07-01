class LogFormatter < ::Logger::Formatter
  def call(severity, time, program_name, message)
    message = '' if message.blank?
    severity = '' if message.blank?

    {
      level: severity,
      progname: program_name,
      message: message,
    }.to_json + "\r\n"
  end
end
