###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DisabilitySummary
  class DisabilitySummaryReport
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
      @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
      @comparison_pattern = filter.comparison_pattern
    end

    def self.comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'disability_summary/warehouse_reports/disability_summary'
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def self.available_section_types
      [
        'disabilities',
      ]
    end

    def section_ready?(section)
      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      case section
      when 'disabilities'
        disabilities_cache_key
      end
    end

    private def disabilities_cache_key
      [self.class.name, cache_slug, 'disabilities']
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        add_demographic_disabilities_control_section,
        build_enrollment_control_section,
      ]
    end

    def report_path_array
      [
        :disability_summary,
        :warehouse_reports,
        :disability_summary,
        :index,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope(all_project_types: false)
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_project_type(scope, all_project_types: all_project_types)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_disabilities(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_dv_status(scope)
      scope = filter_for_chronic_at_entry(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope = filter_for_prior_living_situation(scope)
      scope = filter_for_times_homeless(scope)
      filter_for_destination(scope)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def total_client_count
      @total_client_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        distinct_client_ids.count
      end
    end

    def hoh_count
      @hoh_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        hoh_scope.select(:client_id).distinct.count
      end
    end

    def household_count
      @household_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(:household_id).distinct.count
      end
    end

    # most recent response for each client for each disability type per CoC
    def data_for_disabilities
      @data_for_disabilities ||= Rails.cache.fetch(disabilities_cache_key, expires_in: expiration_length) do
        columns = {
          client_id: :client_id,
          disability_type: :DisabilityType,
          disability_response: :DisabilityResponse,
          indefinite: :IndefiniteAndImpairs,
          coc_code: :CoCCode,
          veteran_status: c_t[:VeteranStatus],
          dob: c_t[:DOB],
          reporting_age: age_calculation,
          entry_date: she_t[:first_date_in_program],
          ethnicity: c_t[:Ethnicity],
        }
        HUD.gender_fields.each do |field|
          columns[field] = c_t[field]
        end
        # race_cache_client = GrdaWarehouse::Hud::Client.new
        data = {}
        # binding.pry
        report_scope.joins(:client, enrollment: :disabilities, project: :project_cocs).
          order(:CoCCode, d_t[:InformationDate].desc).
          pluck(*columns.values).each do |row|
            row = Hash[columns.keys.zip(row)]
            client_id = row[:client_id]
            coc_code = row[:coc_code]
            disability_response = row[:disability_response]
            indefinite = row[:indefinite]
            disability = HUD.disability_type(row[:disability_type])
            # race = nil #race_cache_client.race_string(destination_id: client_id, scope_limit: GrdaWarehouse::Hud::Client.joins(:service_history_enrollments).merge(report_scope))

            # only count the first response for a client in each type per coc
            data[:counted_by_coc] ||= {}
            data[:counted_by_coc][coc_code] ||= disability_options(Set)
            next if data[:counted_by_coc][coc_code][disability].include?(client_id)

            data[:counted_by_coc][coc_code][disability] << client_id

            # ignore no/doesn't know/not collected
            next unless disability_response.in?(GrdaWarehouse::Hud::Disability.positive_responses)

            indefinite ||= 99
            response = if row[:disability_type] == 10
              HUD.disability_response disability_response
            else
              HUD.no_yes_reasons_for_missing_data disability_response
            end

            client_data = {
              disability_type: row[:disability_type],
              disability: disability,
              response: response,
              indefinite: indefinite,
              coc_code: coc_code,
              # race: race,
              veteran_status: row[:veteran_status],
              dob: row[:dob],
              reporting_age: row[:reporting_age],
              ethnicity: row[:ethnicity],
              id: client_id,
            }
            HUD.gender_fields.each do |field|
              client_data[field] = row[field]
            end

            data[:clients] ||= {}
            data[:clients][client_id] ||= client_data

            data[:all] ||= disability_options(Set)
            data[:all][disability] << client_id
            data[:all][:clients] ||= {}
            data[:all][:clients][disability] ||= Set.new
            data[:all][:clients][disability] << client_id

            data[:by_coc] ||= {}
            data[:by_coc][coc_code] ||= {}
            # data[:by_coc][coc_code][:clients] ||= {}
            # data[:by_coc][coc_code][:clients][disability] ||= {}
            # data[:by_coc][coc_code][:clients][disability][HUD.no_yes_reasons_for_missing_data(indefinite)] ||= Set.new
            # data[:by_coc][coc_code][:clients][disability][HUD.no_yes_reasons_for_missing_data(indefinite)] << client_id
            data[:by_coc][coc_code][:disabilities] ||= disability_options(indefinite_options)
            data[:by_coc][coc_code][:disabilities][disability][HUD.no_yes_reasons_for_missing_data(indefinite)] << client_id

            data[:by_coc][coc_code][:disabilities_summary] ||= disability_options(Set)
            data[:by_coc][coc_code][:disabilities_summary][disability] << client_id
          end
        data
      end
    end

    def detail_data(params)
      detail = params.dig(:detail)
      coc = params.dig(:coc)
      disability = params.dig(:disability)
      indefinite = params.dig(:indefinite)

      return unless disability.present?
      return unless disability.in?(HUD.disability_types.values)
      return if coc.present? && ! coc.in?(HUD.cocs.keys)
      return if indefinite.present? && ! indefinite.in?(HUD.no_yes_reasons_for_missing_data_options.values)

      ids = if detail == 'universe'
        data_for_disabilities[:all][:clients][disability]
      elsif indefinite.blank?
        data_for_disabilities[:by_coc][coc][:disabilities][disability].values.map(&:to_a).flatten.to_set
      else
        data_for_disabilities[:by_coc][coc][:disabilities][disability][HUD.no_yes_reasons_for_missing_data(indefinite)]
      end

      clients = data_for_disabilities[:clients].select do |client_id, _|
        ids.include?(client_id)
      end.values
      # Populate Race (this is too expensive to do system-wide, but should be ok for a drill-down)
      race_cache_client = GrdaWarehouse::Hud::Client.new
      clients.map do |client|
        client[:race] = race_cache_client.race_string(destination_id: client[:id], scope_limit: GrdaWarehouse::Hud::Client.joins(:service_history_enrollments).merge(report_scope))
        client
      end
    end

    def support_title(params)
      detail = params.dig(:detail)
      coc = params.dig(:coc)
      disability = params.dig(:disability)
      indefinite = params.dig(:indefinite)
      return unless disability.present?
      return unless disability.in?(HUD.disability_types.values)
      return if coc.present? && ! coc.in?(HUD.cocs.keys)
      return if indefinite.present? && ! indefinite.in?(HUD.no_yes_reasons_for_missing_data_options.values)

      title = disability
      title += " (Indefinite and Impairing: #{indefinite})" if indefinite
      title += ' at the Universe Level' if detail == 'universe'
      title += " for #{coc}" if coc

      title += " for #{filter.date_range_words}"
      title
    end

    private def disability_options(hash_or_set)
      HUD.disability_types.values.map do |v|
        value = if hash_or_set.is_a?(Class)
          hash_or_set.new
        else
          hash_or_set.deep_dup
        end
        [
          v,
          value,
        ]
      end.to_h
    end

    private def indefinite_options
      HUD.no_yes_reasons_for_missing_data_options.values.map { |k| [k, Set.new] }.to_h
    end

    def self.data_for_export(reports)
      {}.tap do |rows|
        reports.each do |report|
          rows['Date Range'] ||= []
          rows['Date Range'] += [report.filter.date_range_words, nil, nil, nil]
          rows['Unique Clients'] ||= []
          rows['Unique Clients'] += [report.total_client_count, nil, nil, nil]
          rows['Heads of Household'] ||= []
          rows['Heads of Household'] += [report.hoh_count, nil, nil, nil]
          rows['Households'] ||= []
          rows['Households'] += [report.household_count, nil, nil, nil]

          # rows = report.age_data_for_export(rows)
          # rows = report.gender_data_for_export(rows)
          # rows = report.race_data_for_export(rows)
          # rows = report.ethnicity_data_for_export(rows)
          # rows = report.relationship_data_for_export(rows)
          # rows = report.disability_data_for_export(rows)
          # rows = report.dv_status_data_for_export(rows)
          # rows = report.priors_data_for_export(rows)
          # rows = report.household_type_data_for_export(rows)
        end
      end
    end

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 30.seconds if Rails.env.development?

      30.minutes
    end
  end
end
