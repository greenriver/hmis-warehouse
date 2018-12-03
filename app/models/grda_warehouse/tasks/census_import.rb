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
      Rails.logger.info 'Processing GrdaWarehouse::Census census format'

      if @replace_all
        Rails.logger.info 'Replacing all GrdaWarehouse::Census census records'
      end

      # Determine the appropriate date range
      if @replace_all
        start_date = history_scope.order(ht[:date]).first.date
        end_date = Date.today
      else
        end_date = Date.today
        start_date = end_date - 3.years
      end
      GrdaWarehouse::Census::CensusBuilder.new.create_census(start_date, end_date)

    end

    private def census_by_project_type_source
      GrdaWarehouse::CensusByProjectType
    end

    private def census_by_project_source
      GrdaWarehouse::CensusByProject
    end

    def history_source
      GrdaWarehouse::ServiceHistory
    end

    def history_scope
      history_source.service.where.not(history_source.project_type_column => nil)
    end

    def client_source
      GrdaWarehouse::Hud::Client
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def project_scope
      project_source.where.not(project_source.project_type_column => nil)
    end

    def history_for_range_by_project(start_date, end_date)
      Rails.logger.info "collecting histories from range #{start_date} to #{end_date}"
      query = history_scope.joins(:client).
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
      query = history_scope.joins(:client, :project).
        group( 
          ht[:date], 
          ht[history_source.project_type_column], 
          coalesced_gender, 
          coalesced_vet_status
        ).
        order(ht[:date]).
        where( ht[:date].between( start_date ... end_date ) ).select([
          ht[:date],
          ht[history_source.project_type_column].as('project_type').to_sql,
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