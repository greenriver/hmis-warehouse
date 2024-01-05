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

    def outcome_count(type, coc_code = base_count_sym)
      # Return average days
      if type.to_s == 'average_los'
        values = outcome_clients[type.to_sym][coc_code].map(&:last)
        return 0 unless values.count.positive?

        return (values.sum.to_f / values.count).round
      elsif type.to_s == 'exits'
        report_scope.distinct.
          exit_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
          select(:client_id).
          distinct.
          count
      end

      mask_small_population(outcome_client_ids(type, coc_code)&.count&.presence || 0)
    end

    def outcome_percentage(type, coc_code = base_count_sym)
      return 'N/A' if type.to_s == 'average_los'

      # Denominator is those who exited
      total_count = outcome_count(:exit_counted)
      return 0 if total_count.zero?

      of_type = outcome_count(type, coc_code)
      return 0 if of_type.zero?

      ((of_type.to_f / total_count) * 100)
    end

    def outcome_data_for_export(rows)
      rows['_Outcome Type'] ||= []
      rows['*Outcome Type'] ||= []
      rows['*Outcome Type'] += ['Outcome Type', nil, 'Count', 'Percentage', nil]
      available_coc_codes.each do |coc_code|
        rows['*Outcome Type'] += ["#{coc_code} Client"]
        rows['*Outcome Type'] += ["#{coc_code} Percentage"]
      end
      rows['*Outcome Type'] += [nil]
      available_outcome_types.invert.each do |id, title|
        title = clean_excel_title(title)
        rows["_Outcome Type_data_#{title}"] ||= []
        outcome_percentage = outcome_percentage(id)
        outcome_percentage /= 100 unless id.to_s == 'average_los'
        rows["_Outcome Type_data_#{title}"] += [
          title,
          nil,
          outcome_count(id),
          outcome_percentage,
          nil,
        ]
        available_coc_codes.each do |coc_code|
          outcome_percentage_coc = outcome_percentage(id, coc_code.to_sym)
          outcome_percentage_coc /= 100 unless id.to_s == 'average_los'
          rows["_Outcome Type_data_#{title}"] += [
            outcome_count(id, coc_code.to_sym),
            outcome_percentage_coc,
          ]
        end
      end
      rows
    end

    private def outcome_client_ids(type, coc_code = base_count_sym)
      return outcome_clients[type][coc_code].map(&:first) if type.to_s == 'average_los'

      outcome_clients[type][coc_code]
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
        'Returns to Selected Universe <br /><em>1-2 years after exiting homelessness</em>' => :returns_1_2_years,
        # NOTE: no homeless enrollment in 30 days prior to the report range, but had one in the prior year
        'Returns to Selected Universe <br /><em>< 1 year after exiting homelessness</em>' => :returns_1_years,
      }
    end

    private def client_ids_with_homeless_activity_1_months
      @client_ids_with_homeless_activity_1_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range and project types so we can look for returns in homeless projects
        scope = report_scope(include_date_range: false, all_project_types: true).
          open_between(start_date: filter.start_date - 1.months, end_date: filter.start_date - 1.days).
          with_service_between(start_date: filter.start_date - 1.months, end_date: filter.start_date - 1.days).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_1_12_months
      @client_ids_with_homeless_activity_1_12_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range and project types so we can look for returns in homeless projects
        scope = report_scope(include_date_range: false, all_project_types: true).
          open_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.months).
          with_service_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.months).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_0_12_months
      @client_ids_with_homeless_activity_0_12_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range and project types so we can look for returns in homeless projects
        scope = report_scope(include_date_range: false, all_project_types: true).
          open_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.days).
          with_service_between(start_date: filter.start_date - 12.months, end_date: filter.start_date - 1.days).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    private def client_ids_with_homeless_activity_12_24_months
      @client_ids_with_homeless_activity_12_24_months ||= begin
        # NOTE: this is limited to the report universe, except for the date range and project types so we can look for returns in homeless projects
        scope = report_scope(include_date_range: false, all_project_types: true).
          open_between(start_date: filter.start_date - 24.months, end_date: filter.start_date - 12.months).
          with_service_between(start_date: filter.start_date - 24.months, end_date: filter.start_date - 12.months).
          in_project_type(homeless_project_type_codes)
        scope = filter_for_user_access(scope)
        scope.pluck(:client_id).to_set
      end
    end

    # Homeless project types that overlap chosen project types
    private def homeless_project_type_codes
      @homeless_project_type_codes ||= HudUtility2024.homeless_project_type_numbers & filter.project_type_ids
    end

    private def initialize_outcome_client_counts(clients, coc_code = base_count_sym)
      # Exit destinations
      available_outcome_types.invert.each do |key, _|
        clients[key][coc_code] = Set.new
      end
      # Exits
      clients[:exit_counted][coc_code] = Set.new
      # Returns
      clients[:return_counted][coc_code] = Set.new
      clients[:returns_1_years][coc_code] = Set.new
      clients[:returns_1_2_years][coc_code] = Set.new
    end

    private def set_outcome_exit_client_counts(clients, client_id, destination, coc_code = base_count_sym)
      clients[:exit_counted][coc_code] << client_id
      clients[:exit_homeless][coc_code] << client_id if HudUtility2024.homeless_destinations.include?(destination)
      clients[:exit_institutional][coc_code] << client_id if HudUtility2024.institutional_destinations.include?(destination)
      clients[:exit_temporary][coc_code] << client_id if HudUtility2024.temporary_destinations.include?(destination)
      clients[:exit_permanent][coc_code] << client_id if HudUtility2024.permanent_destinations.include?(destination)
      clients[:exit_other][coc_code] << client_id if HudUtility2024.other_destinations.include?(destination)
    end

    private def set_outcome_return_client_counts(clients, client_id, coc_code = base_count_sym)
      clients[:return_counted][coc_code] << client_id
      if client_ids_with_homeless_activity_1_12_months.include?(client_id) && ! client_ids_with_homeless_activity_1_months.include?(client_id)
        # Client is in the current report range, but had no homeless service within the month prior, but had homeless service in the year prior
        clients[:returns_1_years][coc_code] << client_id
      elsif client_ids_with_homeless_activity_12_24_months.include?(client_id) && ! client_ids_with_homeless_activity_0_12_months.include?(client_id)
        # Client is in the current report range, but had no homeless service within the year prior, but had homeless service in the 2 years prior
        clients[:returns_1_2_years][coc_code] << client_id
      end
    end

    private def outcome_clients
      @outcome_clients ||= Rails.cache.fetch(outcome_cache_key, expires_in: expiration_length) do
        {}.tap do |clients|
          available_outcome_types.invert.each do |key, _|
            clients[key] = {}
          end
          clients[:return_counted] = {}
          clients[:exit_counted] = {}

          initialize_outcome_client_counts(clients)

          # TODO: Average LOS - Unique days in homeless projects in the report scope
          clients[:average_los][base_count_sym] = report_scope.distinct.in_project_type(homeless_project_type_codes).joins(:service_history_services).group(:client_id).count(shs_t[:date]).to_set

          report_scope.distinct.
            exit_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :destination, :first_date_in_program).
            each do |client_id, destination, _|
              next if clients[:exit_counted][base_count_sym].include?(client_id)

              set_outcome_exit_client_counts(clients, client_id, destination)
            end

          report_scope.distinct.
            entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
            order(first_date_in_program: :desc).
            pluck(:client_id, :first_date_in_program).
            each do |client_id, _|
              next if clients[:return_counted][base_count_sym].include?(client_id)

              set_outcome_return_client_counts(clients, client_id)
            end

          available_coc_codes.each do |coc_code|
            initialize_outcome_client_counts(clients, coc_code.to_sym)

            clients[:average_los][coc_code.to_sym] = report_scope.distinct.in_coc(coc_code: coc_code).in_project_type(homeless_project_type_codes).joins(:service_history_services).group(:client_id).count(shs_t[:date]).to_set

            report_scope.distinct.in_coc(coc_code: coc_code).
              exit_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
              order(first_date_in_program: :desc).
              pluck(:client_id, :destination, :first_date_in_program).
              each do |client_id, destination, _|
                next if clients[:exit_counted][coc_code.to_sym].include?(client_id)

                set_outcome_exit_client_counts(clients, client_id, destination, coc_code.to_sym)
              end

            report_scope.distinct.in_coc(coc_code: coc_code).
              entry_within_date_range(start_date: filter.start_date, end_date: filter.end_date).
              order(first_date_in_program: :desc).
              pluck(:client_id, :first_date_in_program).
              each do |client_id, _|
                next if clients[:return_counted][coc_code.to_sym].include?(client_id)

                set_outcome_return_client_counts(clients, client_id, coc_code.to_sym)
              end
          end
        end
      end
    end

    private def outcome_cache_key
      [self.class.name, cache_slug, 'outcome_clients']
    end
  end
end
