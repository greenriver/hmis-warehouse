###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::HMIS
  class StaffXClient < Base
    dub 'staff_x_clients'

    belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client', inverse_of: :staff_x_clients
    belongs_to :staff, inverse_of: :staff_x_clients

    scope :primary_caseworker, -> { where relationship_id: 1 }
    scope :support_caseworker, -> { where relationship_id: 2 }

    ROLES = {
      1 => 'Primary Caseworker',
      2 => 'Support Caseworker/Secondary',
    }
  end
end