###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module WarehouseReports
  class ProjectTypeReconciliationController < ApplicationController
    include ArelHelper
    include WarehouseReportAuthorization
    before_action :set_limited, only: [:index]

    def index
      @projects = project_source.joins(:organization, :data_source).
        where(
          p_t[:act_as_project_type].not_eq(nil).
          and(p_t[:act_as_project_type].not_eq(p_t[:ProjectType])),
        ).
        order(ds_t[:short_name].asc, o_t[:OrganizationName].asc, p_t[:ProjectName].asc)
    end

    def project_source
      GrdaWarehouse::Hud::Project.viewable_by(current_user)
    end
  end
end
