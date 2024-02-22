###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Base < GrdaWarehouseBase
    self.abstract_class = true
    self.lock_optimistically = false
    self.ignored_columns += [:lock_version]
    class_attribute :import_overrides

    scope :in_coc, ->(*) do
      current_scope
    end
  end
end
