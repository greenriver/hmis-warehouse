###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module GrdaWarehouse::Vispdat
  class Child < GrdaWarehouseBase
    include HasPiiAttributes

    pii_attr :first_name
    pii_attr :last_name
    pii_attr :dob

    belongs_to :family, optional: true
  end
end
