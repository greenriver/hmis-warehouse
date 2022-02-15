###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::InitiativeIncomePieCharts
  attr_accessor :projects, :project_types
  def initialize(data, report_range, comparison_range)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types

    @income_buckets = GrdaWarehouse::Hud::IncomeBenefit.income_ranges

    @ranges = {
      report: report_range,
      comparison: comparison_range,
    }
  end

  def chart_data(data_type, by, _period)
    m = "build_by_#{by}_data".to_sym
    d = send(m, data_type)
    keys = by == :project_type ? @project_types : @projects.map { |_id, name| name }
    { data: d, keys: keys }
  end

  def chart_id(data_type, by, period)
    "d3-#{data_type}-by-#{by}-for-#{period}__chart"
  end

  def table_id(data_type, by, period)
    "d3-#{data_type}-by-#{by}-for-#{period}__table"
  end

  def legend_id(data_type, by, period)
    "d3-#{data_type}-by-#{by}-for-#{period}__legend"
  end

  def collapse_id(data_type, by, period)
    "d3-#{data_type}-by-#{by}-for-#{period}__collapse"
  end

  def bucket_template
    template = {}
    @income_buckets.each do |_id, values|
      template[values[:name]] = { total: 0 }
    end
    template
  end

  def select_data(data_type, period)
    m = "#{data_type}_by_#{period}"
    m = (period == :comparison ? "comparison_#{m}" : m).to_sym
    @data[m] || {}
  end

  def build_by_project_type_data(data_type)
    data = select_data(data_type, :project_type)
    buckets = bucket_template
    @project_types.each do |p_type|
      @income_buckets.each do |id, income|
        data_key = "#{p_type}__#{id}"
        buckets[income[:name]][p_type] = data[data_key]
        buckets[income[:name]][:total] += (data[data_key] || 0)
      end
    end
    buckets
  end

  def build_by_project_data(data_type)
    data = select_data(data_type, :project)
    buckets = bucket_template
    @projects.each do |p_id, p_name|
      @income_buckets.each do |id, income|
        data_key = "#{p_id}__#{id}"
        buckets[income[:name]][p_name] = data[data_key]
        buckets[income[:name]][:total] += (data[data_key] || 0)
      end
    end
    buckets
  end
end
