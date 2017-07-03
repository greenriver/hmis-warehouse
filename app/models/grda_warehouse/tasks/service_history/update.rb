module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does 
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class Update < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    require 'ruby-progressbar'
    attr_accessor :logger

    def build_history

      @to_add = []
      @to_update = clients_needing_updates()
      @to_patch = []
            
      if no_one_to_build?
        logger.info "Nothing to do."
        return
      end

      process_to_update()
    end
  end
end