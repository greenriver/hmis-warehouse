namespace :test do
  desc "Test logging"
  task :logging, [] => [:environment] do |t, args|
    Rails.logger.tagged({process_name: "nightly-process-1"}) do
      Rails.logger.info('Test hash passed')
    end
    Rails.logger.tagged(process_name: "nightly-process-1") do
      Rails.logger.info('Test named args passed')
    end
    Rails.logger.tagged([{process_name: "nightly-process-1"}]) do
      Rails.logger.info('Test array of hash pased')
    end
    Rails.logger.tagged("Test") { Rails.logger.fatal("Test one tag") }
    Rails.logger.tagged("Test", "Test2") { Rails.logger.fatal("Test two tags") }
    Rails.logger.tagged { Rails.logger.fatal("Test no tags") }
    Rails.logger.fatal("Test no tags without a tagged block")
    Rails.logger.tagged("Test") {
      Rails.logger.tagged("InnerTest") {
      Rails.logger.fatal("Test dual tagged blocks")
      }
    }
    TestJob.perform_now
  end

  desc 'Test generating an Exception'
  task :exception, [] => [:environment] do |t, args|
    raise Exception.new('An Exception has been raised from within a Rake task.')
  end

  desc 'Test Sentry'
  task :sentry, [] => [:environment] do |t, args|
    msg = "Testing Sentry from #{Rails.env} for hmis-warehouse"
    Sentry.capture_message(msg)
    Sentry.capture_exception(Exception.new(msg))
  end
end
