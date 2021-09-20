TodoOrDie.config(
  die: ->(message, due_at, condition) {
    error_message = [
      "TODO: \"#{message}\"",
      (" came due on #{due_at.strftime("%Y-%m-%d")}" if due_at),
      (" and" if due_at && condition),
      (" has met the conditions to be acted upon" if condition),
      ". Do it!"
    ].compact.join("")

    if defined?(Rails) && (Rails.env.production? || Rails.env.staging?)
      Rails.logger.warn(error_message)
    else
      raise TodoOrDie::OverdueTodo, error_message, TodoOrDie.__clean_backtrace(caller)
    end
  }
)
