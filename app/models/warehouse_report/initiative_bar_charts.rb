class WarehouseReport::InitiativeBarCharts

  DATA_TYPES = [
    :gender_breakdowns,
    :veteran_breakdowns,
    :ethnicity_breakdowns,
    :race_breakdowns
  ]

  PERIODS = [
    :report,
    :comparison
  ]

  COLORS = {
    gender_breakdowns: ['#F6C9CA', '#96ADD4'],
    veteran_breakdowns: ['#D2D7D9', '#F2AE2E', '#BF8049', '#734B43', '#8C3D2B'],
    ethnicity_breakdowns: ['red', 'purple', 'yellow', 'pink', 'green', 'orange'],
    race_breakdowns: ['orange', 'green', 'purple', 'pink', 'blue', 'green']
  }

  def initialize(data)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
  end

  def periods
    PERIODS
  end

  def chart_data(data_type, by)
    m = "build_data_by_#{by.to_s}".to_sym
    send(m, data_type)
  end

  def charts(data_type, by)
    charts = {}
    chart_data = chart_data(data_type, by)
    PERIODS.each do |period|
      data = {
        data: chart_data[:counts][period],
        types: chart_data[:types], 
        values: chart_data[:values],
        keys: chart_data[:keys],
        colors: chart_data[:colors]
      }
      charts[period]=data
    end
    charts
  end

  def legend_id(data_type, by)
    "d3-#{data_type.to_s}-by-#{by.to_s}__legend"
  end

  def chart_id(data_type, period, by)
    "d3-#{data_type.to_s}-#{period.to_s}-by-#{by.to_s}__chart"
  end

  private

  def select_data(data_type, by, period)
    m = "#{data_type.to_s}_by_#{by.to_s}".to_sym
    if period == :comparison
      m = "comparison_#{m}"
    end
    @data.send(m) || {}
  end

  def stack_keys(data_type)
    keys = {
      gender_breakdowns: @data.involved_genders,
      veteran_breakdowns: ::HUD.no_yes_reasons_for_missing_data_options.map{|id, reason| reason},
      ethnicity_breakdowns: ::HUD.ethnicities.map{|id, value| value},
      race_breakdowns: ::HUD.races.map{|id, value| value.downcase.gsub(' ', '_')}
    }
    keys[data_type] || []
  end

  def chart_data_template
    {counts: {report:[], comparison:[]}, types: [], values: [], keys: []}
  end

  def build_data_by_project_type(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project_type, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type)
    @project_types.each do |k|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = {type: k}
        values = []
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{k}__#{sk}"]||0)
          values.push(d[sk.parameterize])
        end
        chart_data[:counts][period].push(d)
        chart_data[:values].push(values.inject(0, :+))
      end
    end
    chart_data[:types] = @project_types
    chart_data[:keys] = stack_keys.map(&:parameterize)
    chart_data[:colors] = COLORS[data_type]
    chart_data
  end

  def build_data_by_project(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type)
    @projects.each do |p_id, p_name|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = {type: p_name}
        values = []
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{p_id}__#{sk}"]||0)
          values.push(d[sk.parameterize])
        end
        chart_data[:counts][period].push(d)
        chart_data[:values].push(values.inject(0, :+))
      end
    end
    chart_data[:types] = @projects.map{|p_id, p_name| p_name}
    chart_data[:keys] = stack_keys.map(&:parameterize)
    chart_data[:colors] = COLORS[data_type]
    chart_data
  end

end