###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class ProcessController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_range

    def index
      @range = ::Filters::DateRange.new(date_range_options)
      @step_range = ::Filters::StepRange.new(step_params)

      @matches = step_times(@step_range)
      @all_steps = report_source.
        where(match_id: @matches.keys).
        order(decision_order: :asc).
        group_by(&:match_id)

      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'CAS Match Process.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    def set_range
      date_range_options = params.permit(range: [:start, :end])[:range]
      unless date_range_options.present?
        date_range_options = {
          start: 13.month.ago.to_date,
          end: 1.months.ago.to_date,
        }
      end
      @range = ::Filters::DateRange.new(date_range_options)
    end

    def report_source
      GrdaWarehouse::CasReport
    end

    private def step_params
      return {} unless params.key? :steps

      params.require(:steps).permit(:route, :first_step, :second_step, :unit)
    end

    def date_range_options
      options = params.permit(steps: [:start, :end])[:steps]
      unless options.present?
        options = {
          start: 12.month.ago.to_date,
          end: Date.current,
        }
      end
      options
    end

    def step_times(step_range)
      first_step  = step_range.first_step.gsub(/\(\d+\)/, '').strip
      second_step = step_range.second_step.gsub(/\(\d+\)/, '').strip
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
      query = at.where(at[:match_started_at].between(@range.start..@range.end + 1.day)).
        join(at2).on(at[:client_id].eq(at2[:client_id]).
          and(at[:match_id].eq(at2[:match_id])).
          and(at[:match_step].eq(first_step)).
          and(at2[:match_step].eq(second_step))).
        where(at2[:match_started_at].between(@range.start..@range.end + 1.day)).
        project(
          seconds_diff(GrdaWarehouse::CasReport, at2[:updated_at], at[:updated_at]),
          at[:match_id],
          at[:program_name],
          at[:sub_program_name],
          at[:match_started_at],
          at[:match_route],
          at[:client_id],
          at[:cas_client_id],
          at[:source_data_source],
        )
      GrdaWarehouse::CasReport.connection.select_rows(query.to_sql).map do |row|
        h = Hash[[:days, :id, :program_name, :sub_program_name, :match_started_at, :match_route, :client_id, :cas_client_id, :source_data_source].zip(row)]
        h[:days] = (h[:days].to_f / divisor).round.to_i
        ::OpenStruct.new(h)
      end.index_by(&:id)
    end
  end
end
