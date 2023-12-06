module PerformanceMeasurement
  class FakeEquityAnalysisData
    RACES = [
      'American Indian, Alaska Native, or Indigenous',
      'Asian or Asian American',
      'Black, African American, or African',
      'Native Hawaiian or Pacific Islander',
      'White',
      'Hispanic/Latina/e/o',
      'Middle Eastern or North African',
      'Doesn\'t know, prefers not to answer, or not collected',
      'Multi-Racial',
    ].freeze

    AGES = [
      '0 - 4',
      '5 - 10',
      '11 - 14',
      '15 - 17',
      '< 18',
      '18 - 24',
      '25 - 29',
      '30 - 34',
      '35 - 39',
      '40 - 44',
      '45 - 49',
      '50 - 54',
      '55 - 59',
      '60 - 61',
      '62 - 64',
      '65+',
    ].freeze

    GENDERS = [
      'Woman (Girl, if child)',
      'Man (Boy, if child)',
      'Culturally Specific Identity (e.g., Two-Spirit)',
      'Non-Binary',
      'Transgender',
      'Questioning',
      'Different Identity',
      'Client doesn\'t know',
      'Data not collected',
    ].freeze

    HOUSEHOLD_TYPES = [
      'Adult and Child Households',
      'Adult and Child Households With HoH 18-24',
      'Adult and Child Households With HoH 25+',
      'Adult only Households',
      'Child only Households',
      'Non-Veteran',
      'Veterans',
    ].freeze

    BARS = [
      'Current Period - Report Universe',
      'Comparison Period - Report Universe',
      'Current Period - Current Filters',
      'Comparison Period - Current Filters',
      'Current Period - Census',
      'Comparison Period - Census',
    ].freeze

    COLORS = [
      '#4093A5',
      '#4093A5',
      '#182E4E',
      '#182E4E',
      '#EE7850',
      '#EE7850',
    ].freeze

    BAR_HEIGHT = 10
    PADDING = 3
    RATIO = 0.6

    INVESTIGATE_BY = {
      race: RACES,
      age: AGES,
      gender: GENDERS,
      household_type: HOUSEHOLD_TYPES,
    }.freeze

    def data(key)
      groups = INVESTIGATE_BY[key]
      x = [['x'] + groups]
      {
        columns: x + BARS.map { |bar| [bar] + groups.map { |_| rand(100) } },
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
      }
    end

    def data_height(key)
      groups = INVESTIGATE_BY[key]
      bars = BARS.count * (BAR_HEIGHT + PADDING)
      total = bars / RATIO
      groups.count * total
    end

    def race_data_height
      data_height(:race)
    end

    def race_data
      data(:race)
    end

    def age_data_height
      data_height(:age)
    end

    def age_data
      data(:age)
    end

    def gender_data_height
      data_height(:gender)
    end

    def gender_data
      data(:gender)
    end

    def household_type_data_height
      data_height(:household_type)
    end

    def household_type_data
      data(:household_type)
    end
  end
end
