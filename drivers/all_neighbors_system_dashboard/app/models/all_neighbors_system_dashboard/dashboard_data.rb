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

    private def housed_total_scope
      report_enrollments_enrollment_scope.
        housed_in_range(@report.filter.range, filter: @report.filter).
        distinct
    end

    # NOTE: do not apply distinct within this method, averages should not be
    # calculated against distinct values
    private def moved_in_scope
      report_enrollments_enrollment_scope.
        moved_in_in_range(@report.filter.range, filter: @report.filter)
    end

    # Count once per client per day per type
    private def count_one_client_per_date_arel
      nf(
        'concat',
        [
          Enrollment.arel_table[:destination_client_id],
          ' ',
          Enrollment.arel_table[:project_type],
          ' ',
          Enrollment.arel_table[:household_type],
          ' ',
          cl(Enrollment.arel_table[:age], -1),
          ' ',
          cl(Enrollment.arel_table[:move_in_date], Enrollment.arel_table[:exit_date]),
        ],
      )
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
        'Other Permanent Housing',
        # 'R.E.A.L. Time Initiative', # removed in favor of running the report with a limited data set
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
      HudUtility2024.races(multi_racial: true).except(*ignored_races).values + ["Doesn't know, prefers not to answer, or not collected"]
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
        'Over 63',
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

    private def filter_for_type(scope, type)
      case type
      when 'All', 'Overall'
        # Note, we only report on PH and Diversion at this point.  There may be other data in the
        # report scope, but we should not count them in placements or subsequent steps
        scope.where(project_id: @report.filter.effective_project_ids + @report.filter.secondary_project_ids)
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
      when 'PH'
        project_types = HudUtility2024.project_types_with_move_in_dates
        scope.where(project_type: project_types, project_id: @report.filter.effective_project_ids)
      when 'Other Permanent Housing'
        project_types = [HudUtility2024.project_type('PH - Housing Only', true), HudUtility2024.project_type('PH - Housing with Services (no disability required for entry)', true)]
        scope.where(project_type: project_types, project_id: @report.filter.effective_project_ids)
      when 'Permanent Supportive Housing'
        scope.where(project_type: HudUtility2024.project_type('PH - Permanent Supportive Housing', true), project_id: @report.filter.effective_project_ids)
      when 'Rapid Rehousing'
        scope.where(project_type: HudUtility2024.project_type('PH - Rapid Re-Housing', true), project_id: @report.filter.effective_project_ids)
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
      when 'Over 63'
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
