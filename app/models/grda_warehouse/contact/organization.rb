###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Contact
  class Organization < Base
    belongs_to :Organization, class_name: GrdaWarehouse::Hud::Organization.name, foreign_key: :entity_id

  end
end