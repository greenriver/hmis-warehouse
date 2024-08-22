###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class DashboardData
    include ArelHelper
    include ApplicationHelper

    def initialize(report)
      @report = report
      @filter = @report.filter
      @start_date = @filter.start_date.beginning_of_month
      @end_date = @filter.end_date.beginning_of_month
    end

    def report_enrollments_enrollment_scope
      Enrollment.where(report_id: @report.id)
    end

    def with_ce_data
      report_enrollments_enrollment_scope.where.not(ce_entry_date: nil, ce_referral_date: nil)
    end

    private def housed_total_scope
      report_enrollments_enrollment_scope.
        placed_in_range(@report.filter.range)
    end

    # Returns are only counted for people who were housed, and exited
    # For PH this means the client has a move-in-date and exit date,
    # For Diversion this means the client has an exit date
    private def returned_total_scope
      housed_total_scope.where.not(exit_date: nil).where.not(return_date: nil)
    end

    def years
      (@start_date.year .. @end_date.year).to_a
    end

    def label_color(background_color)
      return '#FFFFFF' if background_color.blank?

      colors = GrdaWarehouse::SystemColor.new
      colors.calculated_foreground_color(background_color)
    end

    def cache_key(id, type, options)
      [
        self.class.name,
        id,
        type,
        options,
      ].join('/')
    end

    # We don't de-compose numbers in this report, only add them up, so as long as no individual count
    # is less than 11, we don't need to mask it.
    def mask_small_populations(value, mask: true) # rubocop:disable Lint/UnusedMethodArgument
      # Until we are able to confirm all calculations, don't actually mask anything
      return value

      # return value unless mask
      # return 0 if value.blank? || value < 11

      # value
    end

    def project_types
      [
        'All',
        'Diversion',
        'Permanent Supportive Housing',
        'Rapid Rehousing',
      ]
    end

    def project_type_colors
      # [
      #   '#E6B70F',
      #   '#B2803F',
      #   '#1865AB',
      # ]
      GrdaWarehouse::SystemColor.default_colors['project-type'].values.map { |c| c[:background_color] }
    end

    def household_types
      [
        'Adult Only',
        'Adults and Children',
        'Unknown Household Type', # NOTE: we're using unknown to capture child only as well
      ]
    end

    def household_type_colors
      [
        '#3B528B',
        '#ABBD2A',
        '#CC6600',
      ]
    end

    def count_levels
      [
        'Individuals',
        'Households',
      ]
    end

    def demographics
      ['Race', 'Age', 'Gender', 'Household Type']
    end

    def demographic_race
      # Sorted alphabetically, with not collected at the end
      HudUtility2024.races(multi_racial: true).except(*ignored_races).values.sort + [HudUtility2024.races(multi_racial: true)['RaceNone']]
    end

    # Note, the census doesn't contain MidEastNAfrican and HispanicLatinaeo is represented as ethnicity
    # and the 2024 specs have them, so for now we're ignoring them
    private def ignored_races
      [
        # 'HispanicLatinaeo',
        # 'MidEastNAfrican',
        'MultiRacial',
        'RaceNone',
      ]
    end

    def demographic_race_colors
      # TODO: Pull colors from report config
      GrdaWarehouse::SystemColor.default_colors['race'].values.map { |c| c[:background_color] }
    end

    def demographic_age
      [
        'Under 18',
        '18 to 24',
        '25 to 39',
        '40 to 49',
        '50 to 62',
        'Over 62',
        'Unknown Age',
      ]
    end

    def demographic_age_colors
      [
        '#F4DB00',
        '#ABBD2A',
        '#3F7341',
        '#00B28A',
        '#31688E',
        '#002A92',
        '#64007C',
      ]
    end

    def unknown_genders
      [
        "Client doesn't know",
        'Client prefers not to answer',
        'Data not collected',
      ]
    end

    def demographic_gender
      HudUtility2024.genders.values - unknown_genders + ['Unknown Gender']
    end

    def demographic_gender_colors
      [
        '#336770',
        '#E6B70F',
        '#6F4478',
        '#7FABCA',
      ]
    end

    def demographic_household_type
      [
        'Adult Only',
        'Adults and Children',
        'Unknown Household Type',
      ]
    end

    def demographic_household_type_colors
      household_type_colors
    end

    def homeless_population_types
      [
        'Unsheltered',
        'Emergency Shelter',
        'Transitional Housing',
        'Safe Haven',
      ]
    end

    def homeless_population_type_colors
      [
        '#336770',
        '#E3D8B3',
        '#C7B266',
        '#9E7C02',
      ]
    end

    def homelessness_statuses
      [
        'All',
        'Sheltered',
        'Unsheltered',
      ]
    end

    def homelessness_status_colors
      [
        '#B2803F',
        '#1865AB',
      ]
    end

    def to_key(name)
      name.gsub(/[^a-zA-Z0-9 -]/, '').gsub(' ', '_')
    end

    def date_range
      date_range = []
      current_date = @start_date
      while current_date <= @end_date
        date_range.push(current_date)
        current_date += 1.month
      end
      date_range
    end

    def bucketed_project_type(enrollment)
      return 'Diversion' if enrollment.project_id.in?(@report.filter.secondary_project_ids) && enrollment.destination.in?(@report.class::POSITIVE_DIVERSION_DESTINATIONS)
      return 'Permanent Supportive Housing' if enrollment.project_type.in?([3, 10])
      return 'Rapid Rehousing' if enrollment.project_type.in?([9, 13])
    end

    private def filter_for_type(scope, type)
      case type
      when 'All', 'Overall'
        # Note, we only report on PH and Diversion at this point.  There may be other data in the
        # report scope, but we should not count them in placements or subsequent steps
        # Limit to records with a placed-date so we don't end up catching anything but placements
        scope.where(
          project_id: @report.filter.effective_project_ids + @report.filter.secondary_project_ids,
          placed_date: @report.filter.range,
        )
      # Removed in favor of running the report for a sub-set of data (leaving the code for now)
      # when 'R.E.A.L. Time Initiative'
      #   pilot_scope = Enrollment.
      #     where(date_query(pilot_date_range)).
      #     where(project_id: @report.filter.effective_project_ids_from_secondary_project_groups).
      #     select(:id)
      #   implementation_scope = Enrollment.
      #     where(date_query(implementation_date_range)).
      #     where(project_id: @report.filter.effective_project_ids).
      #     select(:id)
      #   scope.where(id: pilot_scope).or(scope.where(id: implementation_scope))

      # Diversion is a special case, limited to the secondary project ids.
      # For all others, we'll limit to the effective project ids to prevent double counting
      when 'Diversion'
        scope.where(project_id: @report.filter.secondary_project_ids, destination: @report.class::POSITIVE_DIVERSION_DESTINATIONS)
      when 'Permanent Supportive Housing' # NOTE: these project types are specified and do not match HUD
        scope.where(project_type: [3, 10], project_id: @report.filter.effective_project_ids)
      when 'Rapid Rehousing' # NOTE: these project types are specified and do not match HUD
        scope.where(project_type: [9, 13], project_id: @report.filter.effective_project_ids)
      when 'Unsheltered', 'Unhoused Population'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true), project_id: @report.filter.effective_project_ids)
      when 'Sheltered'
        scope.where.not(project_type: HudUtility2024.project_type('Street Outreach', true), project_id: @report.filter.effective_project_ids)
      when *household_types
        scope.where(household_type: type)
      when 'Under 18'
        scope.where(age: 0..17)
      when '18 to 24'
        scope.where(age: 18..24)
      when '25 to 39'
        scope.where(age: 25..39)
      when '40 to 49'
        scope.where(age: 40..49)
      when '50 to 62'
        scope.where(age: 50..62)
      when 'Over 62'
        scope.where(age: 63..)
      when 'Unknown Age'
        scope.where(age: nil).or(scope.where(age: ...0))
      when *HudUtility2024.gender_known_values
        scope.where(gender: type)
      when 'Unknown Gender'
        scope.where.not(gender: HudUtility2024.gender_known_values)
      when *HudUtility2024.races(multi_racial: false).values
        scope.where(Enrollment.arel_table[:race_list].matches("%#{type}"))
      else
        raise "Unknown type: #{type}"
      end
    end

    private def filter_for_count_level(scope, level)
      case level
      when 'Individuals'
        scope
      when 'Households'
        scope.hoh
      end
    end

    def pilot_date_range
      start_date = [@report.filter.start_date, Date.new(2023, 4, 30)].min
      end_date = [@report.filter.end_date, Date.new(2023, 4, 30)].min
      (start_date .. end_date)
    end

    def implementation_date_range
      start_date = [@report.filter.start_date, Date.new(2023, 5, 1)].max
      end_date = [@report.filter.end_date, Date.new(2023, 5, 1)].max
      (start_date .. end_date)
    end
  end
end
