###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class DecisionEfficiencyController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :filter

    def index
      @data = report_scope
    end

    private def filter
      @filter = ::Filters::StepRange.new(
        {
          start: 12.month.ago.to_date,
          end: Date.current,
        }.merge(step_params),
      )
    end

    # @data = {}
    # return unless @filter.first.present?

    # histogram = step_time_histogram(@filter)
    # @data[:labels] = histogram.keys
    # @data[:data_sets] = histogram.values.map(&:keys).flatten.uniq.map do |title|
    #   values = histogram.keys.map do |key|
    #     histogram[key].try(:[], title) || 0
    #   end
    #   [title, values]
    # end.to_h
    # n = histogram.values.map(&:values).flatten.sum
    # counts = []
    # histogram.values.map(&:values).map(&:sum).each_with_index do |count, index|
    #   counts << [index] * count
    # end
    # counts.flatten!
    # mean = (counts.sum.to_f / counts.length).round(2)
    # stddev = 0
    # counts.each do |point|
    #   stddev += (point - mean)**2
    # end
    # stddev /= counts.length - 1
    # stddev = Math.sqrt(stddev)
    # stddev = stddev.round(2)
    # @data[:stats] = {
    #   n: n,
    #   minimum: histogram.keys.first,
    #   maximum: histogram.keys.last,
    #   median: median(counts),
    #   mean: mean,
    #   standard_deviation: stddev,
    # }

    # def median(array)
    #   return 0 if array.empty?

    #   mid = array.size / 2
    #   sorted = array.sort
    #   array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2
    # end

    private def step_params
      return {} unless params.key? :steps

      params.require(:steps).permit(:first, :second, :unit, :route, :start, :end)
    end

    private def report_source
      GrdaWarehouse::CasReport
    end

    private def at
      @at ||= report_source.arel_table
    end

    private def at2
      @at2 ||= begin
        at2 = at.dup
        at2.table_alias = 'at2'
        at2
      end
    end

    private def report_scope
      query = at.where(at[:match_started_at].between(@filter.start..@filter.end + 1.day)).
        join(at2).on(
          at[:client_id].eq(at2[:client_id]).
          and(at[:match_id].eq(at2[:match_id])).
          and(at[:match_step].eq(first_step)).
          and(at2[:match_step].eq(second_step)),
        ).where(at2[:match_started_at].between(@filter.start..@filter.end + 1.day)).
        project(*columns.values)
      report_source.connection.select_rows(query.to_sql).map do |row|
        columns.keys.zip(row).to_h
      end
    end

    private def first_step
      @first_step ||= @filter.first.gsub(/\(\d+\)/, '').strip
    end

    private def second_step
      @second_step ||= @filter.second.gsub(/\(\d+\)/, '').strip
    end

    private def columns
      @columns ||= {
        match_route: at[:match_route],
        program_name: at[:program_name],
        sub_program_name: at[:sub_program_name],
        cas_client_id: at[:cas_client_id],
        warehouse_client_id: at[:client_id],
        match_id: at[:match_id],
        match_stated_at: at[:match_started_at],
        terminal_status: at[:terminal_status],
        first_id: at[:id],
        second_id: at2[:id],
        first_ended_at: at[:updated_at],
        second_ended_at: at2[:updated_at],
      }
    end

    # # creates a histogram mapping intervals to numbers of occurrences
    private def step_time_histogram(step_range)
      first_step  = step_range.first.gsub(/\(\d+\)/, '').strip
      second_step = step_range.second.gsub(/\(\d+\)/, '').strip
      unit        = step_range.unit
      divisor = case unit
      when 'second'
        1
      when 'minute'
        60
      when 'hour'
        60 * 60
      when 'day'
        24 * 60 * 60
      when 'week'
        7 * 24 * 60 * 60
      else
        raise "unanticipated time unit: #{unit}"
      end
      at = GrdaWarehouse::CasReport.arel_table
      at2 = at.dup
      at2.table_alias = 'at2'
      query = at.where(at[:match_started_at].between(@filter.start..@filter.end + 1.day)).
        join(at2).on(
          at[:client_id].eq(at2[:client_id]).
          and(at[:match_id].eq(at2[:match_id])).
          and(at[:match_step].eq(first_step)).
          and(at2[:match_step].eq(second_step)),
        ).where(at2[:match_started_at].between(@filter.start..@filter.end + 1.day)).
        project(
          seconds_diff(GrdaWarehouse::CasReport, at2[:updated_at], at[:updated_at]),
          at[:program_type],
        )
      times = GrdaWarehouse::CasReport.connection.select_rows(query.to_sql).map do |time_diff, program_type|
        [(time_diff.to_f / divisor).round.to_i, program_type]
      end
      return {} if times.empty?

      min, max = times.map { |secs, _| secs }.minmax
      histogram = times.group_by(&:first).map do |bucket, rows|
        grouped_counts = {}
        rows.each do |_, project_type|
          grouped_counts[bucket] ||= {}
          grouped_counts[bucket][project_type] ||= 0
          grouped_counts[bucket][project_type] += 1
        end
        [bucket, grouped_counts[bucket]]
      end.to_h
      (min..max).each { |v| histogram[v] ||= {} }
      histogram.sort_by(&:first).to_h
    end
  end
end
