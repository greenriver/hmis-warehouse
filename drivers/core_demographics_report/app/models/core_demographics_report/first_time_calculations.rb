###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::FirstTimeCalculations
  extend ActiveSupport::Concern
  included do
    def no_recent_homelessness_detail_hash
      {}.tap do |hashes|
        available_no_recent_homelessness_types.invert.each do |key, title|
          hashes["no_recent_homelessness_#{key}"] = {
            title: "No Recent Homelessness - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: no_recent_homelessness_client_ids(key)).distinct },
          }
        end
      end
    end

    def no_recent_homelessness_count(type)
      no_recent_homelessness_clients[type]&.count&.presence || 0
    end

    def no_recent_homelessness_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = no_recent_homelessness_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def no_recent_homelessness_data_for_export(rows)
      rows['_No Recent Homelessness Type'] ||= []
      rows['*No Recent Homelessness Type'] ||= []
      rows['*No Recent Homelessness Type'] += ['No Recent Homelessness Type', nil, 'Count', 'Percentage', nil]
      available_no_recent_homelessness_types.invert.each do |id, title|
        rows["_No Recent Homelessness Type_data_#{title}"] ||= []
        rows["_No Recent Homelessness Type_data_#{title}"] += [
          title,
          nil,
          no_recent_homelessness_count(id),
          no_recent_homelessness_percentage(id) / 100,
        ]
      end
      rows
    end

    private def no_recent_homelessness_client_ids(key)
      no_recent_homelessness_clients[key]
    end

    def available_no_recent_homelessness_types
      {
        'Client' => :client,
        'Household' => :household,
        'Clients in Adult and Child Households' => :adult_and_child,
        'Adult and Child Households' => :hoh_adult_and_child,
        'Unaccompanied Youth (18-24)' => :unaccompanied_youth,
        'Chronically Homeless Clients' => :chronic,
        'Chronically Homeless Households' => :hoh_chronic,
        'Clients with High Acuity' => :high_acuity,
        'Households with High Acuity' => :hoh_high_acuity,
      }
    end

    # inactivity period (default is 24 months).
    private def client_ids_with_prior_homelessness
      @client_ids_with_prior_homelessness ||= begin
        project_types = HudUtility.homeless_project_type_numbers & filter.project_type_numbers
        # Use month duration to handle leap years
        inactivity_duration = filter.inactivity_days > 90 ? filter.inactivity_days.days.in_months.round.months : filter.inactivity_days.days
        # NOTE: this is limited to the report universe, except for the date range
        scope = report_scope(include_date_range: false).
          open_between(start_date: filter.start_date - inactivity_duration, end_date: filter.start_date - 1.day).
          with_service_between(start_date: filter.start_date - inactivity_duration, end_date: filter.start_date - 1.day).
          in_project_type(project_types)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def hoh_client_ids
      @hoh_client_ids ||= hoh_scope.pluck(:client_id)
    end

    private def no_recent_homelessness_clients
      @no_recent_homelessness_clients ||= Rails.cache.fetch(no_recent_homelessness_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          # Get ids once from other calculations
          adult_and_child_ids = enrollment_ids_in_household_type(:with_children)
          hoh_adult_and_child_ids = hoh_enrollment_ids_in_household_type(:with_children)
          unaccompanied_youth_ids = enrollment_ids_in_household_type(:unaccompanied_youth)
          chronic_ids = chronic_client_ids(:client)
          hoh_chronic_ids = chronic_client_ids(:household)
          high_acuity_ids = high_acuity_client_ids(:client)
          hoh_high_acuity_ids = high_acuity_client_ids(:household)

          # Setup sets to hold client ids with no recent homelessness
          clients[:client] = Set.new
          clients[:household] = Set.new
          clients[:adult_and_child] = Set.new
          clients[:hoh_adult_and_child] = Set.new
          clients[:unaccompanied_youth] = Set.new
          clients[:chronic] = Set.new
          clients[:hoh_chronic] = Set.new
          clients[:high_acuity] = Set.new
          clients[:hoh_high_acuity] = Set.new

          # Clients with an entry into the chosen universe occuring within the report range
          report_scope.distinct.
            entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :id, :first_date_in_program).
            each do |client_id, enrollment_id, _|
              next if client_ids_with_prior_homelessness.include?(client_id)

              # Always add them to the clients category
              clients[:client] << client_id
              clients[:household] << client_id if hoh_client_ids.include?(enrollment_id)
              clients[:adult_and_child] << client_id if adult_and_child_ids.include?(enrollment_id)
              clients[:hoh_adult_and_child] << client_id if hoh_adult_and_child_ids.include?(enrollment_id)
              clients[:unaccompanied_youth] << client_id if unaccompanied_youth_ids.include?(enrollment_id)
              clients[:chronic] << client_id if chronic_ids.include?(client_id)
              clients[:hoh_chronic] << client_id if hoh_chronic_ids.include?(client_id)
              clients[:high_acuity] << client_id if high_acuity_ids.include?(client_id)
              clients[:hoh_high_acuity] << client_id if hoh_high_acuity_ids.include?(client_id)
            end
        end
      end
    end

    private def no_recent_homelessness_cache_key
      [self.class.name, cache_slug, 'no_recent_homelessness_clients']
    end
  end
end
