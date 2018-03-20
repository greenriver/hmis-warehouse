class WarehouseReport::InitiativeNcLineCharts

  PERIODS = [
    :report,
    :comparison
  ]

  def initialize(data, report_range, comparison_range)
    @data = data
    @report_range = report_range
    @comparison_ranage = comparison_range
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
  end

  def table_rows(by)
    by == :project_type ? @project_types : @projects.map{|p_id, p_name| p_name}
  end

  def charts(data_type, by)
    chart_data(data_type, by)
  end

  def chart_data(data_type, by)
    m = "build_data_by_#{by.to_s}".to_sym
    send(m, data_type)
  end

  def chart_id(by, period)
    "d3-nc-by-#{by.to_s}__#{period.to_s}__chart"
  end

  def legend_id(by, period)
    "d3-nc-by-#{by.to_s}-#{period.to_s}__legend"
  end

  def collapse_id(by, period)
    "nc-by-#{by.to_s}-#{period.to_s}__collapse"
  end

  def table_id(by, period)
    "d3-nc-by-#{by.to_s}-#{period.to_s}__table"
  end

  def select_data(data_type, by, period)
    m = "#{data_type.to_s}_by_#{by.to_s}"
    if period == :comparison
      m = "comparison_#{m}"
    end
    @data.send(m.to_sym) || {}
  end

  def load_range(period)
    period == :report ? @report_range : @comparison_ranage
  end

  def chart_data_template
    {report: [], comparison: []}
  end

  def build_data_by_project_type(data_type)
    chart_data = chart_data_template
    PERIODS.each do |p|
      data = select_data(data_type, :project_type, p)
      @project_types.each do |pt|
        load_range(p).each do |date|
          key = "#{pt}__#{date}"
          d = data[key] || 0
          chart_data[p].push([pt, date, d])
        end
      end
    end
    chart_data
  end

  def build_data_by_project(data_type)
    chart_data = chart_data_template
    PERIODS.each do |p|
      data = select_data(data_type, :project, p)
      @projects.each do |p_id, p_name|
        load_range(p).each do |date|
          key = "#{p_id}__#{date}"
          d = data[key] || 0
          chart_data[p].push([p_name, date, d])
        end
      end
    end
    chart_data
  end

end