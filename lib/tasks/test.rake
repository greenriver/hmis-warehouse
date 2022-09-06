namespace :test do
  desc "Test logging"
  task :logging, [] => [:environment] do |t, args|
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
end
