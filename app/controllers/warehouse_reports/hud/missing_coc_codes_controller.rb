###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module WarehouseReports::Hud
  class MissingCoCCodesController < ApplicationController
    include WarehouseReportAuthorization

    # This logic is based on 9.2 from the 2020 LSA
    def index
      @enrollments = GrdaWarehouse::Hud::Enrollment.joins(:client, project: :project_cocs).
        left_outer_joins(:enrollment_cocs)

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
  end
end
