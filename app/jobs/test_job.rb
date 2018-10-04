class TestJob < BaseJob
  def perform
    a = Time.now

    while ( (Time.now - a) < 10.seconds) do
      Rails.logger.info "Simulating processing. In `#{STARTING_PATH}` directory."
      sleep 5
    end
  end
end
