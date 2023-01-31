###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BostonReports
  class StreetToHome
    include Filter::ControlSections
    include Filter::FilterScopes
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    attr_reader :filter
    attr_accessor :comparison_pattern, :project_type_codes

    def initialize(filter)
      @filter = filter
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
      'boston_reports/warehouse_reports/street_to_homes'
    end

    def self.available_section_types
      [
        'clients_by_cohort',
        'clients_by_stage',
        'stage_by_cohort',
        'cohort_by_stage',
        'match_type_by_cohort',
        'move_in',
        'demographics_by_cohort',
        'demographics_by_stage',
        'comparison',
      ]
    end

    def section_ready?(_section)
      true
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      [
        build_general_control_section,
      ]
    end

    def report_path_array
      [
        :boston_reports,
        :warehouse_reports,
        :street_to_homes,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    def detail_link_base
      "#{section_subpath}details"
    end

    def section_subpath
      "#{self.class.url}/"
    end

    def detail_path_array
      [:details] + report_path_array
    end

    private def build_general_control_section
      ::Filters::UiControlSection.new(id: 'general').tap do |section|
        # section.add_control(
        #   id: 'reporting_period',
        #   required: true,
        #   value: @filter.date_range_words,
        # )
        section.add_control(
          id: 'cohorts',
          required: true,
          value: @filter.cohorts,
        )
        section.add_control(
          id: 'cohort_column',
          required: true,
          value: @filter.cohort_column,
        )
      end
    end

    private def report_scope
      return GrdaWarehouse::CohortClient.none unless filter.cohort_ids.present? && filter.cohort_column.present?

      GrdaWarehouse::CohortClient.where(cohort_id: filter.cohort_ids)
    end

    def clients_by_cohort
      @clients_by_cohort ||= {}.tap do |counts|
        counts.merge!(all_client_breakdowns)
        cohort_names.each do |cohort|
          counts[cohort] = {
            label: cohort,
            count: clients_for_cohort(cohort).count,
          }
        end
      end
    end

    def clients_by_stage
      @clients_by_stage ||= {}.tap do |counts|
        counts.merge!(all_client_breakdowns)
        stages.each do |(key, stage)|
          counts[key] = {
            label: stage[:label],
            count: stage[:scope].count,
          }
        end
      end
    end

    def stage_by_cohort
      @stage_by_cohort ||= {}.tap do |counts|
        cohort_names.each do |cohort|
          all_client_breakdowns.each do |(key, data)|
            counts[[cohort, key]] = {
              label: data[:label],
              count: data[:scope].merge(clients_for_cohort(cohort)).count,
            }
          end
          stages.each do |(key, stage)|
            counts[[cohort, key]] = {
              label: stage[:label],
              count: stage[:scope].merge(clients_for_cohort(cohort)).count,
            }
          end
        end
      end
    end

    def cohort_by_stage
      @cohort_by_stage ||= {}.tap do |counts|
        stages.each do |(key, stage)|
          cohort_names.each do |cohort|
            counts[[key, cohort]] = {
              label: cohort,
              count: stage[:scope].merge(clients_for_cohort(cohort)).count,
            }
          end
        end
        cohort_names.each do |cohort|
          counts[[:inactive, cohort]] = {
            label: cohort,
            count: all_client_breakdowns[:inactive][:scope].merge(clients_for_cohort(cohort)).count,
          }
        end
      end
    end

    def match_type_by_cohort
      @match_type_by_cohort ||= {}.tap do |counts|
        stages.each do |(key, stage)|
          match_types.each do |match_type|
            cohort_names.each do |cohort|
              counts[[key, match_type, cohort]] = {
                label: cohort,
                count: stage[:scope].merge(clients_for_match_type(match_type)).merge(clients_for_cohort(cohort)).count,
              }
            end
          end
          cohort_names.each do |cohort|
            counts[[key, :inactive, cohort]] = {
              label: cohort,
              count: stage[:scope].merge(all_client_breakdowns[:inactive][:scope]).merge(clients_for_cohort(cohort)).count,
            }
          end
        end
      end
    end

    private def all_client_breakdowns
      @all_client_breakdowns ||= {
        total: {
          label: 'All clients',
          count: report_scope.count,
          scope: report_scope,
        },
        active: {
          label: 'Active',
          count: report_scope.active.count,
          scope: report_scope.active,
        },
        inactive: {
          label: 'Inactive',
          count: report_scope.inactive.count,
          scope: report_scope.inactive,
        },
      }
    end

    private def clients_for_cohort(cohort)
      report_scope.where(filter.cohort_column => cohort)
    end

    private def clients_for_match_type(match_type)
      report_scope.where(matched_column => match_type)
    end

    private def cohort_names
      GrdaWarehouse::CohortColumnOption.active.ordered.
        where(cohort_column: filter.cohort_column).
        pluck(:value)
    end

    private def stages
      @stages ||= {}.tap do |s|
        s[:moved_in] = {
          label: 'Housed',
          scope: report_scope.active.where(c_client_t[:housed_date].not_eq(nil)),
        }
        if matched_column.present?
          s[:matched] = {
            label: 'Matched, Not Yet Housed',
            scope: report_scope.active.where(c_client_t[matched_column].not_eq(nil).and(c_client_t[:housed_date].eq(nil))),
          }
          s[:unmatched] = {
            label: 'Un-matched',
            scope: report_scope.active.where(c_client_t[matched_column].eq(nil).and(c_client_t[:housed_date].eq(nil))),
          }
        end
      end
    end

    private def matched_column
      @matched_column ||= GrdaWarehouse::Cohort.available_columns.detect { |c| c.title == 'Current Voucher or Match Type' }&.column
    end

    private def match_types
      GrdaWarehouse::CohortColumnOption.active.ordered.
        where(cohort_column: matched_column).
        pluck(:value)
    end
  end
end
