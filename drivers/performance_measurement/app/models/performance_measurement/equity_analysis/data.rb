module PerformanceMeasurement::EquityAnalysis
  class Data
    include ArelHelper
    include GrdaWarehouse::UsCensusApi::Aggregates

    RACES = HudUtility2024.races
    AGES = Filters::FilterBase.available_census_age_ranges
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

    HOUSEHOLD_TYPES = HudUtility2024.household_types.merge(nil => 'Unknown household type')

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

    def bars
      [
        'Current Period - Report Universe',
        'Comparison Period - Report Universe',
        'Current Period - Current Filters',
        'Comparison Period - Current Filters',
        # TOOD: these don't quite behave correctly yet
        # 'Current Period - Census',
        # 'Comparison Period - Census',
      ].freeze
    end

    def metric_params
      @builder.metric
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
      return value.underscore.to_sym if value.underscore.starts_with?('race')

      "race_#{value.underscore}".to_sym
    end

    def household_type_params
      @builder.household_type.map(&:to_i) || []
    end

    def project_type_params
      @builder.project_type.map(&:to_i) || []
    end

    def project_params
      @builder.project.map(&:to_i) || []
    end

    def available_projects
      @available_projects ||= @report.projects.joins(:hud_project).map { |project| [project.id, project.pm_project.name] }.to_h
    end

    def view_by_params
      @builder.view_data_by
    end

    def universe_period(universe)
      return 'reporting' if universe.include?('Current Period')

      'comparison'
    end

    def metric_scope(period)
      return @report.clients_for_question(metric_params, period.to_sym) if metric_params.present?

      @report.clients
    end

    def percentage_denominator(period, _investigate_by)
      metric_scope(period).select(:client_id).distinct.count
    end

    def client_scope(period, _)
      metric_scope(period)
    end

    def build_data
      {
        columns: [],
        ordered_keys: bars,
        colors: bars.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
        view_by: view_by_params,
      }
    end

    def data
      build_data
    end

    def bar_data(universe: nil, investigate_by: nil)
      period = universe_period(universe)

      count = 0
      denominator = 0
      if universe.ends_with?('Report Universe')
        count = client_scope(period, investigate_by).count
        denominator = percentage_denominator(period, investigate_by)
      elsif universe.ends_with?('Current Filters')
        count = apply_params(
          client_scope(period, investigate_by),
          period,
        ).count
        denominator = percentage_denominator(period, investigate_by)
      elsif universe.ends_with?('Census')
        year = @report.filter.end.year
        year -= 1 if period == :comparison
        count = apply_census_params(investigate_by: investigate_by, year: year)
        denominator = overall_census_count(year: year)
      end
      apply_view_by_params(count, denominator)
    end

    def apply_view_by_params(count, denominator)
      case view_by_params
      when 'percentage'
        return 0 if count.zero? || denominator.zero?

        (count.to_f / denominator * 100).round
      when 'count'
        count
      when 'rate'
        return 0 if count.zero? || denominator.zero?

        (count.to_f / denominator * 10_000).round
      end
    end

    def apply_params(scope, period)
      if age_params.any?
        age_ranges = age_params.map { |d| Filters::FilterBase.age_range(d) }
        scope = scope.where("#{period}_age" => age_ranges)
      end
      scope = gender_params[1..].inject(scope.send(gender_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if gender_params.any?
      scope = race_params[1..].inject(scope.send(race_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if race_params.any?
      scope = scope.joins(client_projects: { project: :hud_project }).where(p_t[GrdaWarehouse::Hud::Project.project_type_column].in(project_type_params)) if project_type_params.any?
      scope = scope.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(project_id: project_params)) if project_params.any?
      scope = scope.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(household_type: household_type_params)) if household_type_params.any?
      scope
    end

    def chart_height
      calculate_height(data_groups)
    end

    def calculate_height(groups)
      bar_height = bars.count * (BAR_HEIGHT + PADDING)
      total = bar_height / RATIO
      height = groups.count * total
      [height, MIN_HEIGHT].max
    end

    private def apply_census_params(investigate_by:, year:)
      results = geometries.map do |geo|
        geo.population(internal_names: census_code(investigate_by), year: year)
      end

      results.each do |result|
        if result.error
          Rails.logger.error "population error: #{result.msg}. Sum won't be right!"
          return nil
        elsif result.year != year
          Rails.logger.warn "Using #{result.year} instead of #{year}"
        end
      end

      results.map(&:val).sum.round
    end

    private def race_census_code(code)
      case code
      when 'AmIndAKNative' then 'NATIVE_AMERICAN'
      when 'Asian' then 'ASIAN'
      when 'BlackAfAmerican' then 'BLACK'
      when 'NativeHIPacific' then 'PACIFIC_ISLANDER'
      when 'White' then 'WHITE'
      when 'RaceNone' then 'OTHER_RACE'
      when 'MultiRacial' then 'TWO_OR_MORE_RACES'
      when 'HispanicLatinaeo' then 'HISPANIC'
      when 'All' then 'ALL_PEOPLE'
      end
    end

    private def gender_census_code(code)
      case code
      when :gender_man then 'MALE'
      when :gender_woman then 'FEMALE'
      end
    end

    private def age_census_code(code)
      case code
      when :zero_to_four
        'AGE_0_4'
      when :five_to_nine
        'AGE_5_9'
      when :ten_to_fourteen
        'AGE_10_14'
      when :fifteen_to_seventeen
        'AGE_15_17'
      when :eighteen_to_twenty_four
        'AGE_18_24'
      when :twenty_five_to_thirty_four
        'AGE_25_34'
      when :thirty_five_to_forty_four
        'AGE_35_44'
      when :forty_five_to_fifty_four
        'AGE_45_54'
      when :fifty_five_to_sixty_four
        'AGE_55_64'
      when :sixty_five_to_seventy_four
        'AGE_65_74'
      when :seventy_five_to_eighty_four
        'AGE_75_84'
      when :eighty_five_plus
        'AGE_85_PLUS'
      end
    end

    private def census_code(investigate_by)
      # Determine which category investigate_by falls under, then
      # ignore those params, and convert investigate_by into a census variable
      codes = {
        race: [nil],
        gender: [nil],
        age: [nil],
      }
      case @builder.investigate_by
      when 'Race'
        codes[:race] << race_census_code(investigate_by)
        gender_params.each do |p|
          codes[:gender] << gender_census_code(p)
        end
        age_params.each do |p|
          codes[:age] << age_census_code(p)
        end
      when 'Gender'
        codes[:gender] << gender_census_code(investigate_by)
        race_params.each do |p|
          codes[:race] << race_census_code(p)
        end
        age_params.each do |p|
          codes[:age] << age_census_code(p)
        end
      when 'Age'
        codes[:age] << age_census_code(investigate_by)
        gender_params.each do |p|
          codes[:gender] << gender_census_code(p)
        end
        race_params.each do |p|
          codes[:race] << race_census_code(p)
        end
      end

      # aggregates format is race, sex, age
      census_codes = []
      codes[:race].each do |r|
        codes[:gender].each do |g|
          codes[:age].each do |a|
            const_name = [r, g, a].compact.join('_')
            next unless const_name.present?

            census_codes << GrdaWarehouse::UsCensusApi::Aggregates.const_get(const_name)
          end
        end
      end
      # return [NATIVE_AMERICAN_AGE_15_17]
      census_codes.uniq
    end

    # COC CODES
    private def geometries
      coc_code = @report.filter.coc_code
      # CoC code needs to be real, even in development to get census data
      coc_code = "#{GrdaWarehouse::Config.relevant_state_codes&.first}-500" if coc_code.starts_with?('XX')

      @geometries ||= GrdaWarehouse::Shape::Coc.where(cocnum: coc_code)
    end

    private def overall_census_count(year:)
      results = geometries.map do |geo|
        geo.population(year: year)
      end

      results.each do |result|
        if result.error
          Rails.logger.error "population error: #{result.msg}. Sum won't be right!"
          return nil
        elsif result.year != year
          Rails.logger.warn "Using #{result.year} instead of #{year}"
        end
      end

      results.map(&:val).sum.round
    end
  end
end
