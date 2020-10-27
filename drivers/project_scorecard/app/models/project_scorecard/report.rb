###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectScorecard
  class Report < GrdaWarehouseBase
    acts_as_paranoid
    has_paper_trail

    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', optional: true
    belongs_to :project_group, class_name: 'GrdaWarehouse::ProjectGroup', optional: true
    belongs_to :user, class_name: 'User'

    def send_email(from)
      # TODO
    end
  end
end
