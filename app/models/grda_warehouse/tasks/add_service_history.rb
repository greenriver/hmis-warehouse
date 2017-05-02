module GrdaWarehouse::Tasks
  # A simplified version of Generate service history that only does 
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class AddServiceHistory < GenerateServiceHistory
    include TsqlImport
    include ActiveSupport::Benchmarkable
    require 'ruby-progressbar'
    attr_accessor :logger
    
    private def build_history
      @batch_size = 1000

      logger.info "Finding clients without service histories..."
      @to_add = GrdaWarehouse::Hud::Client.destination.without_service_history.pluck(:id)
      logger.info "...found #{@to_add.size}."

      @to_update = {}
      @to_add_count = @to_add.size

      @to_update_count = 0

      if @to_add.empty?
        logger.info "Nothing to do."
        return
      end

      clients_completed = 0

      msg =  "Processing #{@to_add.size} new/invalidated clients in batches of #{@batch_size}"
      logger.info msg

      GC.start
      batches = @to_add.each_slice(@batch_size)
      clients_completed = 0
      batches.each do |batch|
        prepare_for_batch batch # Limit fetching to the current batch
        # Setup a huge transaction, we'll commit frequently
        GrdaWarehouseBase.transaction do
          batch.each_with_index do |id,index|
            add(id)
            clients_completed += 1
            status('Added', clients_completed, commit_after: 10, denominatar: @to_add.size)
          end
        end
        logger.info "... #{@pb_output_for_log.bar_update_string} #{@pb_output_for_log.eol}"
        @batch = nil
        # check for discrepencies
        GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(25).run!
      end
      @progress.refresh

      # check for discrepencies
      GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(100).run!
    end
  end
end
