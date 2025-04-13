###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Cas
  class DecisionEfficiencyController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :filter

    def index
      @cas_user = current_user.cas_user
      @data = report_scope
      respond_to do |format|
        format.html {}
        format.xlsx do
          filename = 'Decision Efficiency.xlsx'
          headers['Content-Disposition'] = "attachment; filename=#{filename}"
        end
      end
    end

    private def filter
      @filter = ::CasAccess::Filters::FilterBase.new(
        {
          start: 12.month.ago.to_date,
          end: Date.current,
          interesting_date: 'created',
        }.merge(step_params),
      )
    end

    def mean(array)
      return 0 if array.empty?

      (array.sum.to_f / array.length).round(2)
    end
    helper_method :mean

    def median(array)
      return 0 if array.empty?

      mid = array.size / 2
      sorted = array.sort
      array.length.odd? ? sorted[mid] : (sorted[mid] + sorted[mid - 1]) / 2
    end
    helper_method :median

    private def step_params
      return {} unless params.key? :steps

      params.require(:steps).permit(
        :first_step,
        :second_step,
        :unit,
        :match_route,
        :agency,
        :start,
        :end,
        :interesting_date,
      )
    end

    private def report_source
      CasAccess::Reporting::Decisions
    end

    private def at
      @at ||= report_source.arel_table
    end

    private def cas_c_t
      @cas_c_t ||= CasAccess::Client.arel_table
    end

    private def report_scope
      return report_source.none unless @cas_user.present?

      scope = report_source.
        select("d1.*, d2.id as second_id, d2.updated_at as second_ended_at, d2.client_move_in_date").
        from("#{report_source.table_name} d1").
        joins("INNER JOIN #{report_source.table_name} d2 ON d1.client_id = d2.client_id AND d1.match_id = d2.match_id").
        joins(:client, match: :programs).
        where("d1.match_step = ? AND d2.match_step = ?", first_step, second_step).
        where(
          "d1.#{@filter.interesting_column} BETWEEN ? AND ? OR d1.#{@filter.interesting_column} IS NULL",
          @filter.start,
          @filter.end + 1.day
        ).
        where(
          "d2.#{@filter.interesting_column} BETWEEN ? AND ?",
          @filter.start,
          @filter.end + 1.day
        ).
        order("d1.program_name ASC, d1.sub_program_name ASC")

      chosen_program_ids = CasAccess::Agency.find_by(id: @filter.agency)&.program_ids.presence || CasAccess::Program.pluck(:id)
      chosen_program_ids &= @cas_user.agency.program_ids unless @cas_user.match_admin?
      scope = scope.merge(CasAccess::Program.where(id: chosen_program_ids))

      scope.pluck(*columns.values).map do |row|
        hashed_row = columns.keys.zip(row).to_h
        hashed_row[:days] = (hashed_row[:second_ended_at].to_date - hashed_row[:first_ended_at].to_date).to_i
        hashed_row
      end
    end

    private def first_step
      @first_step ||= @filter.first_step&.gsub(/\(\d+\)/, '')&.strip
    end

    private def second_step
      @second_step ||= @filter.second_step&.gsub(/\(\d+\)/, '')&.strip
    end

    private def columns
      @columns ||= {
        match_route: 'd1.match_route',
        program_name: 'd1.program_name',
        sub_program_name: 'd1.sub_program_name',
        cas_client_id: 'd1.cas_client_id',
        warehouse_client_id: 'd1.client_id',
        match_id: 'd1.match_id',
        match_stated_at: 'd1.match_started_at',
        terminal_status: 'd1.terminal_status',
        first_id: 'd1.id',
        second_id: 'second_id',
        first_ended_at: 'd1.updated_at',
        second_ended_at: 'second_ended_at',
        first_name: "#{CasAccess::Client.table_name}.first_name",
        last_name: "#{CasAccess::Client.table_name}.last_name",
        hsa_contacts: 'd1.hsa_contacts',
        hsp_contacts: 'd1.hsp_contacts',
        client_move_in_date: 'client_move_in_date'
      }
    end
  end
end
