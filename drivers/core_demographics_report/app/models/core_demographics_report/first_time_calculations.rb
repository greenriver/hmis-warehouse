###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
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
          # These need to use enrollment.id to capture age correctly
          id_field = if key.to_sym.in?([:with_children, :with_children, :unaccompanied_youth])
            :id
          else
            :client_id
          end

          hashes["no_recent_homelessness_#{key}"] = {
            title: "No Recent Homelessness - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(id_field => no_recent_homelessness_client_ids(key)).distinct },
          }
        end
      end
    end

    def no_recent_homelessness_count(type, coc_code = base_count_sym)
      mask_small_population(no_recent_homelessness_client_ids(type, coc_code)&.count&.presence || 0)
    end

    def no_recent_homelessness_percentage(type, coc_code = base_count_sym)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = no_recent_homelessness_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def no_recent_homelessness_data_for_export(rows)
      rows['_Newly Entering Homelessness'] ||= []
      rows['*Newly Entering Homelessness'] ||= []
      rows['*Newly Entering Homelessness'] += ['Newly Entering Homelessness', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Newly Entering Homelessness'] += ["#{coc_code} Client"]
        rows['*Newly Entering Homelessness'] += ["#{coc_code} Client"]
      end
      rows['*Newly Entering Homelessness'] += [nil]
      available_no_recent_homelessness_types.invert.each do |id, title|
        rows["_Newly Entering Homelessness_data_#{title}"] ||= []
        rows["_Newly Entering Homelessness_data_#{title}"] += [
          title,
          nil,
          no_recent_homelessness_count(id),
          no_recent_homelessness_percentage(id) / 100,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          rows["_Newly Entering Homelessness_data_#{title}"] += [
            no_recent_homelessness_count(id, coc_code.to_sym),
            no_recent_homelessness_percentage(id, coc_code.to_sym) / 100,
          ]
        end
      end
      rows
    end

    private def no_recent_homelessness_client_ids(key, coc_code = base_count_sym)
      # These are stored as Set[[enrollment_id, client_id]]
      if key.in?([:adult_and_child, :hoh_adult_and_child, :unaccompanied_youth])
        no_recent_homelessness_clients[key][coc_code].to_a.map(&:last).uniq
      else
        # fetch client_ids from [client_id]
        no_recent_homelessness_clients[key][coc_code]
      end
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
        # This report uses `filter.project_type_codes` `filter.project_type_ids` will convert those to the number equivalents
        project_types = HudUtility2024.homeless_project_type_numbers & filter.project_type_ids
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

    private def adult_and_child_ids
      @adult_and_child_ids ||= enrollment_ids_in_household_type(:with_children)
    end

    private def hoh_adult_and_child_ids
      @hoh_adult_and_child_ids ||= hoh_enrollment_ids_in_household_type(:with_children)
    end

    private def unaccompanied_youth_ids
      @unaccompanied_youth_ids ||= enrollment_ids_in_household_type(:unaccompanied_youth)
    end

    private def chronic_ids
      @chronic_ids ||= chronic_client_ids(:client)
    end

    private def hoh_chronic_ids
      @hoh_chronic_ids ||= chronic_client_ids(:household)
    end

    private def high_acuity_ids
      @high_acuity_ids ||= high_acuity_client_ids(:client)
    end

    private def hoh_high_acuity_ids
      @hoh_high_acuity_ids ||= high_acuity_client_ids(:household)
    end

    private def initialize_recently_homeless_client_counts(clients, coc_code = base_count_sym)
      available_no_recent_homelessness_types.invert.each do |id, _|
        clients[id][coc_code] = Set.new
      end
    end

    private def set_recently_homeless_client_counts(clients, client_id, enrollment_id, coc_code = base_count_sym)
      # Only count them in one category.
      if !clients[:client][coc_code].include?(client_id)
        clients[:chronic][coc_code] << client_id if chronic_ids.include?(client_id)
        clients[:hoh_chronic][coc_code] << client_id if hoh_chronic_ids.include?(client_id)
        clients[:high_acuity][coc_code] << client_id if high_acuity_ids.include?(client_id)
        clients[:hoh_high_acuity][coc_code] << client_id if hoh_high_acuity_ids.include?(client_id)
        # These need to use enrollment.id to capture age correctly, but needs the client for summary counts
        clients[:adult_and_child][coc_code] << [enrollment_id, client_id] if adult_and_child_ids.include?(enrollment_id)
        clients[:hoh_adult_and_child][coc_code] << [enrollment_id, client_id] if hoh_adult_and_child_ids.include?(enrollment_id)
        clients[:unaccompanied_youth][coc_code] << [enrollment_id, client_id] if unaccompanied_youth_ids.include?(enrollment_id)
      end
      # Always add them to the clients category
      clients[:client][coc_code] << client_id
      clients[:household][coc_code] << client_id if hoh_client_ids.include?(client_id)
    end

    private def no_recent_homelessness_clients
      @no_recent_homelessness_clients ||= Rails.cache.fetch(no_recent_homelessness_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          # Setup sets to hold client ids with no recent homelessness
          available_no_recent_homelessness_types.invert.each do |id, _|
            clients[id] = {}
          end

          initialize_recently_homeless_client_counts(clients)

          # Clients with an entry into the chosen universe occuring within the report range
          report_scope.distinct.
            entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :id, :first_date_in_program).
            each do |client_id, enrollment_id, _|
              next if client_ids_with_prior_homelessness.include?(client_id)

              set_recently_homeless_client_counts(clients, client_id, enrollment_id)
            end

          available_coc_codes.each do |coc_code|
            initialize_recently_homeless_client_counts(clients, coc_code.to_sym)

            report_scope.distinct.in_coc(coc_code: coc_code).
              entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
              order(first_date_in_program: :desc).
              pluck(:client_id, :id, :first_date_in_program).
              each do |client_id, enrollment_id, _|
                next if client_ids_with_prior_homelessness.include?(client_id)

                set_recently_homeless_client_counts(clients, client_id, enrollment_id, coc_code.to_sym)
              end
          end
        end
      end
    end

    private def no_recent_homelessness_cache_key
      [self.class.name, cache_slug, 'no_recent_homelessness_clients']
    end
  end
end
