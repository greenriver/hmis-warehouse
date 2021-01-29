###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Contact
  class Project < Base
    belongs_to :project, class_name: 'GrdaWarehouse::Hud::Project', foreign_key: :entity_id

  end
end
