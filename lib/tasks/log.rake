namespace :log do
  desc 'Log INFO to STDOUT'
  task :info_to_stdout, [] => [:environment] do
    # NOTE if you want the logs to go to standard out, set LOG_STD=true
    Rails.logger.level = Logger::INFO if Rails.env == 'development'
  end

  # Moved from :test namespace because something was trying to make that run in
  # the rails test environment.
  desc 'Test logging'
  task :test, [] => [:environment] do |_t, _args|
    Rails.logger.info('Untagged info')

    Rails.logger.tagged({ process_name: 'nightly-process-1' }) do
      Rails.logger.info('Test hash passed')
    end
    Rails.logger.tagged(process_name: 'nightly-process-1') do
      Rails.logger.info('Test named args passed')
    end
    Rails.logger.tagged([{ process_name: 'nightly-process-1' }]) do
      Rails.logger.info('Test array of hash passed')
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
    Rails.logger.info('This should not be tagged')

    TestJob.perform_now
    TestJob.perform_later
  end
end
