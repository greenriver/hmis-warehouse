module PerformanceMeasurement
  class EquityReportData
    include ArelHelper

    BARS = [
      'Current Period - Report Universe',
      'Comparison Period - Report Universe',
      'Current Period - Current Filters',
      'Comparison Period - Current Filters',
      # 'Current Period - Census',
      # 'Comparison Period - Census',
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
      value.underscore.include?('race') ? value.underscore.to_sym : "race_#{value.underscore}".to_sym
    end

    def household_type_params
      # FIXME fake data
      @builder.household_type || []
    end

    def project_type_params
      @builder.project_type.map(&:to_i)
    end

    def project_params
      @builder.project.map(&:to_i)
    end

    def view_by_params
      @builder.view_data_by
    end

    def universe_period(universe)
      universe.include?('Current Period') ? 'reporting' : 'comparison'
    end

    def metric_scope(period)
      # FIXME: we may need to hide other parts of the form until metric is selected? Other things depend on this (project).
      metric_params.present? ? @report.clients_for_question(metric_params, period.to_sym) : @report.clients
    end

    def percentage_denominator(period, _investigate_by)
      return metric_scope(period).select(:client_id).distinct.count
      # FIXME: Not sure if this is correct
      # case period
      # when 'reporting'
      #   @report.client_projects.where(period: period).count
      # when 'comparison'
      #   # TODO: apply filters to this?
      #   # FIXME: I think this is wrong???
      #   client_ids = apply_params(client_scope(period, investigate_by), period).map(&:client_id)
      #   @report.client_projects.where(period: period).where(client_id: client_ids).count
      # end
    end

    def client_scope(period, _)
      # implement in subclass
      metric_scope(period)
    end

    def build_data
      {
        columns: [],
        ordered_keys: BARS,
        colors: BARS.map.with_index { |bar, i| [bar, COLORS[i]] }.to_h,
        view_by: view_by_params,
      }
    end

    def data
      # implement in subclass
      build_data
    end

    def bar_data(universe: nil, investigate_by: nil)
      period = universe_period(universe)
      scope = case universe
      when 'Current Period - Report Universe'
        client_scope(period, investigate_by)
      when 'Comparison Period - Report Universe'
        client_scope(period, investigate_by)
      when 'Current Period - Current Filters'
        apply_params(
          client_scope(period, investigate_by),
          period,
        )
      when 'Comparison Period - Current Filters'
        apply_params(
          client_scope(period, investigate_by),
          period,
        )
      end
      apply_view_by_params(scope.count, period, investigate_by)
    end

    def apply_view_by_params(count, period, investigate_by)
      case view_by_params
      when 'percentage'
        (count.to_f / percentage_denominator(period, investigate_by) * 100).round
      when 'count'
        count
      when 'rate'
        # FIXME
        (count.to_f / percentage_denominator(period, investigate_by) * 10_000).round
      end
    end

    def apply_params(scope, period)
      if age_params.any?
        age_ranges = age_params.map { |d| Filters::FilterBase.age_range(d) }
        scope = scope.where("#{period}_age" => age_ranges)
      end
      # FIXME: double check the stuff below
      scope = gender_params[1..].inject(scope.send(gender_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if gender_params.any?
      scope = race_params[1..].inject(scope.send(race_params[0])) { |query, scope_name| query.or(scope.send(scope_name)) } if race_params.any?
      scope = scope.joins(client_projects: { project: :hud_project }).where(p_t[GrdaWarehouse::Hud::Project.project_type_column].in(project_type_params)) if project_type_params.any?
      scope = scope.joins(:client_projects).merge(PerformanceMeasurement::ClientProject.where(project_id: project_params)) if project_params.any?
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
