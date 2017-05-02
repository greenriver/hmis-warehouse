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

module GrdaWarehouse::Tasks
  require 'ruby-progressbar'
  class ChronicallyHomeless
    include TsqlImport
    include ArelHelper
    CHRONIC_PROJECT_TYPES = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
    DMH_SITE = 38

    def initialize(date: Date.today)
      @progress_format = '%a: '
      @progress = ProgressBar.create(starting_at: 0, total: nil, format: @progress_format)
      @pb_output_for_log = ProgressBar::Outputs::NonTty.new(bar: @progress)
      @date = date
    end

    def run!
      Rails.logger.info "Updating status of chronically homeless clients on #{@date}"
      load_active_clients()
      Rails.logger.info "Found #{@clients.size} clients who are homeless on #{@date}"
      @chronically_homeless = []
      @client_details = {}
      extra_work = 0
      @clients.each_with_index do |client_id, index|
        # remove any cached calculations from the previous client
        reset_for_batch()
        adjusted_homeless_dates_served = residential_history_for_client(client_id: client_id)
        homeless_months = adjusted_months_served(dates: adjusted_homeless_dates_served)
        if disabled?(client_id) && homeless_months.size >= 12
          # load the client.  This is expensive, but we need some related data
          # that's not easy to do without calculations
          client = GrdaWarehouse::Hud::Client.find(client_id)
          # If we've been homless in all of the last 12 months, we're chronic
          if homeless_in_all_last_12_months?(months: homeless_months)
            @chronically_homeless << client_id
            @chronic_trigger = "All previous 12 months, #{homeless_months.size} in last 36"
            @chronic = true
          else
            # If we've been homeless for 12 of 36 months, we need to see if we've had 4 episodes in that time
            #   Get any enrollments for the client in the last 36 months and then count new episodes
            episodes = client.homeless_episodes_between(start_date: (@date - 3.years), end_date: @date)
            if episodes > 3
              @chronically_homeless << client_id
              @chronic_trigger = "#{homeless_months.size} of last 36 months in #{episodes} episodes"
              @chronic = true
            end
          end
          if @chronic
            # Add details for any chronically homeless client
            add_client_details(client: client, days_served: adjusted_homeless_dates_served, months_homeless: homeless_months.size, chronic_trigger: @chronic_trigger)
          end
        end
        @progress.format = "#{@progress_format}Found chronically homeless: #{@chronically_homeless.size} processed #{index}/#{@clients.size} date: #{@date}"
      end
      Rails.logger.info "Found #{@chronically_homeless.size} chronically homeless clients"
      
      GrdaWarehouse::Chronic.transaction do
        GrdaWarehouse::Chronic.where(date: @date, dmh: false).delete_all
        insert_batch GrdaWarehouse::Chronic, @client_details.values.first.keys, @client_details.values.map(&:values)
      end
      Rails.logger.info 'Done updating status of chronically homeless clients'
    end

    def reset_for_batch
      @chronic = false
      @chronic_trigger = 'Unknown reason'
      @entry_dates_by_project_type = nil
      @entry_dates = nil
      @residential_dates = nil
      @homeless_dates = nil
    end

    def load_active_clients
      @clients ||= GrdaWarehouse::ServiceHistory.
        currently_homeless(date: @date).
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
      @client_details[client.id][:individual] = ! client.presented_with_family?(after: @date - 3.years, before: @date)
      @client_details[client.id][:homeless_since] = client.processed_service_history.try(:first_date_served)
      @client_details[client.id][:months_in_last_three_years] = months_homeless
      @client_details[client.id][:trigger] = chronic_trigger
      @client_details[client.id][:dmh] = dmh

    end

    # Fetch the history for a client over the past three years
    # First check to see if any of that includes a 90+ day non-homeless residential
    # project stay.  If there is, limit the full request to only the days after the stay
    def residential_history_for_client(client_id:)
      services = GrdaWarehouse::ServiceHistory
      st = services.arel_table
      homeless_reset = services.residential.
          entry_within_date_range(start_date: @date - 3.years, end_date: @date).
          where(project_type:  RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE).
          where.not(last_date_in_program: nil).
          where( datediff( services, 'day', st[:first_date_in_program], st[:last_date_in_program] ).gteq 90 ).
          where(client_id: client_id).
          maximum(:last_date_in_program)
      # Just load up the histories for the current client, loading all takes too much RAM
      cols = service_history_columns
      scope = GrdaWarehouse::ServiceHistory.residential.
        service_within_date_range(start_date: @date - 3.years, end_date: @date).
        where(client_id: client_id)
      if homeless_reset.present?
        scope = scope.where(date: homeless_reset..@date)
      end 
      all_dates = scope.pluck(*cols).map do |row|
        cols.zip(row).to_h
      end
      # group by enrollment and then calculated adjusted dates for each enrollment
      enrollments_by_project_entry = all_dates.group_by do |m|
        [m[:enrollment_group_id], m[:project_id], m[:data_source_id]]
      end
      all_homeless_dates = Set.new
      enrollments_by_project_entry.map do |_, e|
        e.sort_by!{|m| m[:date]}
        meta = e.first
        dates_served = e.map{|m| m[:date]}.uniq
        # days that are not also served by a later enrollment of the same project type
        # unless this is a bed-night style project, in which case we count all nights
        count_until = if meta[:project_tracking_method] == 3
          meta[:last_date_in_program]
        else
          next_enrollment(enrollments: all_dates, type: meta[:project_type], start: meta[:first_date_in_program]).try(:[], :first_date_in_program) || meta[:last_date_in_program]
        end
        # days included in adjusted days that are not also served by a residential project 
        adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
        homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: all_dates)
        all_homeless_dates += homeless_dates_for_enrollment
      end
      all_homeless_dates
      
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

    def adjusted_dates dates:, stop_date:
      return dates if stop_date.nil?
      dates.select{|date| date < stop_date}
    end

    def residential_dates enrollments:
      @non_homeless_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      @residential_dates ||= enrollments.select do |e| 
        e[:project_type].in? @non_homeless_types
      end.map do |e|
       e[:date]
     end.compact.uniq
    end

    def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e| 
        e[:project_type].in? GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
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
        12.times do |i| 
          last_12_months << (@date.to_date - i.months).to_time.strftime("%Y-%m")
        end
        last_12_months
      end      
      (@last_12_months - months).blank?
    end

    # count months for which we had at least one day of service in a homeless project type
    # that doesn't overlap other non-homeless residential project types 
    # def months_homeless(client_id, client_service_history)
    #   months = Set[]
    #   client_service_history.group_by{|s| s[:date]}.each do |date, services|
    #     homeless = false
    #     other = false
    #     services.each do |service|
    #       homeless = CHRONIC_PROJECT_TYPES.include?(service[:project_type])
    #       other = RESIDENTIAL_NON_HOMELESS_PROJECT_TYPE.include?(service[:project_type])
    #       break if other 
    #     end
    #     if homeless && ! other
    #       months << date.to_time.strftime("%Y-%m")
    #     end
    #   end
    #   return months
    # end

    def disabled?(client_id)
      candidates = client_sources[client_id] || []
      candidates << client_id
      dt = GrdaWarehouse::Hud::Disability.arel_table
      @disabled_clients ||= GrdaWarehouse::Hud::Client.joins(:disabilities)
        .where( dt[:DisabilityResponse].in [1, 2, 3] )
        .distinct
        .pluck(:id).to_set
      candidates.any?{ |id| @disabled_clients.include? id }
    end

    def client_sources
      @client_sources ||= {}.tap do |m|
        GrdaWarehouse::WarehouseClient.where(source_id: GrdaWarehouse::WarehouseClient.select(:source_id)).pluck(:destination_id, :source_id).each do |row|
          m[row.first] ||= []
          m[row.first] << row.last
        end
      end
    end

    def dmh_projects_filter 
      GrdaWarehouse::Hud::Project.
        where(OrganizationID: DMH_SITE).
        pluck(:ProjectID, :data_source_id).
        map do |project_id, data_source_id|
          "(project_id = '#{project_id}' and data_source_id = #{data_source_id})"
      end.join(' or ')
    end

    def dmh_clients
      GrdaWarehouse::ServiceHistory.
        ongoing(on_date: @date).
        where(dmh_projects_filter).
        joins(:processed_client).
        select(:client_id).
        distinct
    end

    def service_history_columns
      [
        :client_id,
        :date,
        :first_date_in_program,
        :last_date_in_program,
        :enrollment_group_id,
        :project_type,
        :project_id,
        :project_tracking_method,
      ]
    end
  end
end