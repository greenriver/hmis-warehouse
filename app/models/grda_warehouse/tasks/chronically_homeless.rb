###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# Figure out who is chronically homeless
# Our working definition of chronic homelessness is:
# 1. Currently Homeless in ES (1), SH (8) or SO (4) and not currently housed (other residential types)
# 2. Disabled
# 3. Homeless in 12 of the last 36 months.
#
# Official Definition:
#
# A ‘‘chronically homeless’’ individual is defined to mean a homeless individual with a disability who lives either in a place not meant for human habitation, a safe haven, or in an emergency shelter, or in an institutional care facility if the individual has been living in the facility for fewer than 90 days and had been living in a place not meant for human habitation, a safe haven, or in an emergency shelter immediately before entering the institutional care facility. In order to meet the ‘‘chronically homeless’’ definition, the individual also must have been living as described above continuously for at least 12 months, or on at least 4 separate occasions in the last 3 years, where the combined occasions total a length of time of at least 12 months. Each period separating the occasions must include at least 7 nights of living in a situation other than a place not meant for human habitation, in an emergency shelter, or in a safe haven.
#
# Some notes:
# 1. Anyone homeless in all of the last 12 months is chronic
# 2. If you are homeless 12 or more months in the last 36 months, you also need to have had at least three episodes, this means that if you were homeless for the last 10 months, had 2 months housed and then the prior 24 months were homeless, you are still not chronic.
# 3. Ignore anyone currently enrolled in a DMH project, we'll catch them in the DMH chronic calculator
#
# Something like this is very helpful for debugging:
# ch = GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: '2017-06-01'.to_date, dry_run: true, client_ids: [123456,123457], debug: true);

module GrdaWarehouse::Tasks
  class ChronicallyHomeless
    include TsqlImport
    include ArelHelper
    CHRONIC_PROJECT_TYPES = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    SO = 4

    attr_accessor :logger, :debug

    # Pass client_ids as an array
    def initialize(
      date: Date.current,
      count_so_as_full_month: true,
      dry_run: false,
      client_ids: nil,
      debug: false,
      sanity_check: false
    )
      self.logger = Rails.logger
      @date = date
      @hard_stop = @date.beginning_of_month
      @count_so_as_full_month = GrdaWarehouse::Config.get(:so_day_as_month)
      @dry_run = dry_run
      @clients = client_ids
      @limited = client_ids.present? && client_ids.any?
      @sanity_check = sanity_check
      @debug = debug
    end

    def run!
      logger.info "====DRY RUN====" if @dry_run
      logger.info "Updating status of chronically homeless clients on #{@date}"
      load_active_clients()
      logger.info "====Using supplied client ids====" if @limited
      logger.info "Found #{@clients.size} clients who are homeless on #{@date}"
      @chronically_homeless = []
      @client_details = {}
      extra_work = 0
      @clients.each_with_index do |client_id, index|
        debug_log "Calculating chronicity for #{client_id}"
        # All chronically homeless must also be disabled
        next unless disabled?(client_id)
        # remove any cached calculations from the previous client
        reset_for_batch()
        adjusted_homeless_dates_served = residential_history_for_client(client_id: client_id)
        homeless_months = adjusted_months_served(dates: adjusted_homeless_dates_served)
        homeless_months_size = if homeless_months.size > 36 then 36 else homeless_months.size end
        # debug_log homeless_months.inspect
        debug_log "Found #{homeless_months.size} homeless months"
        if homeless_months.size >= 12
          disabled = disabled?(client_id)
          debug_log "Client disabled? #{disabled.inspect}"
          if disabled
            # load the client.  This is expensive, but we need some related data
            # that's not easy to do without calculations
            client = GrdaWarehouse::Hud::Client.find(client_id)
            # If we've been homeless in all of the last 12 months, we're chronic
            if homeless_in_all_last_12_months?(months: homeless_months)
              @chronically_homeless << client_id
              @chronic_trigger = "All previous 12 months, #{homeless_months.size} in last 36"
              @chronic = true
            else
              # If we've been homeless for 12 of 36 months, we need to see if we've had 4 episodes in that time
              #   Get any enrollments for the client in the last 36 months and then count new episodes
              episodes = client.homeless_episodes_between(start_date: (@date - 3.years), end_date: @date)
              debug_log "Episodes: #{episodes.inspect}"
              if episodes > 3
                @chronically_homeless << client_id
                @chronic_trigger = "#{homeless_months.size} of last 36 months in #{episodes} episodes"
                @chronic = true
              end
            end
            if @chronic
              debug_log "Chronic Triggers: "
              debug_log @chronic_trigger.inspect
              # Add details for any chronically homeless client
              add_client_details(client: client, days_served: adjusted_homeless_dates_served, months_homeless: homeless_months.size, chronic_trigger: @chronic_trigger)
            end
          end
        end
      end
      logger.info "Found #{@chronically_homeless.size} chronically homeless clients"
      if @dry_run
        logger.info @client_details.inspect
      else
        chronic_source.transaction do
          chronic_source.where(date: @date, dmh: false).delete_all
          insert_batch chronic_source, @client_details.values.first.keys, @client_details.values.map(&:values) if @client_details.present?
        end
        logger.info 'Done updating status of chronically homeless clients'
      end
      logger.info 'Completed chronic calculations'
    end

    def reset_for_batch
      @chronic = false
      @chronic_trigger = 'Unknown reason'
      @entry_dates_by_project_type = nil
      @entry_dates = nil
      @residential_dates = nil
      @homeless_dates = nil
      @project_names = []
      @homeless_reset = nil
    end

    def load_active_clients
      @clients = active_client_scope unless @limited
      # before we return, sanity check these clients, then load them again if
      # any don't pass
      if @sanity_check
        if GrdaWarehouse::Tasks::SanityCheckServiceHistory.new(client_ids: @clients).run!
          @clients = active_client_scope unless @limited
        end
      end
    end

    def active_client_scope
      service_history_enrollments_source.
      hud_currently_homeless(date: @date, chronic_types_only: true).
      where.not(client_id: dmh_clients).
      joins(:processed_client).
      select(:client_id).
      distinct.
      pluck(:client_id)
    end

    def add_client_details(client:, days_served:, months_homeless:, chronic_trigger:, dmh: false)
      @client_details[client.id] ||= {}
      @client_details[client.id][:date] = @date
      @client_details[client.id][:client_id] = client.id
      @client_details[client.id][:days_in_last_three_years] = days_served.length
      @client_details[client.id][:age] = client.age_on(@date)
      @client_details[client.id][:individual] = GrdaWarehouse::Hud::Client.where(id: client.id).homeless_individual(on_date: @date, chronic_types_only: true).exists?

      @client_details[client.id][:homeless_since] = client.date_of_first_service
      @client_details[client.id][:months_in_last_three_years] = months_homeless
      @client_details[client.id][:trigger] = chronic_trigger
      @client_details[client.id][:dmh] = dmh
      @client_details[client.id][:project_names] = @project_names.join('|')
    end

    # the end of the most recent 90+ day residential, non-homeless enrollment
    # that is open within the range
    # NOTE, if the non-homeless enrollment is PH, it must also have a move-in date
    def homeless_reset(client_id:)
      @homeless_reset ||= service_history_enrollments_source.hud_residential_non_homeless.
        open_between(start_date: @date - 3.years, end_date: @date).
        where(
          she_t[:move_in_date].not_eq(nil).and(
            she_t[:computed_project_type].in(
              GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
            )
          ).or(
            she_t[:computed_project_type].in(
              GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th]
            )
          )
        ).
        where(she_t[:last_date_in_program].lteq(@date)).
        where( datediff( service_history_enrollments_source, 'day', she_t[:last_date_in_program], she_t[:first_date_in_program] ).gteq(90)).
        where(client_id: client_id).
        maximum(:last_date_in_program)
    end

    # Fetch the history for a client over the past three years
    # First check to see if any of that includes a 90+ day non-homeless residential
    # project stay.  If there is, limit the full request to only the days after the stay
    def residential_history_for_client(client_id:)
      debug_log "calculating residential history"
      # Just load up the histories for the current client, loading all takes too much RAM
      scope = service_history_enrollments_source.hud_homeless(chronic_types_only: true).
        joins(:service_history_services).
        service_within_date_range(start_date: @date - 3.years, end_date: @date).
        where(client_id: client_id)
      if homeless_reset(client_id: client_id).present?
        debug_log "Found previous residential history, using #{homeless_reset(client_id: client_id)} instead of #{@date - 3.years} as beginning of calculation"
        scope = scope.where(shs_t[:date].between(homeless_reset(client_id: client_id)..@date))
      end
      all_dates = scope.joins(:project, project: [:organization]).pluck(*service_history_columns.values).map do |row|
        h = service_history_columns.keys.zip(row).to_h
        h[:project_name] = GrdaWarehouse::Hud::Project.confidential_project_name if h[:confidential]
        h.except!(:confidential)
      end
      # Throw out any dates that fall outside of the enrollment
      # Unless this is SO and we allow them
      all_dates.reject! do |m|
        m[:last_date_in_program].present? && m[:last_date_in_program] < m[:date] && ! count_so_as_full_month?(m)
      end
      debug_log "Found #{all_dates.size} days in the residential history"

      # group by enrollment and then calculated adjusted dates for each enrollment
      enrollments_by_project_entry = all_dates.group_by do |m|
        [m[:enrollment_group_id], m[:project_id], m[:data_source_id]]
      end
      all_homeless_dates = Set.new

      @project_names = enrollments_by_project_entry.map do |_, e|
        e.map do |enrollment|
          days_for_project = all_dates.select{|d| d[:project_name] == enrollment[:project_name]}.size
          project_type_id = ::HUD.project_type_brief(enrollment[:project_type])
          "#{project_type_id}: #{enrollment[:project_name]} (#{days_for_project})"
        end
      end.flatten.uniq

      enrollments_by_project_entry.map do |_, e|
        e.sort_by!{|m| m[:date]}
        meta = e.first
        dates_served = e.map{|m| m[:date]}.uniq

        # days that are not also served by a later enrollment of the same project type
        # unless this is a bed-night style project, in which case we count all nights
        count_until = if bed_night?(meta)
          meta[:last_date_in_program]
        else
          next_enrollment(enrollments: all_dates, type: meta[:project_type], start: meta[:first_date_in_program]).try(:[], :first_date_in_program) || meta[:last_date_in_program]
        end
        # days included in adjusted days that are not also served by a residential project
        # If the project uses bed-night tracking, just count them all
        # otherwise ignore overlapping dates (this allows for overlapping SO from two sources)
        # We de-dupe dates later, none will be double counted
        if count_all_dates?(meta)
          adj_dates = adjusted_dates(dates: dates_served, stop_date: @hard_stop)
          debug_log "Adding #{adj_dates.count} days from: #{meta[:project_name]}, entry: #{meta[:first_date_in_program]}, until: #{count_until}"
          all_homeless_dates += adj_dates
        else
          adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
          homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: all_dates)
          all_homeless_dates += homeless_dates_for_enrollment
        end
      end
      # debug_log all_homeless_dates.sort.inspect
      debug_log "Counting #{all_homeless_dates.size} homeless days"
      all_homeless_dates

    end

    def debug_log string
      logger.info string if debug
    end

    def count_all_dates?(meta)
      bed_night?(meta) || count_so_as_full_month?(meta)
    end

    def bed_night?(meta)
      meta[:project_tracking_method] == 3
    end

    def count_so_as_full_month?(meta)
      so?(meta) && @count_so_as_full_month
    end

    def so?(meta)
      meta[:project_type] == SO
    end

    def next_enrollment enrollments:, type:, start:
      entry_dates = entry_dates(enrollments: enrollments)
      entry_dates_for_type(entry_dates: entry_dates, type: type).reverse.find do |m|
        m[:first_date_in_program] > start
      end
    end

    def entry_dates_for_type entry_dates:, type:
      @entry_dates_by_project_type ||= entry_dates.group_by do |e|
        e[:project_type]
      end
      @entry_dates_by_project_type[type]
    end

    def entry_dates enrollments:
      @entry_dates ||= enrollments.map do |e|
        {
          enrollment_group_id: e[:enrollment_group_id],
          first_date_in_program: e[:first_date_in_program],
          last_date_in_program: e[:last_date_in_program],
          project_type: e[:project_type],
          data_source_id: e[:data_source_id],
        }
      end.uniq
    end

    # count dates up to the end of the previous month
    # We're always going back 3 years, and don't want to count the current month
    # until we have complete data for it
    def adjusted_dates dates:, stop_date:
      return dates.select{|date| date < @hard_stop} if stop_date.nil?
      dates.select{|date| date < stop_date}
    end

    # days served in PH *after* the move-in-date
    def residential_dates enrollments:
      @non_homeless_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      @residential_dates ||= enrollments.select do |e|
        e[:project_type].in? @non_homeless_types
      end.map do |e|
        e[:date] if e[:move_in_date].present? && e[:move_in_date] < e[:date]
     end.compact.uniq
    end

    def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e|
        e[:project_type].in? project_source::CHRONIC_PROJECT_TYPES
      end.map do |e|
       e[:date]
      end.compact.uniq
    end

    def adjusted_months_served dates:
      dates.group_by{ |d| d.to_time.strftime("%Y-%m") }.keys.to_set.sort
    end

    def homeless_in_all_last_12_months? months:
      @last_12_months ||= begin
        last_12_months = Set.new
        (1..12).each do |i|
          last_12_months << (@date.to_date - i.months).to_time.strftime("%Y-%m")
        end
        last_12_months
      end
      (@last_12_months - months).blank?
    end

    def disabled?(client_id)
      @disabled_clients ||= GrdaWarehouse::Hud::Client.where(id: @clients).chronically_disabled.pluck(:id)
      @disabled_clients.include? client_id
    end

    def client_sources
      @client_sources ||= {}.tap do |m|
        GrdaWarehouse::WarehouseClient.all.pluck(:destination_id, :source_id).each do |row|
          m[row.first] ||= []
          m[row.first] << row.last
        end
      end
    end

    def dmh_projects_filter
      filter = project_source.chronic.
        joins(:organization).merge(GrdaWarehouse::Hud::Organization.dmh).
        pluck(:ProjectID, :data_source_id).
        map do |project_id, data_source_id|
          she_t[:project_id].eq(project_id).and(she_t[:data_source_id].eq(data_source_id)).to_sql
      end.join(' or ')
      filter = "0=1" if filter.blank?
      return filter
    end

    def dmh_clients
      service_history_enrollments_source.
        ongoing(on_date: @date).
        where(dmh_projects_filter).
        joins(:processed_client).
        select(:client_id).
        distinct
    end

    def service_history_columns
      @service_history_columns ||= {
        client_id: :client_id,
        date: shs_t[:date].as('date').to_sql,
        first_date_in_program: :first_date_in_program,
        last_date_in_program: :last_date_in_program,
        enrollment_group_id: :enrollment_group_id,
        project_type: service_history_enrollments_source.project_type_column,
        project_id: :project_id,
        project_tracking_method: :project_tracking_method,
        project_name: :project_name,
        move_in_date: :move_in_date,
        confidential: bool_or(p_t[:confidential], o_t[:confidential]),
      }
    end

    def service_history_enrollments_source
      GrdaWarehouse::ServiceHistoryEnrollment
    end

    def service_history_services_source
      GrdaWarehouse::ServiceHistoryServices
    end

    def project_source
      GrdaWarehouse::Hud::Project
    end

    def chronic_source
      GrdaWarehouse::Chronic
    end

  end
end
