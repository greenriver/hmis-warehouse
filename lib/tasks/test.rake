namespace :test do
  desc 'Test generating an Exception'
  task :exception, [] => [:environment] do |_t, _args|
    raise StandardError.new('An Exception has been raised from within a Rake task.')
  end

  desc 'Test Sentry'
  task :sentry, [] => [:environment] do |_t, _args|
    include NotifierConfig
    setup_notifier('SentryTest')

    # The sleeps make it easier to see which steps trigger a 'sending envelope to Sentry' log message

    puts 'Sentry.capture_exception'
    Sentry.capture_exception(StandardError.new("Testing Sentry.capture_exception from #{Rails.env} for hmis-warehouse"))
    sleep 1

    puts 'Sentry.capture_message'
    Sentry.capture_message("Testing Sentry.capture_message from #{Rails.env} for hmis-warehouse")
    sleep 1

    puts 'Sentry.capture_exception_with_info'
    Sentry.capture_exception_with_info(
      StandardError.new("Testing Sentry.capture_exception_with_info from #{Rails.env} for hmis-warehouse"),
      'Testing custom error message',
      { with: 'data' }
    )
    sleep 1

    puts 'Sentry.capture_exception_with_info_no_exception'
    Sentry.capture_exception_with_info(
      StandardError.new("Testing Sentry.capture_exception_with_info_no_exception from #{Rails.env} for hmis-warehouse"),
      'Testing custom error message',
      { info: 'info' }
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry)'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry with data'),
        info: { with: 'data' },
      },
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry), but no info'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry without data'),
      },
    )
    sleep 1

    puts '@notifier.ping with exception (Sentry), but nil info'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry with nil data'),
        info: nil,
      },
    )
    sleep 1

    puts '@notifier.ping normal (Slack)'
    @notifier.ping('Testing .ping polymorphism - this should go to Slack')
  end
end
