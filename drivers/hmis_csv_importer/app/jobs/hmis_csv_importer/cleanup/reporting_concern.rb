module HmisCsvImporter::Cleanup::ReportingConcern
  extend ActiveSupport::Concern

  def log(str)
    Rails.logger.info(str)
  end

  included do |base|
    base.define_method(:benchmark) do |name, &block|
      rr = nil
      elapsed = Benchmark.realtime { rr = block.call}
      log "[#{base.name}] #{name} completed: #{elapsed.round(2)}s"
      rr
    end
  end
end
