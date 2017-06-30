module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does 
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class Patch < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    require 'ruby-progressbar'
    attr_accessor :logger
    
    private def build_history
      @to_add = []
      @to_update = {}
      @to_update_count = 0
      # Debug
      # @to_patch = [324032]

      @to_patch = clients_with_open_enrollments()
      
      # Sanity check anyone with an open enrollment
      # @sanity_check += service_history_source.entry.
      #   where(last_date_in_program: nil).pluck(:client_id)
      
      if no_one_to_build?
        logger.info "Nothing to do."
        return
      end

      process_to_patch()
    end
  end
end
