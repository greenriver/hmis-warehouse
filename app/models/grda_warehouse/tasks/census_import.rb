module GrdaWarehouse::Tasks
  class CensusImport
    include TsqlImport
    include ArelHelper
    
    def initialize replace_all = nil
      if replace_all.present?
        @replace_all = true
      end
    end

    def run!
      GrdaWarehouseBase.transaction do
        if @replace_all
          Rails.logger.info 'Replacing all previous census records'
        end

        Rails.logger.info 'collecting client histories'
        # clear out the appropriate data and scope things to the appropriate date range
        if @replace_all
          start_date = history_source.order(ht[:date]).first.date
          census_by_project_source.delete_all
        else
          end_date = Date.today
          start_date = end_date - 1.year
          census_by_project_source.where( 
            census_t[:date].gteq(start_date).and(census_t[:date].lt(end_date))
          ).delete_all
        end

        # make a map from identifying triplets of keys to projects
        Rails.logger.info 'finding relevant projects'
        projects = project_scope.uniq.all.preload(:inventories)
        projects = projects.index_by{ |p| [ p.data_source_id, p.ProjectID.to_s, p.OrganizationID.to_s ] }
        
        data_by_date = {}
        while start_date < Date.today
          values = []
          # Fetch the day before the first day so we can have yesterday's data for the first day
          # last_yesterday = start_date - 1.day
          # last_yesterday_data = data_by_date.delete(last_yesterday) || history_for_range_by_project(last_yesterday, start_date)
          # data_by_date.clear
          # Add yesterday to the data set
          # data_by_date[last_yesterday] = last_yesterday_data
          # Fetch the next year of data
          next_data = history_for_range_by_project(start_date, start_date + 1.year).group_by(&:first)
          data_by_date.merge! next_data
          next_data.each do |date, rows|
            date = Date.parse date if date.is_a? String
            yesterday = date - 1.day
            # yesterdata = data_by_date[yesterday] || []
            rows.each do |date,ds,pi,oi,gender,veteran,count|
              key = [ds.to_i,pi.to_s,oi.to_s]
              project = projects[key]
              unless project.present?
                Rails.logger.warn "cannot find a project for the key (data_source_id, project_id, organization_id) #{key.inspect}"
                next
              end
              bed_count = 0
              project.inventories.each do |inventory|
                if inventory.start_date.nil? || inventory.start_date.to_date < yesterday && (inventory.end_date.nil? || inventory.end_date.to_date > date.to_date)
                  bed_count += inventory.beds || 0
                end
              end
              # yr = yesterdata.detect do |_,ds2,pi2,oi2,gender2,veteran2|
              #   ds == ds2 && pi == pi2 && oi == oi2 && gender == gender2 && veteran == veteran2
              # end || [0]
              # yesterdays_count = yr.last
              pt = project.computed_project_type
              values << {
                data_source_id:   ds.to_i,
                ProjectType:      pt,
                OrganizationID:   oi,
                ProjectID:        pi,
                date:             date,
                veteran:          veteran.to_i == 1,
                gender:           gender,
                client_count:     count.to_i,
                # yesterdays_count: yesterdays_count,
                bed_inventory:    bed_count
              }
            end
          end

          if values.any?
            columns = values.first.keys
            Rails.logger.info "Batch inserting #{values.length} rows"
            insert_batch census_by_project_source, columns, values.map(&:values)
          end
          start_date += 1.year
        end
        Rails.logger.info "Done with census by project"
        # clear out the appropriate data and scope things to the appropriate date range
        if @replace_all
          start_date = history_source.order(ht[:date]).first.date
          census_by_project_type_source.delete_all
        else
          end_date = Date.today
          start_date = end_date - 1.year
          cpt = census_by_project_type_source.arel_table
          census_by_project_type_source.where( cpt[:date].gteq(start_date).and cpt[:date].lt(end_date) ).delete_all
        end

        data_by_date = {}
        while start_date < Date.today
          values = []
          # last_yesterday = start_date - 1.day
          # last_yesterday_data = data_by_date.delete(last_yesterday) || history_for_range_by_project_type(last_yesterday, start_date)
          # data_by_date.clear
          # data_by_date[last_yesterday] = last_yesterday_data
          next_data = history_for_range_by_project_type(start_date, start_date + 1.year).group_by(&:first)
          data_by_date.merge! next_data
          next_data.each do |date, rows|
            date = Date.parse date if date.is_a? String
            # yesterday = date - 1.day
            # yesterdata = data_by_date[yesterday] || []
            rows.each do |date,pt,gender,veteran,count|
              date = Date.parse date if date.is_a? String
              bed_count = 0
              # yr = yesterdata.detect do |_,pt2,gender2,veteran2|
              #   pt == pt2 && gender == gender2 && veteran == veteran2
              # end || [0]
              # yesterdays_count = yr.last
              values << {
                ProjectType:      pt,
                date:             date,
                veteran:          veteran.to_i == 1,
                gender:           gender,
                client_count:     count.to_i,
                # yesterdays_count: yesterdays_count,
              }
            end
          end

          if values.any?
            columns = values.first.keys
            Rails.logger.info "batch inserting #{values.length} rows"
            insert_batch census_by_project_type_source, columns, values.map(&:values)
          end
          start_date += 1.year
        end
      end
      Rails.logger.info "Done with census by project_type"
    end

    private def census_by_project_type_source
      GrdaWarehouse::CensusByProjectType
    end

    private def census_by_project_source
      GrdaWarehouse::CensusByProject
    end

    def history_source
      GrdaWarehouse::ServiceHistory.service.where.not(project_type: nil)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def project_scope
      GrdaWarehouse::Hud::Project.where.not(ProjectType: nil)
    end

    def history_for_range_by_project(start_date, end_date)
      Rails.logger.info "collecting histories from range #{start_date} to #{end_date}"
      query = history_source.joins(:client).
        group( 
          ht[:date], 
          ht[:data_source_id], 
          ht[:project_id], 
          ht[:organization_id], 
          coalesced_gender, 
          coalesced_vet_status
        ).
        order(ht[:date]).
        where( ht[:date].between( start_date ... end_date ) ).select([
          ht[:date],
          ht[:data_source_id],
          ht[:project_id],
          ht[:organization_id],
          coalesced_gender,
          coalesced_vet_status,
          nf( 'COUNT', [ nf( 'DISTINCT', [ht[:client_id]] ) ])
        ])

      query.connection.select_rows(query.to_sql)
    end

    def history_for_range_by_project_type(start_date, end_date)
      Rails.logger.info "collecting histories from range #{start_date} to #{end_date}"
      query = history_source.joins(:client, :project).
        group( 
          ht[:date], 
          ht[:computed_project_type], 
          coalesced_gender, 
          coalesced_vet_status
        ).
        order(ht[:date]).
        where( ht[:date].between( start_date ... end_date ) ).select([
          ht[:date],
          ht[:computed_project_type].as('project_type').to_sql,
          coalesced_gender,
          coalesced_vet_status,
          nf( 'COUNT', [ nf( 'DISTINCT', [ht[:client_id]] ) ])
        ])
      query.connection.select_rows(query.to_sql)
    end

    private def coalesced_gender
      cl client_source.arel_table[:Gender], 99
    end

    private def coalesced_vet_status
      cl client_source.arel_table[:VeteranStatus], 0
    end

    def p_t
      project_scope.arel_table
    end

    def sh_t
      history_source.arel_table
    end

    def ht
      sh_t
    end

    def ct
      client_source.arel_table
    end

    def census_t
      census_by_project_source.arel_table
    end

  end
end