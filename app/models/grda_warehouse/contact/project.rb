###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Contact
  class Project < Base
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: :entity_id

  end
end