module AllNeighborsSystemDashboard
  class FakeData
    def initialize(start_date, end_date)
      @start_date = start_date.beginning_of_month
      @end_date = end_date.beginning_of_month
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
      [
        'African American, Black, or African',
        'White',
        'American Indian, Alaska Native, or Indigenous',
        'Asian American or Asian',
        'Multi-racial',
        'Other or Unknown',
        'Doesn’t Know',
      ]
    end

    def demographic_race_colors
      [
        '#516478',
        '#6C987A',
        '#5E98CE',
        '#2D2D2D',
        '#96A8AA',
        '#9B5479',
        '#C67269',
      ]
    end

    def demographic_age
      [
        'Under 18',
        '18 to 24',
        '25 to 39',
        '40 to 49',
        '50 to 62',
        'Over 63',
        'Unknown',
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

    def demographic_gender
      [
        'Female',
        'Male',
        'Transgender',
        'Unknown',
      ]
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

    def stack(options)
      project_type = options[:project_type]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            {
              date: date,
              values: options[:types].map { |_| rand(0..150) },
            }
          end,
        }
      end
    end
  end
end
