###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Hud
  class MissingCoCCodesController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter

    # This logic is based on 9.2 from the 2020 LSA
    def index
      @enrollments = GrdaWarehouse::Hud::Enrollment.
        heads_of_households.
        where(e_t[:EntryDate].lt(@filter.end)).
        joins(:client, project: :project_cocs).
        left_outer_joins(:enrollment_cocs, :exit).
        preload(:enrollment_cocs, :exit, project: :project_cocs, client: :destination_client).
        merge(
          GrdaWarehouse::Hud::Project.
          viewable_by(current_user).
          coc_funded.
          with_hud_project_type(project_types_requiring_enrollment_coc).
          where(id: @filter.effective_project_ids),
        ).
        merge(GrdaWarehouse::Hud::ProjectCoc.with_coc).
        where(
          ex_t[:ExitDate].gteq(@filter.start - 3.years).
          or(ex_t[:ExitDate].eq(nil)),
        ).
        where(ec_t[:CoCCode].eq(nil)).
        order(EntryDate: :desc)
      respond_to do |format|
        format.html do
          @enrollments = @enrollments.page(params[:page]).per(50)
        end
        format.xlsx {}
      end

      # NoCoC = (select count (distinct n.HouseholdID)
      # from hmis_Enrollment n
      # left outer join hmis_EnrollmentCoC coc on
      #   coc.EnrollmentID = n.EnrollmentID
      #   and coc.DateDeleted is null
      # inner join hmis_Project p on p.ProjectID = n.ProjectID
      #   and p.ContinuumProject = 1 and p.ProjectType in (1,2,3,8,13)
      # inner join hmis_ProjectCoC pcoc on pcoc.CoCCode = rpt.ReportCoC
      #   and pcoc.DateDeleted is null
      # left outer join hmis_Exit x on x.EnrollmentID = n.EnrollmentID
      #   and x.ExitDate >= dateadd(yy, -3, rpt.ReportStart)
      #   and x.DateDeleted is null
      # where n.EntryDate <= rpt.ReportEnd
      #   and n.RelationshipToHoH = 1
      #   and coc.CoCCode is null
      #   and coc.DateDeleted is null)
    end

    private def project_types_requiring_enrollment_coc
      [1, 2, 3, 8, 13]
    end
    helper_method :project_types_requiring_enrollment_coc

    def set_filter
      @filter = ::Filters::DateRangeAndSources.new(filter_params.merge(user_id: current_user.id))
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
        coc_codes: [],
        project_ids: [],
      )
    end
  end
end
