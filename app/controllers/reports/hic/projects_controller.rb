###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Reports
  class Hic::ProjectsController < Hic::BaseController
    def show
      @projects = project_scope.joins(:organization).
        distinct
    end
  end
end
