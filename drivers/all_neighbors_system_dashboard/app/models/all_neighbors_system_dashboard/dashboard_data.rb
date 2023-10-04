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
      HudUtility2024.races(multi_racial: true).values
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
  end
end
