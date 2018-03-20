class WarehouseReport::InitiativeBarCharts

  DATA_TYPES = [
    :gender_breakdowns,
    :veteran_breakdowns,
    :ethnicity_breakdowns,
    :race_breakdowns,
    :age_breakdowns,
    :length_of_stay_breakdowns,
    :living_situation_breakdowns,
    :income_at_entry_breakdowns,
    :income_most_recent_breakdowns,
    :destination_breakdowns,
    :zip_breakdowns,
    :client_counts
  ]

  PERIODS = [
    :report,
    :comparison
  ]

  def initialize(data)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
  end

  def chart_title(period)
    "#{period.to_s.titleize} Period"
  end

  def table_rows(by)
    by == :project_type ? @project_types : @projects.map{|p_id, p_name| p_name}
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
        labels: chart_data[:labels]
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

  def collapse_id(data_type, by)
    "d3-#{data_type.to_s}-by-#{by.to_s}__collapse"
  end

  def table_id(data_type, by)
    "d3-#{data_type.to_s}-by-#{by.to_s}__table"
  end

  def empty?(data_type, by, period)
    select_data(data_type, by, period).empty?
  end

  def stack_keys(data_type, by)
    keys = {
      gender_breakdowns: @data.involved_genders,
      veteran_breakdowns: ::HUD.no_yes_reasons_for_missing_data_options.map{|id, reason| reason},
      ethnicity_breakdowns: ::HUD.ethnicities.map{|id, value| value},
      race_breakdowns: ::HUD.races.map{|id, value| value.downcase.gsub(' ', '_')},
      age_breakdowns: age_breakdowns_stack_keys(by),
      length_of_stay_breakdowns: GrdaWarehouse::Hud::Enrollment.lengths_of_stay.map{|l_key, _| l_key.to_s},
      living_situation_breakdowns: living_situation_stack_keys(by),
      income_at_entry_breakdowns: GrdaWarehouse::Hud::IncomeBenefit.income_ranges.map{|i_key, income_bucket| i_key.to_s},
      income_most_recent_breakdowns: GrdaWarehouse::Hud::IncomeBenefit.income_ranges.map{|i_key, income_bucket| i_key.to_s},
      destination_breakdowns: destination_breakdowns_stack_keys(by),
      zip_breakdowns: @data.involved_zipcodes.select(&:present?).map{|z| z.split('-')[0]},
      client_counts: ['count']
    }
    keys[data_type] || []
  end

  private

  def select_data(data_type, by, period)
    m = "#{data_type.to_s}_by_#{by.to_s}".to_sym
    if period == :comparison
      m = "comparison_#{m}"
    end
    @data.send(m) || {}
  end

  def destination_breakdowns_stack_keys(by)
    (select_data(:destination_breakdowns, by, :report).select{|k, v| v > 0}.keys + select_data(:destination_breakdowns, by, :comparison).select{|k, v| v > 0}.keys).
      map do |key|
        key.split('__')[1]
      end.
      uniq
  end

  def living_situation_stack_keys(by)
    (select_data(:living_situation_breakdowns, by, :report).select{|k, v| v > 0}.keys + select_data(:living_situation_breakdowns, by, :comparison).select{|k, v| v > 0}.keys).
      map do |key|
        key.split('__')[1]
      end.
      uniq.
      select do |key|
        key.present?
      end
  end

  def age_breakdowns_stack_keys(by)
    (select_data(:age_breakdowns, by, :report).select{|k, v| v > 0}.keys + select_data(:age_breakdowns, by, :comparison).select{|k, v| v > 0}.keys).
      map do |key|
        key.split('__')[1]
      end.
      uniq.
      sort_by do |key|
        key.split('_')[0].to_i
      end
  end

  def label(data_type, key)
    if data_type == :race_breakdowns
      key.gsub('_', ' ').titleize
    elsif data_type == :age_breakdowns
      GrdaWarehouse::Hud::Client.extended_age_groups.
        select{|age_key, age_bucket| age_bucket[:name].parameterize.underscore == key}.
        map{|age_key, age_bucket| age_bucket[:name]}.
        first
    elsif data_type == :length_of_stay_breakdowns
      key.humanize.titleize
    elsif data_type == :income_at_entry_breakdowns || data_type == :income_most_recent_breakdowns
      GrdaWarehouse::Hud::IncomeBenefit.income_ranges.
        select{|i_key, i_bucket| i_key.to_s == key}.
        map{|i_key, i_bucket| i_bucket[:name]}.
        first 
    elsif data_type == :destination_breakdowns
      ::HUD.valid_destinations.select{|id, value| key == id.to_s}.
        map{|id, value| value}.first
    else
      key
    end
  end

  def chart_data_template
    {counts: {report:[], comparison:[]}, types: [], values: [], keys: []}
  end

  def build_data_by_project_type(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project_type, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project_type)
    @project_types.each do |k|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = {type: k}
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{k}__#{sk}"]||0)
          chart_data[:values].push(d[sk.parameterize])
        end
        chart_data[:counts][period].push(d)
      end
    end
    chart_data[:types] = @project_types
    chart_data[:keys] = stack_keys.map(&:parameterize)
    chart_data[:labels] = {}
    stack_keys.each do |k|
      chart_data[:labels][k.parameterize] = label(data_type, k)
    end
    chart_data
  end

  def build_data_by_project(data_type)
    period_data = PERIODS.map{|p| select_data(data_type, :project, p)}
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project)
    @projects.each do |p_id, p_name|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = {type: p_name}
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{p_id}__#{sk}"]||0)
          chart_data[:values].push(d[sk.parameterize])
        end
        chart_data[:counts][period].push(d)
      end
    end
    chart_data[:types] = @projects.map{|p_id, p_name| p_name}
    chart_data[:keys] = stack_keys.map(&:parameterize)
    chart_data[:labels] = {}
    stack_keys.each do |k|
      chart_data[:labels][k.parameterize] = label(data_type, k)
    end
    chart_data
  end

end