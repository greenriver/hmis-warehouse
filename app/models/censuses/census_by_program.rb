module Censuses
  class CensusByProgram < Base
    def for_date_range start_date, end_date, scope: nil
      load_associated_records()
      service_days = fetch_service_days(start_date.to_date - 1.day, end_date, scope)
      project_ids = service_days.map{|m| m['project_id']}.uniq
      project_id_scope = GrdaWarehouse::CensusByProject.where(ProjectID: project_ids)
      at = project_id_scope.arel_table
      project_id_scope = project_id_scope.
        where(ProjectType: @project_types.values.flatten.uniq).
        where( at[:date].between start_date.to_date .. end_date.to_date )
      inventory = fetch_inventory(start_date, end_date, project_id_scope.distinct.select(:ProjectID))
      @totals = {}
      @programs = {}
      services_by_program = service_days.group_by do |m|
        [
          m['date'], 
          m['data_source_id'], 
          m['organization_id'], 
          m['project_id']
        ]
      end.map do |k,m|
        [
          k, 
          m.map{|day| day['count_all']}.sum
        ]
      end.to_h

      services_by_program.each do |k, count_all|
        # make useful variables from the composite key
        date, ds_id, org_id, p_id = k
        # We fetched an extra day so we could get a count for yesterday on the first day, ignore it
        if date == start_date.to_date - 1.day
          next
        end
        yesterdays_count = services_by_program[[date.to_date - 1.day, ds_id, org_id, p_id]] || 0
        data_source = @data_sources[ds_id][data_source_columns.index(:short_name)]
        organization = @org_names_by_org_id_data_source_id[[ds_id, org_id]][organization_columns.index(:OrganizationName)]
        project = @project_names_by_project_id_organization_id_data_source_id[[ds_id, org_id, p_id]][project_columns.index(:ProjectName)]
        project_type_code = @project_names_by_project_id_organization_id_data_source_id[[ds_id, org_id, p_id]][project_columns.index(:ProjectType)]
        act_as_project_type_code = @project_names_by_project_id_organization_id_data_source_id[[ds_id, org_id, p_id]][project_columns.index(:act_as_project_type)]
        project_type = @project_types.select{|k,v| v.include? project_type_code}.keys.first
        act_as_project_type = @project_types.select{|k,v| v.include? act_as_project_type_code}.keys.first
        
        @programs[ds_id] ||= {}
        @programs[ds_id][org_id] ||= {}
        @programs[ds_id][org_id][p_id] ||= {}
        @programs[ds_id][org_id][p_id][:datasets] ||= []
        @programs[ds_id][org_id][p_id][:datasets][0] ||= {
          label: 'Client Count'
        }
        @programs[ds_id][org_id][p_id][:datasets][1] ||= {
          label: 'Bed Inventory Count'
        }
        @programs[ds_id][org_id][p_id][:title] ||= {}
        @programs[ds_id][org_id][p_id][:title][:display] ||= true
        @programs[ds_id][org_id][p_id][:title][:text] ||= begin
          title = "#{project} (#{project_type&.upcase}) < #{organization} < #{data_source}" 
          if act_as_project_type.present?
            title += "; Acts as #{act_as_project_type.upcase} for HUD Reporting"
          end
          title
        end
        @programs[ds_id][org_id][p_id][:datasets][0][:data] ||= []
        @programs[ds_id][org_id][p_id][:datasets][0][:data] << {
          x: date, 
          y: count_all, 
          yesterday: yesterdays_count,
        }
        @programs[ds_id][org_id][p_id][:datasets][1][:data] ||= []

        inventory_count = begin
          count = 0
          if inventory[[ds_id, p_id]].present?
            inventory[[ds_id, p_id]].each do |i|
              inventory_start_date = i[inventory_columns.index(:InventoryStartDate)]
              inventory_end_date = i[inventory_columns.index(:InventoryEndDate)]
              if inventory_start_date.blank? || inventory_end_date.blank? || (date > inventory_start_date && date < inventory_end_date)
                count += i[inventory_columns.index(:BedInventory)] || 0
              end
            end
          end
          count
        end

        @programs[ds_id][org_id][p_id][:datasets][1][:data] << {x: date, y: inventory_count}
        # Only return totals if we have more than one project_id
        if project_ids.size > 1
          @totals['all'] ||= {}
          @totals['all'][date] ||= {}
          @totals['all'][date]['count_all'] ||= 0
          @totals['all'][date]['count_all'] += count_all
          @totals['all'][date]['yesterday'] ||= 0
          @totals['all'][date]['yesterday'] += yesterdays_count
          @totals['all'][date]['beds'] ||= 0
          @totals['all'][date]['beds'] += inventory_count
          @totals[ds_id] ||= {}
          @totals[ds_id][date] ||= {}
          @totals[ds_id][date]['count_all'] ||= 0
          @totals[ds_id][date]['count_all'] += count_all
          @totals[ds_id][date]['yesterday'] ||= 0
          @totals[ds_id][date]['yesterday'] += yesterdays_count
          @totals[ds_id][date]['beds'] ||= 0
          @totals[ds_id][date]['beds'] += inventory_count

        end
        @totals.each do |ds_id, days|
          @programs[ds_id] ||= {}
          @programs[ds_id]['all'] ||= {}
          @programs[ds_id]['all']['all'] ||= {}
          @programs[ds_id]['all']['all'][:datasets] ||= []
          @programs[ds_id]['all']['all'][:datasets][0] ||= {
            label: 'Client Count'
          }
          @programs[ds_id]['all']['all'][:datasets][0][:data] = days.map{|day,counts| {x: day, y: counts['count_all'], yesterday: counts['yesterday']}}
          @programs[ds_id]['all']['all'][:datasets][1] ||= {
            label: 'Bed Inventory Count'
          }
          @programs[ds_id]['all']['all'][:datasets][1][:data] = days.map{|day,counts| {x: day, y: counts['beds']}}
          if ds_id == 'all'
            @programs[ds_id]['all']['all'][:title] ||= {
              display: true, 
              text: 'All Programs from All Sources'
            }
          else
            @programs[ds_id]['all']['all'][:title] ||= {
              display: true,
              text: "All Programs from #{@data_sources[ds_id][1]}"
            }
          end
        end
      end
      #raise @totals.inspect
      return @programs #.sort_by{|k,v| k.to_s}
    end

    def detail_name string
      load_associated_records()
      ds_id, org_id, p_id = string.split('-')
      if ds_id == 'all'
        return 'All Programs from All Sources on'
      end
      data_source = @data_sources[ds_id.to_i][1]
      if org_id == 'all'
        return "All Programs from #{data_source} on"
      end
      organization = @org_names_by_org_id_data_source_id[[ds_id.to_i, org_id]][2]
      project = @project_names_by_project_id_organization_id_data_source_id[[ds_id.to_i, org_id, p_id]][3]
      return "#{project} at #{organization} on"
    end

    private def fetch_service_days start_date, end_date, scope      
      # FIXME, need to only include programs that are bed-nights
      # Specifically barred guests should be excluded, at least from the totals
      # Can we identify them by service_type = 200? 
      scope ||= GrdaWarehouse::CensusByProject
      at = scope.arel_table
      relation = scope.
        where(ProjectType: @project_types.values.flatten.uniq).
        where( at[:date].between start_date.to_date .. end_date.to_date ).
        group(:date, :data_source_id, :OrganizationID, :ProjectID).
        select( at[:date], at[:data_source_id], at[:OrganizationID].as('organization_id'), at[:ProjectID].as('project_id'), at[:client_count].sum.as('count_all') ).
        order(date: :asc)
      service_days = relation_as_report relation
    end


  end
end