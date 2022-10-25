namespace :test do
  desc 'Test logging'
  task :logging, [] => [:environment] do |_t, _args|
    Rails.logger.tagged({ process_name: 'nightly-process-1' }) do
      Rails.logger.info('Test hash passed')
    end
    Rails.logger.tagged(process_name: 'nightly-process-1') do
      Rails.logger.info('Test named args passed')
    end
    Rails.logger.tagged([{ process_name: 'nightly-process-1' }]) do
      Rails.logger.info('Test array of hash pased')
    end
    Rails.logger.tagged('Test') { Rails.logger.fatal('Test one tag') }
    Rails.logger.tagged('Test', 'Test2') { Rails.logger.fatal('Test two tags') }
    Rails.logger.tagged { Rails.logger.fatal('Test no tags') }
    Rails.logger.fatal('Test no tags without a tagged block')
    Rails.logger.tagged('Test') do
      Rails.logger.tagged('InnerTest') do
        Rails.logger.fatal('Test dual tagged blocks')
      end
    end
    TestJob.perform_now
  end

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

    puts '@notifier.ping with exception (Sentry)'
    @notifier.ping(
      'Testing .ping polymorphism - this should go to Sentry',
      {
        exception: StandardError.new('Testing .ping polymorphism - this should go to Sentry'),
        info: { with: 'data' },
      },
    )
    sleep 1

    puts '@notifier.ping normal (Slack)'
    @notifier.ping('Testing .ping polymorphism - this should go to Slack')
  end
end
