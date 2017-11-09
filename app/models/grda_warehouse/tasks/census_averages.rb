module GrdaWarehouse::Tasks
  class CensusAverages
    include TsqlImport
    
    def initialize replace_all = nil
      if replace_all.present?
        @replace_all = true
      end
    end

    def run!
      if @replace_all
        Rails.logger.info 'Replacing all previous census averages'
      end

      Rails.logger.info 'Collecting census data'
      # clear out the appropriate data and scope things to the appropriate date range
      if @replace_all
        ht = history_source.arel_table
        start_year = history_source.order(ht[:date]).first.date.year
        census_averages_source.delete_all
      else
        end_date = Date.today
        start_year = 3.years.ago.year
        ct = census_averages_source.arel_table
        census_averages_source.where(year: start_year).delete_all
      end

      # make a make from identifying triplets of keys to projects
      # Rails.logger.info 'Loading relevant projects'
      # projects = GrdaWarehouse::Hud::Project.uniq.all
      # projects = projects.index_by{ |p| [ p.data_source_id, p.ProjectID, p.OrganizationID ] }
      inventory = GrdaWarehouse::Hud::Inventory.all.group_by do |m|
        [m[:data_source_id], m[:ProjectID]]
      end

      while start_year <= 1.year.ago.year
        # build census numbers by project
        census = census_by_project_source.for_year(start_year).pluck(*census_columns).group_by do |m| 
          [
            m[census_columns.index(:data_source_id)], 
            m[census_columns.index(:ProjectType)], 
            m[census_columns.index(:OrganizationID)], 
            m[census_columns.index(:ProjectID)]
          ]
        end.map do |k,m|
          data_source_id, project_type, organization_id, project_id = k
          [k, {
              year: start_year,
              data_source_id: data_source_id,
              ProjectType: project_type,
              OrganizationID: organization_id,
              ProjectID: project_id,
              client_count: m.map{|e| e[census_columns.index(:client_count)]}.sum,
              days_of_service: m.map{|e| e[census_columns.index(:date)]}.uniq.size
          }]
        end.to_h
        census.each do |k, v|
          census[k][:bed_inventory] = 0
          census[k][:seasonal_inventory] = 0
          census[k][:overflow_inventory] = 0
          program_inventory = inventory[[k[census_columns.index(:data_source_id)], k[census_columns.index(:ProjectID)]]] || []
          program_inventory.each do |m|
            inventory_start = m.InventoryStartDate&.year
            inventory_end = m.InventoryEndDate&.year
            no_start = (inventory_start.blank? && (inventory_end.blank? || inventory_end >= start_year)
            open_during_year = inventory_start.present? && inventory_start <= start_year && inventory_end.blank? || (inventory_end.present? && inventory_end >= start_year)
            # If the inventory was available during the year
            if open_during_year || no_start
              if m.Availability.blank? || m.Availability == 1
                census[k][:bed_inventory] += m.BedInventory || 0
              else
                census[project_type][:seasonal_inventory] += m.BedInventory || 0
              end
            end
          end
        end

        if census.any?
          columns = census.values.first.keys
          Rails.logger.info "Batch inserting #{census.length} rows"
          begin
            insert_batch census_averages_source, columns, census.values.map(&:values)
            census.clear
          rescue Exception => e
            Rails.logger.warn "Unable to insert batch from #{start_year} #{e.message}"
            next
          end
        end

        # build census numbers by project type
        census = census_by_project_type_source.for_year(start_year).pluck(*census_by_project_type_columns).group_by do |m| 
            m[census_columns.index(:ProjectType)]
        end.map do |project_type,m|
          @destination_data_source_id ||= data_source_source.destination.first.id
          [project_type, {
              year: start_year,
              ProjectType: project_type,
              client_count: m.map{|e| e[census_columns.index(:client_count)] || 0}.sum,
              days_of_service: m.map{|e| e[census_columns.index(:date)]}.uniq.size,
              data_source_id: @destination_data_source_id, # When combining by project type, this is meaningless
          }]
        end.to_h
        census.each do |project_type, v|
          census[project_type][:bed_inventory] = 0
          census[project_type][:seasonal_inventory] = 0
          census[project_type][:overflow_inventory] = 0
          program_inventory = inventory[[project_type[census_columns.index(:data_source_id)], project_type[census_columns.index(:ProjectID)]]] || []
          program_inventory.each do |m|
            inventory_start = m.InventoryStartDate&.year
            inventory_end = m.InventoryEndDate&.year
            no_start = (inventory_start.blank? && (inventory_end.blank? || inventory_end >= start_year)
            open_during_year = inventory_start.present? && inventory_start <= start_year && inventory_end.blank? || (inventory_end.present? && inventory_end >= start_year)
            # If the inventory was available during the year
            if open_during_year || no_start
              if m.Availability.blank? || m.Availability == 1
                census[k][:bed_inventory] += m.BedInventory || 0
              else
                census[project_type][:seasonal_inventory] += m.BedInventory || 0
              end
            end
          end
        end

        if census.any?
          columns = census.values.first.keys
          Rails.logger.info "Batch inserting #{census.length} rows"
          begin
            insert_batch census_averages_source, columns, census.values.map(&:values)
          rescue Exception => e
            Rails.logger.warn "Unable to insert batch from #{start_year} #{e.message}"
            next
          end
        end
        start_year += 1
      end
      Rails.logger.info 'Done collecting census data'
    end

    private def census_averages_source
      GrdaWarehouse::CensusByYear
    end

    private def census_by_project_source
      GrdaWarehouse::CensusByProject
    end

    private def census_by_project_type_source
      GrdaWarehouse::CensusByProjectType
    end

    private def history_source
      GrdaWarehouse::ServiceHistory.service.where.not(project_type: nil)
    end

    private def client_source
      GrdaWarehouse::Hud::Client
    end

    private def data_source_source
      GrdaWarehouse::DataSource
    end
    
    private def census_columns
      [:data_source_id, :ProjectType, :OrganizationID, :ProjectID, :client_count, :date]
    end

    private def census_by_project_type_columns
      [:ProjectType, :client_count, :date]
    end

  end
end