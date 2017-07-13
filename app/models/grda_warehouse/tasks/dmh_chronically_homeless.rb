# Figure out who is chronically homeless under the adjusted DMH rules
# Our working definition of DMH chronic homelessness is:
# 1. Currently Homeless in one of the DMH projects
# 2. Disabled
# 3. Homeless on 365+ nights of the last 3 years.
# 4. 180 nights in ES, SO or SH - non-DMH (ignore 3 year window)

module GrdaWarehouse::Tasks
  require 'ruby-progressbar'
  class DmhChronicallyHomeless < ChronicallyHomeless
    include TsqlImport
    CHRONIC_PROJECT_TYPES = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
  
    def run!
      Rails.logger.info "Updating status of DMH chronically homeless clients on #{@date}"
      @clients = dmh_clients.pluck(:client_id)
      Rails.logger.info "Found #{@clients.size} DMH clients who are currently homeless"
      @chronically_homeless = []
      @client_details = {}
      extra_work = 0
      @clients.each_with_index do |client_id, index|
        reset_for_batch()
        dmh_days_homeless = service_history_source.
          hud_currently_homeless(date: @date).
          where(client_id: client_id).
          where(dmh_projects_filter).
          service_within_date_range(start_date: @date - 3.years, end_date: @date).
          select(:date).
          distinct.
          count
        mainstream_days_homeless = service_history_source.service.
          joins(:project).
          where(client_id: client_id).
          where("#{coalesce_project_type.to_sql} in (#{CHRONIC_PROJECT_TYPES.join(', ')})").
          where.not(dmh_projects_filter).
          select(:date).
          distinct.
          count
        if dmh_days_homeless + mainstream_days_homeless >= 365 && mainstream_days_homeless >= 90
          adjusted_homeless_dates_served = residential_history_for_client(client_id: client_id)
          @chronic_trigger = "#{dmh_days_homeless + mainstream_days_homeless} days total #{mainstream_days_homeless} of which were mainstream, DMH client"
          homeless_months = adjusted_months_served(dates: adjusted_homeless_dates_served)
          @chronically_homeless << client_id
          # Add details for any chronically homeless client
          client = GrdaWarehouse::Hud::Client.find(client_id)
          add_client_details(
            client: client, 
            days_served: adjusted_homeless_dates_served, 
            months_homeless: homeless_months.size, 
            chronic_trigger: @chronic_trigger, 
            dmh: true
          )
         
        end
        @progress.format = "#{@progress_format}Found DMH chronically homeless: #{@chronically_homeless.size} processed #{index}/#{@clients.size} date: #{@date}"
      end
      Rails.logger.info "Found #{@chronically_homeless.size} DMH chronically homeless clients"
      
      chronic_source.transaction do
        chronic_source.where(date: @date, dmh: true).delete_all
        if @client_details.present?
          insert_batch(chronic_source, @client_details.values.first.keys, @client_details.values.map(&:values))
        end
      end
      Rails.logger.info 'Done updating status of chronically homeless clients'
    end   
  end
end