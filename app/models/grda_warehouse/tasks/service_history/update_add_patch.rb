module GrdaWarehouse::Tasks::ServiceHistory
  # A simplified version of Generate service history that only does 
  # the add section.
  # This allows us to invalidate clients and relatively quickly rebuild
  # their service history
  class UpdateAddPatch < Base
    include TsqlImport
    include ActiveSupport::Benchmarkable
    require 'ruby-progressbar'
    attr_accessor :logger

    # Build service history nights for all GrdaWarehouse::Hud::Client.destination
    # Process:
    # 1. NEW: Fetch any clients who don't have an entry in GrdaWarehouse::WarehouseClientsProcessed for routine service_history
    # 2. UPDATES:
    #   a. Fetch any source_clients who have entries that have changed in:
    #       Enrollment, Exit, Services, Client, Disability, EmploymentEducation, HealthAndDv, IncomeBenefit
    #       where the DateUpdated or DateDeleted > GrdaWarehouse::WarehouseClientsProcessed.last_service_updated_at
    #   b. Fetch any client with an open Enrollment
    #
    # These two groups are the clients that need rebuilding
    # Load any service history we have into RAM for a client
    # Build service history for those clients in RAM
    # Compare, and update/delete/insert as appropriate
    # Make note of the newest DateUpdated or DateDeleted in:
    #   Enrollment, Exit, Services, Client, Disability, EmploymentEducation, HealthAndDv, IncomeBenefit
    # Save as GrdaWarehouse::WarehouseClientsProcessed.last_service_updated_at
    def build_history

      @to_add = determine_clients_with_no_service_history()
      @to_update = clients_needing_updates()
      @to_patch = clients_with_open_enrollments()
      
      # Sanity check anyone with an open enrollment
      @sanity_check += service_history_source.entry.
        where(last_date_in_program: nil).pluck(:client_id)
      
      if no_one_to_build?
        logger.info "Nothing to do."
        return
      end


      # Walk the daily life of each client.
      # Determine all programs for that day, when they started, ended, where the client left to
      #
      # Make appropriate entries in the warehouse_client_service_history table 
      process_to_update()
      process_to_add()
      process_to_patch()
    end
  end
end