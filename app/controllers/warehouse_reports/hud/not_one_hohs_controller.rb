###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports::Hud
  class NotOneHohsController < ApplicationController
    include WarehouseReportAuthorization
    include ArelHelper
    before_action :set_filter

    # This logic is based on 9.2 from the 2020 LSA
    def index
      @enrollments = GrdaWarehouse::Hud::Enrollment.
        where(e_t[:EntryDate].lt(@filter.end)).
        joins(:client, project: :project_cocs).
        left_outer_joins(:exit).
        preload(client: :destination_client).
        merge(
          GrdaWarehouse::Hud::Project.
          viewable_by(current_user).
          coc_funded.
          with_hud_project_type(project_types_requiring_hoh).
          where(id: @filter.effective_project_ids),
        ).
        merge(GrdaWarehouse::Hud::ProjectCoc.with_coc).
        where(
          ex_t[:ExitDate].gteq(@filter.start - 3.years).
          or(ex_t[:ExitDate].eq(nil)),
        ).
        joins(hoh_count_query).
        where('hoh.hoh_count != 1'). # NOTE: the exporter fixes hoh.HouseholdID is null
        order(EntryDate: :desc, HouseholdID: :asc, RelationshipToHoH: :asc).
        page(params[:page]).per(50)

      # NotOneHoH3 = (select count(distinct n.HouseholdID)
      # from dq_Enrollment n
      # left outer join (select hn.HouseholdID, count(distinct hn.EnrollmentID) as hoh
      #   from hmis_Enrollment hn
      #   where hn.RelationshipToHoH = 1
      #   group by hn.HouseholdID
      # ) hoh on hoh.HouseholdID = n.HouseholdID
      # where hoh.hoh <> 1 or hoh.HouseholdID is null)
    end

    private def hoh_count_query
      <<~SQL
        LEFT OUTER JOIN (
          select en."HouseholdID", en."ProjectID", en."data_source_id", count(distinct(en."EnrollmentID")) as hoh_count
          from "Enrollment" as en
          where en."RelationshipToHoH" = 1
          group by en."HouseholdID", en."ProjectID", en."data_source_id"
        ) as hoh
        on hoh."HouseholdID" = "Enrollment"."HouseholdID"
          and hoh."ProjectID" = "Enrollment"."ProjectID"
          and hoh."data_source_id" = "Enrollment"."data_source_id"
      SQL
    end

    private def project_types_requiring_hoh
      [1, 2, 3, 8, 13]
    end
    helper_method :project_types_requiring_hoh

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
      )
    end
  end
end
