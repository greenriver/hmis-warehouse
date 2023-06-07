###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module
  CoreDemographicsReport::OutcomeCalculations
  extend ActiveSupport::Concern
  included do
    def outcome_detail_hash
      {}.tap do |hashes|
        available_outcome_types.invert.each do |key, title|
          hashes["outcome_#{key}"] = {
            title: "Outcome - #{title}",
            headers: client_headers,
            columns: client_columns,
            scope: -> { report_scope.joins(:client, :enrollment).where(client_id: outcome_client_ids(key)).distinct },
          }
        end
      end
    end

    def outcome_count(type)
      # Return average days
      if type.to_s == 'average_los'
        values = outcome_clients[type.to_sym].map(&:last)
        return 0 unless values.count.positive?

        (values.sum.to_f / values.count).round
      end

      outcome_clients[type]&.count&.presence || 0
    end

    def outcome_percentage(type)
      total_count = total_client_count
      return 0 if total_count.zero?

      of_type = outcome_count(type)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def outcome_data_for_export(rows)
      rows['_Outcome Type'] ||= []
      rows['*Outcome Type'] ||= []
      rows['*Outcome Type'] += ['Outcome Type', 'Count', 'Percentage', nil, nil]
      @filter.available_outcome_types.invert.each do |id, title|
        rows["_Outcome Type_data_#{title}"] ||= []
        rows["_Outcome Type_data_#{title}"] += [
          title,
          outcome_count(id),
          outcome_percentage(id) / 100,
          nil,
        ]
      end
      rows
    end

    private def outcome_client_ids(type)
      return outcome_clients[type].map(&:first) if type.to_s == 'average_los'

      outcome_clients[type]
    end

    def available_outcome_types
      {
        'Average Length of Stay in Homeless System' => :average_los,
        'Exits to Homeless Situations' => :exit_homeless,
        'Exits to Institutional Situations' => :exit_institutional,
        'Exits to Temporary Situations' => :exit_temporary,
        'Exits to Permanent Situations' => :exit_permanent,
        'Exits to Other Situations' => :exit_other,
        # These return calculations are kinda wonky
        # NOTE: no homeless enrollment in year prior to the report range, but had one between 2 years and 1 year
        'Returns to Homelessness after 1-2 years' => :returns_1_2_years,
        # NOTE: no homeless enrollment in 30 days prior to the report range, but had one in the prior year
        'Returns to Homelessness after < 1 year' => :returns_1_years,
      }
    end

    private def client_ids_with_homeless_activity_1_months
      @client_ids_with_homeless_activity_1_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range
        scope = report_scope(include_date_range: false).
          open_between(start_date: filter.start_date - 1.months, end_date: filter.start_date - 1.days).
          with_service_between(start_date: filter.start_date - 1.months, end_date: filter.start_date - 1.days).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_1_12_months
      @client_ids_with_homeless_activity_1_12_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range
        scope = report_scope(include_date_range: false).
          open_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.months).
          with_service_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.months).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_0_12_months
      @client_ids_with_homeless_activity_0_12_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range
        scope = report_scope(include_date_range: false).
          open_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.days).
          with_service_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.days).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_12_24_months
      @client_ids_with_homeless_activity_12_24_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range
        scope = report_scope(include_date_range: false).
          open_between(start_date: filter.start_date - 24.months, end_date: filter.start_date - 12.months).
          with_service_between(start_date: filter.start_date - 24.months, end_date: filter.start_date - 12.months).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    # Homeless project types that overlap chosen project types
    private def homeless_project_type_codes
      @homeless_project_type_codes ||= HudUtility.homeless_project_type_numbers & filter.project_type_ids
    end

    private def outcome_clients
      @outcome_clients ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        {}.tap do |clients|
          # TODO: Average LOS - Unique days in homeless projects in the report scope
          clients[:average_los] = report_scope.distinct.in_project_type(homeless_project_type_codes).joins(:service_history_services).group(:client_id).count(:date).to_set

          # Exit destinations
          clients[:exit_counted] = Set.new
          clients[:exit_homeless] = Set.new
          clients[:exit_institutional] = Set.new
          clients[:exit_temporary] = Set.new
          clients[:exit_permanent] = Set.new
          clients[:exit_other] = Set.new
          report_scope.distinct.
            exit_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :destination, :first_date_in_program).
            each do |client_id, destination, _|
              next if clients[:exit_counted].include?(client_id)

              clients[:exit_counted] << client_id
              clients[:exit_homeless] << client_id if HudUtility.homeless_destinations.include?(destination)
              clients[:exit_institutional] << client_id if HudUtility.institutional_destinations.include?(destination)
              clients[:exit_temporary] << client_id if HudUtility.temporary_destinations.include?(destination)
              clients[:exit_permanent] << client_id if HudUtility.permanent_destinations.include?(destination)
              clients[:exit_other] << client_id if HudUtility.other_destinations.include?(destination)
            end

          # Returns
          clients[:return_counted] = Set.new
          clients[:returns_1_years] = Set.new
          clients[:returns_1_2_years] = Set.new
          report_scope.distinct.
            entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              next if clients[:return_counted].include?(client_id)

              if client_ids_with_homeless_activity_1_12_months.include?(client_id) && ! client_ids_with_homeless_activity_0_12_months.include?(client_id)
                # Client is in the current report range, but had no homeless service within the month prior, but had homeless service in the year prior
                clients[:returns_1_years] << client_id

              elsif client_ids_with_homeless_activity_12_24_months.include?(client_id) && ! client_ids_with_homeless_activity_0_12_months.include?(client_id)
                # Client is in the current report range, but had no homeless service within the year prior, but had homeless service in the 2 years prior
                clients[:returns_1_2_years] << client_id
              end
            end
        end
      end
    end
  end
end
