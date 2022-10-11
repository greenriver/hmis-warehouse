###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Hud
  class IncorrectMoveInDatesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter

    # This logic is based on 9.2 from the 2020 LSA
    def index
      @enrollments = GrdaWarehouse::Hud::Enrollment.heads_of_households.
        where(e_t[:EntryDate].lt(@filter.end)).
        joins(project: :project_cocs, client: :destination_client).
        left_outer_joins(:exit).
        preload(:exit, project: :project_cocs, client: :destination_client).
        merge(
          GrdaWarehouse::Hud::Project.
          viewable_by(current_user).
          coc_funded.
          with_hud_project_type(project_types_requiring_move_in).
          where(id: @filter.effective_project_ids),
        ).
        merge(GrdaWarehouse::Hud::ProjectCoc.with_coc).
        where(
          ex_t[:ExitDate].gteq(@filter.start - 3.years).
          or(ex_t[:ExitDate].eq(nil)),
        ).
        where(
          e_t[:EntryDate].gt(e_t[:MoveInDate]).
          or(ex_t[:ExitDate].lt(e_t[:MoveInDate])).
          or(ex_t[:Destination].in(HUD.permanent_destinations).and(e_t[:MoveInDate].eq(nil))),
        ).
        distinct.
        order(EntryDate: :desc)
      respond_to do |format|
        format.html do
          @pagy, @enrollments = pagy(@enrollments, items: 50)
        end
        format.xlsx {}
      end

      # MoveInDate3 = coalesce((select count(distinct n.EnrollmentID)
      # from dq_Enrollment n
      # inner join lsa_Report rpt on rpt.ReportEnd >= n.EntryDate
      # left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
      #   and x.ExitDate < rpt.ReportEnd
      #   and x.DateDeleted is null
      # where n.RelationshipToHoH = 1
      #   and n.ProjectType in (3,13)
      #   and (x.ExitDate is null or x.ExitDate >= rpt.ReportStart)
      #   and ((n.MoveInDate < n.EntryDate or n.MoveInDate > x.ExitDate)
      #     or (x.Destination in (3,31,19,20,21,26,28,10,11,22,23,33,34)
      #       and n.MoveInDate is null))), 0)
    end

    private def project_types_requiring_move_in
      [3, 13]
    end
    helper_method :project_types_requiring_move_in

    def set_filter
      @filter = ::Filters::FilterBase.new(filter_params.merge(user_id: current_user.id))
    end

    def filter_params
      unless params[:filter].present?
        return {
          start: ::HUD.fiscal_year_start,
          end: ::HUD.fiscal_year_end,
        }
      end

      params.require(:filter).permit(
        :start,
        :end,
        project_ids: [],
        coc_codes: [],
      )
    end
  end
end
