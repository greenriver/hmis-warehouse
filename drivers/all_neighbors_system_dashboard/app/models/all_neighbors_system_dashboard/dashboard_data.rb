module AllNeighborsSystemDashboard
  class DashboardData
    include ArelHelper

    def initialize(report)
      @report = report
      @filter = @report.filter
      @start_date = @filter.start_date.beginning_of_month
      @end_date = @filter.end_date.beginning_of_month
    end

    def report_enrollments_enrollment_scope
      Enrollment.where(report_id: @report.id)
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

    def project_types
      [
        'All',
        'Diversion',
        'Permanent Supportive Housing',
        'Rapid Rehousing',
      ]
    end

    def project_type_colors
      [
        '#E6B70F',
        '#B2803F',
        '#1865AB',
      ]
    end

    def household_types
      ['Adults Only', 'Adults and Children']
    end

    def household_type_colors
      ['#3B528B', '#ABBD2A']
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
      HudUtility2024.races(multi_racial: true).except(*ignored_races).values
    end

    # Note, the census doesn't contain MidEastNAfrican and HispanicLatinaeo is represented as ethnicity
    # and the 2024 specs have them, so for now we're ignoring them
    private def ignored_races
      [
        'HispanicLatinaeo',
        'MidEastNAfrican',
        'RaceNone',
        'MultiRacial',
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
        'Adults Only',
        'Adults and Children',
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

    def ranges_overlap?(range_a, range_b)
      range_b.begin <= range_a.end && range_a.begin <= range_b.end
    end

    private def filter_for_type(scope, type)
      case type
      when 'Permanent Supportive Housing'
        scope.where(project_type: HudUtility2024.project_type('PH - Permanent Supportive Housing', true))
      when 'Rapid Rehousing'
        scope.where(project_type: HudUtility2024.project_type('PH - Rapid Re-Housing', true))
      when 'Diversion'
        # FIXME
        scope.where(destination: @report.class::POSITIVE_DIVERSION_DESTINATIONS)
      when 'Unsheltered'
        scope.where(project_type: HudUtility2024.project_type('Street Outreach', true))
      when 'Sheltered'
        scope.where.not(project_type: HudUtility2024.project_type('Street Outreach', true))
      when 'Adults Only', 'Adults and Children'
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
        scope.where(age: nil)
      when *HudUtility2024.genders.values
        scope.where(gender: type)
      when 'Unknown Gender'
        scope.where(gender: nil)
      else
        scope
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
  end
end
