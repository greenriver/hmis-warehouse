###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::OrganizationsController < Hic::BaseController
    def show
      @organizations = organization_scope.joins(:projects).
        merge(project_scope).
        distinct
      respond_to do |format|
        format.html
        format.csv { send_data GrdaWarehouse::Hud::Organization.to_csv(scope: @organizations), filename: "organization-#{Time.current.to_s(:number)}.csv" }
      end
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization
    end
  end
end
