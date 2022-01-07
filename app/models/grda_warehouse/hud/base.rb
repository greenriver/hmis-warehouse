###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Base < GrdaWarehouseBase
    self.abstract_class = true

    scope :in_coc, ->(*) do
      current_scope
    end
  end
end
