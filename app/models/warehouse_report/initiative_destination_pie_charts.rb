###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class WarehouseReport::InitiativeDestinationPieCharts
  attr_accessor :projects, :project_types
  def initialize(data, report_range, comparison_range)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
    @permanent_destinations = HUD.permanent_destinations
    @temporary_destinations = HUD.temporary_destinations
    @institutional_destinations = HUD.institutional_destinations
    @other_destinations = HUD.other_destinations
    @ranges = {
      report: report_range,
      comparison: comparison_range,
    }
  end

  def chart_id(by, period)
    "d3-dc-by-#{by}-for-#{period}__chart"
  end

  def table_id(by, period)
    "d3-dc-by-#{by}-for-#{period}__table"
  end

  def legend_id(by, period)
    "d3-dc-by-#{by}-for-#{period}__legend"
  end

  def collapse_id(by, period)
    "d3-dc-by-#{by}-for-#{period}__collapse"
  end

  def bucket_template
    { Permanent: { total: 0 }, Temporary: { total: 0 }, Institutional: { total: 0 }, Other: { total: 0 } }
  end

  def build_by_project_type_data(period)
    m = 'destination_breakdowns_by_project_type'
    m = (period == :comparison ? "comparison_#{m}" : m).to_sym
    data = @data[m] || {}
    # test data
    # update project types to match your project types
    # data = JSON.parse('{"ES__30": 5,"Services Only__30":1,"PH__22":2,"Other__22":5,"Services Only__1":4,"PH__10":3,"Services Only__10":3,"PH__31":1,"PH__20":2,"PH__30":2,"Services Only__11":1,"Services Only__31":1,"PH__17":1, "PH__29":1}')
    buckets = bucket_template
    buckets.each_key do |bk|
      @project_types.each do |pt|
        buckets[bk][pt] = 0
      end
    end
    data.each do |k, count|
      (project_type, destination) = k.split('__')
      case destination.to_i
      when *@permanent_destinations
        buckets[:Permanent][project_type] += count
        buckets[:Permanent][:total] += count
      when *@temporary_destinations
        buckets[:Temporary][project_type] += count
        buckets[:Temporary][:total] += count
      when *@institutional_destinations
        buckets[:Institutional][project_type] += count
        buckets[:Institutional][:total] += count
      when *@other_destinations
        buckets[:Other][project_type] += count
        buckets[:Other][:total] += count
      end
    end
    buckets == bucket_template ? {} : buckets
  end

  def build_by_project_data(period)
    m = 'destination_breakdowns_by_project'
    m = (period == :comparison ? "comparison_#{m}" : m).to_sym
    data = @data[m] || {}
    # test data
    # update ids to match your project ids
    # data = JSON.parse('{"2__30":2,"2__20":2,"2__31":1,"115__31":1,"115__30":1,"69__10":2,"115__1":4,"116__10":1,"115__11":1,"2__10":2,"2__17":1,"2__22":2,"115__10":1,"113__10":1,"113__22":1,"26__30":2,"26__20":2,"26__31":1}')
    buckets = bucket_template
    if data.present?
      @projects.each do |(p_id, _p_name)|
        buckets.each do |k, _|
          buckets[k][p_id] ||= 0
        end
      end
    end
    data.each do |k, count|
      (project_id, destination) = k.split('__')
      case destination.to_i
      when *@permanent_destinations
        buckets[:Permanent][project_id] += count
        buckets[:Permanent][:total] += count
      when *@temporary_destinations
        buckets[:Temporary][project_id] += count
        buckets[:Temporary][:total] += count
      when *@institutional_destinations
        buckets[:Institutional][project_id] += count
        buckets[:Institutional][:total] += count
      when *@other_destinations
        buckets[:Other][project_id] += count
        buckets[:Other][:total] += count
      end
    end
    name_buckets = {}
    buckets.each_key do |bk|
      name_buckets[bk] = { total: buckets[bk][:total] }
      @projects.each do |p_id, p_name|
        name_buckets[bk][p_name] = buckets[bk][p_id]
      end
    end
    buckets == bucket_template ? {} : name_buckets
  end

  def chart_data(by, period)
    m = "build_by_#{by}_data".to_sym
    d = send(m, period)
    keys = by == :project_type ? @project_types : @projects.map { |_id, name| name }
    { data: d, keys: keys }
  end
end
