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

    # This will return an equivalent record in the HMIS format
    # Note: this will incur a db call.  Without it, permissions
    # refuse to function.
    def as_hmis
      return self unless HmisEnforcement.hmis_enabled?

      hmis_class = "Hmis::Hud::#{self.class.name.demodulize}".constantize
      hmis_class.find(id)
    end
  end
end
