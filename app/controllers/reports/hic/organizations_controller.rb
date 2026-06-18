###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  class Hic::OrganizationsController < Hic::BaseController
    def show
      @organizations = organization_scope.joins(:projects).
        merge(project_scope).
        distinct
    end

    def organization_scope
      GrdaWarehouse::Hud::Organization
    end
  end
end
