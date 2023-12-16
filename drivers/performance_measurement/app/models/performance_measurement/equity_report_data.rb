module PerformanceMeasurement
  class EquityReportData
    BARS = [
      'Current Period - Report Universe',
      'Comparison Period - Report Universe',
      'Current Period - Current Filters',
      'Comparison Period - Current Filters',
      # 'Current Period - Census',
      # 'Comparison Period - Census',
    ].freeze

    METRICS = [
      'Number of Homeless People Seen on Jan 26, 2022',
      'Number of Homeless People Seen Throughout the Year',
      'Number of First-Time Homeless People',
      'Average Bed Utilization Overall',
      'Length of Time Homeless in ES, SH and TH',
      'Length of Time Homeless in ES, SH, TH, and PH',
      'Length of Homeless Stay',
      'Length of Time to Move-In',
      'Percentage of People with a Successful Placement or Retention of Housing',
      'Percentage of People Who Returned to Homelessness Within Two Years',
      'Number of People with Increased Income',
    ].freeze

    RACES = HudUtility2024.races

    AGES = Filters::FilterBase.available_age_ranges

    GENDERS = HudUtility2024.genders

    GENDER_ID_TO_SCOPE = {
      0 => :gender_woman,
      1 => :gender_man,
      2 => :gender_culturally_specific,
      4 => :gender_non_binary,
      5 => :gender_transgender,
      6 => :gender_questioning,
      3 => :gender_different_identity,
      8 => :gender_unknown,
      9 => :gender_unknown,
      99 => :gender_unknown,
    }.freeze

    # FIXME Fake data
    HOUSEHOLD_TYPES = [
      'Adult and Child Households',
      'Adult and Child Households With HoH 18-24',
      'Adult and Child Households With HoH 25+',
      'Adult only Households',
      'Child only Households',
      'Non-Veteran',
      'Veterans',
    ].freeze

    INVESTIGATE_BY = {
      race: RACES,
      age: AGES,
      gender: GENDERS,
      household_type: HOUSEHOLD_TYPES,
    }.freeze

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

    MIN_HEIGHT = 200

    def initialize(builder)
      @builder = builder
      @params = builder.params
      @report = builder.report
    end

    def age_params
      (@builder.age || []).map(&:to_sym)
    end

    def gender_params
      (@builder.gender || []).map(&:to_i).map { |id| gender_value_to_scope(id) }.reject(&:nil?)
    end

    def gender_value_to_scope(value)
      GENDER_ID_TO_SCOPE[value]
    end

    def race_params
      (@builder.race || []).map { |d| race_value_to_scope(d) }
    end

    def race_value_to_scope(value)
      value.underscore.include?('race') ? value.underscore.to_sym : "race_#{value.underscore}".to_sym
    end

    def household_type_params
      # FIXME fake data
      @builder.household_type || []
    end

    def data_groups
      # implement in subclass
      []
    end

    def bar_data(*)
      # implement in subclass
      0
    end

    def metric_scope
      # TODO apply selected metric to the initial scope
      @report.clients
    end

    def data
      # implement in subclass
      x = [['x'] + data_groups]
      {
        columns: x + BARS.map { |bar| [bar] + data_groups.map { |group| bar_data(universe: bar, metric: group) } },
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
      }
    end

    def apply_params(scope, period)
      if age_params.any?
        age_ranges = age_params.map { |d| Filters::FilterBase.age_range(d) }
        scope = scope.where("#{period}_age" => age_ranges)
      end
      # FIXME: should there be different values (reporting/comparison) for these
      scope = gender_params[1..].inject(scope.send(gender_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if gender_params.any?
      # FIXME: should there be different values (reporting/comparison) for these
      scope = race_params[1..].inject(scope.send(race_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if race_params.any?
      scope
    end

    def chart_height
      calculate_height(data_groups)
    end

    def calculate_height(groups)
      bars = BARS.count * (BAR_HEIGHT + PADDING)
      total = bars / RATIO
      height = groups.count * total
      height < MIN_HEIGHT ? MIN_HEIGHT : height
    end
  end
end
