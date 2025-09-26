# frozen_string_literal: true

module TestRecovery
  # Use GitHub Actions workspace or fall back to tmp for local development
  PROGRESS_DIR = ENV['GITHUB_WORKSPACE'] || '/tmp'
  PROGRESS_FILE = File.join(PROGRESS_DIR, 'system_test_progress.txt')
  RECOVERY_ATTEMPTS_FILE = File.join(PROGRESS_DIR, 'recovery_attempts.txt')
  MAX_RECOVERY_ATTEMPTS = 3

  class << self
    def mark_test_started(example)
      File.write(PROGRESS_FILE, "STARTED:#{example.id}")
    end

    def mark_test_completed(example)
      File.write(PROGRESS_FILE, "COMPLETED:#{example.id}")
    end

    def last_completed_test
      return nil unless File.exist?(PROGRESS_FILE)

      content = File.read(PROGRESS_FILE).strip
      return nil unless content.start_with?('COMPLETED:')

      content.split(':', 2)[1]
    end

    def should_skip_test?(example)
      last_completed = last_completed_test
      return false unless last_completed

      # Skip tests that come before the last completed test
      example.id <= last_completed
    end

    def increment_recovery_attempts
      attempts = current_recovery_attempts + 1
      File.write(RECOVERY_ATTEMPTS_FILE, attempts.to_s)
      attempts
    end

    def current_recovery_attempts
      return 0 unless File.exist?(RECOVERY_ATTEMPTS_FILE)

      File.read(RECOVERY_ATTEMPTS_FILE).strip.to_i
    end

    def reset_recovery_attempts
      File.delete(RECOVERY_ATTEMPTS_FILE) if File.exist?(RECOVERY_ATTEMPTS_FILE)
    end

    def cleanup_progress_files
      File.delete(PROGRESS_FILE) if File.exist?(PROGRESS_FILE)
      File.delete(RECOVERY_ATTEMPTS_FILE) if File.exist?(RECOVERY_ATTEMPTS_FILE)
    end

    def handle_browser_crash(example, error)
      puts "\n🚨 Browser crashed on test: #{example.id}"
      puts "Error: #{error.class}: #{error.message}"

      attempts = increment_recovery_attempts

      if attempts > MAX_RECOVERY_ATTEMPTS
        puts "❌ Max recovery attempts (#{MAX_RECOVERY_ATTEMPTS}) exceeded. Failing test suite."
        cleanup_progress_files
        raise error
      end

      puts "🔄 Recovery attempt #{attempts}/#{MAX_RECOVERY_ATTEMPTS}"
      puts '📝 Progress saved. Restart with: RECOVER_FROM_CRASH=true rspec ...'

      # Mark this test as needing retry by not marking it completed
      exit(2) # Special exit code to indicate recovery needed
    end
  end
end

RSpec.configure do |config|
  config.before(:suite, type: :system) do
    if ENV['RECOVER_FROM_CRASH']
      puts '🔄 Recovering from previous crash...'
      puts "📍 Last completed test: #{TestRecovery.last_completed_test || 'none'}"
    else
      TestRecovery.cleanup_progress_files
    end
  end

  config.before(:each, type: :system) do |example|
    # Skip tests that were already completed
    skip 'Skipping - completed in previous run' if ENV['RECOVER_FROM_CRASH'] && TestRecovery.should_skip_test?(example)

    TestRecovery.mark_test_started(example)
  end

  config.after(:each, type: :system) do |example|
    TestRecovery.mark_test_completed(example) if example.execution_result.status == :passed
  end

  config.around(:each, type: :system) do |example|
    example.run
  rescue Ferrum::DeadBrowserError, Ferrum::TimeoutError, Ferrum::PendingConnectionsError => e
    TestRecovery.handle_browser_crash(example, e)
  end

  config.after(:suite, type: :system) do
    # Clean up on successful completion
    TestRecovery.cleanup_progress_files if RSpec.world.filtered_examples.values.flatten.all? { |ex| ex.execution_result.status == :passed }
  end
end
