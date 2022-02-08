###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

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
    :client_counts,
  ].freeze

  PERIODS = [
    :report,
    :comparison,
  ].freeze

  def initialize(data, report_range, comparison_range)
    @data = data
    @projects = @data.involved_projects.sort_by(&:last)
    @project_types = @data.involved_project_types
    @ranges = {
      report: report_range,
      comparison: comparison_range,
    }
  end

  def chart_title(period)
    dates = "(#{@ranges[period].first.to_date} to #{@ranges[period].last.to_date}"
    "#{period.to_s.titleize} Period #{dates})"
  end

  def table_rows(by)
    by == :project_type ? @project_types : @projects.map { |_p_id, p_name| p_name }
  end

  def periods
    PERIODS
  end

  def chart_data(data_type, by)
    m = "build_data_by_#{by}".to_sym
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
        labels: chart_data[:labels],
        support_keys: chart_data[:support_keys],
      }
      charts[period] = data
    end
    charts
  end

  def legend_id(data_type, by)
    "d3-#{data_type}-by-#{by}__legend"
  end

  def chart_id(data_type, period, by)
    "d3-#{data_type}-#{period}-by-#{by}__chart"
  end

  def collapse_id(data_type, by)
    "d3-#{data_type}-by-#{by}__collapse"
  end

  def table_id(data_type, by)
    "d3-#{data_type}-by-#{by}__table"
  end

  def support_section(data_type, by)
    "#{data_type}_by_#{by}".parameterize.underscore
  end

  def empty?(data_type, by, period)
    select_data(data_type, by, period).empty?
  end

  def stack_keys(data_type, by)
    keys = {
      gender_breakdowns: @data.involved_genders,
      veteran_breakdowns: ::HUD.no_yes_reasons_for_missing_data_options.map { |_id, reason| reason },
      ethnicity_breakdowns: ::HUD.ethnicities.map { |_id, value| value },
      race_breakdowns: ::HUD.races.map { |_id, value| value.downcase.gsub(' ', '_') },
      age_breakdowns: age_breakdowns_stack_keys(by),
      length_of_stay_breakdowns: GrdaWarehouse::Hud::Enrollment.lengths_of_stay.map { |l_key, _| l_key.to_s },
      living_situation_breakdowns: living_situation_stack_keys(by),
      income_at_entry_breakdowns: GrdaWarehouse::Hud::IncomeBenefit.income_ranges.map { |i_key, _income_bucket| i_key.to_s },
      income_most_recent_breakdowns: GrdaWarehouse::Hud::IncomeBenefit.income_ranges.map { |i_key, _income_bucket| i_key.to_s },
      destination_breakdowns: destination_breakdowns_stack_keys(by),
      zip_breakdowns: @data.involved_zipcodes.select(&:present?).map { |z| z.split('-')[0] },
      client_counts: ['count'],
    }
    keys[data_type] || []
  end

  private

  def select_data(data_type, by, period)
    m = "#{data_type}_by_#{by}".to_sym
    m = "comparison_#{m}" if period == :comparison
    @data.send(m) || {}
  end

  def destination_breakdowns_stack_keys(by)
    (select_data(:destination_breakdowns, by, :report).select { |_k, v| v.positive? }.keys + select_data(:destination_breakdowns, by, :comparison).select { |_k, v| v.positive? }.keys).
      map do |key|
        key.split('__')[1]
      end.
      uniq
  end

  def living_situation_stack_keys(by)
    (select_data(:living_situation_breakdowns, by, :report).select { |_k, v| v.positive? }.keys + select_data(:living_situation_breakdowns, by, :comparison).select { |_k, v| v.positive? }.keys).
      map do |key|
        key.split('__')[1]
      end.
      uniq.
      select(&:present?)
  end

  def age_breakdowns_stack_keys(by)
    (select_data(:age_breakdowns, by, :report).select { |_k, v| v.positive? }.keys + select_data(:age_breakdowns, by, :comparison).select { |_k, v| v.positive? }.keys).
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
        select { |_age_key, age_bucket| age_bucket[:name].parameterize.underscore == key }.
        map { |_age_key, age_bucket| age_bucket[:name] }.
        first
    elsif data_type == :length_of_stay_breakdowns
      key.humanize.titleize
    elsif data_type.in?([:income_at_entry_breakdowns, :income_most_recent_breakdowns])
      GrdaWarehouse::Hud::IncomeBenefit.income_ranges.
        select { |i_key, _i_bucket| i_key.to_s == key }.
        map { |_i_key, i_bucket| i_bucket[:name] }.
        first
    elsif data_type == :destination_breakdowns
      ::HUD.valid_destinations.select { |id, _value| key == id.to_s }.
        map { |_id, value| value }.first
    else
      key
    end
  end

  def chart_data_template
    { counts: { report: [], comparison: [] }, types: [], values: [], keys: [], support_keys: {} }
  end

  def build_data_by_project_type(data_type)
    period_data = PERIODS.map { |p| select_data(data_type, :project_type, p) }
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project_type).reject(&:blank?)
    @project_types.each do |k|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = { type: k }
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{k}__#{sk}"] || 0)
          chart_data[:values].push(d[sk.parameterize])
          chart_data[:support_keys][k] ||= {}
          chart_data[:support_keys][k][sk.parameterize] = "#{k}__#{sk}"
        end
        chart_data[:counts][period].push(d)
      end
    end
    chart_data[:types] = @project_types
    chart_data[:labels] = {}
    stack_keys.each do |k|
      key = k.parameterize
      chart_data[:keys] << key
      chart_data[:labels][key] = label(data_type, k)
    end
    chart_data
  end

  def build_data_by_project(data_type)
    period_data = PERIODS.map { |p| select_data(data_type, :project, p) }
    chart_data = chart_data_template
    stack_keys = stack_keys(data_type, :project).reject(&:blank?)
    @projects.each do |p_id, p_name|
      period_data.each_with_index do |data, index|
        period = PERIODS[index]
        d = { type: p_name }
        stack_keys.each do |sk|
          d[sk.parameterize] = (data["#{p_id}__#{sk}"] || 0)
          chart_data[:values].push(d[sk.parameterize])
          chart_data[:support_keys][p_name] ||= {}

          chart_data[:support_keys][p_name][sk.parameterize] = "#{p_id}__#{sk}"
        end
        chart_data[:counts][period].push(d)
      end
    end
    chart_data[:types] = @projects.map { |_p_id, p_name| p_name }
    chart_data[:keys] = stack_keys.map(&:parameterize)
    chart_data[:labels] = {}
    stack_keys.each do |k|
      chart_data[:labels][k.parameterize] = label(data_type, k)
    end
    chart_data
  end
end
