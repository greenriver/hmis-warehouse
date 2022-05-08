###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Reports
  class Hic::ProjectsController < Hic::BaseController
    def show
      @projects = project_scope.joins(:organization).
        distinct
    end
  end
end
