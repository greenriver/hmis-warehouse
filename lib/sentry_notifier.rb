module ExceptionNotifier
  class SentryNotifier
    def initialize(options)
      # do something with the options...
    end

    def call(exception, options={})
      # puts exception.message + "!!!"
      Sentry.capture_exception(exception)
    end
  end
end
