###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module AllNeighborsSystemDashboard
  class FakeData
    def initialize(start_date, end_date)
      @start_date = start_date.beginning_of_month
      @end_date = end_date.beginning_of_month
    end

    def header_data
      [
        {
          id: 'individuals_housed',
          icon: 'icon-group-alt',
          value: 1987,
          name: 'Individuals Housed To-Date',
        },
        {
          id: 'days_to_obtain_housing',
          icon: 'icon-house',
          value: 223,
          name: 'Days to Obtain Housing',
        },
        {
          id: 'no_return',
          icon: 'icon-clip-board-check',
          value: '87%',
          name: 'Did not return to homelessness after 12 months',
        },
      ]
    end

    def label_color(background_color)
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

    def return_cohorts
      [
        '0 to 6 months after housing',
        '7 to 12 months after housing',
        '13 to 24 months after housing',
        'Within 2 years of housing',
      ]
    end

    def household_types
      ['Adult Only', 'Adults and Children', 'Unknown Household Type']
    end

    def household_type_colors
      ['#3B528B', '#ABBD2A', '#ABBD2A']
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
        'Over 62',
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
        'Adult Only',
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

    def housing_retention_types
      [
        'Retained Housing',
        'Returned to Homelessness',
      ]
    end

    def housing_retention_type_colors
      [
        '#E4C1DE',
        '#754F77',
      ]
    end

    def program_names
      [
        'All',
        'ASC - DRTTR CM 200 (RRH CAS)',
        'Catholic Charities - DRTRR CM (RHH CAS)',
        'Catholic Charities - DRTRR EHV CM (OPH CAS)',
        'CitySquare - DRTRR EHV 60 CM (OPH CAS)',
        'Family Place',
        'FG - DRTRR EHV 50 (CAS OPH)',
        'FG - DRTRR RRH (CAS)',
      ]
    end

    def populations
      [
        'All',
        'DV',
        'HMIS',
      ]
    end

    def count_types
      [
        'Enrollments',
        'Pacements',
      ]
    end

    def to_key(name)
      name.gsub(/[^a-zA-Z0-9 -]/, '').gsub(' ', '_')
    end

    def quarter_range
      quarters = []
      current_quarter = @start_date.beginning_of_quarter
      while current_quarter < @end_date
        quarters.push(
          {
            name: "Q#{(current_quarter.month / 3.0).ceil} #{current_quarter.year}",
            range: [
              current_quarter.strftime('%Y-%-m-%-d'),
              current_quarter.end_of_quarter.strftime('%Y-%-m-%-d'),
            ],
          },
        )
        current_quarter += 3.months
      end
      quarters
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

    def year_range
      years = []
      current_date = @start_date.beginning_of_year
      end_date = @end_date.beginning_of_year
      while current_date <= end_date
        years.push(current_date)
        current_date += 1.year
      end
      years
    end

    def line(range, options)
      random = options[:range] || [0, 1500]
      range.map do |date|
        if date.is_a? DateTime
          [date.strftime('%Y-%-m-%-d'), rand(random[0]..random[1])]
        else
          [date[:range][0], rand(random[0]..random[1])]
        end
      end
    end

    def donut(options)
      project_type = options[:project_type] || options[:homelessness_status]
      options[:types].map do |type|
        # value = options[:fake_data] && project_type != 'All' && type != project_type ? 0 : rand(10..1500)
        {
          name: type,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: [options[:fake_data] && project_type != 'All' && type != project_type ? 0 : rand(10..1500)],
            }
          end,
        }
      end
    end

    def stack(options)
      project_type = options[:project_type]
      homelessness_status = options[:homelessness_status]
      bars = project_type.present? ? [project_type] + options[:bars] : options[:bars]
      bars[0] = "#{homelessness_status} #{bars[0]}" if homelessness_status.present?
      bars.map do |bar|
        {
          name: bar,
          series: date_range.map do |date|
            {
              date: date.strftime('%Y-%-m-%-d'),
              values: options[:types].map.with_index { |_, i| i.zero? ? 1 : rand(0..150) },
              # only need for time to obtain housing stack tooltip
              household_count: rand(0..2),
            }
          end,
        }
      end
    end
  end
end
