###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Contact
  class Organization < Base
    belongs_to :Organization, class_name: 'GrdaWarehouse::Hud::Organization', foreign_key: :entity_id, optional: true

  end
end
