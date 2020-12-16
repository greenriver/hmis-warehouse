###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PriorLivingSituation
  class PriorLivingSituationReport
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
      'prior_living_situation/warehouse_reports/prior_living_situation'
    end

    def multiple_project_types?
      true
    end

    def report_path_array
      [
        :prior_living_situation,
        :warehouse_reports,
        :prior_living_situation,
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
      scope = filter_for_range(report_scope_source)
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
      scope = filter_for_chronic_status(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_prior_living_situation(scope)
      scope = filter_for_destination(scope)
      scope
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

    def data_for_living_situations
      @data_for_living_situations ||= begin
        data = {}
        report_scope.joins(:enrollment, project: :project_cocs).
          order(:CoCCode, :first_date_in_program).
          pluck(
            :client_id,
            :LivingSituation,
            :LengthOfStay,
            :CoCCode,
          ).each do |client_id, living_situation_id, length_of_stay, coc_code|
            data[coc_code] ||= {}
            data[coc_code][:clients] ||= {}
            next if data[coc_code][:clients][client_id]

            living_situation = HUD.situation_type(living_situation_id, include_homeless_breakout: true)
            data[coc_code][:clients][client_id] ||= {
              living_situation_id: living_situation_id,
              living_situation: living_situation,
              length_of_stay: length_of_stay,
              coc_code: coc_code,
            }

            data[coc_code][:situations] ||= living_situation_buckets.map { |b| [b, Set.new] }.to_h

            # data[coc_code][:situations_length] ||= living_situation_buckets.product(HUD.residence_prior_length_of_stays_brief.values.uniq).map { |b| [b, Set.new] }.to_h
            data[coc_code][:situations_length] ||= living_situation_buckets.map { |b| [b, {}] }.to_h
            living_situation_buckets.each do |b|
              HUD.residence_prior_length_of_stays_brief.values.uniq.each do |l|
                data[coc_code][:situations_length][b][l] ||= Set.new
              end
            end

            data[coc_code][:situations][living_situation] << client_id
            data[coc_code][:situations_length][living_situation][HUD.residence_prior_length_of_stay_brief(length_of_stay) || ''] << client_id
          end
        data
      end
      # By ProjectCoc.CoCCode
      # include total by location

      # columns:
      #   'location' ()
      #   'length of stay' HUD.residence_prior_length_of_stay_brief
    end

    private def living_situation_buckets
      [
        'Homeless',
        'Institutional',
        'Temporary or Permanent',
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

          rows = report.age_data_for_export(rows)
          rows = report.gender_data_for_export(rows)
          rows = report.race_data_for_export(rows)
          rows = report.ethnicity_data_for_export(rows)
          rows = report.relationship_data_for_export(rows)
          rows = report.disability_data_for_export(rows)
          rows = report.dv_status_data_for_export(rows)
          rows = report.priors_data_for_export(rows)
          rows = report.household_type_data_for_export(rows)
        end
      end
    end

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def adult_clause
      Arel.sql("EXTRACT(YEAR FROM #{age_calculation.to_sql})").in((18..110).to_a)
    end

    private def child_clause
      Arel.sql("EXTRACT(YEAR FROM #{age_calculation.to_sql})").in((0..17).to_a)
    end

    private def male_clause
      c_t[:Gender].eq(1)
    end

    private def female_clause
      c_t[:Gender].eq(0)
    end

    private def average_age(clause:)
      average_age = nf('AVG', [age_calculation])
      scope = report_scope.joins(:client).where(clause)
      scope.joins(:client).pluck(Arel.sql("EXTRACT(YEAR FROM #{average_age.to_sql})"))&.first&.to_i
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
