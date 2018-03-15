class WarehouseReport::InitiativeMmBarCharts

  DATA_TYPES = [
    :length_of_stay_breakdowns
  ]

  PERIODS = [
    :report,
    :comparison
  ]

  TYPES = [
    :mean,
    :median
  ]

  def initialize(data)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
  end

  def chart_title(type)
    if type == :mean
      "Report Period Mean vs. Comparison Period Mean"
    else
      "Report Period Median vs. Comparison Period Median"
    end
  end

  def table_rows(by)
    PERIODS
  end

  def empty?(data_type, by, period)
    false
  end

  def chart_id(data_type, calc, by)
    "d3-#{data_type.to_s}-#{calc.to_s}-by-#{by.to_s}__chart"
  end

  def legend_id(data_type, by)
    "d3-#{data_type.to_s}-mm-by-#{by.to_s}__legend"
  end

  def collapse_id(data_type, by)
    "d3-#{data_type.to_s}-mm-by-#{by.to_s}__collapse"
  end

  def table_id(data_type, by)
    "d3-#{data_type.to_s}-mm-by-#{by.to_s}__table"
  end

  def chart_data(data_type, by)
    m = "build_data_by_#{by.to_s}".to_sym
    send(m, data_type)
  end

  def charts(data_type, by)
    charts = {}
    chart_data = chart_data(data_type, by)
    TYPES.each do |type|
      data = {
        data: chart_data[:counts][type],
        types: chart_data[:types],
        values: chart_data[:values],
        keys: chart_data[:keys],
        labels: chart_data[:labels]
      }
      charts[type]=data
    end
    charts
  end

  def select_data(data_type, by, period)
    m = "#{data_type.to_s}_by_#{by.to_s}".to_sym
    if period == :comparison
      m = "all_comparison_#{m}"
    else
      m = "all_#{m}"
    end
    @data.send(m) || {}
  end

  def mean(values)
    (values.sum.to_f/values.length).round rescue 0
  end

  def median(values)
    mid = values.size / 2
    sorted = values.sort
    values.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2
  end

  def stack_keys(data_type, by)
    by == :project_type ? @project_types : @projects.map{|p_id, p_name| p_name }
  end

  def chart_data_template
    {counts: {mean:[], median:[]}, types: [], values: [], keys: []}
  end

  def build_data_by_project_type(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project_type, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project_type)
    TYPES.each do |type|
      period_data.each_with_index do |data, index|
        p = PERIODS[index] 
        d = {type: p.to_s}
        stack_keys.each do |sk|
          d[sk] = 0
        end
        data.keys.each do |pt_id|
          pt = ::HUD.project_type_brief(pt_id.to_i)
          d[pt] = send(type, data[pt_id])
          chart_data[:values].push(d[pt])
        end
        chart_data[:counts][type].push(d)
      end
    end
    chart_data[:types] = PERIODS
    chart_data[:keys] = stack_keys
    chart_data[:labels] = {}
    stack_keys.each do |k|
      chart_data[:labels][k] = k
    end
    chart_data
  end

  def build_data_by_project(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project)
    TYPES.each do |type|
      period_data.each_with_index do |data, index|
        p = PERIODS[index] 
        d = {type: p.to_s}
        @projects.each do |p_id, p_name|
          values = data[p_id] || [0]
          d[p_name] = send(type, values)
          chart_data[:values].push(d[p_name])
        end
        chart_data[:counts][type].push(d)
      end
    end
    chart_data[:types] = PERIODS
    chart_data[:keys] = stack_keys
    chart_data[:labels] = {}
    stack_keys.each do |k|
      chart_data[:labels][k] = k
    end
    chart_data
  end

end