###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Figure out who is chronically homeless under the adjusted DMH rules
# Our working definition of DMH chronic homelessness is:
# 1. Currently Homeless in one of the DMH projects
# 2. Disabled
# 3. Homeless on 365+ nights of the last 3 years.
# 4. 180 nights in ES, SO or SH - non-DMH (ignore 3 year window)

module GrdaWarehouse::Tasks
  class DmhChronicallyHomeless < ChronicallyHomeless
    include TsqlImport
    CHRONIC_PROJECT_TYPES = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES

    def run!
      logger.info "====DRY RUN====" if @dry_run
      logger.info "Updating status of DMH chronically homeless clients on #{@date}"
      if @clients.present?
        # limit to those we provided where it intersects with actual DMH clients
        @clients = @clients #dmh_clients.pluck(:client_id) && @clients
      else
        @clients = dmh_clients.pluck(:client_id)
      end
      logger.info "Found #{@clients.size} DMH clients who are currently homeless"
      @chronically_homeless = []
      @client_details = {}
      extra_work = 0
      @clients.each_with_index do |client_id, index|
        debug_log "Calculating chronicity for #{client_id}"
        reset_for_batch()
        dmh_client_scope = service_history_enrollments_source.
          hud_currently_homeless(date: @date, chronic_types_only: true).
          where(client_id: client_id).
          where(dmh_projects_filter).
          service_within_date_range(start_date: @date - 3.years, end_date: @date)
        if homeless_reset(client_id: client_id)
          debug_log "Found previous residential history, using #{homeless_reset(client_id: client_id)} instead of #{@date - 3.years} as beginning of calculation"
          dmh_client_scope = dmh_client_scope.where(date: homeless_reset(client_id: client_id)..@date)
        end
        dmh_days_homeless = dmh_client_scope.pluck(shs_t[:date].as('date').to_sql).
          uniq.
          count
          debug_log "Found #{dmh_days_homeless} DMH homeless days"
        mainstream_days_homeless = service_history_enrollments_source.
          hud_homeless(chronic_types_only: true).
          joins(:service_history_services, :project).
          where(client_id: client_id).
          where.not(dmh_projects_filter).
          pluck(shs_t[:date].as('date').to_sql).
          uniq.
          count
        if dmh_days_homeless > 0 && dmh_days_homeless + mainstream_days_homeless >= 365 && mainstream_days_homeless >= 90
          adjusted_homeless_dates_served = residential_history_for_client(client_id: client_id)
          @chronic_trigger = "#{dmh_days_homeless + mainstream_days_homeless} days total #{mainstream_days_homeless} of which were mainstream, DMH client"
          homeless_months = adjusted_months_served(dates: adjusted_homeless_dates_served)
          debug_log "Found #{homeless_months.size} homeless months"
          debug_log "Chronic Triggers: "
          debug_log @chronic_trigger.inspect
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
      end
      logger.info "Found #{@chronically_homeless.size} DMH chronically homeless clients"
      if @dry_run
        logger.info @client_details.inspect
      else
        chronic_source.transaction do
          chronic_source.where(date: @date, dmh: true).delete_all
          if @client_details.present?
            insert_batch(chronic_source, @client_details.values.first.keys, @client_details.values.map(&:values))
          end
        end
        logger.info 'Done updating status of chronically homeless clients'
      end
      logger.info 'Completed chronic calculations'
    end
  end
end
