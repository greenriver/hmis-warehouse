# frozen_string_literal: true

TodoOrDie.config(
  die: ->(message, due_at, condition) {
    error_message = [
      "TODO: \"#{message}\"",
      (" came due on #{due_at.strftime('%Y-%m-%d')}" if due_at),
      (' and' if due_at && condition),
      (' has met the conditions to be acted upon' if condition),
      '. Do it!',
    ].compact.join('')

    raise TodoOrDie::OverdueTodo, error_message, TodoOrDie.__clean_backtrace(caller) unless defined?(Rails) && (Rails.env.production? || Rails.env.staging? || ENV['TODO_OR_DIE_LOG_ONLY'] == 'true')

    Rails.logger.warn(error_message)

    # Raise in development or test where TODO_OR_DIE_LOG_ONLY is false
  },
)
