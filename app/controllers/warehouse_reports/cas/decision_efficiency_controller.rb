###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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

    private def at2
      @at2 ||= begin
        at2 = at.dup
        at2.table_alias = 'at2'
        at2
      end
    end

    private def report_scope
      decision_join = at.join(at2).on(
        at[:client_id].eq(at2[:client_id]).
        and(at[:match_id].eq(at2[:match_id])).
        and(at[:match_step].eq(first_step)).
        and(at2[:match_step].eq(second_step)),
      ).join_sources

      scope = report_source.where(
        at[@filter.interesting_column].
          between(@filter.start..@filter.end + 1.day).
          or(at[@filter.interesting_column].eq(nil)),
      ).
        where(at2[@filter.interesting_column].between(@filter.start..@filter.end + 1.day)).
        joins(:client, match: :programs).
        joins(decision_join).
        order(at[:program_name].asc, at[:sub_program_name].asc)

      user = current_user.cas_user
      chosen_program_ids = CasAccess::Agency.find_by(id: @filter.agency)&.program_ids.presence || CasAccess::Program.pluck(:id)
      chosen_program_ids &= user.agency.program_ids unless user.match_admin?
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
        first_name: cas_c_t[:first_name],
        last_name: cas_c_t[:last_name],
        hsa_contacts: at[:hsa_contacts],
        hsp_contacts: at[:hsp_contacts],
        client_move_in_date: at2[:client_move_in_date],
      }
    end
  end
end
