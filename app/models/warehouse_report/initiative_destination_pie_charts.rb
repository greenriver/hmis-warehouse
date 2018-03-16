class WarehouseReport::InitiativeDestinationPieCharts

  def initialize(data)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @permanent_destinations = HUD::permanent_destinations
    @temporary_destinations = HUD::temporary_destinations
    @institutional_destinations = HUD::institutional_destinations
    @other_destinations = HUD::other_destinations
  end

  def chart_id(by, period)
    "d3-dc-by-#{by.to_s}-for-#{period.to_s}__chart"
  end

  def bucket_template
    {permanent: {total: 0}, temporary: {total: 0}, institutional: {total: 0}, other: {total: 0}}
  end

  def build_by_project_type_data(period)
    m = "destination_breakdowns_by_project_type"
    m = (period == :comparison ? "comparison_#{m}" : m).to_sym
    data = @data[m] || {}
    # test data
    # update project types to match your project types
    # data = JSON.parse('{"Services Only__30":1,"PH__22":2,"Services Only__1":4,"PH__10":3,"Services Only__10":3,"PH__31":1,"PH__20":2,"PH__30":2,"Services Only__11":1,"Services Only__31":1,"PH__17":1, "PH__29":1}')
    buckets = bucket_template
    data.each do |k, count|
      (project_type, destination) = k.split('__')
      buckets.each do |k, _|
        buckets[k][project_type] ||= 0
      end
      case destination.to_i
      when *@permanent_destinations
        buckets[:permanent][project_type] += count
        buckets[:permanent][:total] += count
      when *@temporary_destinations
        buckets[:temporary][project_type] += count
        buckets[:temporary][:total] += count
      when *@institutional_destinations
        buckets[:institutional][project_type] += count
        buckets[:institutional][:total] += count
      when *@other_destinations
        buckets[:other][project_type] += count
        buckets[:other][:total] += count
      end
    end
    buckets == bucket_template ? {} : buckets
  end

  def build_by_project_data(period)
    m = "destination_breakdowns_by_project"
    m = (period == :comparison ? "comparison_#{m}" : m).to_sym
    data = @data[m] || {}
    # test data
    # update ids to match your project ids
    # data = JSON.parse('{"2__30":2,"2__20":2,"2__31":1,"115__31":1,"115__30":1,"69__10":2,"115__1":4,"116__10":1,"115__11":1,"2__10":2,"2__17":1,"2__22":2,"115__10":1}')
    buckets = bucket_template
    if data.present?
      @projects.each do |(p_id, p_name)|
        buckets.each do |k, _|
          buckets[k][p_id] ||= 0
        end
      end
    end
    data.each do |k, count|
      (project_id, destination) = k.split('__')
      case destination.to_i
      when *@permanent_destinations
        buckets[:permanent][project_id] += count
        buckets[:permanent][:total] += count
      when *@temporary_destinations
        buckets[:temporary][project_id] += count
        buckets[:temporary][:total] += count
      when *@institutional_destinations
        buckets[:institutional][project_id] += count
        buckets[:institutional][:total] += count
      when *@other_destinations
        buckets[:other][project_id] += count
        buckets[:other][:total] += count
      end
    end
    name_buckets = {}
    buckets.keys.each do |bk|
      name_buckets[bk] = {total: buckets[bk][:total]}
      @projects.each do |p_id, p_name|
        name_buckets[bk][p_name] = buckets[bk][p_id]
      end
    end
    buckets == bucket_template ? {} : name_buckets
  end

  def chart_data(by, period)
    m = "build_by_#{by.to_s}_data".to_sym
    send(m, period)
  end

end