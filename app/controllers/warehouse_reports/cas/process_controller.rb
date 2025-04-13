# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
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
      first_step  = step_range.first_step&.gsub(/\(\d+\)/, '')&.strip
      second_step = step_range.second_step&.gsub(/\(\d+\)/, '')&.strip
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

      sql = <<~SQL
        WITH step_times AS (
          SELECT
            EXTRACT(EPOCH FROM (t2.updated_at - t1.updated_at)) as time_diff,
            t1.match_id,
            t1.program_name,
            t1.sub_program_name,
            t1.match_started_at,
            t1.match_route,
            t1.client_id,
            t1.cas_client_id,
            t1.source_data_source
          FROM grda_warehouse_cas_reports t1
          JOIN grda_warehouse_cas_reports t2
            ON t1.client_id = t2.client_id
            AND t1.match_id = t2.match_id
            AND t1.match_step = $1
            AND t2.match_step = $2
          WHERE t1.match_started_at BETWEEN $3 AND $4
            AND t2.match_started_at BETWEEN $3 AND $4
        )
        SELECT * FROM step_times
      SQL

      binds = [
        first_step,
        second_step,
        @range.start,
        @range.end + 1.day,
      ]

      GrdaWarehouse::CasReport.connection.exec_query(sql, 'SQL', binds).map do |row|
        h = {
          days: (row['time_diff'].to_f / divisor).round.to_i,
          id: row['match_id'],
          program_name: row['program_name'],
          sub_program_name: row['sub_program_name'],
          match_started_at: row['match_started_at'],
          match_route: row['match_route'],
          client_id: row['client_id'],
          cas_client_id: row['cas_client_id'],
          source_data_source: row['source_data_source'],
        }
        ::OpenStruct.new(h)
      end.index_by(&:id)
    end
  end
end
