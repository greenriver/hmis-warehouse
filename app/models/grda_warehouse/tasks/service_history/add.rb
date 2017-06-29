module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does 
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class Add < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    require 'ruby-progressbar'
    attr_accessor :logger
    
    private def build_history
      @to_add = determine_clients_with_no_service_history()
      # Fill some variables we expect to have
      @to_update = {}
      @to_update_count = 0

      if @to_add.empty?
        logger.info "Nothing to do."
        return
      end

      process_to_add()
    end
  end
end
