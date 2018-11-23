module Censuses
  class Base
    def self.available_census_types
      [
        Censuses::CensusBedNightProgram,
        Censuses::CensusByProgram,
        Censuses::CensusByProjectType,
        Censuses::CensusVeteran,
      ]
    end

    # -- OLD BELOW HERE --

    # def initialize
    #   @project_types = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES
    # end
    #
    # def for_date_range start_date, end_date, scope: nil
    #   raise 'Abstract method'
    # end
    #
    # # pass the project_id, data_source_id and organization_id through the scope to limit
    # def for_date date, scope: nil, constraint: -> (h) { h['client_id'] }
    #   load_associated_records()
    #   scope ||= GrdaWarehouse::ServiceHistory.service
    #   at = scope.arel_table
    #   pt = GrdaWarehouse::Hud::Project.arel_table
    #   dt = GrdaWarehouse::DataSource.arel_table
    #   ct = GrdaWarehouse::Hud::Client.arel_table
    #   relation = scope.
    #     joins(:project).
    #     joins(:data_source).
    #     joins(:client).
    #     where( at[:date].eq date ).
    #     distinct.
    #     select( at[:date], at[:client_id], ct[:LastName], ct[:FirstName], ct[:MiddleName], pt[:ProjectName], pt[:ProjectID], dt[:short_name] ).
    #     order( dt[:short_name].asc, pt[:ProjectName].asc, ct[:LastName].asc, ct[:FirstName].asc )
    #   relation_as_report(relation).uniq{ |h| constraint.call h  }   # we generally only want each client once (but we override this in one test)
    # end
    #
    # def detail_name string
    #   raise 'Abstract method'
    # end
    #
    # private
    #
    #   def relation_as_report relation
    #     sql = relation.to_sql
    #     # Rails.logger.debug "#{self.class.name}#relation_as_report: #{sql}"
    #     if relation.engine.postgres?
    #       result = relation.connection.select_all(sql)
    #       result.map do |row|
    #         Hash.new.tap do |hash|
    #           result.columns.each_with_index.map do |name, idx|
    #             hash[name.to_s] = result.send(:column_type, name).type_cast_from_database(row[name])
    #           end
    #         end
    #       end
    #     else
    #       relation.connection.raw_connection.execute(sql).each( as: :hash )
    #     end
    #   end
    #
    #   def load_associated_records
    #     @project_names_by_project_id_organization_id_data_source_id ||=
    #       GrdaWarehouse::Hud::Project.pluck(*project_columns).index_by do |m|
    #         @proj_indices ||= [ :data_source_id, :OrganizationID, :ProjectID ].map{ |i| project_columns.index i }
    #         m.values_at *@proj_indices
    #       end
    #     @org_names_by_org_id_data_source_id ||=
    #       GrdaWarehouse::Hud::Organization.pluck(*organization_columns).index_by do |m|
    #         @org_indices ||= [ :data_source_id, :OrganizationID ].map{ |i| organization_columns.index i }
    #         m.values_at *@org_indices
    #       end
    #     @data_sources ||= GrdaWarehouse::DataSource.importable.pluck(*data_source_columns).index_by{ |m| m.first}
    #   end
    #
    #   def fetch_service_days start_date, end_date, scope
    #     raise 'Abstract method'
    #   end
    #
    #   # project_ids can be a scope or an array of IDS
    #   def fetch_inventory start_date, end_date, project_ids
    #     ::GrdaWarehouse::Hud::Inventory.where(ProjectID: project_ids).
    #       pluck(*inventory_columns).
    #       group_by do |m|
    #         [
    #           m[inventory_columns.index(:data_source_id)],
    #           m[inventory_columns.index(:ProjectID)],
    #         ]
    #       end
    #   end
    #
    #   def project_columns
    #     [:data_source_id, :OrganizationID, :ProjectID, :ProjectName, :ProjectType, :act_as_project_type]
    #   end
    #
    #   def organization_columns
    #     [:data_source_id, :OrganizationID, :OrganizationName]
    #   end
    #
    #   def data_source_columns
    #     [:id, :name, :short_name]
    #   end
    #
    #   def inventory_columns
    #     [:data_source_id, :ProjectID, :Availability, :BedInventory, :HMISParticipatingBeds, :InventoryStartDate, :InventoryEndDate]
    #   end
  end
end