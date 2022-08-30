###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module DestinationReport
  class Report
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include DestinationReport::Details
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

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def self.url
      'destination_report/warehouse_reports/destination_report'
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
        :destination_report,
        :warehouse_reports,
        :reports,
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
      scope = filter_for_destination(scope)
      scope = filter_for_times_homeless(scope)
      scope.joins(enrollment: :exit)
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

    def data_for_destinations
      @data_for_destinations ||= begin
        data = {}
        data[:all] ||= destination_buckets.map { |b| [b, Set.new] }.to_h
        data[:by_coc] ||= {}
        report_scope.joins(project: :project_cocs).
          order(:CoCCode, :first_date_in_program).
          pluck(
            :client_id,
            :Destination,
            :CoCCode,
          ).each do |client_id, destination_id, coc_code|
            destination = HUD.destination_type(destination_id)
            detailed_destination = HUD.destination(destination_id)

            data[:all][destination] << client_id
            data[:by_coc][coc_code] ||= {}
            data[:by_coc][coc_code][:clients] ||= {}
            next if data[:by_coc][coc_code][:clients][client_id]

            data[:by_coc][coc_code][:clients][client_id] ||= {
              destination_id: destination_id,
              destination: destination,
              detailed_destination: detailed_destination,
              coc_code: coc_code,
            }

            data[:by_coc][coc_code][:destinations] ||= destination_buckets.map { |b| [b, Set.new] }.to_h

            data[:by_coc][coc_code][:destination_details] ||= destination_buckets.map { |b| [b, {}] }.to_h
            destination_buckets.each do |b|
              HUD.valid_destinations.values.uniq.each do |l|
                data[:by_coc][coc_code][:destination_details][b][l] ||= Set.new
              end
              data[:by_coc][coc_code][:destination_details][b]['Unknown'] ||= Set.new
            end

            data[:by_coc][coc_code][:destinations][destination] ||= destination_buckets.map { |b| [b, Set.new] }.to_h
            data[:by_coc][coc_code][:destinations][destination] << client_id
            data[:by_coc][coc_code][:destination_details][destination][detailed_destination || 'Unknown'] << client_id
          end
        data
      end
    end

    private def destination_buckets
      [
        'Homeless',
        'Institutional',
        'Temporary',
        'Permanent',
        'Other',
      ]
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
          rows = rows_for_export(rows, report)
        end
      end
    end

    def self.rows_for_export(rows, report)
      rows['*Universe'] ||= []
      rows['*Universe'] += report.data_for_destinations[:all].keys
      rows['_Universe - Universe'] ||= []
      rows['_Universe - Universe'] += report.data_for_destinations[:all].values.map(&:count)
      rows['*By CoC'] ||= []
      report.data_for_destinations[:by_coc].each do |coc_code, data|
        rows["*#{coc_code}"] ||= []
        rows["*#{coc_code}"] += data[:destinations].keys
        rows["_#{coc_code}"] ||= []
        rows["_#{coc_code}"] = data[:destinations].map { |_, ids| ids.count }

        data[:destination_details].each do |destination, d_data|
          rows["*#{coc_code} - #{destination}"] ||= []
          rows["*#{coc_code} - #{destination}"] += ['Destination', 'Destination Detail', 'Client Count', nil, nil]
          d_data.each do |(detailed_destination, ids)|
            next if ids.empty?

            rows["_#{coc_code} - #{destination} #{detailed_destination}"] ||= []
            rows["_#{coc_code} - #{destination} #{detailed_destination}"] += [destination, detailed_destination, ids.count, nil, nil]
          end
        end
      end

      rows
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
